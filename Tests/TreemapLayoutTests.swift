import SwiftUI
import Testing

@testable import MacDirStatKit

@Suite("TreemapLayout")
struct TreemapLayoutTests {
    let layout = SquarifiedTreemapLayout()
    let bounds = CGRect(x: 0, y: 0, width: 800, height: 600)

    private func makeNode(_ name: String, size: Int64) -> FileNode {
        FileNode(
            name: name, url: URL(filePath: "/tmp/\(name)"),
            isDirectory: false, fileSize: size, fileExtension: "txt")
    }

    private func makeItems(_ sizes: [(String, Double)]) -> [LayoutItem] {
        sizes.map { name, area in
            LayoutItem(node: makeNode(name, size: Int64(area)), area: area)
        }
    }

    @Test func emptyInputProducesEmptyOutput() {
        let result = layout.layout(items: [], in: bounds)
        #expect(result.isEmpty)
    }

    @Test func singleItemFillsEntireRect() {
        let items = makeItems([("file.txt", 100)])
        let result = layout.layout(items: items, in: bounds)
        #expect(result.count == 1)
        #expect(abs(result[0].frame.minX - bounds.minX) < 0.01)
        #expect(abs(result[0].frame.minY - bounds.minY) < 0.01)
        #expect(abs(result[0].frame.width - bounds.width) < 0.01)
        #expect(abs(result[0].frame.height - bounds.height) < 0.01)
    }

    @Test func twoEqualItemsProduceEqualAreas() {
        let items = makeItems([("a.txt", 50), ("b.txt", 50)])
        let result = layout.layout(items: items, in: bounds)
        #expect(result.count == 2)
        let area1 = Double(result[0].frame.width * result[0].frame.height)
        let area2 = Double(result[1].frame.width * result[1].frame.height)
        #expect(abs(area1 - area2) < 1.0)
    }

    @Test func areaConservation() {
        let items = makeItems([
            ("big.txt", 1000), ("med.txt", 500), ("small.txt", 200), ("tiny.txt", 100),
        ])
        let result = layout.layout(items: items, in: bounds)
        let totalResultArea = result.reduce(0.0) {
            $0 + Double($1.frame.width * $1.frame.height)
        }
        let boundsArea = Double(bounds.width * bounds.height)
        #expect(abs(totalResultArea - boundsArea) < 1.0)
    }

    @Test func allRectsContainedInBounds() {
        let items = makeItems([
            ("a", 100), ("b", 80), ("c", 60), ("d", 40), ("e", 20), ("f", 10),
        ])
        let result = layout.layout(items: items, in: bounds)
        for r in result {
            #expect(r.frame.minX >= bounds.minX - 0.01)
            #expect(r.frame.minY >= bounds.minY - 0.01)
            #expect(r.frame.maxX <= bounds.maxX + 0.01)
            #expect(r.frame.maxY <= bounds.maxY + 0.01)
        }
    }

    @Test func noRectsOverlap() {
        let items = makeItems([
            ("a", 300), ("b", 200), ("c", 150), ("d", 100), ("e", 50),
        ])
        let result = layout.layout(items: items, in: bounds)
        for i in 0..<result.count {
            for j in (i + 1)..<result.count {
                let intersection = result[i].frame.intersection(result[j].frame)
                let overlapArea = intersection.width * intersection.height
                #expect(overlapArea < 1.0)
            }
        }
    }

    @Test func aspectRatioQuality() {
        let items = makeItems([
            ("a", 500), ("b", 400), ("c", 300), ("d", 200), ("e", 100),
        ])
        let result = layout.layout(items: items, in: bounds)
        for r in result {
            let ratio = max(
                Double(r.frame.width / r.frame.height),
                Double(r.frame.height / r.frame.width))
            #expect(ratio < 5.0)
        }
    }

    @Test func zeroSizeItemsFiltered() {
        let items = makeItems([("real.txt", 100), ("empty.txt", 0)])
        let result = layout.layout(items: items, in: bounds)
        #expect(result.count == 1)
        #expect(result[0].node.name == "real.txt")
    }

    @Test func allInputItemsHaveOutputRects() {
        let items = makeItems([("a", 100), ("b", 200), ("c", 300)])
        let result = layout.layout(items: items, in: bounds)
        let resultNames = Set(result.map(\.node.name))
        let inputNames = Set(items.map(\.node.name))
        #expect(resultNames == inputNames)
    }

    @Test func tinyRectProducesEmptyOutput() {
        let tiny = CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
        let items = makeItems([("a", 100)])
        let result = layout.layout(items: items, in: tiny)
        #expect(result.isEmpty)
    }

    @Test func manyItemsStillConserveArea() {
        let items = (1...20).map { i in
            LayoutItem(
                node: makeNode("f\(i).txt", size: Int64(i * 100)),
                area: Double(i * 100))
        }
        let result = layout.layout(items: items, in: bounds)
        #expect(result.count == 20)
        let totalArea = result.reduce(0.0) {
            $0 + Double($1.frame.width * $1.frame.height)
        }
        let boundsArea = Double(bounds.width * bounds.height)
        #expect(abs(totalArea - boundsArea) < 2.0)
    }
}
