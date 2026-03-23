import Darwin
import Foundation

private let scanLogEnabled = ProcessInfo.processInfo.environment["MACDIRSTAT_DEBUG"] != nil

private let scanLog: FileHandle? = {
    guard scanLogEnabled else { return nil }
    let path = "/tmp/macdirstat-scan.log"
    FileManager.default.createFile(atPath: path, contents: nil)
    return FileHandle(forWritingAtPath: path)
}()

private func log(_ msg: String) {
    guard scanLogEnabled else { return }
    scanLog?.seekToEndOfFile()
    scanLog?.write((msg + "\n").data(using: .utf8)!)
}

public protocol FileSystemScanning: Sendable {
    func scan(
        url: URL,
        progressHandler: @escaping @MainActor @Sendable (Int, String, Int) -> Void
    ) async throws -> FileNode
}

public struct FileManagerScanner: FileSystemScanning {
    private let progressIntervalMs: UInt64
    private static let systemVolumeInodeThreshold: UInt64 = 1 << 62

    public init(progressIntervalMs: UInt64 = 100) {
        self.progressIntervalMs = progressIntervalMs
    }

    public func scan(
        url: URL,
        progressHandler: @escaping @MainActor @Sendable (Int, String, Int) -> Void
    ) async throws -> FileNode {
        let path = url.path(percentEncoded: false)
        log("SCAN_START: path=\(path)")

        let rootDevice: dev_t = try {
            var sb = stat()
            guard lstat(path, &sb) == 0 else {
                throw ScanError.cannotAccessPath(path)
            }
            return sb.st_dev
        }()
        log("ROOT_DEV: \(rootDevice)")

        let state = ScanState()
        let intervalNs = progressIntervalMs * 1_000_000

        let root = try await ftsWalk(
            path: path, depth: 0, rootDevice: rootDevice,
            state: state, progressIntervalNs: intervalNs,
            progressHandler: progressHandler)

        let snap = state.snapshot()
        log("SCAN_DONE: items=\(snap.itemCount) skipped=\(snap.skippedDirs) rootSubtreeSize=\(root.subtreeSize) rootChildren=\(root.children?.count ?? -1)")
        await MainActor.run { progressHandler(snap.itemCount, "", snap.skippedDirs) }
        return root
    }

