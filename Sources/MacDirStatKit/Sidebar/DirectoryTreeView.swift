import SwiftUI

public struct DirectoryTreeView: View {
    let rootNode: FileNode?

    public init(rootNode: FileNode?) {
        self.rootNode = rootNode
    }

    public var body: some View {
        if let root = rootNode, let children = root.children {
            List {
                OutlineGroup(children, children: \.optionalChildren) { node in
                    HStack {
                        Image(systemName: node.isDirectory ? "folder.fill" : "doc.fill")
                            .foregroundStyle(node.isDirectory ? .blue : .secondary)
                            .frame(width: 16)
                        Text(node.name)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Text(SizeFormatter.format(node.subtreeSize))
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
            .listStyle(.sidebar)
        } else {
            Text("No scan data")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
}

extension FileNode {
    var optionalChildren: [FileNode]? {
        guard isDirectory, let children = children, !children.isEmpty else { return nil }
        return children
    }
}
