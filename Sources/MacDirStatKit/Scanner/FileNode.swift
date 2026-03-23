import Foundation

public final class FileNode: Sendable, Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let url: URL
    public let isDirectory: Bool
    public let fileSize: Int64
    public let subtreeSize: Int64
    public let children: [FileNode]?
    public let fileExtension: String
    public let depth: Int

    public init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        isDirectory: Bool,
        fileSize: Int64,
        children: [FileNode]? = nil,
        fileExtension: String = "",
        depth: Int = 0
    ) {
        self.id = id
        self.name = name
        self.url = url
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
