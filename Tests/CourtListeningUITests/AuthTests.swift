import XCTest
@testable import CourtListeningUI
import CourtListeningCore

final class AuthTests: XCTestCase {

    // MARK: - TokenValidator

    func testAlwaysValidValidatorSucceeds() async throws {
        let token = try APIToken("valid_token_1234")
        let result = await TokenValidator.alwaysValid.validate(token)
        guard case .success = result else { return XCTFail("expected success") }
    }

    func testFailingValidatorReturnsError() async throws {
        let token = try APIToken("valid_token_1234")
        let result = await TokenValidator.failing(.unauthorized).validate(token)
        guard case .failure(.unauthorized) = result else { return XCTFail("expected .unauthorized") }
    }

    // MARK: - SessionStore sign-in

    @MainActor
    func testSignInWithValidTokenReachesSignedIn() async throws {
        let session = SessionStore(validator: .alwaysValid)
        await session.signInAwaiting(rawToken: "valid_token_1234")
        guard case .signedIn = session.phase else { return XCTFail("expected .signedIn, got \(session.phase)") }
        XCTAssertNil(session.authError)
    }

    @MainActor
    func testSignInWithShortTokenIsRejectedBeforeValidation() async {
        let session = SessionStore(validator: .alwaysValid)
        await session.signInAwaiting(rawToken: "short")
        guard case .signedOut = session.phase else { return XCTFail("expected .signedOut") }
        XCTAssertNotNil(session.authError, "invalid token should surface an auth error")
    }

    @MainActor
    func testSignInWithRejectedTokenSurfacesError() async {
        let session = SessionStore(validator: .failing(.unauthorized))
        await session.signInAwaiting(rawToken: "valid_token_1234")
        guard case .signedOut = session.phase else { return XCTFail("expected .signedOut") }
        XCTAssertEqual(session.authError, CourtListenerError.unauthorized.errorDescription)
    }
}
