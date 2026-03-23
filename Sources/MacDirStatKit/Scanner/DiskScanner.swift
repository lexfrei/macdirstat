import Darwin
import Foundation

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

        let rootDevice: dev_t = try {
            var sb = stat()
            guard lstat(path, &sb) == 0 else {
                throw ScanError.cannotAccessPath(path)
            }
            return sb.st_dev
        }()

        let state = ScanState()
        let intervalNs = progressIntervalMs * 1_000_000

        let root = try await ftsWalk(
            path: path, depth: 0, rootDevice: rootDevice,
            state: state, progressIntervalNs: intervalNs,
            progressHandler: progressHandler)

        let snap = state.snapshot()
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
            state.incrementSkipped()
            return FileNode(
                name: Self.lastName(from: path), path: path,
                isDirectory: true, fileSize: 0, children: [], depth: depth)
        }
        defer { fts_close(fts) }

        var rootNode: FileNode?
        var dirStack: [(path: String, children: [FileNode], depth: Int)] = []

        while let entry = fts_read(fts) {
            try Task.checkCancellation()

            let info = entry.pointee.fts_info
            let entryPath = String(cString: entry.pointee.fts_path)
            let entryName = Self.lastName(from: entryPath)
            let statp = entry.pointee.fts_statp!.pointee

            // Skip APFS system volume files (very large inodes)
            if statp.st_ino > Self.systemVolumeInodeThreshold {
                if info == FTS_D { fts_set(fts, entry, FTS_SKIP) }
                continue
            }

            // Skip different devices
            if statp.st_dev != rootDevice {
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
                dirStack.append((path: entryPath, children: [], depth: entryDepth))
                state.incrementItems()

            case FTS_DP:
                guard let current = dirStack.popLast() else { continue }
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
                } else {
                    dirStack[dirStack.count - 1].children.append(dirNode)
                }

            case FTS_F:
                let size = Int64(statp.st_size)
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
