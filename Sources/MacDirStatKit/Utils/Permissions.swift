import Foundation

public enum Permissions {
    private static let protectedRelPaths: [String] = [
        "Desktop", "Documents", "Downloads", "Pictures", "Music",
        "Library/Application Support/AddressBook",
        "Library/Calendars", "Library/Reminders",
        "Library/Mail", "Library/Messages",
        "Library/Safari", "Library/Cookies",
    ]

    /// Pre-trigger TCC permission dialogs for protected directories
    /// that overlap with the scan path. Lightweight: only stat, no listing.
    public static func preTriggerIfNeeded(scanPath: String) {
        let home = NSHomeDirectory()
        let fm = FileManager.default

        for relPath in protectedRelPaths {
            let fullPath = (home as NSString).appendingPathComponent(relPath)
            // Trigger if scan path contains the protected dir, or is inside it
            guard fullPath.hasPrefix(scanPath) || scanPath.hasPrefix(fullPath)
                || scanPath == "/"
            else { continue }
            // isReadableFile triggers TCC dialog if needed (lightweight stat)
            _ = fm.isReadableFile(atPath: fullPath)
        }
    }
}
