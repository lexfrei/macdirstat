import Testing

@testable import MacDirStatKit

@Suite("AppState")
struct AppStateTests {
    @Test @MainActor func initializes() {
        let state = AppState()
        #expect(state.selectedURL == nil)
    }
}
