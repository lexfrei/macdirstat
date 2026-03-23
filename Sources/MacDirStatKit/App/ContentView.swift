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
            VStack(spacing: 0) {
                if appState.rootNode != nil, !appState.scanProgress.isScanning {
                    BreadcrumbView(
                        rootName: appState.rootNode?.name ?? "Root",
                        stack: appState.navigationStack,
                        onSelectRoot: { appState.navigateTo(index: -1) },
                        onSelect: { appState.navigateTo(index: $0) })
                }
                detail
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Open", systemImage: "folder") {
                    appState.isPickerPresented = true
                }
                .disabled(appState.scanProgress.isScanning)
            }
        }
        .fileImporter(
            isPresented: $appState.isPickerPresented,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                _ = url.startAccessingSecurityScopedResource()
                appState.startScan(url: url)
            }
        }
        .safeAreaInset(edge: .bottom) {
            statusBar
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            DirectoryTreeView(rootNode: appState.rootNode)
                .frame(maxHeight: .infinity)

            Divider()

            Section {
                if let root = appState.rootNode {
                    ExtensionLegendView(
                        entries: appState.colorMapper.legend(for: root))
                } else {
                    Text("No data")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            } header: {
                Text("Legend")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            Divider()

            Section {
                FileInfoView(node: appState.selectedNode ?? appState.hoveredNode)
            } header: {
                Text("File Info")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
        }
        .frame(minWidth: 250)
    }

    // MARK: - Detail

    private var detail: some View {
        VStack {
            if appState.scanProgress.isScanning {
                scanProgressView
            } else if let error = appState.scanError {
                errorView(error)
            } else if appState.rootNode != nil {
                TreemapView(
                    appState: appState,
                    renderer: TreemapRenderer(colorMapper: appState.colorMapper))
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var scanProgressView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .controlSize(.large)
            Text("Scanning...")
                .font(.title2)
            Text("\(appState.scanProgress.filesScanned) files")
                .font(.headline)
                .monospacedDigit()
            Text(appState.scanProgress.currentPath)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 400)
            Text(String(format: "%.1fs", appState.scanProgress.elapsedTime))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
            Spacer()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Scan Failed")
                .font(.title2)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            Spacer()
        }
    }

    private var emptyState: some View {
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
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            if appState.scanProgress.isScanning {
                ProgressView()
                    .controlSize(.small)
                Text("Scanning: \(appState.scanProgress.filesScanned) files")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            } else if let root = appState.rootNode {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("\(appState.scanProgress.filesScanned) files")
                    .monospacedDigit()
                Text(SizeFormatter.format(root.subtreeSize))
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1fs", appState.scanProgress.elapsedTime))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                if let hovered = appState.hoveredNode {
                    Divider()
                        .frame(height: 12)
                    Text(hovered.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(SizeFormatter.format(hovered.subtreeSize))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Ready")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}
