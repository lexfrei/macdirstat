import SwiftUI

@MainActor
@Observable
public final class AppState {
    public var selectedURL: URL?
    public var isPickerPresented = false
    public var rootNode: FileNode?
    public var scanProgress = ScanProgress()
    public var scanError: String?

    public var selectedNode: FileNode?
    public var hoveredNode: FileNode?
    public var navigationStack: [FileNode] = []

    public var currentViewRoot: FileNode? {
        navigationStack.last ?? rootNode
    }

    public var colorMapper = GoldenAngleColorMapper()
    public var isLiveWatching = false
    public var zoomScale: CGFloat = 1.0
    public var panOffset: CGSize = .zero

    public static let minZoom: CGFloat = 1.0
    public static let maxZoom: CGFloat = 10.0

    public var showDeleteConfirmation = false
    public var nodesToDelete: [FileNode] = []

    private var scanTask: Task<Void, Never>?
    private var securityScopedURL: URL?
    private let watcher = FSEventWatcher(debounceInterval: 0.5)
    public let scanner: any FileSystemScanning

    public init(scanner: any FileSystemScanning = FileManagerScanner()) {
        self.scanner = scanner
    }

    public func startScan(url: URL) {
        scanTask?.cancel()
        stopLiveWatching()
        stopSecurityScopedAccess()
        rootNode = nil
        scanError = nil
        selectedNode = nil
        hoveredNode = nil
        navigationStack = []
        scanProgress.reset()
        scanProgress.isScanning = true
        selectedURL = url

        if url.startAccessingSecurityScopedResource() {
            securityScopedURL = url
        }

        // Pre-trigger TCC dialogs so they appear before scan, not mid-scan
        Permissions.preTriggerPermissions()

        runScan(url: url, releaseSecurityScope: true)
    }

    public func drillDown(into node: FileNode) {
        guard node.isDirectory else { return }
        navigationStack.append(node)
        selectedNode = nil
    }

    public func requestDelete(nodes: [FileNode]) {
        nodesToDelete = nodes
        showDeleteConfirmation = true
    }

    public func confirmDelete() {
        scanTask?.cancel()
        let fm = FileManager.default
        var trashed: [String] = []
        for node in nodesToDelete {
            do {
                try fm.trashItem(at: node.url, resultingItemURL: nil)
                trashed.append(node.name)
            } catch {
                let remaining = nodesToDelete.count - trashed.count
                scanError =
                    "Failed to trash \(node.name): \(error.localizedDescription). \(remaining) item(s) not processed."
                break
            }
        }
        nodesToDelete = []
        showDeleteConfirmation = false

        if let url = selectedURL {
            rescan(url: url)
        }
    }

    public func cancelDelete() {
        nodesToDelete = []
        showDeleteConfirmation = false
    }

    public func navigateUp() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
        selectedNode = nil
    }

    public func navigateTo(index: Int) {
        guard index >= 0 else {
            navigationStack.removeAll()
            selectedNode = nil
            return
        }
        guard index < navigationStack.count else { return }
        navigationStack = Array(navigationStack.prefix(index + 1))
        selectedNode = nil
    }

    public func toggleLiveWatching() {
        if isLiveWatching {
            stopLiveWatching()
        } else {
            startLiveWatching()
        }
    }

    private func startLiveWatching() {
        guard let url = selectedURL, rootNode != nil else { return }
        isLiveWatching = true
        watcher.start(paths: [url.path(percentEncoded: false)]) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isLiveWatching,
                    !self.scanProgress.isScanning,
                    let url = self.selectedURL
                else { return }
                self.rescan(url: url)
            }
        }
    }

    public func stopLiveWatching() {
        guard isLiveWatching else { return }
        isLiveWatching = false
        watcher.stop()
    }

    private func rescan(url: URL) {
        scanTask?.cancel()
        scanProgress.reset()
        scanProgress.isScanning = true
        runScan(url: url, releaseSecurityScope: false)
    }

    private func runScan(url: URL, releaseSecurityScope: Bool) {
        let scanner = self.scanner
        let startTime = Date()

        scanTask = Task {
            do {
                let node = try await scanner.scan(url: url) { count, total, path, skipped in
                    self.scanProgress.filesScanned = count
                    self.scanProgress.totalEstimatedItems = total
                    self.scanProgress.currentPath = path
                    self.scanProgress.skippedDirectories = skipped
                    self.scanProgress.elapsedTime = Date().timeIntervalSince(startTime)
                }
                self.rootNode = node
                self.colorMapper = self.colorMapper.withMapping(from: node)
                self.scanProgress.elapsedTime = Date().timeIntervalSince(startTime)
            } catch is CancellationError {
                // Scan cancelled
            } catch {
                self.scanError = error.localizedDescription
            }
            self.scanProgress.isScanning = false
            if releaseSecurityScope {
                self.stopSecurityScopedAccess()
            }
        }
    }

    private func stopSecurityScopedAccess() {
        securityScopedURL?.stopAccessingSecurityScopedResource()
        securityScopedURL = nil
    }
}
