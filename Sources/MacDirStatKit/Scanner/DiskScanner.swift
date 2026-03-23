import Foundation

public protocol FileSystemScanning: Sendable {
    func scan(
        url: URL,
        progressHandler: @escaping @MainActor @Sendable (Int, String, Int) -> Void
    ) async throws -> FileNode
}

public struct FileManagerScanner: FileSystemScanning {
    private let progressIntervalMs: UInt64

    public init(progressIntervalMs: UInt64 = 100) {
        self.progressIntervalMs = progressIntervalMs
    }

    public func scan(
        url: URL,
        progressHandler: @escaping @MainActor @Sendable (Int, String, Int) -> Void
    ) async throws -> FileNode {
        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey, .isDirectoryKey, .totalFileAllocatedSizeKey,
            .isSymbolicLinkKey, .volumeIdentifierKey, .isUbiquitousItemKey,
            .ubiquitousItemDownloadingStatusKey,
        ]

        let rootVolumeID = try url.resourceValues(forKeys: [.volumeIdentifierKey])
            .volumeIdentifier as? NSObject

        let state = ScanState()
        let intervalNs = progressIntervalMs * 1_000_000

        let root = try await scanDirectory(
            url: url, depth: 0, resourceKeys: resourceKeys,
            rootVolumeID: rootVolumeID, state: state,
            progressIntervalNs: intervalNs,
            progressHandler: progressHandler)

        await MainActor.run {
            progressHandler(state.itemCount, "", state.skippedDirs)
        }
        return root
    }

    private func scanDirectory(
        url: URL,
        depth: Int,
        resourceKeys: Set<URLResourceKey>,
        rootVolumeID: NSObject?,
        state: ScanState,
        progressIntervalNs: UInt64,
        progressHandler: @escaping @MainActor @Sendable (Int, String, Int) -> Void
    ) async throws -> FileNode {
        let fm = FileManager.default
        let contents: [URL]
        do {
            contents = try fm.contentsOfDirectory(
                at: url, includingPropertiesForKeys: Array(resourceKeys),
                options: []
            )
        } catch {
            state.skippedDirs += 1
            return FileNode(
                name: url.lastPathComponent, url: url, isDirectory: true,
                fileSize: 0, children: [], depth: depth)
        }

        var children: [FileNode] = []
        for childURL in contents {
            try Task.checkCancellation()

            let resourceValues: URLResourceValues
            do {
                resourceValues = try childURL.resourceValues(forKeys: resourceKeys)
            } catch {
                continue
            }

            if resourceValues.isSymbolicLink == true {
                continue
            }

            if let rootVol = rootVolumeID,
                let childVol = resourceValues.volumeIdentifier as? NSObject,
                rootVol != childVol
            {
                state.skippedDirs += 1
                continue
            }

            let isDirectory = resourceValues.isDirectory ?? false

            if isDirectory {
                let child = try await scanDirectory(
                    url: childURL, depth: depth + 1, resourceKeys: resourceKeys,
                    rootVolumeID: rootVolumeID, state: state,
                    progressIntervalNs: progressIntervalNs,
                    progressHandler: progressHandler)
                children.append(child)
            } else {
                let size = physicalSize(for: resourceValues)
                let ext = childURL.pathExtension.lowercased()
                let node = FileNode(
                    name: childURL.lastPathComponent, url: childURL,
                    isDirectory: false, fileSize: size,
                    fileExtension: ext, depth: depth + 1)
                children.append(node)
            }

            state.itemCount += 1

            let now = DispatchTime.now().uptimeNanoseconds
            if now - state.lastProgressTime >= progressIntervalNs {
                state.lastProgressTime = now
                let count = state.itemCount
                let path = childURL.lastPathComponent
                let skipped = state.skippedDirs
                await MainActor.run { progressHandler(count, path, skipped) }
            }
        }

        children.sort { $0.subtreeSize > $1.subtreeSize }

        return FileNode(
            name: url.lastPathComponent, url: url, isDirectory: true,
            fileSize: 0, children: children,
            depth: depth)
    }

    private func physicalSize(for values: URLResourceValues) -> Int64 {
        if values.isUbiquitousItem == true {
            let status = values.ubiquitousItemDownloadingStatus
            if status != .current {
                return Int64(values.totalFileAllocatedSize ?? 0)
            }
        }
        return Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
    }
}

private final class ScanState: @unchecked Sendable {
    var itemCount: Int = 0
    var skippedDirs: Int = 0
    var lastProgressTime: UInt64 = 0
}
