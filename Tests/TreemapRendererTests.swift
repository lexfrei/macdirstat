import SwiftUI
import Testing

@testable import MacDirStatKit

@Suite("TreemapRenderer")
struct TreemapRendererTests {
    private func makeTree() -> FileNode {
        let children: [FileNode] = [
            FileNode(
                name: "big.mp4", path: "/tmp/big.mp4",
                isDirectory: false, fileSize: 10000, fileExtension: "mp4"),
            FileNode(
                name: "med.jpg", path: "/tmp/med.jpg",
                isDirectory: false, fileSize: 5000, fileExtension: "jpg"),
            FileNode(
                name: "small.txt", path: "/tmp/small.txt",
                isDirectory: false, fileSize: 1000, fileExtension: "txt"),
        ]
        return FileNode(
            name: "root", path: "/tmp",
            isDirectory: true, fileSize: 0, children: children)
    }

    @Test func computeLayoutReturnsRectsForChildren() {
        let renderer = TreemapRenderer()
        let root = makeTree()
        let rect = CGRect(x: 0, y: 0, width: 800, height: 600)
        let rects = renderer.computeLayout(root: root, in: rect)
        #expect(rects.count == 3)
        let names = Set(rects.map(\.node.name))
        #expect(names.contains("big.mp4"))
        #expect(names.contains("med.jpg"))
        #expect(names.contains("small.txt"))
    }

    @Test func computeLayoutReturnsEmptyForLeafNode() {
        let renderer = TreemapRenderer()
        let leaf = FileNode(
            name: "file.txt", path: "/tmp/file.txt",
            isDirectory: false, fileSize: 100)
        let rects = renderer.computeLayout(root: leaf, in: CGRect(x: 0, y: 0, width: 800, height: 600))
        #expect(rects.isEmpty)
    }

    @Test func computeLayoutReturnsEmptyForEmptyDir() {
        let renderer = TreemapRenderer()
        let dir = FileNode(
            name: "empty", path: "/tmp/empty",
            isDirectory: true, fileSize: 0, children: [])
        let rects = renderer.computeLayout(root: dir, in: CGRect(x: 0, y: 0, width: 800, height: 600))
        #expect(rects.isEmpty)
    }

    @Test func computeLayoutRecursesIntoSubdirectories() {
        let renderer = TreemapRenderer(lod: LODController(maximumDepth: 10))
        let innerFile = FileNode(
            name: "deep.txt", path: "/tmp/sub/deep.txt",
            isDirectory: false, fileSize: 5000, fileExtension: "txt")
        let subDir = FileNode(
            name: "sub", path: "/tmp/sub",
            isDirectory: true, fileSize: 0, children: [innerFile])
        let topFile = FileNode(
            name: "top.txt", path: "/tmp/top.txt",
            isDirectory: false, fileSize: 5000, fileExtension: "txt")
        let root = FileNode(
            name: "root", path: "/tmp",
            isDirectory: true, fileSize: 0, children: [subDir, topFile])

        let rects = renderer.computeLayout(root: root, in: CGRect(x: 0, y: 0, width: 800, height: 600))
        let names = Set(rects.map(\.node.name))
        #expect(names.contains("deep.txt"))
        #expect(names.contains("top.txt"))
        #expect(!names.contains("sub"))
    }

    @Test func computeLayoutRespectsLODDepth() {
        let renderer = TreemapRenderer(lod: LODController(minimumRecurseSize: 1000, maximumDepth: 0))
        let innerFile = FileNode(
            name: "deep.txt", path: "/tmp/sub/deep.txt",
            isDirectory: false, fileSize: 5000, fileExtension: "txt")
        let subDir = FileNode(
            name: "sub", path: "/tmp/sub",
            isDirectory: true, fileSize: 0, children: [innerFile])
        let root = FileNode(
            name: "root", path: "/tmp",
            isDirectory: true, fileSize: 0, children: [subDir])

        let rects = renderer.computeLayout(root: root, in: CGRect(x: 0, y: 0, width: 800, height: 600))
        let names = Set(rects.map(\.node.name))
        #expect(names.contains("sub"))
        #expect(!names.contains("deep.txt"))
    }
}
