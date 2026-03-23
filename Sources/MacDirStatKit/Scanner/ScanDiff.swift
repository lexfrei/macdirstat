import Foundation

public struct ScanDiffEntry: Sendable {
    public let path: String
    public let name: String
    public let oldSize: Int64?
    public let newSize: Int64?
    public let fileExtension: String

    public var sizeDelta: Int64 {
        (newSize ?? 0) - (oldSize ?? 0)
    }

    public var isAdded: Bool { oldSize == nil && newSize != nil }
    public var isRemoved: Bool { oldSize != nil && newSize == nil }
    public var isChanged: Bool { oldSize != nil && newSize != nil && oldSize != newSize }
}

public struct ScanDiffResult: Sendable {
    public let entries: [ScanDiffEntry]
    public let totalSizeDelta: Int64

    public var added: [ScanDiffEntry] { entries.filter(\.isAdded) }
    public var removed: [ScanDiffEntry] { entries.filter(\.isRemoved) }
    public var changed: [ScanDiffEntry] { entries.filter(\.isChanged) }

    public init(entries: [ScanDiffEntry]) {
        self.entries = entries
        self.totalSizeDelta = entries.reduce(0) { $0 + $1.sizeDelta }
    }
}

public enum ScanDiffer {
    public static func diff(old: SnapshotNode, new: SnapshotNode) -> ScanDiffResult {
        var oldFiles: [String: (Int64, String)] = [:]
        var newFiles: [String: (Int64, String)] = [:]

        collectFiles(old, into: &oldFiles)
        collectFiles(new, into: &newFiles)

        var entries: [ScanDiffEntry] = []

        let allPaths = Set(oldFiles.keys).union(newFiles.keys)
        for path in allPaths {
            let oldInfo = oldFiles[path]
            let newInfo = newFiles[path]
            let name = URL(filePath: path).lastPathComponent
            let ext = oldInfo?.1 ?? newInfo?.1 ?? ""

            if oldInfo?.0 != newInfo?.0 {
                entries.append(ScanDiffEntry(
                    path: path, name: name,
                    oldSize: oldInfo?.0, newSize: newInfo?.0,
                    fileExtension: ext))
            }
        }

        entries.sort { abs($0.sizeDelta) > abs($1.sizeDelta) }
        return ScanDiffResult(entries: entries)
    }

    private static func collectFiles(
        _ node: SnapshotNode, into files: inout [String: (Int64, String)]
    ) {
        if node.isDirectory {
            for child in node.children ?? [] {
                collectFiles(child, into: &files)
            }
        } else {
            files[node.path] = (node.fileSize, node.fileExtension)
        }
    }
}
