import Foundation

public enum Permissions {
    /// All known TCC-protected paths that may trigger permission dialogs.
    /// Grouped by TCC service type.
    private static func protectedPaths() -> [String] {
        let home = NSHomeDirectory()
        return [
            // kTCCServiceSystemPolicyDesktopFolder
            home + "/Desktop",
            // kTCCServiceSystemPolicyDocumentsFolder
            home + "/Documents",
            // kTCCServiceSystemPolicyDownloadsFolder
            home + "/Downloads",
            // kTCCServicePhotos — Photos library
            home + "/Pictures",
            // kTCCServiceMediaLibrary — Apple Music
            home + "/Music",
            // kTCCServiceAddressBook — Contacts
            home + "/Library/Application Support/AddressBook",
            // kTCCServiceCalendar
            home + "/Library/Calendars",
            // kTCCServiceReminders
            home + "/Library/Reminders",
            // Mail (requires FDA)
            home + "/Library/Mail",
            // Messages (requires FDA)
            home + "/Library/Messages",
            // Safari (requires FDA)
            home + "/Library/Safari",
            // Cookies (requires FDA)
            home + "/Library/Cookies",
        ]
    }

    /// Pre-trigger TCC permission dialogs for all protected directories.
    /// Call before starting a full scan so dialogs appear upfront.
    public static func preTriggerPermissions() {
        let fm = FileManager.default
        for path in protectedPaths() {
            // Attempt to read triggers the TCC dialog if needed
            _ = fm.isReadableFile(atPath: path)
            _ = try? fm.contentsOfDirectory(atPath: path)
        }
    }
}
