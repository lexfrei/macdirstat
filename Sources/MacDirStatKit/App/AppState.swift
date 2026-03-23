import SwiftUI

@MainActor
@Observable
public final class AppState {
    public var selectedURL: URL?
    public var isPickerPresented = false

    public init() {}
}
