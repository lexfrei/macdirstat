import SwiftUI
import Testing

@testable import MacDirStatKit

@Suite("FileNode")
struct FileNodeTests {
    @Test func fileHasCorrectSubtreeSize() {
        let node = FileNode(
            name: "test.txt",
            url: URL(filePath: "/tmp/test.txt"),
            isDirectory: false,
            fileSize: 1024,
            fileExtension: "txt"
        )
        #expect(node.subtreeSize == 1024)
        #expect(node.fileSize == 1024)
        #expect(node.isDirectory == false)
        #expect(node.children == nil)
    }

    @Test func directorySubtreeSizeSumsChildren() {
        let child1 = FileNode(
            name: "a.txt",
            url: URL(filePath: "/tmp/dir/a.txt"),
            isDirectory: false,
            fileSize: 100,
            fileExtension: "txt"
        )
        let child2 = FileNode(
            name: "b.png",
            url: URL(filePath: "/tmp/dir/b.png"),
            isDirectory: false,
            fileSize: 200,
            fileExtension: "png"
        )
        let dir = FileNode(
            name: "dir",
            url: URL(filePath: "/tmp/dir"),
            isDirectory: true,
            fileSize: 0,
            children: [child1, child2]
        )
        #expect(dir.subtreeSize == 300)
        #expect(dir.fileSize == 0)
        #expect(dir.children?.count == 2)
    }

    @Test func emptyDirectoryHasZeroSubtreeSize() {
        let dir = FileNode(
            name: "empty",
            url: URL(filePath: "/tmp/empty"),
            isDirectory: true,
            fileSize: 0,
            children: []
        )
        #expect(dir.subtreeSize == 0)
        #expect(dir.children?.isEmpty == true)
    }

    @Test func nestedDirectoriesAccumulateSize() {
        let file = FileNode(
            name: "deep.txt",
            url: URL(filePath: "/tmp/a/b/deep.txt"),
            isDirectory: false,
            fileSize: 500
        )
        let innerDir = FileNode(
            name: "b",
            url: URL(filePath: "/tmp/a/b"),
            isDirectory: true,
            fileSize: 0,
            children: [file]
        )
        let outerDir = FileNode(
            name: "a",
            url: URL(filePath: "/tmp/a"),
            isDirectory: true,
            fileSize: 0,
            children: [innerDir]
        )
        #expect(outerDir.subtreeSize == 500)
        #expect(innerDir.subtreeSize == 500)
    }

    @Test func hashableByID() {
        let id = UUID()
        let node1 = FileNode(
            id: id,
            name: "file.txt",
            url: URL(filePath: "/tmp/file.txt"),
            isDirectory: false,
            fileSize: 100
        )
        let node2 = FileNode(
            id: id,
            name: "file.txt",
            url: URL(filePath: "/tmp/file.txt"),
            isDirectory: false,
            fileSize: 100
        )
        #expect(node1 == node2)
        #expect(node1.hashValue == node2.hashValue)
    }

    @Test func differentIDsAreNotEqual() {
        let node1 = FileNode(
            name: "file.txt",
            url: URL(filePath: "/tmp/file.txt"),
            isDirectory: false,
            fileSize: 100
        )
        let node2 = FileNode(
            name: "file.txt",
            url: URL(filePath: "/tmp/file.txt"),
            isDirectory: false,
            fileSize: 100
        )
        #expect(node1 != node2)
    }

    @Test func fileExtensionIsStored() {
        let node = FileNode(
            name: "image.PNG",
            url: URL(filePath: "/tmp/image.PNG"),
            isDirectory: false,
            fileSize: 2048,
            fileExtension: "png"
        )
        #expect(node.fileExtension == "png")
    }

    @Test func depthIsStored() {
        let node = FileNode(
            name: "deep",
            url: URL(filePath: "/tmp/a/b/c/deep"),
            isDirectory: false,
            fileSize: 100,
            depth: 3
        )
        #expect(node.depth == 3)
    }

    @Test func directoryWithNilChildrenIsFile() {
        let file = FileNode(
            name: "file",
            url: URL(filePath: "/tmp/file"),
            isDirectory: false,
            fileSize: 50
        )
        #expect(file.children == nil)
    }
}
