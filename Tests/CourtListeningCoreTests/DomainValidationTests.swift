import XCTest
@testable import CourtListeningCore

final class DomainValidationTests: XCTestCase {

    // MARK: - CourtID

    func testCourtIDRejectsEmptyString() {
        XCTAssertThrowsError(try CourtID("")) { error in
            guard case CourtListenerError.invalidIdentifier = error else {
                XCTFail("Expected .invalidIdentifier, got \(error)")
                return
            }
        }
    }

    func testCourtIDRejectsWhitespaceOnly() {
        XCTAssertThrowsError(try CourtID("   ")) { error in
            guard case CourtListenerError.invalidIdentifier = error else {
                XCTFail("Expected .invalidIdentifier, got \(error)")
                return
            }
        }
    }

    func testCourtIDTrimsLeadingAndTrailingWhitespace() throws {
        let id = try CourtID("  scotus  ")
        XCTAssertEqual(id.rawValue, "scotus")
    }

    func testCourtIDAcceptsValidValue() throws {
        let id = try CourtID("scotus")
        XCTAssertEqual(id.rawValue, "scotus")
    }

    func testCourtIDEquality() throws {
        let a = try CourtID("ca9")
        let b = try CourtID("ca9")
        XCTAssertEqual(a, b)
    }

    func testCourtIDHashability() throws {
        let a = try CourtID("ca9")
        let b = try CourtID("ca9")
        var set = Set<CourtID>()
        set.insert(a)
        set.insert(b)
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - PersonID

    func testPersonIDRejectsZero() {
        XCTAssertThrowsError(try PersonID(0)) { error in
            guard case CourtListenerError.invalidIdentifier = error else {
                XCTFail("Expected .invalidIdentifier, got \(error)")
                return
            }
        }
    }

    func testPersonIDRejectsNegative() {
        XCTAssertThrowsError(try PersonID(-1)) { error in
            guard case CourtListenerError.invalidIdentifier = error else {
                XCTFail("Expected .invalidIdentifier, got \(error)")
                return
            }
        }
    }

    func testPersonIDAcceptsPositive() throws {
        let id = try PersonID(1781)
        XCTAssertEqual(id.rawValue, 1781)
    }

    // MARK: - DocketID

    func testDocketIDRejectsZero() {
        XCTAssertThrowsError(try DocketID(0)) { error in
            guard case CourtListenerError.invalidIdentifier = error else {
                XCTFail("Expected .invalidIdentifier, got \(error)")
                return
            }
        }
    }

    func testDocketIDAcceptsPositive() throws {
        let id = try DocketID(12345)
        XCTAssertEqual(id.rawValue, 12345)
    }

    // MARK: - APIToken

    func testAPITokenRejectsShortString() {
        XCTAssertThrowsError(try APIToken("short")) { error in
            XCTAssertEqual(error as? CourtListenerError, .invalidToken)
        }
    }

    func testAPITokenRejectsExactly9Characters() {
        XCTAssertThrowsError(try APIToken("123456789")) { error in
            XCTAssertEqual(error as? CourtListenerError, .invalidToken)
        }
    }

    func testAPITokenAccepts10OrMoreCharacters() throws {
        let token = try APIToken("1234567890")
        XCTAssertEqual(token.rawValue, "1234567890")
    }

    func testAPITokenAuthorizationHeader() throws {
        let token = try APIToken("myvalidtoken")
        XCTAssertEqual(token.authorizationHeaderValue, "Token myvalidtoken")
    }

    // MARK: - Other integer IDs

    func testClusterIDRejectsZero() {
        XCTAssertThrowsError(try ClusterID(0))
    }

    func testOpinionIDRejectsZero() {
        XCTAssertThrowsError(try OpinionID(0))
    }

    func testPartyIDRejectsZero() {
        XCTAssertThrowsError(try PartyID(0))
    }

    func testAttorneyIDRejectsZero() {
        XCTAssertThrowsError(try AttorneyID(0))
    }

    // MARK: - Cursor

    func testCursorRejectsEmptyString() {
        XCTAssertThrowsError(try Cursor("")) { error in
            guard case CourtListenerError.invalidIdentifier = error else {
                XCTFail("Expected .invalidIdentifier, got \(error)")
                return
            }
        }
    }

    func testCursorRejectsWhitespaceOnly() {
        XCTAssertThrowsError(try Cursor("   "))
    }

    func testCursorAcceptsBase64Value() throws {
        let cursor = try Cursor("cD0xNjIyMw==")
        XCTAssertEqual(cursor.rawValue, "cD0xNjIyMw==")
    }

    func testCursorTrimsWhitespace() throws {
        let cursor = try Cursor("  cD0xNjIyMw==  ")
        XCTAssertEqual(cursor.rawValue, "cD0xNjIyMw==")
    }

    func testCursorEquality() throws {
        let a = try Cursor("cD0xNjIyMw==")
        let b = try Cursor("cD0xNjIyMw==")
        XCTAssertEqual(a, b)
    }

    // MARK: - EmailAddress

    func testEmailAddressRejectsEmptyString() {
        XCTAssertThrowsError(try EmailAddress("")) { error in
            guard case CourtListenerError.invalidIdentifier = error else {
                XCTFail("Expected .invalidIdentifier, got \(error)")
                return
            }
        }
    }

    func testEmailAddressRejectsBlankString() {
        XCTAssertThrowsError(try EmailAddress("   "))
    }

    func testEmailAddressRejectsMissingAtSign() {
        XCTAssertThrowsError(try EmailAddress("nodomain.com"))
    }

    func testEmailAddressRejectsMissingDot() {
        XCTAssertThrowsError(try EmailAddress("user@nodot"))
    }

    func testEmailAddressAcceptsValidAddress() throws {
        let addr = try EmailAddress("judge@example.com")
        XCTAssertEqual(addr.rawValue, "judge@example.com")
    }

    func testEmailAddressTrimsWhitespace() throws {
        let addr = try EmailAddress("  judge@example.com  ")
        XCTAssertEqual(addr.rawValue, "judge@example.com")
    }

    // MARK: - PhoneNumber

    func testPhoneNumberRejectsEmptyString() {
        XCTAssertThrowsError(try PhoneNumber(""))
    }

    func testPhoneNumberRejectsTooFewDigits() {
        XCTAssertThrowsError(try PhoneNumber("123456")) { error in
            guard case CourtListenerError.invalidIdentifier = error else {
                XCTFail("Expected .invalidIdentifier, got \(error)")
                return
            }
        }
    }

    func testPhoneNumberAcceptsFormattedNumber() throws {
        let number = try PhoneNumber("+1-800-555-0199")
        XCTAssertTrue(number.rawValue.filter(\.isNumber).count >= 7)
    }

    func testPhoneNumberAcceptsSevenDigitMinimum() throws {
        let number = try PhoneNumber("555-0100")
        XCTAssertNotNil(number)
    }

    // MARK: - NonEmptyString

    func testNonEmptyStringRejectsEmptyString() {
        XCTAssertThrowsError(try NonEmptyString("")) { error in
            guard case CourtListenerError.invalidIdentifier = error else {
                XCTFail("Expected .invalidIdentifier, got \(error)")
                return
            }
        }
    }

    func testNonEmptyStringRejectsWhitespaceOnly() {
        XCTAssertThrowsError(try NonEmptyString("   "))
    }

    func testNonEmptyStringAcceptsNonBlankValue() throws {
        let s = try NonEmptyString("angel-kelley")
        XCTAssertEqual(s.rawValue, "angel-kelley")
    }
}
