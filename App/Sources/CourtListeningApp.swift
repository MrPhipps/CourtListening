import SwiftUI
import CourtListeningUI

/// Universal (iOS + macOS) host for the CourtListening interface. All logic lives in
/// CourtListeningUI / CourtListening / CourtListeningCore; this target is only the app shell.
@main
struct CourtListeningApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
