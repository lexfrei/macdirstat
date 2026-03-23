import Darwin
import Foundation

public protocol FileSystemScanning: Sendable {
    func scan(
        url: URL,
        progressHandler: @escaping @MainActor @Sendable (Int, Int, String, Int) -> Void
    ) async throws -> FileNode
}

// MARK: - FTS-based fast scanner

public struct FileManagerScanner: FileSystemScanning {
    private let progressIntervalMs: UInt64
    /// Inode threshold for APFS system volume files (2^62)
    private static let systemVolumeInodeThreshold: UInt64 = 1 << 62

    public init(progressIntervalMs: UInt64 = 100) {
        self.progressIntervalMs = progressIntervalMs
    }

    public func scan(
        url: URL,
        progressHandler: @escaping @MainActor @Sendable (Int, Int, String, Int) -> Void
    ) async throws -> FileNode {
        let path = url.path(percentEncoded: false)
        let estimatedTotal = Self.estimatedItemCount(at: path)

        // Get root device to stay on same filesystem
        let rootDevice: dev_t = try {
            var sb = stat()
            guard lstat(path, &sb) == 0 else {
                throw ScanError.cannotAccessPath(path)
            }
            return sb.st_dev
        }()

        await MainActor.run { progressHandler(0, estimatedTotal, "", 0) }

        let state = ScanState()
        let intervalNs = progressIntervalMs * 1_000_000

        let root = try await ftsWalk(
            path: path, depth: 0, rootDevice: rootDevice,
            state: state, estimatedTotal: estimatedTotal,
            progressIntervalNs: intervalNs, progressHandler: progressHandler)

        let finalSnap = state.snapshot()
        await MainActor.run {
            progressHandler(finalSnap.itemCount, estimatedTotal, "", finalSnap.skippedDirs)
        }
        return root
    }

    private func ftsWalk(
        path: String,
        depth: Int,
        rootDevice: dev_t,
        state: ScanState,
        estimatedTotal: Int,
        progressIntervalNs: UInt64,
        progressHandler: @escaping @MainActor @Sendable (Int, Int, String, Int) -> Void
    ) async throws -> FileNode {
        // Use fts_open for fast directory traversal
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
                name: URL(filePath: path).lastPathComponent, url: URL(filePath: path),
                isDirectory: true, fileSize: 0, children: [], depth: depth)
        }
        defer { fts_close(fts) }

        // Build tree from fts entries
        var rootNode: FileNode?
        var dirStack: [(path: String, children: [FileNode], depth: Int)] = []

        while let entry = fts_read(fts) {
            try Task.checkCancellation()

            let info = entry.pointee.fts_info
            let entryPath = String(cString: entry.pointee.fts_path)
            let entryName = URL(filePath: entryPath).lastPathComponent
            let stat = entry.pointee.fts_statp.pointee

            // Skip APFS system volume files (very large inodes)
            if stat.st_ino > Self.systemVolumeInodeThreshold {
                if info == FTS_D { fts_set(fts, entry, FTS_SKIP) }
                continue
            }

            // Skip different devices (shouldn't happen with FTS_XDEV, but safety)
            if stat.st_dev != rootDevice {
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
                // Entering directory — push onto stack
                dirStack.append((path: entryPath, children: [], depth: entryDepth))

            case FTS_DP:
                // Leaving directory — build node from accumulated children
                guard let current = dirStack.popLast() else { continue }
                var sorted = current.children
                sorted.sort { $0.subtreeSize > $1.subtreeSize }
                let dirNode = FileNode(
                    name: entryName,
                    url: URL(filePath: entryPath),
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
                // Regular file
                let size = Int64(stat.st_blocks) * 512  // Physical blocks * block size
                let url = URL(filePath: entryPath)
                let ext = fileExtension(from: entryName)
                let node = FileNode(
                    name: entryName,
                    url: url,
                    isDirectory: false,
                    fileSize: size,
                    fileExtension: ext,
                    depth: entryDepth)

                if !dirStack.isEmpty {
                    dirStack[dirStack.count - 1].children.append(node)
                }

                state.incrementItems()

            case FTS_DNR, FTS_ERR:
                // Cannot read directory or error
                state.incrementSkipped()

            default:
                break
            }

            // Time-based progress reporting (atomic check + update)
            let now = DispatchTime.now().uptimeNanoseconds
            if state.shouldReportProgress(now: now, interval: progressIntervalNs) {
                let snap = state.snapshot()
                let total = estimatedTotal
                let name = entryName
                await MainActor.run { progressHandler(snap.itemCount, total, name, snap.skippedDirs) }
            }
        }

        return rootNode ?? FileNode(
            name: URL(filePath: path).lastPathComponent,
            url: URL(filePath: path),
            isDirectory: true, fileSize: 0, children: [], depth: depth)
    }

    private func fileExtension(from name: String) -> String {
        guard let dotIndex = name.lastIndex(of: "."),
            dotIndex != name.startIndex,
            name.index(after: dotIndex) != name.endIndex
        else { return "" }
        return String(name[name.index(after: dotIndex)...]).lowercased()
    }

    private static func estimatedItemCount(at path: String) -> Int {
        let buf = UnsafeMutablePointer<statfs>.allocate(capacity: 1)
        defer { buf.deallocate() }
        guard path.withCString({ statfs($0, buf) }) == 0 else { return 0 }
        return Int(buf.pointee.f_files) - Int(buf.pointee.f_ffree)
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

/// Thread-safe scan state. All mutations go through the lock as compound operations.
private final class ScanState: @unchecked Sendable {
    private let lock = NSLock()
    private var _itemCount: Int = 0
    private var _skippedDirs: Int = 0
    private var _lastProgressTime: UInt64 = 0

    var itemCount: Int { lock.withLock { _itemCount } }
    var skippedDirs: Int { lock.withLock { _skippedDirs } }
    var lastProgressTime: UInt64 { lock.withLock { _lastProgressTime } }

    func incrementItems() { lock.withLock { _itemCount += 1 } }
    func incrementSkipped() { lock.withLock { _skippedDirs += 1 } }

    /// Check and update progress time atomically. Returns true if enough time passed.
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
