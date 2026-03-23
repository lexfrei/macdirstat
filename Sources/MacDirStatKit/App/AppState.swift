import SwiftUI

@MainActor
@Observable
public final class AppState {
    public var selectedURL: URL?
    public var rootNode: (any Identifiable)?

    public init() {}
}
