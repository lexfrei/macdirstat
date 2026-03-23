import CoreGraphics

public struct LayoutItem: Sendable {
    public let node: FileNode
    public let area: Double

    public init(node: FileNode, area: Double) {
        self.node = node
        self.area = area
    }
}

public struct LayoutRect: Sendable {
    public let node: FileNode
    public let frame: CGRect

    public init(node: FileNode, frame: CGRect) {
        self.node = node
        self.frame = frame
    }
}

public protocol TreemapLayoutAlgorithm: Sendable {
    func layout(items: [LayoutItem], in rect: CGRect) -> [LayoutRect]
}

public struct SquarifiedTreemapLayout: TreemapLayoutAlgorithm {
    public init() {}

    public func layout(items: [LayoutItem], in rect: CGRect) -> [LayoutRect] {
        let filtered = items.filter { $0.area > 0 }
            .sorted { $0.area > $1.area }

        guard !filtered.isEmpty else { return [] }
        guard rect.width >= 1, rect.height >= 1 else { return [] }

        if filtered.count == 1 {
            return [LayoutRect(node: filtered[0].node, frame: rect)]
        }

        let totalArea = filtered.reduce(0.0) { $0 + $1.area }
        guard totalArea > 0 else { return [] }

        let scale = Double(rect.width * rect.height) / totalArea
        let scaled = filtered.map { LayoutItem(node: $0.node, area: $0.area * scale) }

        return squarify(items: scaled, in: rect)
    }

    private func squarify(items: [LayoutItem], in rect: CGRect) -> [LayoutRect] {
        guard !items.isEmpty else { return [] }
        guard rect.width >= 1, rect.height >= 1 else { return [] }

        if items.count == 1 {
            return [LayoutRect(node: items[0].node, frame: rect)]
        }

        var result: [LayoutRect] = []
        var currentRow: [LayoutItem] = []
        var remaining = items
        var currentRect = rect

        while !remaining.isEmpty {
            let side = min(Double(currentRect.width), Double(currentRect.height))
            let candidate = remaining[0]
            let testRow = currentRow + [candidate]

            if currentRow.isEmpty
                || worstRatio(testRow, side: side) <= worstRatio(currentRow, side: side)
            {
                currentRow = testRow
                remaining.removeFirst()
            } else {
                let (rects, remainingRect) = layoutRow(currentRow, in: currentRect)
                result.append(contentsOf: rects)
                currentRect = remainingRect
                currentRow = []
            }
        }

        if !currentRow.isEmpty {
            let (rects, _) = layoutRow(currentRow, in: currentRect)
            result.append(contentsOf: rects)
        }

        return result
    }

    private func worstRatio(_ row: [LayoutItem], side: Double) -> Double {
        guard side > 0 else { return Double.infinity }
        let totalArea = row.reduce(0.0) { $0 + $1.area }
        guard totalArea > 0 else { return Double.infinity }
        let rowWidth = totalArea / side

        var worst = 0.0
        for item in row {
            let length = item.area / rowWidth
            let ratio = max(length / rowWidth, rowWidth / length)
            worst = max(worst, ratio)
        }
        return worst
    }

    private func layoutRow(_ row: [LayoutItem], in rect: CGRect)
        -> ([LayoutRect], CGRect)
    {
        guard !row.isEmpty else { return ([], rect) }

        let totalRowArea = row.reduce(0.0) { $0 + $1.area }
        let isHorizontal = rect.width >= rect.height

        if isHorizontal {
            let rowWidth = CGFloat(totalRowArea / Double(rect.height))
            var y = rect.minY
            var rects: [LayoutRect] = []

            for item in row {
                let itemHeight = CGFloat(item.area / Double(rowWidth))
                rects.append(
                    LayoutRect(
                        node: item.node,
                        frame: CGRect(
                            x: rect.minX, y: y,
                            width: rowWidth, height: itemHeight)))
                y += itemHeight
            }

            let remainingRect = CGRect(
                x: rect.minX + rowWidth, y: rect.minY,
                width: rect.width - rowWidth, height: rect.height)
            return (rects, remainingRect)
        } else {
            let rowHeight = CGFloat(totalRowArea / Double(rect.width))
            var x = rect.minX
            var rects: [LayoutRect] = []

            for item in row {
                let itemWidth = CGFloat(item.area / Double(rowHeight))
                rects.append(
                    LayoutRect(
                        node: item.node,
                        frame: CGRect(
                            x: x, y: rect.minY,
                            width: itemWidth, height: rowHeight)))
                x += itemWidth
            }

            let remainingRect = CGRect(
                x: rect.minX, y: rect.minY + rowHeight,
                width: rect.width, height: rect.height - rowHeight)
            return (rects, remainingRect)
        }
    }
}
