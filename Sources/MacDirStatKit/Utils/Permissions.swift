import Foundation

public enum Permissions {
    private static let protectedPaths: [String] = [
        "Desktop", "Documents", "Downloads", "Pictures", "Music",
        "Library/Application Support/AddressBook",
        "Library/Calendars", "Library/Reminders",
        "Library/Mail", "Library/Messages",
        "Library/Safari", "Library/Cookies",
    ]

    /// Pre-trigger TCC permission dialogs for protected directories
    /// that overlap with the scan path. Only triggers dialogs when
    /// the scan path is a parent of (or equal to) a protected directory.
    public static func preTriggerIfNeeded(scanPath: String) {
        let home = NSHomeDirectory()

        for relPath in protectedPaths {
            let fullPath = (home as NSString).appendingPathComponent(relPath)
            // Only trigger if the scan path is a parent of the protected path
            if fullPath.hasPrefix(scanPath) || scanPath == "/" {
                _ = FileManager.default.isReadableFile(atPath: fullPath)
                _ = try? FileManager.default.contentsOfDirectory(atPath: fullPath)
            }
        }
    }
}
