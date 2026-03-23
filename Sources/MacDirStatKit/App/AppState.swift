import SwiftUI

@MainActor
@Observable
public final class AppState {
    public var selectedURL: URL?
    public var isPickerPresented = false
    public var rootNode: FileNode?
    public var scanProgress = ScanProgress()
    public var scanError: String?

    private var scanTask: Task<Void, Never>?
    public let scanner: any FileSystemScanning

    public init(scanner: any FileSystemScanning = FileManagerScanner()) {
        self.scanner = scanner
    }

    public func startScan(url: URL) {
        scanTask?.cancel()
        rootNode = nil
        scanError = nil
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
                self.scanProgress.filesScanned = self.countFiles(node)
                self.scanProgress.elapsedTime = Date().timeIntervalSince(startTime)
            } catch is CancellationError {
                // Scan was cancelled — no error to show
            } catch {
                self.scanError = error.localizedDescription
            }
            self.scanProgress.isScanning = false
        }
    }

    private func countFiles(_ node: FileNode) -> Int {
        if node.isDirectory {
            return (node.children ?? []).reduce(0) { $0 + countFiles($1) }
        }
        return 1
    }
}
