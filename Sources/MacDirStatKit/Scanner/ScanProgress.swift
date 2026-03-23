import Foundation
import Observation

@MainActor
@Observable
public final class ScanProgress {
    public var filesScanned: Int = 0
    public var totalEstimatedItems: Int = 0
    public var isVolumeRootScan: Bool = false
    public var currentPath: String = ""
    public var isScanning: Bool = false
    public var elapsedTime: TimeInterval = 0
    public var skippedDirectories: Int = 0

    /// Only meaningful for volume-root scans where statfs gives accurate estimate.
    public var fractionComplete: Double? {
        guard isVolumeRootScan, totalEstimatedItems > 0 else { return nil }
        return min(1.0, Double(filesScanned) / Double(totalEstimatedItems))
    }

    public init() {}

    public func reset() {
        filesScanned = 0
        totalEstimatedItems = 0
        isVolumeRootScan = false
        currentPath = ""
        isScanning = false
        elapsedTime = 0
        skippedDirectories = 0
    }
}
