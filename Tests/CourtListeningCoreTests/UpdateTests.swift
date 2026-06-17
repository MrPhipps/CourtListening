import XCTest
@testable import CourtListeningCore

final class UpdateTests: XCTestCase {

    // MARK: - fetchCourt

    func testFetchCourtAddsCommandToActive() throws {
        let id = try CourtID("scotus")
        let (newModel, commands) = update(message: .fetchCourt(id), model: .initial)
        XCTAssertTrue(newModel.activeCommands.contains(.fetchCourt(id: id)))
        XCTAssertEqual(commands, [.fetchCourt(id: id)])
    }

    func testFetchCourtClearsLastError() throws {
        let id = try CourtID("scotus")
        let (newModel, _) = update(message: .fetchCourt(id), model: .TestVariants.withError)
        XCTAssertNil(newModel.lastError)
    }

    // MARK: - courtReceived

    func testCourtReceivedStoresInModel() throws {
        let court = Court.TestData.supremeCourt
        let (newModel, commands) = update(message: .courtReceived(court), model: .initial)
        XCTAssertEqual(newModel.courts[court.id], court)
        XCTAssertTrue(commands.isEmpty)
    }

    func testCourtReceivedRemovesFromActiveCommands() throws {
        let court = Court.TestData.supremeCourt
        let (newModel, _) = update(
            message: .courtReceived(court),
            model: .TestVariants.loadingCourts
        )
        XCTAssertFalse(newModel.activeCommands.contains(.fetchCourt(id: court.id)))
    }

    // MARK: - courtsPageReceived

    func testCourtsPageReceivedStoresAllResults() throws {
        let court1 = Court.TestData.supremeCourt
        let court2 = Court.TestData.firstCircuit
        let page = PaginatedResponse(
            count: .total(2),
            next: nil,
            previous: nil,
            results: [court1, court2]
        )
        let (newModel, commands) = update(message: .courtsPageReceived(page), model: .initial)
        XCTAssertEqual(newModel.courts[court1.id], court1)
        XCTAssertEqual(newModel.courts[court2.id], court2)
        XCTAssertTrue(commands.isEmpty)
    }

    func testCourtsPageReceivedUpdatesPageCount() throws {
        let court = Court.TestData.supremeCourt
        let page = PaginatedResponse(count: .total(3359), next: nil, previous: nil, results: [court])
        let (newModel, _) = update(message: .courtsPageReceived(page), model: .initial)
        XCTAssertEqual(newModel.courtsPagination.totalCount, 3359)
    }

    // MARK: - listCourts

    func testListCourtsAddsCommandToActive() {
        let (newModel, commands) = update(message: .listCourts(cursor: nil), model: .initial)
        XCTAssertTrue(newModel.activeCommands.contains(.listCourts(cursor: nil)))
        XCTAssertEqual(commands, [.listCourts(cursor: nil)])
    }

    func testListCourtsWithCursorPassesCursor() {
        let cursor = "abc123"
        let (newModel, commands) = update(message: .listCourts(cursor: cursor), model: .initial)
        XCTAssertTrue(newModel.activeCommands.contains(.listCourts(cursor: cursor)))
        XCTAssertEqual(commands, [.listCourts(cursor: cursor)])
    }

    // MARK: - fetchPerson

    func testFetchPersonAddsCommandToActive() throws {
        let id = try PersonID(1781)
        let (newModel, commands) = update(message: .fetchPerson(id), model: .initial)
        XCTAssertTrue(newModel.activeCommands.contains(.fetchPerson(id: id)))
        XCTAssertEqual(commands, [.fetchPerson(id: id)])
    }

    // MARK: - personReceived

    func testPersonReceivedStoresInModel() throws {
        let person = Person.TestData.angelKelley
        let (newModel, commands) = update(message: .personReceived(person), model: .initial)
        XCTAssertEqual(newModel.people[person.id], person)
        XCTAssertTrue(commands.isEmpty)
    }

    // MARK: - failed

    func testFailedSetsLastError() {
        let (newModel, commands) = update(message: .failed(.unauthorized), model: .initial)
        XCTAssertEqual(newModel.lastError, .unauthorized)
        XCTAssertTrue(commands.isEmpty)
    }

    func testFailedClearsActiveCommands() throws {
        let (newModel, _) = update(message: .failed(.networkUnavailable), model: .TestVariants.loadingCourts)
        XCTAssertTrue(newModel.activeCommands.isEmpty)
    }

    // MARK: - Chained transitions

