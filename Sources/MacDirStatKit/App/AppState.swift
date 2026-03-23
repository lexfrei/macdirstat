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

    private var scanTask: Task<Void, Never>?
    private var securityScopedURL: URL?
    public let scanner: any FileSystemScanning

    public init(scanner: any FileSystemScanning = FileManagerScanner()) {
        self.scanner = scanner
    }

    public func startScan(url: URL) {
        scanTask?.cancel()
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

        let scanner = self.scanner
        let startTime = Date()

        scanTask = Task {
            do {
                let node = try await scanner.scan(url: url) { count, path, skipped in
                    self.scanProgress.filesScanned = count
                    self.scanProgress.currentPath = path
                    self.scanProgress.skippedDirectories = skipped
                    self.scanProgress.elapsedTime = Date().timeIntervalSince(startTime)
                }
                self.rootNode = node
                self.colorMapper = self.colorMapper.withMapping(from: node)
                self.scanProgress.elapsedTime = Date().timeIntervalSince(startTime)
            } catch is CancellationError {
                self.stopSecurityScopedAccess()
            } catch {
                self.scanError = error.localizedDescription
                self.stopSecurityScopedAccess()
            }
            self.scanProgress.isScanning = false
        }
    }

    public func drillDown(into node: FileNode) {
        guard node.isDirectory else { return }
        navigationStack.append(node)
        selectedNode = nil
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

    private func stopSecurityScopedAccess() {
        securityScopedURL?.stopAccessingSecurityScopedResource()
        securityScopedURL = nil
    }
}
