import SwiftUI

public struct TreemapView: View {
    @Bindable var appState: AppState
    let renderer: TreemapRenderer

    @State private var cachedRects: [LayoutRect] = []
    @State private var lastSize: CGSize = .zero

    public init(appState: AppState, renderer: TreemapRenderer) {
        self.appState = appState
        self.renderer = renderer
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
                recomputeLayout(size: newSize)
            }
            .onAppear {
                recomputeLayout(size: geometry.size)
            }
        }
    }

    private func recomputeLayout(size: CGSize) {
        guard let root = appState.currentViewRoot else {
            cachedRects = []
            return
        }
        lastSize = size
        let rect = CGRect(origin: .zero, size: size)
        cachedRects = renderer.computeLayout(root: root, in: rect)
    }
}
