import SwiftUI

public struct BreadcrumbView: View {
    let rootName: String
    let stack: [FileNode]
    let onSelectRoot: () -> Void
    let onSelect: (Int) -> Void

    public init(
        rootName: String,
        stack: [FileNode],
        onSelectRoot: @escaping () -> Void,
        onSelect: @escaping (Int) -> Void
    ) {
        self.rootName = rootName
        self.stack = stack
        self.onSelectRoot = onSelectRoot
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 2) {
            Button(rootName) {
                onSelectRoot()
            }
            .buttonStyle(.plain)
            .foregroundStyle(stack.isEmpty ? Color.primary : Color.blue)

            ForEach(Array(stack.enumerated()), id: \.element.id) { index, node in
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Button(node.name) {
                    onSelect(index)
                }
                .buttonStyle(.plain)
                .foregroundStyle(index == stack.count - 1 ? Color.primary : Color.blue)
            }

            Spacer()
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider() }
    }
}
