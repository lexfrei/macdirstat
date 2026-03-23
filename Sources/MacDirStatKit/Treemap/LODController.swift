import CoreGraphics

public struct LODController: Sendable {
    public let minimumDrawSize: CGFloat
    public let minimumRecurseSize: CGFloat
    public let minimumLabelWidth: CGFloat
    public let minimumLabelHeight: CGFloat
    public let maximumDepth: Int

    public init(
        minimumDrawSize: CGFloat = 2,
        minimumRecurseSize: CGFloat = 10,
        minimumLabelWidth: CGFloat = 60,
        minimumLabelHeight: CGFloat = 20,
        maximumDepth: Int = 6
    ) {
        self.minimumDrawSize = minimumDrawSize
        self.minimumRecurseSize = minimumRecurseSize
        self.minimumLabelWidth = minimumLabelWidth
        self.minimumLabelHeight = minimumLabelHeight
        self.maximumDepth = maximumDepth
    }

    public func shouldDraw(rect: CGRect) -> Bool {
        rect.width >= minimumDrawSize && rect.height >= minimumDrawSize
    }

    public func shouldRecurse(rect: CGRect, depth: Int) -> Bool {
        depth < maximumDepth
            && rect.width >= minimumRecurseSize
            && rect.height >= minimumRecurseSize
    }

    public func shouldDrawLabel(rect: CGRect) -> Bool {
        rect.width >= minimumLabelWidth && rect.height >= minimumLabelHeight
    }
}
