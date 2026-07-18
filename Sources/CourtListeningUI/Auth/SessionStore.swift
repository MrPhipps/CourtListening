import Foundation
import Observation
import CourtListeningCore
import CourtListening

/// Owns the authentication lifecycle, above the domain loop. The `CourtListenerRunner` takes an
/// immutable token at init, so a session is simply "a `CourtListenerStore` or not": signing in
/// constructs one, signing out discards it.
///
/// `phase` is enum-vended so `RootView` can switch exhaustively over the render states.
@MainActor
@Observable
public final class SessionStore {
    public enum Phase: Sendable {
        case signedOut
        case validating
        case signedIn(CourtListenerStore)
    }

    public private(set) var phase: Phase = .signedOut
    public private(set) var authError: String?

    @ObservationIgnored private let keychain: KeychainStore
    @ObservationIgnored private let validator: TokenValidator
    @ObservationIgnored private let transport: (any HTTPTransport)?

    public init(
        keychain: KeychainStore = KeychainStore(),
        validator: TokenValidator = .live,
        transport: (any HTTPTransport)? = nil
    ) {
        self.keychain = keychain
        self.validator = validator
        self.transport = transport
    }

    /// Silent sign-in: try the stored token first, then the `$COURTLISTENER_API_TOKEN`
    /// dev-fallback environment variable.
    public func restore() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let stored = await self.keychain.load() {
                await self.attempt(rawToken: stored, persist: false)
                if case .signedIn = self.phase { return }
            }
            let env = ProcessInfo.processInfo.environment["COURTLISTENER_API_TOKEN"]
            if let env, !env.isEmpty {
                await self.attempt(rawToken: env, persist: true)
            }
        }
    }

    public func signIn(rawToken: String) {
        Task { @MainActor [weak self] in
            await self?.attempt(rawToken: rawToken, persist: true)
        }
    }

    public func signOut() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.keychain.delete()
            self.authError = nil
            self.phase = .signedOut
        }
    }

    private func attempt(rawToken: String, persist: Bool) async {
        authError = nil
        let trimmed = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        let token: APIToken
        do {
            token = try APIToken(trimmed)
        } catch {
            phase = .signedOut
            authError = (error as? CourtListenerError)?.errorDescription ?? "Invalid token"
            return
        }
        phase = .validating
        switch await validator.validate(token) {
        case .success:
            if persist { try? await keychain.save(token.rawValue) }
            phase = .signedIn(CourtListenerStore(token: token, transport: transport))
        case .failure(let error):
            phase = .signedOut
            authError = error.errorDescription
        }
    }
}

#if DEBUG
extension SessionStore {
    /// Testing hook: run a sign-in attempt and await completion, without persisting to Keychain.
    public func signInAwaiting(rawToken: String) async {
        await attempt(rawToken: rawToken, persist: false)
    }
}
#endif
