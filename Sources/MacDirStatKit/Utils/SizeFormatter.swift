public enum SizeFormatter {
    private static let units = ["B", "KB", "MB", "GB", "TB", "PB"]

    public static func format(_ bytes: Int64) -> String {
        if bytes == 0 { return "0 B" }

        let negative = bytes < 0
        let absBytes = abs(bytes)

        if absBytes < 1000 {
            return negative ? "-\(absBytes) B" : "\(absBytes) B"
        }

        var value = Double(absBytes)
        var unitIndex = 0

        while value >= 999.95, unitIndex < units.count - 1 {
            value /= 1000
            unitIndex += 1
        }

        let formatted = String(format: "%.1f %@", value, units[unitIndex])
        return negative ? "-\(formatted)" : formatted
    }
}
