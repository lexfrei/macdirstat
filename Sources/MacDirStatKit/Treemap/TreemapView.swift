import AppKit
import SwiftUI

public struct TreemapView: View {
    @Bindable var appState: AppState
    let renderer: TreemapRenderer

    @State private var cachedRects: [LayoutRect] = []
    @State private var currentSize: CGSize = .zero

    public init(appState: AppState, renderer: TreemapRenderer) {
        self.appState = appState
        self.renderer = renderer
    }

    private var viewRootID: UUID? {
        appState.currentViewRoot?.id
    }

    public var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let scaledSize = CGSize(
                    width: size.width * appState.zoomScale,
                    height: size.height * appState.zoomScale)

                context.translateBy(x: appState.panOffset.width, y: appState.panOffset.height)
                context.scaleBy(x: appState.zoomScale, y: appState.zoomScale)

                renderer.draw(
                    context: &context,
                    rects: cachedRects,
                    hoveredNode: appState.hoveredNode,
                    selectedNode: appState.selectedNode)
            }
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    let adjusted = adjustedPoint(location)
                    appState.hoveredNode = nodeAt(point: adjusted)
                case .ended:
                    appState.hoveredNode = nil
                }
            }
            .onTapGesture(count: 2) { location in
                let adjusted = adjustedPoint(location)
                if let node = nodeAt(point: adjusted), node.isDirectory {
                    appState.drillDown(into: node)
                }
            }
            .onTapGesture { location in
                let adjusted = adjustedPoint(location)
                appState.selectedNode = nodeAt(point: adjusted)
            }
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        let newScale = max(
                            AppState.minZoom,
                            min(AppState.maxZoom, appState.zoomScale * value.magnification))
                        appState.zoomScale = newScale
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard appState.zoomScale > 1.0 else { return }
                        appState.panOffset = CGSize(
                            width: value.translation.width,
                            height: value.translation.height)
                    }
                    .onEnded { _ in
                        // Keep the current offset
                    }
            )
            .onKeyPress(.delete) {
                appState.navigateUp()
                return .handled
            }
            .onKeyPress(.escape) {
                appState.selectedNode = nil
                appState.zoomScale = 1.0
                appState.panOffset = .zero
                return .handled
            }
            .contextMenu {
                if let node = appState.selectedNode ?? appState.hoveredNode {
                    Button("Reveal in Finder") {
                        NSWorkspace.shared.selectFile(
                            node.url.path(percentEncoded: false), inFileViewerRootedAtPath: "")
                    }
                    Button("Copy Path") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(
                            node.url.path(percentEncoded: false), forType: .string)
                    }
                    if node.isDirectory {
                        Divider()
                        Button("Open Here") {
                            appState.drillDown(into: node)
                        }
                    }
                    Divider()
                    Button("Move to Trash", role: .destructive) {
                        appState.requestDelete(nodes: [node])
                    }
                }
            }
            .focusable()
            .onChange(of: geometry.size) { _, newSize in
                currentSize = newSize
                recomputeLayout(size: newSize)
            }
            .onChange(of: viewRootID) { _, _ in
                appState.zoomScale = 1.0
                appState.panOffset = .zero
                recomputeLayout(size: currentSize)
            }
            .onChange(of: appState.rootNode?.id) { _, _ in
                appState.zoomScale = 1.0
                appState.panOffset = .zero
                recomputeLayout(size: currentSize)
            }
            .onAppear {
                currentSize = geometry.size
                recomputeLayout(size: geometry.size)
            }
        }
    }

    private func adjustedPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: (point.x - appState.panOffset.width) / appState.zoomScale,
            y: (point.y - appState.panOffset.height) / appState.zoomScale)
    }

    private func nodeAt(point: CGPoint) -> FileNode? {
        for i in stride(from: cachedRects.count - 1, through: 0, by: -1) {
            if cachedRects[i].frame.contains(point) {
                return cachedRects[i].node
            }
        }
        return nil
    }

    private func recomputeLayout(size: CGSize) {
        guard size.width > 0, size.height > 0 else {
            cachedRects = []
            return
        }
        guard let root = appState.currentViewRoot else {
            cachedRects = []
            return
        }
        let rect = CGRect(origin: .zero, size: size)
        cachedRects = renderer.computeLayout(root: root, in: rect)
    }
}
