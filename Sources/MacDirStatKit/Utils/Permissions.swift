import AppKit
import Foundation

public enum FullDiskAccessStatus {
    case granted
    case denied
    case unknown
}

public enum PermissionsChecker {
    public static func checkFullDiskAccess() -> FullDiskAccessStatus {
        let testPaths = [
            NSHomeDirectory() + "/Library/Mail",
            NSHomeDirectory() + "/Library/Safari/Bookmarks.plist",
        ]

        for path in testPaths {
            if FileManager.default.isReadableFile(atPath: path) {
                return .granted
            }
            if FileManager.default.fileExists(atPath: path) {
                return .denied
            }
        }

        return .unknown
    }

    public static func openFullDiskAccessSettings() {
        if let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
        {
            NSWorkspace.shared.open(url)
        }
    }
}
