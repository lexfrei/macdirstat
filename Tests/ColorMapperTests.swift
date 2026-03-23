import SwiftUI
import Testing

@testable import MacDirStatKit

@Suite("ColorMapper")
struct ColorMapperTests {
    private func makeTree() -> FileNode {
        let children: [FileNode] = [
            FileNode(
                name: "big.mp4", url: URL(filePath: "/tmp/big.mp4"),
                isDirectory: false, fileSize: 10000, fileExtension: "mp4"),
            FileNode(
                name: "med.jpg", url: URL(filePath: "/tmp/med.jpg"),
                isDirectory: false, fileSize: 5000, fileExtension: "jpg"),
            FileNode(
                name: "small.txt", url: URL(filePath: "/tmp/small.txt"),
                isDirectory: false, fileSize: 1000, fileExtension: "txt"),
            FileNode(
                name: "noext", url: URL(filePath: "/tmp/noext"),
                isDirectory: false, fileSize: 500, fileExtension: ""),
        ]
        return FileNode(
            name: "root", url: URL(filePath: "/tmp"),
            isDirectory: true, fileSize: 0, children: children)
    }

    @Test func sameExtensionReturnsSameColor() {
        let mapper = GoldenAngleColorMapper().withMapping(from: makeTree())
        let color1 = mapper.color(for: "mp4")
        let color2 = mapper.color(for: "mp4")
        #expect(color1 == color2)
    }

    @Test func differentExtensionsReturnDifferentColors() {
        let mapper = GoldenAngleColorMapper().withMapping(from: makeTree())
        let mp4 = mapper.color(for: "mp4")
        let jpg = mapper.color(for: "jpg")
        let txt = mapper.color(for: "txt")
        #expect(mp4 != jpg)
        #expect(mp4 != txt)
        #expect(jpg != txt)
    }

    @Test func noExtensionReturnsGray() {
        let mapper = GoldenAngleColorMapper()
        let color = mapper.color(for: "")
        #expect(color == GoldenAngleColorMapper.noExtensionColor)
    }

    @Test func legendSortedBySizeDescending() {
        let mapper = GoldenAngleColorMapper().withMapping(from: makeTree())
        let legend = mapper.legend(for: makeTree())
        let sizes = legend.map(\.totalSize)
        #expect(sizes == sizes.sorted(by: >))
    }

    @Test func legendContainsTopExtensions() {
        let mapper = GoldenAngleColorMapper().withMapping(from: makeTree())
        let legend = mapper.legend(for: makeTree())
        let extensions = legend.map(\.fileExtension)
        #expect(extensions.contains("mp4"))
        #expect(extensions.contains("jpg"))
        #expect(extensions.contains("txt"))
    }

    @Test func legendLimitedToMaxDistinct() {
        let mapper = GoldenAngleColorMapper(maxDistinct: 2).withMapping(from: makeTree())
        let legend = mapper.legend(for: makeTree())
        #expect(legend.count <= 2)
    }

    @Test func unknownExtensionStillReturnsColor() {
        let mapper = GoldenAngleColorMapper().withMapping(from: makeTree())
        let color = mapper.color(for: "xyz")
        #expect(color != GoldenAngleColorMapper.noExtensionColor)
    }

    @Test func djb2HashIsDeterministic() {
        let hash1 = GoldenAngleColorMapper.djb2Hash("swift")
        let hash2 = GoldenAngleColorMapper.djb2Hash("swift")
        #expect(hash1 == hash2)
        #expect(hash1 != 0)

        let hashA = GoldenAngleColorMapper.djb2Hash("mp4")
        let hashB = GoldenAngleColorMapper.djb2Hash("jpg")
        #expect(hashA != hashB)
    }

    @Test func withMappingIsImmutable() {
        let original = GoldenAngleColorMapper()
        let mapped = original.withMapping(from: makeTree())
        // Original should still return fallback colors (no mapping)
        let origColor = original.color(for: "mp4")
        let mappedColor = mapped.color(for: "mp4")
        #expect(origColor != mappedColor)
    }
}