    private func ftsWalk(
        path: String,
        depth: Int,
        rootDevice: dev_t,
        state: ScanState,
        progressIntervalNs: UInt64,
        progressHandler: @escaping @MainActor @Sendable (Int, String, Int) -> Void
    ) async throws -> FileNode {
        guard
            let fts = path.withCString({ cPath in
                var paths: [UnsafeMutablePointer<CChar>?] = [
                    UnsafeMutablePointer(mutating: cPath), nil,
                ]
                return fts_open(&paths, FTS_PHYSICAL | FTS_NOCHDIR | FTS_XDEV, nil)
            })
        else {
            log("FTS_OPEN_FAILED: \(path)")
            state.incrementSkipped()
            return FileNode(
                name: Self.lastName(from: path), path: path,
                isDirectory: true, fileSize: 0, children: [], depth: depth)
        }
        defer { fts_close(fts) }

        var rootNode: FileNode?
        var dirStack: [(path: String, children: [FileNode], depth: Int, level: Int)] = []
        var infoHistogram: [UInt16: Int] = [:]
        var totalFileSize: Int64 = 0
        var ftsDPMatched = 0
        var ftsDPSkipped = 0

        while let entry = fts_read(fts) {
            try Task.checkCancellation()

            let info = entry.pointee.fts_info
            let entryPath = String(cString: entry.pointee.fts_path)
            let entryName = Self.lastName(from: entryPath)
            let statp = entry.pointee.fts_statp!.pointee

            infoHistogram[info, default: 0] += 1

            // FTS_DP must ALWAYS reach the switch to pop dirStack.
            let isFTSDP = (Int32(info) == FTS_DP)

            // Skip APFS system volume files (very large inodes)
            if !isFTSDP, statp.st_ino > Self.systemVolumeInodeThreshold {
                if info == FTS_D { fts_set(fts, entry, FTS_SKIP) }
                continue
            }

            // Skip different devices
            if !isFTSDP, statp.st_dev != rootDevice {
                if info == FTS_D { fts_set(fts, entry, FTS_SKIP) }
                state.incrementSkipped()
                continue
            }

            // Skip symlinks
            if info == FTS_SL || info == FTS_SLNONE {
                continue
            }

            let entryDepth = Int(entry.pointee.fts_level) + depth

            switch Int32(info) {
            case FTS_D:
                let level = Int(entry.pointee.fts_level)
                dirStack.append((path: entryPath, children: [], depth: entryDepth, level: level))
                state.incrementItems()

            case FTS_DP:
                // Pop by fts_level — firmlinks can change paths between FTS_D and FTS_DP
                let level = Int(entry.pointee.fts_level)
                guard let top = dirStack.last, top.level == level else {
                    ftsDPSkipped += 1
                    continue
                }
                ftsDPMatched += 1
                let current = dirStack.removeLast()
                var sorted = current.children
                sorted.sort { $0.subtreeSize > $1.subtreeSize }
                let dirNode = FileNode(
                    inode: statp.st_ino,
                    name: entryName,
                    path: entryPath,
                    isDirectory: true,
                    fileSize: 0,
                    children: sorted,
                    depth: current.depth)

                if dirStack.isEmpty {
                    rootNode = dirNode
                    log("ROOT_SET: \(entryPath) subtreeSize=\(dirNode.subtreeSize) children=\(sorted.count)")
                } else {
                    dirStack[dirStack.count - 1].children.append(dirNode)
                }

            case FTS_F:
                let size = Int64(statp.st_size)
                totalFileSize += size
                let ext = Self.fileExtension(from: entryName)
                let node = FileNode(
                    inode: statp.st_ino,
                    name: entryName,
                    path: entryPath,
                    isDirectory: false,
                    fileSize: size,
                    fileExtension: ext,
                    depth: entryDepth)

                if !dirStack.isEmpty {
                    dirStack[dirStack.count - 1].children.append(node)
                }
                state.incrementItems()

            case FTS_DNR, FTS_ERR:
                state.incrementSkipped()

            default:
                break
            }

            let now = DispatchTime.now().uptimeNanoseconds
            if state.shouldReportProgress(now: now, interval: progressIntervalNs) {
                let snap = state.snapshot()
                let name = entryName
                await MainActor.run { progressHandler(snap.itemCount, name, snap.skippedDirs) }
            }
        }

        log("LOOP_END: rootNode=\(rootNode != nil) dirStack=\(dirStack.count) ftsDPMatched=\(ftsDPMatched) ftsDPSkipped=\(ftsDPSkipped) totalFileSize=\(totalFileSize)")
        log("INFO_HIST: \(infoHistogram.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" }.joined(separator: " "))")

        return rootNode ?? FileNode(
            name: Self.lastName(from: path), path: path,
            isDirectory: true, fileSize: 0, children: [], depth: depth)
    }

    static func lastName(from path: String) -> String {
        guard let slashIdx = path.lastIndex(of: "/") else { return path }
        let afterSlash = path.index(after: slashIdx)
        guard afterSlash < path.endIndex else { return path }
        return String(path[afterSlash...])
    }

    static func fileExtension(from name: String) -> String {
        guard let dotIndex = name.lastIndex(of: "."),
            dotIndex != name.startIndex,
            name.index(after: dotIndex) != name.endIndex
        else { return "" }
        return String(name[name.index(after: dotIndex)...]).lowercased()
    }
}

public enum ScanError: Error, LocalizedError {
    case cannotAccessPath(String)

    public var errorDescription: String? {
        switch self {
        case .cannotAccessPath(let path):
            return "Cannot access path: \(path)"
        }
    }
}

private final class ScanState: @unchecked Sendable {
    private let lock = NSLock()
    private var _itemCount: Int = 0
    private var _skippedDirs: Int = 0
    private var _lastProgressTime: UInt64 = 0

    var itemCount: Int { lock.withLock { _itemCount } }
    var skippedDirs: Int { lock.withLock { _skippedDirs } }

    func incrementItems() { lock.withLock { _itemCount += 1 } }
    func incrementSkipped() { lock.withLock { _skippedDirs += 1 } }

    func shouldReportProgress(now: UInt64, interval: UInt64) -> Bool {
        lock.withLock {
            if now - _lastProgressTime >= interval {
                _lastProgressTime = now
                return true
            }
            return false
        }
    }

    func snapshot() -> (itemCount: Int, skippedDirs: Int) {
        lock.withLock { (_itemCount, _skippedDirs) }
    }
}
