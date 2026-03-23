import SwiftUI

@MainActor
@Observable
public final class TabState: Identifiable {
    public let id = UUID()
    public let appState: AppState
    public let title: String

    public init(title: String, scanner: any FileSystemScanning = FileManagerScanner()) {
        self.title = title
        self.appState = AppState(scanner: scanner)
    }
}

@MainActor
@Observable
public final class MultiTabState {
    public var tabs: [TabState] = []
    public var selectedTabID: UUID?
    public var availableVolumes: [VolumeInfo] = []

    public var selectedTab: TabState? {
        tabs.first { $0.id == selectedTabID }
    }

    public init() {
        refreshVolumes()
    }

    public func refreshVolumes() {
        availableVolumes = VolumeDiscovery.mountedVolumes()
    }

    public func addTab(for url: URL, title: String) {
        let tab = TabState(title: title)
        tabs.append(tab)
        selectedTabID = tab.id
        tab.appState.startScan(url: url)
    }

    public func closeTab(_ id: UUID) {
        if let tab = tabs.first(where: { $0.id == id }) {
            tab.appState.cancelScan()
        }
        tabs.removeAll { $0.id == id }
        if selectedTabID == id {
            selectedTabID = tabs.first?.id
        }
    }

    public func addTabFromPicker(url: URL) {
        addTab(for: url, title: url.lastPathComponent)
    }

    public func scanVolume(_ volume: VolumeInfo) {
        addTab(for: volume.url, title: volume.name)
    }
}
