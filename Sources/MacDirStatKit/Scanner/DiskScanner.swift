import Foundation

public protocol FileSystemScanning: Sendable {
    func scan(url: URL, progressHandler: @escaping @MainActor @Sendable (Int, String) -> Void) async throws
        -> FileNode
}

public struct FileManagerScanner: FileSystemScanning {
    private let progressBatchSize: Int

    public init(progressBatchSize: Int = 500) {
        self.progressBatchSize = progressBatchSize
    }

    public func scan(
        url: URL, progressHandler: @escaping @MainActor @Sendable (Int, String) -> Void
    ) async throws -> FileNode {
        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey, .isDirectoryKey, .totalFileAllocatedSizeKey,
        ]
        var fileCount = 0
        let root = try await scanDirectory(
            url: url, depth: 0, resourceKeys: resourceKeys,
            fileCount: &fileCount, progressHandler: progressHandler)
        return root
    }

    private func scanDirectory(
        url: URL,
        depth: Int,
        resourceKeys: Set<URLResourceKey>,
        fileCount: inout Int,
        progressHandler: @escaping @MainActor @Sendable (Int, String) -> Void
    ) async throws -> FileNode {
        let fm = FileManager.default
        let contents: [URL]
        do {
            contents = try fm.contentsOfDirectory(
                at: url, includingPropertiesForKeys: Array(resourceKeys),
                options: []
            )
        } catch {
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

            let isDirectory = resourceValues.isDirectory ?? false

            if isDirectory {
                let child = try await scanDirectory(
                    url: childURL, depth: depth + 1, resourceKeys: resourceKeys,
                    fileCount: &fileCount, progressHandler: progressHandler)
                children.append(child)
            } else {
                let size = Int64(
                    resourceValues.totalFileAllocatedSize ?? resourceValues.fileSize ?? 0)
                let ext = childURL.pathExtension.lowercased()
                let node = FileNode(
                    name: childURL.lastPathComponent, url: childURL,
                    isDirectory: false, fileSize: size,
                    fileExtension: ext, depth: depth + 1)
                children.append(node)
            }

            fileCount += 1
            if fileCount % progressBatchSize == 0 {
                let count = fileCount
                let path = childURL.lastPathComponent
                await MainActor.run { progressHandler(count, path) }
            }
        }

        children.sort { $0.subtreeSize > $1.subtreeSize }

        return FileNode(
            name: url.lastPathComponent, url: url, isDirectory: true,
            fileSize: 0, children: children,
            depth: depth)
    }
}
