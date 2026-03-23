import Foundation

public struct VolumeInfo: Identifiable, Sendable {
    public let id: URL
    public let name: String
    public let url: URL
    public let totalCapacity: Int64
    public let availableCapacity: Int64

    public var usedCapacity: Int64 { totalCapacity - availableCapacity }
}

public enum VolumeDiscovery {
    public static func mountedVolumes() -> [VolumeInfo] {
        guard
            let volumeURLs = FileManager.default.mountedVolumeURLs(
                includingResourceValuesForKeys: [
                    .volumeNameKey, .volumeTotalCapacityKey,
                    .volumeAvailableCapacityForImportantUsageKey,
                ],
                options: [.skipHiddenVolumes])
        else { return [] }

        return volumeURLs.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: [
                .volumeNameKey, .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey,
            ]) else { return nil }

            return VolumeInfo(
                id: url,
                name: values.volumeName ?? url.lastPathComponent,
                url: url,
                totalCapacity: Int64(values.volumeTotalCapacity ?? 0),
                availableCapacity: Int64(
                    values.volumeAvailableCapacityForImportantUsage ?? 0))
        }
    }
}
