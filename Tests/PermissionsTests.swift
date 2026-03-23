import Testing

@testable import MacDirStatKit

@Suite("Permissions")
struct PermissionsTests {
    // Note: We can't mock FileManager in Permissions directly,
    // but we can verify the path matching logic by testing AppState.isVolumeRoot

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
