import SwiftUI

public struct ExtensionLegendEntry: Sendable {
    public let fileExtension: String
    public let color: Color
    public let totalSize: Int64
}

public struct GoldenAngleColorMapper: Sendable {
    private let extensionToIndex: [String: Int]
    private let maxDistinct: Int
    private let saturation: Double
    private let brightness: Double
    private let goldenAngle: Double = 137.508

    public static let noExtensionColor = Color(hue: 0, saturation: 0, brightness: 0.533)
    public static let folderColor = Color(hue: 0, saturation: 0, brightness: 0.333)

    public init(maxDistinct: Int = 20, saturation: Double = 0.65, brightness: Double = 0.85) {
        self.extensionToIndex = [:]
        self.maxDistinct = maxDistinct
        self.saturation = saturation
        self.brightness = brightness
    }

    private init(
        extensionToIndex: [String: Int], maxDistinct: Int,
        saturation: Double, brightness: Double
    ) {
        self.extensionToIndex = extensionToIndex
        self.maxDistinct = maxDistinct
        self.saturation = saturation
        self.brightness = brightness
    }

    public func withMapping(from rootNode: FileNode) -> GoldenAngleColorMapper {
        var sizesPerExt: [String: Int64] = [:]
        Self.accumulateSizes(rootNode, into: &sizesPerExt)

        let sorted = sizesPerExt
            .sorted { $0.value > $1.value }
            .prefix(maxDistinct)

        var mapping: [String: Int] = [:]
        for (index, entry) in sorted.enumerated() {
            mapping[entry.key] = index
        }

        return GoldenAngleColorMapper(
            extensionToIndex: mapping, maxDistinct: maxDistinct,
            saturation: saturation, brightness: brightness)
    }

    public func color(for fileExtension: String) -> Color {
        if fileExtension.isEmpty {
            return Self.noExtensionColor
        }

        if let index = extensionToIndex[fileExtension] {
            let hue = Double(index) * goldenAngle / 360.0
            return Color(
                hue: hue.truncatingRemainder(dividingBy: 1.0),
                saturation: saturation,
                brightness: brightness)
        }

        let hash = abs(fileExtension.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: saturation * 0.5, brightness: brightness * 0.8)
    }

    public func legend(for rootNode: FileNode) -> [ExtensionLegendEntry] {
        var sizesPerExt: [String: Int64] = [:]
        Self.accumulateSizes(rootNode, into: &sizesPerExt)

        return sizesPerExt
            .sorted { $0.value > $1.value }
            .prefix(maxDistinct)
            .map { ext, size in
                ExtensionLegendEntry(
                    fileExtension: ext.isEmpty ? "(no extension)" : ext,
                    color: color(for: ext),
                    totalSize: size)
            }
    }

    private static func accumulateSizes(_ node: FileNode, into sizes: inout [String: Int64]) {
        if node.isDirectory {
            for child in node.children ?? [] {
                accumulateSizes(child, into: &sizes)
            }
        } else {
            sizes[node.fileExtension, default: 0] += node.fileSize
        }
    }
}
