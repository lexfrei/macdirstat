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

    public let colorMapper = GoldenAngleColorMapper()

    private var scanTask: Task<Void, Never>?
    public let scanner: any FileSystemScanning

    public init(scanner: any FileSystemScanning = FileManagerScanner()) {
        self.scanner = scanner
    }

    public func startScan(url: URL) {
        scanTask?.cancel()
        rootNode = nil
        scanError = nil
        selectedNode = nil
        hoveredNode = nil
        navigationStack = []
        scanProgress.reset()
        scanProgress.isScanning = true
        selectedURL = url

        let scanner = self.scanner
        let startTime = Date()

        scanTask = Task {
            do {
                let node = try await scanner.scan(url: url) { count, path in
                    self.scanProgress.filesScanned = count
                    self.scanProgress.currentPath = path
                    self.scanProgress.elapsedTime = Date().timeIntervalSince(startTime)
                }
                self.rootNode = node
                self.colorMapper.buildMapping(from: node)
                self.scanProgress.filesScanned = self.countFiles(node)
                self.scanProgress.elapsedTime = Date().timeIntervalSince(startTime)
            } catch is CancellationError {
                // Scan was cancelled
            } catch {
                self.scanError = error.localizedDescription
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

    private func countFiles(_ node: FileNode) -> Int {
        if node.isDirectory {
            return (node.children ?? []).reduce(0) { $0 + countFiles($1) }
        }
        return 1
    }
}
