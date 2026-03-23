import Testing

@testable import MacDirStatKit

@Suite("LODController")
struct LODControllerTests {
    let lod = LODController()

    @Test func drawsLargeRect() {
        #expect(lod.shouldDraw(rect: .init(x: 0, y: 0, width: 100, height: 100)))
    }

    @Test func skipsDrawForTinyRect() {
        #expect(!lod.shouldDraw(rect: .init(x: 0, y: 0, width: 1, height: 1)))
    }

    @Test func drawsBoundaryRect() {
        #expect(lod.shouldDraw(rect: .init(x: 0, y: 0, width: 2, height: 2)))
    }

    @Test func recursesLargeRect() {
        #expect(lod.shouldRecurse(rect: .init(x: 0, y: 0, width: 100, height: 100), depth: 0))
    }

    @Test func skipsRecurseForSmallRect() {
        #expect(!lod.shouldRecurse(rect: .init(x: 0, y: 0, width: 5, height: 5), depth: 0))
    }

    @Test func skipsRecurseForDeepDepth() {
        #expect(!lod.shouldRecurse(rect: .init(x: 0, y: 0, width: 100, height: 100), depth: 6))
    }

    @Test func recursesAtBoundaryDepth() {
        #expect(lod.shouldRecurse(rect: .init(x: 0, y: 0, width: 100, height: 100), depth: 5))
    }

    @Test func drawsLabelForLargeRect() {
        #expect(lod.shouldDrawLabel(rect: .init(x: 0, y: 0, width: 100, height: 30)))
    }

    @Test func skipsLabelForNarrowRect() {
        #expect(!lod.shouldDrawLabel(rect: .init(x: 0, y: 0, width: 50, height: 30)))
    }

    @Test func skipsLabelForShortRect() {
        #expect(!lod.shouldDrawLabel(rect: .init(x: 0, y: 0, width: 100, height: 10)))
    }
}
