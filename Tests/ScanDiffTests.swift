import SwiftUI
import Testing

@testable import MacDirStatKit

@Suite("ScanDiff")
struct ScanDiffTests {
    private func makeSnapshot(_ files: [(String, Int64)]) -> SnapshotNode {
        let children = files.map { name, size in
            SnapshotNode(
                from: FileNode(
                    name: name, url: URL(filePath: "/tmp/\(name)"),
                    isDirectory: false, fileSize: size,
                    fileExtension: URL(filePath: name).pathExtension.lowercased()))
        }
        return SnapshotNode(
            from: FileNode(
                name: "root", url: URL(filePath: "/tmp"),
                isDirectory: true, fileSize: 0, children: children.map { snap in
                    FileNode(
                        name: snap.name, url: URL(filePath: snap.path),
                        isDirectory: false, fileSize: snap.fileSize,
                        fileExtension: snap.fileExtension)
                }))
    }

    @Test func identicalTreesProduceEmptyDiff() {
        let old = makeSnapshot([("a.txt", 100), ("b.txt", 200)])
        let new = makeSnapshot([("a.txt", 100), ("b.txt", 200)])
        let diff = ScanDiffer.diff(old: old, new: new)
        #expect(diff.entries.isEmpty)
        #expect(diff.totalSizeDelta == 0)
    }

    @Test func detectsAddedFiles() {
        let old = makeSnapshot([("a.txt", 100)])
        let new = makeSnapshot([("a.txt", 100), ("b.txt", 200)])
        let diff = ScanDiffer.diff(old: old, new: new)
        #expect(diff.added.count == 1)
        #expect(diff.added[0].name == "b.txt")
        #expect(diff.added[0].newSize == 200)
    }

    @Test func detectsRemovedFiles() {
        let old = makeSnapshot([("a.txt", 100), ("b.txt", 200)])
        let new = makeSnapshot([("a.txt", 100)])
        let diff = ScanDiffer.diff(old: old, new: new)
        #expect(diff.removed.count == 1)
        #expect(diff.removed[0].name == "b.txt")
        #expect(diff.removed[0].oldSize == 200)
    }

    @Test func detectsSizeChanges() {
        let old = makeSnapshot([("a.txt", 100)])
        let new = makeSnapshot([("a.txt", 500)])
        let diff = ScanDiffer.diff(old: old, new: new)
        #expect(diff.changed.count == 1)
        #expect(diff.changed[0].sizeDelta == 400)
    }

    @Test func totalSizeDeltaIsCorrect() {
        let old = makeSnapshot([("a.txt", 100)])
        let new = makeSnapshot([("a.txt", 100), ("b.txt", 300)])
        let diff = ScanDiffer.diff(old: old, new: new)
        #expect(diff.totalSizeDelta == 300)
    }

    @Test func entriesSortedByAbsSizeDelta() {
        let old = makeSnapshot([("small.txt", 100), ("big.txt", 100)])
        let new = makeSnapshot([("small.txt", 110), ("big.txt", 1000)])
        let diff = ScanDiffer.diff(old: old, new: new)
        #expect(diff.entries.count == 2)
        #expect(abs(diff.entries[0].sizeDelta) >= abs(diff.entries[1].sizeDelta))
    }
}

@Suite("ScanSnapshot")
struct ScanSnapshotTests {
    @Test func roundTripsViaSerialization() throws {
        let root = FileNode(
            name: "root", url: URL(filePath: "/tmp"),
            isDirectory: true, fileSize: 0,
            children: [
                FileNode(
                    name: "file.txt", url: URL(filePath: "/tmp/file.txt"),
                    isDirectory: false, fileSize: 1024, fileExtension: "txt")
            ])

        let snapshot = ScanSnapshot(from: root)
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("snapshot-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempFile) }

        try snapshot.save(to: tempFile)
        let loaded = try ScanSnapshot.load(from: tempFile)

        #expect(loaded.rootPath == snapshot.rootPath)
        #expect(loaded.totalSize == snapshot.totalSize)
        #expect(loaded.fileCount == snapshot.fileCount)
        #expect(loaded.tree.name == "root")
        #expect(loaded.tree.children?.count == 1)
    }
}
