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
}

struct FailingScanner: FileSystemScanning {
    struct ScanError: Error, LocalizedError {
        var errorDescription: String? { "Test scan error" }
    }

    func scan(
        url: URL,
        progressHandler: @escaping @MainActor @Sendable (Int, String) -> Void
    ) async throws -> FileNode {
        throw ScanError()
    }
}
