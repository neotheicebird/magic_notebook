import SwiftUI

@main
struct MagicNotesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowStyle(DefaultWindowStyle())
        #endif
    }
} 