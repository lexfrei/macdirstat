import MacDirStatKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
}

@main
struct MacDirStatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var multiTab = MultiTabState()

    var body: some Scene {
        WindowGroup {
            MultiTabView(multiTab: multiTab)
        }
    }
}
