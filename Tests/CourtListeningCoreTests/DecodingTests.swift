import XCTest
@testable import CourtListeningCore

final class DecodingTests: XCTestCase {

    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = makeDecoder()
    }

    // MARK: - courts-list.json

    func testCourtsListDecodesPaginationCount() throws {
        let data = try fixture("courts-list")
        let response = try decoder.decode(PaginatedResponse<Court>.self, from: data)
        guard case .total(let n) = response.count else {
            XCTFail("Expected .total count for page-based endpoint, got \(response.count)")
            return
        }
        XCTAssertEqual(n, 3359)
    }

    func testCourtsListDecodesResults() throws {
        let data = try fixture("courts-list")
        let response = try decoder.decode(PaginatedResponse<Court>.self, from: data)
        XCTAssertFalse(response.results.isEmpty)
    }

    func testCourtsListFirstResultIsSCOTUS() throws {
        let data = try fixture("courts-list")
        let response = try decoder.decode(PaginatedResponse<Court>.self, from: data)
        let first = try XCTUnwrap(response.results.first)
        XCTAssertEqual(first.id, try CourtID("scotus"))
    }

    func testCourtsListHasNextPage() throws {
        let data = try fixture("courts-list")
        let response = try decoder.decode(PaginatedResponse<Court>.self, from: data)
        XCTAssertNotNil(response.next)
        XCTAssertNil(response.previous)
    }

    // MARK: - court-scotus.json

    func testSCOTUSDecodes() throws {
        let data = try fixture("court-scotus")
        let court = try decoder.decode(Court.self, from: data)
        XCTAssertEqual(court.id, try CourtID("scotus"))
    }

    func testSCOTUSJurisdictionIsFederal() throws {
        let data = try fixture("court-scotus")
        let court = try decoder.decode(Court.self, from: data)
        XCTAssertEqual(court.jurisdiction, .federal)
    }

    func testSCOTUSShortName() throws {
        let data = try fixture("court-scotus")
        let court = try decoder.decode(Court.self, from: data)
        XCTAssertEqual(court.shortName, "Supreme Court")
    }

    func testSCOTUSFullName() throws {
        let data = try fixture("court-scotus")
        let court = try decoder.decode(Court.self, from: data)
        XCTAssertEqual(court.fullName, "Supreme Court of the United States")
    }

    func testSCOTUSCitationString() throws {
        let data = try fixture("court-scotus")
        let court = try decoder.decode(Court.self, from: data)
        XCTAssertEqual(court.citationString, "SCOTUS")
    }

    func testSCOTUSInUse() throws {
        let data = try fixture("court-scotus")
        let court = try decoder.decode(Court.self, from: data)
        XCTAssertTrue(court.inUse)
    }

    func testSCOTUSStartDate() throws {
        let data = try fixture("court-scotus")
        let court = try decoder.decode(Court.self, from: data)
        XCTAssertEqual(court.startDate, "1789-09-24")
    }

    func testSCOTUSEndDateIsNil() throws {
        let data = try fixture("court-scotus")
        let court = try decoder.decode(Court.self, from: data)
        XCTAssertNil(court.endDate)
    }

    // MARK: - people-list.json (cursor-based pagination)

    func testPeopleListCountIsDeferred() throws {
        let data = try fixture("people-list")
        let response = try decoder.decode(PaginatedResponse<Person>.self, from: data)
        guard case .deferred = response.count else {
            XCTFail("Expected .deferred count for cursor-based endpoint, got \(response.count)")
            return
        }
    }

    func testPeopleListHasCursorInNextURL() throws {
        let data = try fixture("people-list")
        let response = try decoder.decode(PaginatedResponse<Person>.self, from: data)
        XCTAssertNotNil(response.nextCursor)
    }

    func testPeopleListDecodesResults() throws {
        let data = try fixture("people-list")
        let response = try decoder.decode(PaginatedResponse<Person>.self, from: data)
        XCTAssertFalse(response.results.isEmpty)
    }

    func testPeopleListFirstPersonGender() throws {
        let data = try fixture("people-list")
        let response = try decoder.decode(PaginatedResponse<Person>.self, from: data)
        let first = try XCTUnwrap(response.results.first)
        XCTAssertEqual(first.gender, .female)
    }

    func testPeopleListFirstPersonDateGranularity() throws {
        let data = try fixture("people-list")
        let response = try decoder.decode(PaginatedResponse<Person>.self, from: data)
        let first = try XCTUnwrap(response.results.first)
        XCTAssertEqual(first.dateOfBirthGranularity, .year)
    }

    // MARK: - court-unknown-jurisdiction.json (graceful degradation)

    func testUnknownJurisdictionDecodesWithoutCrash() throws {
        let data = try fixture("court-unknown-jurisdiction")
        let court = try decoder.decode(Court.self, from: data)
        XCTAssertEqual(court.jurisdiction, .unknown)
    }

    // MARK: - parties-list.json (real shape: no top-level `docket`)

    /// Regression guard: the live /parties/ response has NO top-level `docket` key
    /// (it lives under `party_types[]`). A required `docket: URL` field would throw
    /// `keyNotFound` here — every party decode would fail.
    func testPartiesListDecodesWithoutTopLevelDocket() throws {
        let data = try fixture("parties-list")
        let response = try decoder.decode(PaginatedResponse<Party>.self, from: data)
        XCTAssertEqual(response.results.count, 2)
        let first = try XCTUnwrap(response.results.first)
        XCTAssertEqual(first.id, try PartyID(4001))
        XCTAssertEqual(first.name, "United States of America")
    }

    func testPartiesListCountIsDeferred() throws {
        let data = try fixture("parties-list")
        let response = try decoder.decode(PaginatedResponse<Party>.self, from: data)
        guard case .deferred = response.count else {
            return XCTFail("parties is a cursor endpoint; count should be .deferred, got \(response.count)")
        }
    }

    // MARK: - Enum raw values (verified live via OPTIONS)

    /// Raw values are the API's `value` field, not the `display_name`. "Separate" and
    /// "Relating-to" previously used display_names and silently decoded as `.unknown`.
    func testPrecedentialStatusDecodesAPIValues() throws {
        let data = Data("[\"Published\",\"Separate\",\"Relating-to\",\"In-chambers\",\"Non-Precedential\"]".utf8)
        let statuses = try decoder.decode([PrecedentialStatus].self, from: data)
        XCTAssertEqual(statuses, [.published, .separateOpinion, .relatingTo, .inChambers, .unknown])
    }

    func testOpinionTypeDecodesTrialCourtAndRealMisspelling() throws {
        let data = Data("[\"100trialcourt\",\"015unamimous\",\"010combined\"]".utf8)
        let types = try decoder.decode([OpinionType].self, from: data)
        XCTAssertEqual(types, [.trialCourtDocument, .unanimous, .combined])
    }

    // MARK: - audio-list.json (oral arguments, real shape)

    func testAudioListDecodesWithTopLevelDocket() throws {
        let data = try fixture("audio-list")
        let response = try decoder.decode(PaginatedResponse<Audio>.self, from: data)
        XCTAssertEqual(response.results.count, 2)
        let first = try XCTUnwrap(response.results.first)
        XCTAssertEqual(first.id, try AudioID(105800))
        XCTAssertEqual(first.caseName, "In re Catron")
        XCTAssertEqual(first.duration, 569)
        XCTAssertEqual(first.docket.absoluteString, "https://www.courtlistener.com/api/rest/v4/dockets/73632039/")
        XCTAssertNotNil(first.downloadURL)
    }

    func testAudioListCountIsDeferredAndBlankDownloadIsNil() throws {
        let data = try fixture("audio-list")
        let response = try decoder.decode(PaginatedResponse<Audio>.self, from: data)
        guard case .deferred = response.count else {
            return XCTFail("audio is a cursor endpoint; count should be .deferred, got \(response.count)")
        }
        // Second record has download_url "" — must degrade to nil, not throw.
        let second = response.results[1]
        XCTAssertNil(second.downloadURL)
        XCTAssertEqual(second.caseNameShort, "")
    }
}

// MARK: - Helpers

private func fixture(_ name: String) throws -> Data {
    guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
        XCTFail("Missing fixture: \(name).json")
        throw FixtureError.missing(name)
    }
    return try Data(contentsOf: url)
}

private func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        let iso8601Full = ISO8601DateFormatter()
        iso8601Full.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Full.date(from: string) { return date }
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime]
        if let date = iso8601.date(from: string) { return date }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = fmt.date(from: string) { return date }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot parse date: \(string)")
    }
    return decoder
}

private enum FixtureError: Error {
    case missing(String)
}
