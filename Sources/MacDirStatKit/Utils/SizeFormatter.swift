public enum SizeFormatter {
    private static let units = ["B", "KB", "MB", "GB", "TB", "PB"]

    public static func format(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }

        if bytes < 1000 {
            return "\(bytes) B"
        }

        var value = Double(bytes)
        var unitIndex = 0

        while value >= 1000, unitIndex < units.count - 1 {
            value /= 1000
            unitIndex += 1
        }

        return String(format: "%.1f %@", value, units[unitIndex])
    }
}
