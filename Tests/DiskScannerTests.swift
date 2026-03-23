import SwiftUI
import Testing

@testable import MacDirStatKit

@Suite("DiskScanner")
struct DiskScannerTests {
    private let scanner = FileManagerScanner(progressBatchSize: 1)

    private func createTempDir() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacDirStatTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test func scansEmptyDirectory() async throws {
        let dir = try createTempDir()
        defer { cleanup(dir) }

        let root = try await scanner.scan(url: dir) { _, _, _ in }
        #expect(root.isDirectory == true)
        #expect(root.children?.isEmpty == true)
        #expect(root.subtreeSize == 0)
    }

    @Test func scansDirectoryWithFiles() async throws {
        let dir = try createTempDir()
        defer { cleanup(dir) }

        let data100 = Data(repeating: 0x42, count: 100)
        let data200 = Data(repeating: 0x43, count: 200)
        try data100.write(to: dir.appendingPathComponent("small.txt"))
        try data200.write(to: dir.appendingPathComponent("large.png"))

        let root = try await scanner.scan(url: dir) { _, _, _ in }
        #expect(root.isDirectory == true)
        #expect(root.children?.count == 2)
        #expect(root.subtreeSize > 0)

        let names = Set(root.children?.map(\.name) ?? [])
        #expect(names.contains("small.txt"))
        #expect(names.contains("large.png"))
    }

    @Test func scansNestedDirectories() async throws {
        let dir = try createTempDir()
        defer { cleanup(dir) }

        let subDir = dir.appendingPathComponent("sub")
        try FileManager.default.createDirectory(
            at: subDir, withIntermediateDirectories: true)
        let data = Data(repeating: 0x44, count: 500)
        try data.write(to: subDir.appendingPathComponent("nested.txt"))

        let root = try await scanner.scan(url: dir) { _, _, _ in }
        #expect(root.children?.count == 1)

        let sub = root.children?.first
        #expect(sub?.isDirectory == true)
        #expect(sub?.name == "sub")
        #expect(sub?.children?.count == 1)
        #expect(sub?.children?.first?.name == "nested.txt")
    }

    @Test func extractsFileExtensions() async throws {
        let dir = try createTempDir()
        defer { cleanup(dir) }

        let data = Data(repeating: 0x45, count: 10)
        try data.write(to: dir.appendingPathComponent("file.SWIFT"))
        try data.write(to: dir.appendingPathComponent("noext"))

        let root = try await scanner.scan(url: dir) { _, _, _ in }
        let extensions = Set(root.children?.map(\.fileExtension) ?? [])
        #expect(extensions.contains("swift"))
        #expect(extensions.contains(""))
    }

    @Test func childrenSortedBySizeDescending() async throws {
        let dir = try createTempDir()
        defer { cleanup(dir) }

        try Data(repeating: 0x01, count: 100).write(
            to: dir.appendingPathComponent("small.txt"))
        try Data(repeating: 0x02, count: 10000).write(
            to: dir.appendingPathComponent("large.txt"))
        try Data(repeating: 0x03, count: 1000).write(
            to: dir.appendingPathComponent("medium.txt"))

        let root = try await scanner.scan(url: dir) { _, _, _ in }
        let sizes = root.children?.map(\.subtreeSize) ?? []
        #expect(sizes == sizes.sorted(by: >))
    }

    @Test @MainActor func reportsProgress() async throws {
        let dir = try createTempDir()
        defer { cleanup(dir) }

        let data = Data(repeating: 0x46, count: 10)
        try data.write(to: dir.appendingPathComponent("a.txt"))
        try data.write(to: dir.appendingPathComponent("b.txt"))
        try data.write(to: dir.appendingPathComponent("c.txt"))

        var progressCounts: [Int] = []
        let root = try await scanner.scan(url: dir) { count, _, _ in
            progressCounts.append(count)
        }
        #expect(root.children?.count == 3)
        #expect(!progressCounts.isEmpty)
    }

    @Test func setsCorrectDepth() async throws {
        let dir = try createTempDir()
        defer { cleanup(dir) }

        let subDir = dir.appendingPathComponent("level1")
        try FileManager.default.createDirectory(
            at: subDir, withIntermediateDirectories: true)
        let data = Data(repeating: 0x47, count: 10)
        try data.write(to: subDir.appendingPathComponent("file.txt"))

        let root = try await scanner.scan(url: dir) { _, _, _ in }
        #expect(root.depth == 0)
        #expect(root.children?.first?.depth == 1)
        #expect(root.children?.first?.children?.first?.depth == 2)
    }
}
