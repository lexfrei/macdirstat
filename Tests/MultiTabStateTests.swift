import SwiftUI
import Testing

@testable import MacDirStatKit

@Suite("MultiTabState")
struct MultiTabStateTests {
    @Test @MainActor func initiallyEmpty() {
        let state = MultiTabState()
        #expect(state.tabs.isEmpty)
        #expect(state.selectedTabID == nil)
        #expect(state.selectedTab == nil)
    }

    @Test @MainActor func addTabFromPicker() {
        let state = MultiTabState()
        state.addTabFromPicker(url: URL(filePath: "/tmp"))
        #expect(state.tabs.count == 1)
        #expect(state.selectedTabID == state.tabs.first?.id)
        #expect(state.selectedTab?.title == "tmp")
    }

    @Test @MainActor func addMultipleTabs() {
        let state = MultiTabState()
        state.addTabFromPicker(url: URL(filePath: "/tmp"))
        state.addTabFromPicker(url: URL(filePath: "/var"))
        #expect(state.tabs.count == 2)
        #expect(state.selectedTab?.title == "var")
    }

    @Test @MainActor func closeTab() {
        let state = MultiTabState()
        state.addTabFromPicker(url: URL(filePath: "/tmp"))
        let tabID = state.tabs.first!.id
        state.closeTab(tabID)
        #expect(state.tabs.isEmpty)
        #expect(state.selectedTabID == nil)
    }

    @Test @MainActor func closeSelectedTabSelectsFirst() {
        let state = MultiTabState()
        state.addTabFromPicker(url: URL(filePath: "/tmp"))
        state.addTabFromPicker(url: URL(filePath: "/var"))
        let secondID = state.tabs[1].id
        state.closeTab(secondID)
        #expect(state.tabs.count == 1)
        #expect(state.selectedTabID == state.tabs.first?.id)
    }

    @Test @MainActor func refreshVolumesReturnsVolumeInfoArray() {
        let state = MultiTabState()
        state.refreshVolumes()
        // Verify structure, not emptiness (would fail in containers)
        for vol in state.availableVolumes {
            #expect(!vol.name.isEmpty)
            #expect(vol.totalCapacity >= 0)
        }
    }
}
