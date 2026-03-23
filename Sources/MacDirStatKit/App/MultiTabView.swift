import SwiftUI
import UniformTypeIdentifiers

public struct MultiTabView: View {
    @Bindable var multiTab: MultiTabState
    @State private var isPickerPresented = false

    public init(multiTab: MultiTabState) {
        self.multiTab = multiTab
    }

    public var body: some View {
        VStack(spacing: 0) {
            if multiTab.tabs.isEmpty {
                welcomeView
            } else {
                tabBar
                if let tab = multiTab.selectedTab {
                    ContentView(appState: tab.appState)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Open Folder", systemImage: "folder") {
                    isPickerPresented = true
                }
            }
            ToolbarItem(placement: .automatic) {
                Menu {
                    ForEach(multiTab.availableVolumes) { volume in
                        Button {
                            multiTab.scanVolume(volume)
                        } label: {
                            Label {
                                Text(
                                    "\(volume.name) (\(SizeFormatter.format(volume.totalCapacity)))"
                                )
                            } icon: {
                                Image(systemName: "externaldrive.fill")
                            }
                        }
                    }
                    Divider()
                    Button("Refresh Volumes") {
                        multiTab.refreshVolumes()
                    }
                } label: {
                    Label("Volumes", systemImage: "externaldrive")
                }
            }
        }
        .fileImporter(
            isPresented: $isPickerPresented,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                multiTab.addTabFromPicker(url: url)
            }
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("MacDirStat")
                .font(.title)
            Text("Select a folder or volume to scan")
                .foregroundStyle(.secondary)

            if !multiTab.availableVolumes.isEmpty {
                Divider()
                    .frame(maxWidth: 300)
                Text("Available Volumes")
                    .font(.headline)
                    .padding(.top, 8)
                ForEach(multiTab.availableVolumes) { volume in
                    Button {
                        multiTab.scanVolume(volume)
                    } label: {
                        HStack {
                            Image(systemName: "externaldrive.fill")
                            Text(volume.name)
                            Spacer()
                            Text(SizeFormatter.format(volume.totalCapacity))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: 300)
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(multiTab.tabs) { tab in
                    tabButton(tab)
                }
            }
        }
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func tabButton(_ tab: TabState) -> some View {
        HStack(spacing: 4) {
            Text(tab.title)
                .lineLimit(1)
                .font(.caption)
            Button {
                multiTab.closeTab(tab.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            multiTab.selectedTabID == tab.id
                ? Color.accentColor.opacity(0.15) : Color.clear
        )
        .onTapGesture {
            multiTab.selectedTabID = tab.id
        }
    }
}
