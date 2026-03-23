import Foundation

public final class FileNode: Sendable, Identifiable, Hashable {
    /// Inode number from the filesystem — unique per volume, zero cost.
    public let id: UInt64
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public let fileSize: Int64
    public let subtreeSize: Int64
    public let children: [FileNode]?
    public let fileExtension: String
    public let depth: Int

    /// Lazy URL — only created when actually needed (Finder reveal, etc.)
    public var url: URL { URL(filePath: path) }

    public init(
        inode: UInt64 = 0,
        name: String,
        path: String,
        isDirectory: Bool,
        fileSize: Int64,
        children: [FileNode]? = nil,
        fileExtension: String = "",
        depth: Int = 0
    ) {
        self.id = inode
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.fileSize = fileSize
        self.children = children
        self.fileExtension = fileExtension
        self.depth = depth

        if isDirectory {
            self.subtreeSize = children?.reduce(0) { $0 + $1.subtreeSize } ?? 0
        } else {
            self.subtreeSize = fileSize
        }
    }

    public static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
