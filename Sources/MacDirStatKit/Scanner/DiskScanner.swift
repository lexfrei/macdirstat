import Foundation

public protocol FileSystemScanning: Sendable {
    func scan(
        url: URL,
        progressHandler: @escaping @MainActor @Sendable (Int, String, Int) -> Void
    ) async throws -> FileNode
}

public struct FileManagerScanner: FileSystemScanning {
    private let progressBatchSize: Int

    public init(progressBatchSize: Int = 500) {
        self.progressBatchSize = progressBatchSize
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

        // Get the volume identifier of the root to avoid crossing filesystem boundaries
        let rootVolumeID = try url.resourceValues(forKeys: [.volumeIdentifierKey])
            .volumeIdentifier as? NSObject

        var fileCount = 0
        var skippedDirs = 0
        let root = try await scanDirectory(
            url: url, depth: 0, resourceKeys: resourceKeys,
            rootVolumeID: rootVolumeID,
            fileCount: &fileCount, skippedDirs: &skippedDirs,
            progressHandler: progressHandler)
        let finalCount = fileCount
        let finalSkipped = skippedDirs
        await MainActor.run { progressHandler(finalCount, "", finalSkipped) }
        return root
    }

    private func scanDirectory(
        url: URL,
        depth: Int,
        resourceKeys: Set<URLResourceKey>,
        rootVolumeID: NSObject?,
        fileCount: inout Int,
        skippedDirs: inout Int,
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
            skippedDirs += 1
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

            // Skip entries on different volumes (network mounts, external drives under /Volumes)
            if let rootVol = rootVolumeID,
                let childVol = resourceValues.volumeIdentifier as? NSObject,
                rootVol != childVol
            {
                skippedDirs += 1
                continue
            }

            let isDirectory = resourceValues.isDirectory ?? false

            if isDirectory {
                let child = try await scanDirectory(
                    url: childURL, depth: depth + 1, resourceKeys: resourceKeys,
                    rootVolumeID: rootVolumeID,
                    fileCount: &fileCount, skippedDirs: &skippedDirs,
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
                fileCount += 1
            }

            if fileCount > 0, fileCount % progressBatchSize == 0 {
                let count = fileCount
                let path = childURL.lastPathComponent
                let skipped = skippedDirs
                await MainActor.run { progressHandler(count, path, skipped) }
            }
        }

        children.sort { $0.subtreeSize > $1.subtreeSize }

        return FileNode(
            name: url.lastPathComponent, url: url, isDirectory: true,
            fileSize: 0, children: children,
            depth: depth)
    }

    /// Returns the physical on-disk size, accounting for iCloud-evicted files.
    /// For files evicted to iCloud, totalFileAllocatedSize is 0 or minimal — we use that.
    /// We never fall back to logical fileSize, since we want actual disk usage.
    private func physicalSize(for values: URLResourceValues) -> Int64 {
        // If it's an iCloud item that isn't downloaded, report 0 disk usage
        if values.isUbiquitousItem == true {
            let status = values.ubiquitousItemDownloadingStatus
            if status != .current {
                // File is evicted or downloading — not fully on disk
                return Int64(values.totalFileAllocatedSize ?? 0)
            }
        }

        // Use physical allocated size (accounts for sparse files, compression)
        // Fall back to logical size only for non-iCloud local files
        return Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
    }
}
