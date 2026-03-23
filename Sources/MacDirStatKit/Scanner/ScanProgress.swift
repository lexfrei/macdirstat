import Foundation
import Observation

@MainActor
@Observable
public final class ScanProgress {
    public var filesScanned: Int = 0
    public var currentPath: String = ""
    public var isScanning: Bool = false
    public var elapsedTime: TimeInterval = 0
    public var skippedDirectories: Int = 0

    public var itemsPerSecond: Int {
        guard elapsedTime > 0 else { return 0 }
        return Int(Double(filesScanned) / elapsedTime)
    }

    public init() {}

    public func reset() {
        filesScanned = 0
        currentPath = ""
        isScanning = false
        elapsedTime = 0
        skippedDirectories = 0
    }
}
