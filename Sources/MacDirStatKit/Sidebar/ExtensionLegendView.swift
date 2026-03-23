import SwiftUI

public struct ExtensionLegendView: View {
    let entries: [ExtensionLegendEntry]

    public init(entries: [ExtensionLegendEntry]) {
        self.entries = entries
    }

    public var body: some View {
        if entries.isEmpty {
            Text("No data")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(entry.color)
                                .frame(width: 12, height: 12)
                            Text(entry.fileExtension)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(SizeFormatter.format(entry.totalSize))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
    }
}
