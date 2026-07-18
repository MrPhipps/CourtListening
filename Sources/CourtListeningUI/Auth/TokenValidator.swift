import Foundation
import CourtListeningCore
import CourtListening

/// Validates an API token by exercising a cheap authenticated request.
///
/// Modeled as an enum with behavior cases (dependency-as-data) rather than a protocol mock:
/// `.live` hits the real API; `.alwaysValid` / `.failing` drive previews and tests.
public enum TokenValidator: Sendable {
    case live
    case alwaysValid
    case failing(CourtListenerError)

    public func validate(_ token: APIToken) async -> Result<Void, CourtListenerError> {
        switch self {
        case .live:
            // Reuse the shell's validated networking + error mapping (401 -> .unauthorized).
            let runner = CourtListenerRunner(token: token)
            await runner.handle(message: .listCourts(page: 1))
            if let error = await runner.model.lastError { return .failure(error) }
            return .success(())
        case .alwaysValid:
            return .success(())
        case .failing(let error):
            return .failure(error)
        }
    }
}