    func testChainedFetchAndReceiveCourt() throws {
        let id = try CourtID("scotus")
        let court = Court.TestData.supremeCourt

        let (afterFetch, _) = update(message: .fetchCourt(id), model: .initial)
        XCTAssertTrue(afterFetch.activeCommands.contains(.fetchCourt(id: id)))

        let (afterReceive, _) = update(message: .courtReceived(court), model: afterFetch)
        XCTAssertEqual(afterReceive.courts[id], court)
        XCTAssertFalse(afterReceive.activeCommands.contains(.fetchCourt(id: id)))
    }

    // MARK: - partiesReceived

    func testPartiesReceivedStoresUnderDocketID() throws {
        let docketID = try DocketID(1001)
        let party = Party.TestData.petitioner
        let (newModel, commands) = update(
            message: .partiesReceived(docketID: docketID, [party]),
            model: .initial
        )
        XCTAssertEqual(newModel.parties[docketID], [party])
        XCTAssertTrue(commands.isEmpty)
    }

    // MARK: - API Usage tracking

    func testUsageRecordedIncrementsAllCounters() {
        let now = Date()
        let (newModel, commands) = update(message: .usageRecorded(at: now), model: .initial)
        XCTAssertEqual(newModel.apiUsage.requestsThisMinute, 1)
        XCTAssertEqual(newModel.apiUsage.requestsThisHour, 1)
        XCTAssertEqual(newModel.apiUsage.requestsThisDay, 1)
        XCTAssertTrue(commands.isEmpty)
    }

    func testUsageRecordedAccumulatesWithinWindow() {
        let base = Date()
        var model = CourtListenerModel.initial
        for i in 0..<3 {
            let t = base.addingTimeInterval(Double(i) * 10)
            (model, _) = update(message: .usageRecorded(at: t), model: model)
        }
        XCTAssertEqual(model.apiUsage.requestsThisMinute, 3)
        XCTAssertEqual(model.apiUsage.requestsThisHour, 3)
        XCTAssertEqual(model.apiUsage.requestsThisDay, 3)
    }

    func testUsageRecordedResetsMinuteWindowAfter60Seconds() {
        let base = Date()
        var model = CourtListenerModel.initial
        // Fill minute window
        for _ in 0..<5 {
            (model, _) = update(message: .usageRecorded(at: base), model: model)
        }
        XCTAssertEqual(model.apiUsage.requestsThisMinute, 5)
        // 61 seconds later — minute window resets, hour/day continue
        let later = base.addingTimeInterval(61)
        (model, _) = update(message: .usageRecorded(at: later), model: model)
        XCTAssertEqual(model.apiUsage.requestsThisMinute, 1, "Minute window should reset")
        XCTAssertEqual(model.apiUsage.requestsThisHour, 6, "Hour window should not reset")
    }

    func testUsageRemainingDecrements() {
        let now = Date()
        var model = CourtListenerModel.initial
        XCTAssertEqual(model.apiUsage.minuteRemaining, APIUsage.minuteLimit)
        for _ in 0..<3 {
            (model, _) = update(message: .usageRecorded(at: now), model: model)
        }
        XCTAssertEqual(model.apiUsage.minuteRemaining, APIUsage.minuteLimit - 3)
    }

    func testUsageAtLimitFlagsCorrectly() {
        let now = Date()
        var model = CourtListenerModel.initial
        for _ in 0..<APIUsage.minuteLimit {
            (model, _) = update(message: .usageRecorded(at: now), model: model)
        }
        XCTAssertTrue(model.apiUsage.isAtMinuteLimit)
        XCTAssertFalse(model.apiUsage.isAtHourLimit)
    }

    // MARK: - Pagination cursor removal

    func testListCourtsCommandClearedAfterPageReceived() throws {
        let cursor = "cD0yMDA="
        var model = CourtListenerModel.initial
        (model, _) = update(message: .listCourts(cursor: cursor), model: model)
        XCTAssertTrue(model.activeCommands.contains(.listCourts(cursor: cursor)))

        let page = PaginatedResponse<Court>(
            count: .total(3359),
            next: nil,
            previous: nil,
            results: [Court.TestData.supremeCourt]
        )
        (model, _) = update(message: .courtsPageReceived(page), model: model)
        let hasListCourts = model.activeCommands.contains { if case .listCourts = $0 { return true }; return false }
        XCTAssertFalse(hasListCourts, "All listCourts commands should be cleared on page receipt")
    }
}
