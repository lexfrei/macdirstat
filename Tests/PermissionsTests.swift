import SwiftUI
import Testing

@testable import MacDirStatKit

@Suite("Permissions")
struct PermissionsTests {
    @Test @MainActor func rootIsVolumeRoot() {
        #expect(AppState.isVolumeRoot(path: "/") == true)
    }

    @Test @MainActor func subdirectoryIsNotVolumeRoot() {
        #expect(AppState.isVolumeRoot(path: "/Users/test/Documents") == false)
    }

    @Test @MainActor func tmpIsNotVolumeRoot() {
        #expect(AppState.isVolumeRoot(path: "/tmp") == false)
    }
}

@Suite("FileNode.optionalChildren")
struct OptionalChildrenTests {
    @Test func fileHasNilOptionalChildren() {
        let file = FileNode(
            name: "file.txt", path: "/tmp/file.txt",
            isDirectory: false, fileSize: 100)
        #expect(file.optionalChildren == nil)
    }

    @Test func emptyDirHasNilOptionalChildren() {
        let dir = FileNode(
            name: "empty", path: "/tmp/empty",
            isDirectory: true, fileSize: 0, children: [])
        #expect(dir.optionalChildren == nil)
    }

    @Test func dirWithChildrenHasOptionalChildren() {
        let child = FileNode(
            name: "a.txt", path: "/tmp/dir/a.txt",
            isDirectory: false, fileSize: 100)
        let dir = FileNode(
            name: "dir", path: "/tmp/dir",
            isDirectory: true, fileSize: 0, children: [child])
        #expect(dir.optionalChildren?.count == 1)
    }
}

@Suite("VolumeInfo")
struct VolumeInfoTests {
    @Test func usedCapacityIsCorrect() {
        let vol = VolumeInfo(
            id: URL(filePath: "/"),
            name: "Test",
            url: URL(filePath: "/"),
            totalCapacity: 1000,
            availableCapacity: 400)
        #expect(vol.usedCapacity == 600)
    }
}
