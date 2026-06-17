import XCTest
@testable import CourtListening
import CourtListeningCore

final class RunnerIntegrationTests: XCTestCase {

    // MARK: - Stubbed transport: courts

    func testListCourtsPopulatesModel() async throws {
        let fixtureData = try loadFixture("courts-list")
        let url = URL(string: "https://www.courtlistener.com/api/rest/v4/courts/")!
        let transport = CourtListenerTransport.stubbed(responses: [url: fixtureData])
        let runner = CourtListenerRunner(token: try APIToken("testtoken123"), transport: transport)

        await runner.handle(message: .listCourts(cursor: nil))

        let model = await runner.model
        XCTAssertFalse(model.courts.isEmpty)
        XCTAssertNotNil(model.courts[try CourtID("scotus")])
    }

    func testListCourtsStoresCorrectCourtName() async throws {
        let fixtureData = try loadFixture("courts-list")
        let url = URL(string: "https://www.courtlistener.com/api/rest/v4/courts/")!
        let transport = CourtListenerTransport.stubbed(responses: [url: fixtureData])
        let runner = CourtListenerRunner(token: try APIToken("testtoken123"), transport: transport)

        await runner.handle(message: .listCourts(cursor: nil))

        let model = await runner.model
        let scotus = model.courts[try CourtID("scotus")]
        XCTAssertEqual(scotus?.shortName, "Supreme Court")
    }

    func testListCourtsUpdatesPagination() async throws {
        let fixtureData = try loadFixture("courts-list")
        let url = URL(string: "https://www.courtlistener.com/api/rest/v4/courts/")!
        let transport = CourtListenerTransport.stubbed(responses: [url: fixtureData])
        let runner = CourtListenerRunner(token: try APIToken("testtoken123"), transport: transport)

        await runner.handle(message: .listCourts(cursor: nil))

        let model = await runner.model
        XCTAssertEqual(model.courtsPagination.totalCount, 3359)
    }

    func testListCourtsActiveCommandsClearedAfterResponse() async throws {
        let fixtureData = try loadFixture("courts-list")
        let url = URL(string: "https://www.courtlistener.com/api/rest/v4/courts/")!
        let transport = CourtListenerTransport.stubbed(responses: [url: fixtureData])
        let runner = CourtListenerRunner(token: try APIToken("testtoken123"), transport: transport)

        await runner.handle(message: .listCourts(cursor: nil))

        let model = await runner.model
        XCTAssertTrue(model.activeCommands.isEmpty)
    }

    // MARK: - Failing transport

    func testUnauthorizedErrorSetsLastError() async throws {
        let transport = CourtListenerTransport.failing(.unexpectedStatusCode(401))
        let runner = CourtListenerRunner(token: try APIToken("testtoken123"), transport: transport)

        await runner.handle(message: .listCourts(cursor: nil))

        let model = await runner.model
        XCTAssertNotNil(model.lastError)
    }

    func testNetworkErrorClearsActiveCommands() async throws {
        let transport = CourtListenerTransport.failing(.requestFailed(URLError(.notConnectedToInternet)))
        let runner = CourtListenerRunner(token: try APIToken("testtoken123"), transport: transport)

        await runner.handle(message: .listCourts(cursor: nil))

        let model = await runner.model
        XCTAssertTrue(model.activeCommands.isEmpty)
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
