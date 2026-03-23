import SwiftUI

@MainActor
@Observable
public final class ScanProgress {
    public var filesScanned: Int = 0
    public var currentPath: String = ""
    public var isScanning: Bool = false
    public var elapsedTime: TimeInterval = 0

    public init() {}

    public func reset() {
        filesScanned = 0
        currentPath = ""
        isScanning = false
        elapsedTime = 0
    }
}
