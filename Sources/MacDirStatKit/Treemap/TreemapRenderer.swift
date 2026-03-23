import SwiftUI

public struct TreemapRenderer {
    public let lod: LODController
    public let colorMapper: GoldenAngleColorMapper
    public let layoutAlgorithm: any TreemapLayoutAlgorithm

    public init(
        lod: LODController = LODController(),
        colorMapper: GoldenAngleColorMapper = GoldenAngleColorMapper(),
        layoutAlgorithm: any TreemapLayoutAlgorithm = SquarifiedTreemapLayout()
    ) {
        self.lod = lod
        self.colorMapper = colorMapper
        self.layoutAlgorithm = layoutAlgorithm
    }

    public func computeLayout(root: FileNode, in rect: CGRect) -> [LayoutRect] {
        guard let children = root.children, !children.isEmpty else { return [] }

        let items = children.map {
            LayoutItem(node: $0, area: Double($0.subtreeSize))
        }
        let topLevel = layoutAlgorithm.layout(items: items, in: rect)

        var result: [LayoutRect] = []
        for lr in topLevel {
            appendRects(for: lr, depth: 0, into: &result)
        }
        return result
    }

    private func appendRects(for lr: LayoutRect, depth: Int, into result: inout [LayoutRect]) {
        guard lod.shouldDraw(rect: lr.frame) else { return }

        if lr.node.isDirectory,
            let children = lr.node.children,
            !children.isEmpty,
            lod.shouldRecurse(rect: lr.frame, depth: depth)
        {
            let childItems = children.map {
                LayoutItem(node: $0, area: Double($0.subtreeSize))
            }
            let childRects = layoutAlgorithm.layout(items: childItems, in: lr.frame)
            for childLR in childRects {
                appendRects(for: childLR, depth: depth + 1, into: &result)
            }
        } else {
            result.append(lr)
        }
    }

    public func draw(
        context: inout GraphicsContext,
        rects: [LayoutRect],
        hoveredNode: FileNode?,
        selectedNode: FileNode?
    ) {
        let borderColor = Color.black.opacity(0.2)

        for lr in rects {
            guard lod.shouldDraw(rect: lr.frame) else { continue }

            let ext = lr.node.isDirectory ? "" : lr.node.fileExtension
            let fillColor =
                lr.node.isDirectory
                ? GoldenAngleColorMapper.folderColor
                : colorMapper.color(for: ext)

            context.fill(Path(lr.frame), with: .color(fillColor))
            context.stroke(
                Path(lr.frame),
                with: .color(borderColor),
                lineWidth: 0.5)

            if lod.shouldDrawLabel(rect: lr.frame) {
                let labelRect = lr.frame.insetBy(dx: 2, dy: 2)
                let text = Text(lr.node.name)
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
                context.draw(
                    context.resolve(text),
                    in: labelRect)
            }
        }

        if let hovered = hoveredNode,
            let hr = rects.first(where: { $0.node.id == hovered.id })
        {
            context.fill(Path(hr.frame), with: .color(.white.opacity(0.3)))
        }

        if let selected = selectedNode,
            let sr = rects.first(where: { $0.node.id == selected.id })
        {
            context.stroke(
                Path(sr.frame),
                with: .color(.white),
                lineWidth: 2)
        }
    }
}
