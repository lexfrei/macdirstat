import Foundation

/// Sequential ID generator — much faster than UUID() for millions of nodes.
private let nextID = _NextID()
private final class _NextID: @unchecked Sendable {
    private let _value = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
    init() { _value.initialize(to: 0) }
    func next() -> Int64 { OSAtomicIncrement64(_value) }
}

public final class FileNode: Sendable, Identifiable, Hashable {
    public let id: Int64
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
        name: String,
        path: String,
        isDirectory: Bool,
        fileSize: Int64,
        children: [FileNode]? = nil,
        fileExtension: String = "",
        depth: Int = 0
    ) {
        self.id = nextID.next()
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
