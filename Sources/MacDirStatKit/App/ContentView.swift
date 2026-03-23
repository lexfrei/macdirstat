import AppKit
import SwiftUI

public struct ContentView: View {
    @Bindable var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Open", systemImage: "folder") {
                    openFolder()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            statusBar
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Section {
                Text("No scan data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } header: {
                Text("Directory Tree")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            Divider()

            Section {
                Text("No data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } header: {
                Text("Legend")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            Divider()

            Section {
                Text("No selection")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } header: {
                Text("File Info")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .frame(minWidth: 250)
    }

    // MARK: - Detail

    private var detail: some View {
        VStack {
            Spacer()
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Select a folder to scan")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Use the Open button in the toolbar")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            Text("Ready")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: - Actions

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to scan"
        panel.prompt = "Scan"

        if panel.runModal() == .OK {
            appState.selectedURL = panel.url
        }
    }
}
