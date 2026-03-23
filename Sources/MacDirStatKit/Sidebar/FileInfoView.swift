import SwiftUI

public struct FileInfoView: View {
    let node: FileNode?

    public init(node: FileNode?) {
        self.node = node
    }

    public var body: some View {
        if let node = node {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: node.isDirectory ? "folder.fill" : "doc.fill")
                        .foregroundStyle(node.isDirectory ? .blue : .secondary)
                    Text(node.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Text(node.path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.head)
                HStack {
                    Text("Size:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(SizeFormatter.format(node.subtreeSize))
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                if !node.fileExtension.isEmpty {
                    HStack {
                        Text("Type:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(".\(node.fileExtension)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
                if node.isDirectory, let children = node.children {
                    HStack {
                        Text("Items:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(children.count)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        } else {
            Text("No selection")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
}
