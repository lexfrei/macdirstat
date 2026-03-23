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
                renderer.draw(
                    context: &context,
                    rects: cachedRects,
                    hoveredNode: appState.hoveredNode,
                    selectedNode: appState.selectedNode)
            }
            .onChange(of: geometry.size) { _, newSize in
                currentSize = newSize
                recomputeLayout(size: newSize)
            }
            .onChange(of: viewRootID) { _, _ in
                recomputeLayout(size: currentSize)
            }
            .onChange(of: appState.rootNode?.id) { _, _ in
                recomputeLayout(size: currentSize)
            }
            .onAppear {
                currentSize = geometry.size
                recomputeLayout(size: geometry.size)
            }
        }
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
