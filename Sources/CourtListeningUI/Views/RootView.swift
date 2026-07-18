import SwiftUI
import CourtListeningCore

/// App entry point. Vends the top-level screen by switching exhaustively over the session phase.
public struct RootView: View {
    @State private var session: SessionStore

    @MainActor
    public init() {
        _session = State(initialValue: SessionStore())
    }

    @MainActor
    public init(session: SessionStore) {
        _session = State(initialValue: session)
    }

    public var body: some View {
        content
            .environment(session)
            .task { session.restore() }
    }

    @ViewBuilder
    private var content: some View {
        switch session.phase {
        case .signedOut:
            SignInView(error: session.authError) { token in session.signIn(rawToken: token) }
        case .validating:
            LoadingView(label: "Validating token…")
        case .signedIn(let store):
            MainView(store: store) { session.signOut() }
        }
    }
}

struct LoadingView: View {
    let label: String

    var body: some View {
        VStack(spacing: Design.Spacing.md) {
            ProgressView()
            Text(label)
                .font(Design.Font.body)
                .foregroundStyle(Design.Color.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview("Loading") {
    LoadingView(label: "Validating token…")
}
#endif
