import SwiftUI

/// The signed-in shell: a tabbed browser with a persistent rate-limit HUD pinned to the top.
/// Additional tabs (Dockets, Opinions) are added as those screens land.
struct MainView: View {
    @Bindable var store: CourtListenerStore
    let onSignOut: () -> Void

    var body: some View {
        TabView {
            CourtsView(store: store, onSignOut: onSignOut)
                .tabItem { Label("Courts", systemImage: "building.columns") }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            UsageHUD(usage: store.model.apiUsage)
        }
    }
}

#if DEBUG
#Preview("Main") {
    MainView(store: .preview(.TestVariants.withSCOTUS), onSignOut: {})
}
#endif
