import SwiftUI

/// Token entry. Purely presentational — it owns only the draft token text and reports
/// submission upward; all auth logic lives in `SessionStore`.
struct SignInView: View {
    let error: String?
    let onSubmit: (String) -> Void

    @State private var token: String = ""

    var body: some View {
        VStack(spacing: Design.Spacing.lg) {
            VStack(spacing: Design.Spacing.sm) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: Design.Size.iconMedium))
                    .foregroundStyle(Design.Color.accent)
                Text("CourtListening")
                    .font(Design.Font.title)
                Text("Sign in with your CourtListener API token")
                    .font(Design.Font.body)
                    .foregroundStyle(Design.Color.secondaryText)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Design.Spacing.md) {
                TextField("API token", text: $token)
                    .textFieldStyle(.roundedBorder)
                    .font(Design.Font.mono)
                    .onSubmit(submit)

                if let error {
                    ErrorBanner(message: error)
                }

                Button(action: submit) {
                    Text("Sign In")
                        .frame(maxWidth: .infinity, minHeight: Design.Size.minTapTarget)
                }
                .buttonStyle(.borderedProminent)
                .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .frame(maxWidth: 420)

            Text("Get a token at courtlistener.com/profile/api-token/")
                .font(Design.Font.caption)
                .foregroundStyle(Design.Color.secondaryText)
        }
        .padding(Design.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func submit() {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
    }
}

/// Inline error surface used across auth + data screens.
struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: Design.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(Design.Font.caption)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Design.Color.danger)
        .padding(Design.Spacing.sm)
        .background(Design.Color.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: Design.Size.cornerRadius))
    }
}

#if DEBUG
#Preview("Sign In — empty") {
    SignInView(error: nil) { _ in }
}

#Preview("Sign In — error") {
    SignInView(error: "Authentication required — provide a valid API token") { _ in }
}
#endif
