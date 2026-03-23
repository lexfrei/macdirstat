import SwiftUI
import Testing

@testable import MacDirStatKit

@Suite("FileNode")
struct FileNodeTests {
    @Test func fileHasCorrectSubtreeSize() {
        let node = FileNode(
            name: "test.txt",
            path: "/tmp/test.txt",
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
            path: "/tmp/dir/a.txt",
            isDirectory: false,
            fileSize: 100,
            fileExtension: "txt"
        )
        let child2 = FileNode(
            name: "b.png",
            path: "/tmp/dir/b.png",
            isDirectory: false,
            fileSize: 200,
            fileExtension: "png"
        )
        let dir = FileNode(
            name: "dir",
            path: "/tmp/dir",
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
            path: "/tmp/empty",
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
            path: "/tmp/a/b/deep.txt",
            isDirectory: false,
            fileSize: 500
        )
        let innerDir = FileNode(
            name: "b",
            path: "/tmp/a/b",
            isDirectory: true,
            fileSize: 0,
            children: [file]
        )
        let outerDir = FileNode(
            name: "a",
            path: "/tmp/a",
            isDirectory: true,
            fileSize: 0,
            children: [innerDir]
        )
        #expect(outerDir.subtreeSize == 500)
        #expect(innerDir.subtreeSize == 500)
    }

    @Test func hashableByID() {
        let node = FileNode(
            name: "file.txt",
            path: "/tmp/file.txt",
            isDirectory: false,
            fileSize: 100
        )
        // Same object has same hash
        #expect(node == node)
        #expect(node.hashValue == node.hashValue)
    }

    @Test func differentInodesAreNotEqual() {
        let node1 = FileNode(
            inode: 1001,
            name: "file.txt",
            path: "/tmp/file.txt",
            isDirectory: false,
            fileSize: 100
        )
        let node2 = FileNode(
            inode: 1002,
            name: "file.txt",
            path: "/tmp/file.txt",
            isDirectory: false,
            fileSize: 100
        )
        #expect(node1 != node2)
    }

    @Test func fileExtensionIsStored() {
        let node = FileNode(
            name: "image.PNG",
            path: "/tmp/image.PNG",
            isDirectory: false,
            fileSize: 2048,
            fileExtension: "png"
        )
        #expect(node.fileExtension == "png")
    }

    @Test func depthIsStored() {
        let node = FileNode(
            name: "deep",
            path: "/tmp/a/b/c/deep",
            isDirectory: false,
            fileSize: 100,
            depth: 3
        )
        #expect(node.depth == 3)
    }

    @Test func directoryWithNilChildrenIsFile() {
        let file = FileNode(
            name: "file",
            path: "/tmp/file",
            isDirectory: false,
            fileSize: 50
        )
        #expect(file.children == nil)
    }
}
