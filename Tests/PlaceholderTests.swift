import SwiftUI
import Testing

@testable import MacDirStatKit

@Suite("AppState")
struct AppStateTests {
    @Test @MainActor func initializes() {
        let state = AppState()
        #expect(state.selectedURL == nil)
        #expect(state.isPickerPresented == false)
    }

    @Test @MainActor func selectedURLCanBeSet() {
        let state = AppState()
        let url = URL(filePath: "/tmp")
        state.selectedURL = url
        #expect(state.selectedURL == url)
    }
}
