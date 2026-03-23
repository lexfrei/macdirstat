import SwiftUI
import UniformTypeIdentifiers

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
                    appState.isPickerPresented = true
                }
            }
        }
        .fileImporter(
            isPresented: $appState.isPickerPresented,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                appState.selectedURL = url
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
            if let url = appState.selectedURL {
                Spacer()
                Image(systemName: "folder.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
                Text("Ready to scan")
                    .font(.title2)
                Text(url.path(percentEncoded: false))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            if let url = appState.selectedURL {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.secondary)
                Text(url.lastPathComponent)
                    .foregroundStyle(.secondary)
            } else {
                Text("Ready")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}
