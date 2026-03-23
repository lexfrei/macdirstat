import SwiftUI
import Testing

@testable import MacDirStatKit

@Suite("AppState")
struct AppStateTests {
    @Test @MainActor func initializes() {
        let state = AppState()
        #expect(state.selectedURL == nil)
        #expect(state.isPickerPresented == false)
        #expect(state.rootNode == nil)
        #expect(state.scanError == nil)
        #expect(state.scanProgress.isScanning == false)
        #expect(state.selectedNode == nil)
        #expect(state.hoveredNode == nil)
        #expect(state.navigationStack.isEmpty)
        #expect(state.currentViewRoot == nil)
    }

    @Test @MainActor func selectedURLCanBeSet() {
        let state = AppState()
        let url = URL(filePath: "/tmp")
        state.selectedURL = url
        #expect(state.selectedURL == url)
    }

    @Test @MainActor func startScanSetsURL() {
        let state = AppState()
        let url = URL(filePath: "/tmp")
        state.startScan(url: url)
        #expect(state.selectedURL == url)
        #expect(state.scanProgress.isScanning == true)
        #expect(state.scanError == nil)
    }

    @Test @MainActor func acceptsCustomScanner() {
        let state = AppState(scanner: FailingScanner())
        #expect(state.scanner is FailingScanner)
    }

    // MARK: - Navigation

    @Test @MainActor func drillDownPushesToStack() {
        let state = AppState()
        let dir = FileNode(
            name: "dir", path: "/tmp/dir",
            isDirectory: true, fileSize: 0, children: [])
        state.rootNode = dir
        state.drillDown(into: dir)
        #expect(state.navigationStack.count == 1)
        #expect(state.currentViewRoot?.id == dir.id)
    }

    @Test @MainActor func scanErrorSetsErrorMessage() async throws {
        let state = AppState(scanner: FailingScanner())
        state.startScan(url: URL(filePath: "/tmp"))
        // Wait for scan task to complete
        try await Task.sleep(for: .seconds(2))
        #expect(state.scanError != nil)
        #expect(state.scanProgress.isScanning == false)
    }

    @Test @MainActor func drillDownIgnoresFiles() {
        let state = AppState()
        let file = FileNode(
            name: "file", path: "/tmp/file",
            isDirectory: false, fileSize: 100)
        state.drillDown(into: file)
        #expect(state.navigationStack.isEmpty)
    }

    @Test @MainActor func navigateUpPopsStack() {
        let state = AppState()
        let dir = FileNode(
            name: "dir", path: "/tmp/dir",
            isDirectory: true, fileSize: 0, children: [])
        state.rootNode = dir
        state.drillDown(into: dir)
        #expect(state.navigationStack.count == 1)
        state.navigateUp()
        #expect(state.navigationStack.isEmpty)
    }

    @Test @MainActor func navigateUpOnEmptyStackIsNoop() {
        let state = AppState()
        state.navigateUp()
        #expect(state.navigationStack.isEmpty)
    }

    @Test @MainActor func navigateToIndex() {
        let state = AppState()
        let dir1 = FileNode(
            name: "a", path: "/tmp/a",
            isDirectory: true, fileSize: 0, children: [])
        let dir2 = FileNode(
            name: "b", path: "/tmp/a/b",
            isDirectory: true, fileSize: 0, children: [])
        state.drillDown(into: dir1)
        state.drillDown(into: dir2)
        #expect(state.navigationStack.count == 2)

        state.navigateTo(index: 0)
        #expect(state.navigationStack.count == 1)
        #expect(state.currentViewRoot?.id == dir1.id)
    }

    @Test @MainActor func navigateToNegativeIndexClearsStack() {
        let state = AppState()
        let dir = FileNode(
            name: "dir", path: "/tmp/dir",
            isDirectory: true, fileSize: 0, children: [])
        state.drillDown(into: dir)
        state.navigateTo(index: -1)
        #expect(state.navigationStack.isEmpty)
    }

    @Test @MainActor func navigateToOutOfRangeIsNoop() {
        let state = AppState()
        let dir = FileNode(
            name: "dir", path: "/tmp/dir",
            isDirectory: true, fileSize: 0, children: [])
        state.drillDown(into: dir)
        state.navigateTo(index: 5)
        #expect(state.navigationStack.count == 1)
    }

    @Test @MainActor func currentViewRootFallsBackToRootNode() {
        let state = AppState()
        let root = FileNode(
            name: "root", path: "/tmp",
            isDirectory: true, fileSize: 0, children: [])
        state.rootNode = root
        #expect(state.currentViewRoot?.id == root.id)
    }

    // MARK: - Delete Flow

    @Test @MainActor func requestDeleteSetsState() {
        let state = AppState()
        let file = FileNode(
            name: "file", path: "/tmp/file",
            isDirectory: false, fileSize: 100)
        state.requestDelete(nodes: [file])
        #expect(state.showDeleteConfirmation == true)
        #expect(state.nodesToDelete.count == 1)
    }

    @Test @MainActor func cancelDeleteResetsState() {
        let state = AppState()
        let file = FileNode(
            name: "file", path: "/tmp/file",
            isDirectory: false, fileSize: 100)
        state.requestDelete(nodes: [file])
        state.cancelDelete()
        #expect(state.showDeleteConfirmation == false)
        #expect(state.nodesToDelete.isEmpty)
    }

    @Test @MainActor func startScanStopsLiveWatching() {
        let state = AppState()
        state.isLiveWatching = true
        state.startScan(url: URL(filePath: "/tmp"))
        #expect(state.isLiveWatching == false)
    }

    @Test @MainActor func drillDownClearsSelection() {
        let state = AppState()
        let file = FileNode(
            name: "file", path: "/tmp/file",
            isDirectory: false, fileSize: 100)
        let dir = FileNode(
            name: "dir", path: "/tmp/dir",
            isDirectory: true, fileSize: 0, children: [])
        state.selectedNode = file
        state.drillDown(into: dir)
        #expect(state.selectedNode == nil)
    }
}

struct FailingScanner: FileSystemScanning {
    struct ScanError: Error, LocalizedError {
        var errorDescription: String? { "Test scan error" }
    }

    func scan(
        url: URL,
        progressHandler: @escaping @MainActor @Sendable (Int, Int, String, Int) -> Void
    ) async throws -> FileNode {
        throw ScanError()
    }
}
