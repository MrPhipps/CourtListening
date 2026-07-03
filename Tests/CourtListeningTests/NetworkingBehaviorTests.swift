import XCTest
@testable import CourtListening
import CourtListeningCore

final class NetworkingBehaviorTests: XCTestCase {

    // MARK: - Authorization header

    func testAuthorizationHeaderIsPresentOnEveryRequest() async throws {
        let fixtureData = try loadFixture("courts-list")
        let url = URL(string: "https://www.courtlistener.com/api/rest/v4/courts/")!
        let capture = RequestCapture()
        let token = try APIToken("mytesttoken99")
        let transport = CourtListenerTransport.spy(capture: capture, responses: [url: fixtureData])
        let runner = CourtListenerRunner(token: token, transport: transport)

        await runner.handle(message: .listCourts(cursor: nil))

        let requests = await capture.capturedRequests
        XCTAssertFalse(requests.isEmpty)
        for request in requests {
            let header = request.value(forHTTPHeaderField: "Authorization")
            XCTAssertEqual(header, "Token mytesttoken99", "Missing or wrong Authorization header on \(request.url?.absoluteString ?? "?")")
        }
    }

    // MARK: - Correct URLs

    func testListCourtsRequestsCorrectURL() async throws {
        let fixtureData = try loadFixture("courts-list")
        let expectedURL = URL(string: "https://www.courtlistener.com/api/rest/v4/courts/")!
        let capture = RequestCapture()
        let transport = CourtListenerTransport.spy(capture: capture, responses: [expectedURL: fixtureData])
        let runner = CourtListenerRunner(token: try APIToken("testtoken123"), transport: transport)

        await runner.handle(message: .listCourts(cursor: nil))

        let requests = await capture.capturedRequests
        XCTAssertEqual(requests.first?.url, expectedURL)
    }

    func testCursorPaginationAppendsQueryParameter() async throws {
        let cursor = try Cursor("cD0xNjIyMw==")
        let expectedURL = URL(string: "https://www.courtlistener.com/api/rest/v4/courts/?cursor=\(cursor.rawValue)")!
        let fixtureData = try loadFixture("courts-list")
        let capture = RequestCapture()
        let transport = CourtListenerTransport.spy(capture: capture, responses: [expectedURL: fixtureData])
        let runner = CourtListenerRunner(token: try APIToken("testtoken123"), transport: transport)

        await runner.handle(message: .listCourts(cursor: cursor))

        let requests = await capture.capturedRequests
        let requestURL = try XCTUnwrap(requests.first?.url)
        let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)
        let cursorItem = components?.queryItems?.first(where: { $0.name == "cursor" })
        XCTAssertEqual(cursorItem?.value, cursor.rawValue)
    }

    // MARK: - HTTP method

    func testAllRequestsUseGETMethod() async throws {
        let fixtureData = try loadFixture("courts-list")
        let url = URL(string: "https://www.courtlistener.com/api/rest/v4/courts/")!
        let capture = RequestCapture()
        let transport = CourtListenerTransport.spy(capture: capture, responses: [url: fixtureData])
        let runner = CourtListenerRunner(token: try APIToken("testtoken123"), transport: transport)

        await runner.handle(message: .listCourts(cursor: nil))

        let requests = await capture.capturedRequests
        for request in requests {
            XCTAssertEqual(request.httpMethod, "GET")
        }
    }

    // MARK: - 401 produces unauthorized error

    func testUnauthorizedResponseProducesCorrectError() async throws {
        let transport = CourtListenerTransport.failing(.unexpectedStatusCode(401))
        let runner = CourtListenerRunner(token: try APIToken("testtoken123"), transport: transport)

        await runner.handle(message: .listCourts(cursor: nil))

        let model = await runner.model
        XCTAssertNotNil(model.lastError)
    }
}

// MARK: - Helpers

private func loadFixture(_ name: String) throws -> Data {
    guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
        XCTFail("Missing fixture: \(name).json")
        throw FixtureError.missing(name)
    }
    return try Data(contentsOf: url)
}

private enum FixtureError: Error {
    case missing(String)
}
