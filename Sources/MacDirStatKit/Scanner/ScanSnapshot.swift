import Foundation

public struct ScanSnapshot: Codable, Sendable {
    public let date: Date
    public let rootPath: String
    public let fileCount: Int
    public let totalSize: Int64
    public let tree: SnapshotNode

    public init(from node: FileNode) {
        self.date = Date()
        self.rootPath = node.url.path(percentEncoded: false)
        self.totalSize = node.subtreeSize
        self.tree = SnapshotNode(from: node)
        self.fileCount = Self.countFiles(node)
    }

    private static func countFiles(_ node: FileNode) -> Int {
        if node.isDirectory {
            return (node.children ?? []).reduce(0) { $0 + countFiles($1) }
        }
        return 1
    }

    public func save(to url: URL) throws {
        let data = try JSONEncoder().encode(self)
        try data.write(to: url)
    }

    public static func load(from url: URL) throws -> ScanSnapshot {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ScanSnapshot.self, from: data)
    }
}

public struct SnapshotNode: Codable, Sendable {
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public let fileSize: Int64
    public let subtreeSize: Int64
    public let fileExtension: String
    public let children: [SnapshotNode]?

    public init(from node: FileNode) {
        self.name = node.name
        self.path = node.url.path(percentEncoded: false)
        self.isDirectory = node.isDirectory
        self.fileSize = node.fileSize
        self.subtreeSize = node.subtreeSize
        self.fileExtension = node.fileExtension
        self.children = node.children?.map { SnapshotNode(from: $0) }
    }
}
