import Foundation
import CourtListeningCore
import CourtListening

// ============================================================
// CourtListening Swift Package — Interactive Demonstration
//
// Open this playground via CourtListening.xcworkspace in Xcode.
// Sections 1–2 run entirely without a network connection.
// Sections 3–5 require a valid CourtListener API token at:
//   https://www.courtlistener.com/profile/api/
// ============================================================


// MARK: - Section 1: Domain Types & Validated Primitives

// The architecture enforces "no primitives in the public API."
// Every identifier is a validated domain type with a throwing initializer.

let scotusID = try CourtID("scotus")
let ca9ID = try CourtID("ca9")

// Blank or whitespace-only IDs are rejected at construction time.
do {
    let _ = try CourtID("")
} catch CourtListenerError.invalidIdentifier(let message) {
    print("✅ Empty CourtID rejected: \(message)")
}

do {
    let _ = try CourtID("   ")
} catch CourtListenerError.invalidIdentifier(let message) {
    print("✅ Whitespace CourtID rejected: \(message)")
}

// Integer identifiers enforce positive values.
let judgeID = try PersonID(1781)
do {
    let _ = try PersonID(0)
} catch CourtListenerError.invalidIdentifier(let message) {
    print("✅ Zero PersonID rejected: \(message)")
}

// APIToken requires at least 10 characters.
do {
    let _ = try APIToken("tooshort")
} catch CourtListenerError.invalidToken {
    print("✅ Short token rejected")
}


// MARK: - Section 2: Pure Functional Core (no network required)

// Build up state by passing messages through the pure update() function.
// This is entirely synchronous — no async, no network, no side effects.

var model = CourtListenerModel.initial

// Sending a fetchCourt message produces a command and marks the ID as loading.
let (afterFetch, fetchCommands) = update(message: .fetchCourt(scotusID), model: model)
print("\n— After .fetchCourt —")
print("Active commands: \(afterFetch.activeCommands)")
print("Commands to execute: \(fetchCommands)")

// Simulate the shell executing the command and returning a result.
let scotus = Court.TestData.supremeCourt
let (afterReceive, _) = update(message: .courtReceived(scotus), model: afterFetch)
print("\n— After .courtReceived —")
print("Courts stored: \(afterReceive.courts.count)")
print("SCOTUS short name: \(afterReceive.courts[scotusID]?.shortName ?? "not found")")
print("Active commands cleared: \(afterReceive.activeCommands.isEmpty)")

// Error states are explicit model transitions. commandFailed carries the specific
// command that failed, so update() removes only that command from activeCommands.
let failingCommand = CourtListenerCommand.fetchCourt(scotusID)
let (errorModel, _) = update(message: .commandFailed(.unauthorized, failingCommand), model: afterReceive)
print("\n— After .commandFailed(.unauthorized, .fetchCourt) —")
print("Last error: \(errorModel.lastError?.localizedDescription ?? "none")")
print("Active commands: \(errorModel.activeCommands.count) (only the failed command cleared)")

// Reset and demonstrate pagination flow.
let page = PaginatedResponse(
    count: ResponseCount.total(3359),
    next: URL(string: "https://www.courtlistener.com/api/rest/v4/courts/?page=2"),
    previous: nil,
    results: [Court.TestData.supremeCourt, Court.TestData.firstCircuit]
)
let (pagedModel, _) = update(message: .courtsPageReceived(page), model: .initial)
print("\n— After .courtsPageReceived —")
print("Courts stored: \(pagedModel.courts.count)")
print("Total count: \(pagedModel.courtsPagination.totalCount ?? 0)")
print("Has more pages: \(pagedModel.courtsPagination.hasMore)")


// MARK: - Section 3: Live API — List Courts
//
// Replace the placeholder below with your CourtListener API token.
// Get one at: https://www.courtlistener.com/profile/api/
//
// Note: the placeholder is long enough to pass APIToken validation (≥10 chars),
// so it won't throw here. If you run Sections 3–5 without replacing it, the
// runner will receive a 401 and model.lastError will be set to
// .commandFailed(.unauthorized, ...) — which actually demonstrates the
// error-handling path. Replace it to see live data.

let apiToken = try APIToken("REPLACE_ME_WITH_YOUR_TOKEN_AT_LEAST_TEN_CHARS")

let runner = CourtListenerRunner(token: apiToken)

print("\n— Fetching first page of courts from live API —")
await runner.handle(message: .listCourts(page: nil))

let liveModel = await runner.model
print("Courts fetched: \(liveModel.courts.count)")
print("Total courts in API: \(liveModel.courtsPagination.totalCount ?? 0)")
print("Has next page: \(liveModel.courtsPagination.hasMore)")

if let scotusLive = liveModel.courts[scotusID] {
    print("SCOTUS full name: \(scotusLive.fullName)")
    print("SCOTUS jurisdiction: \(scotusLive.jurisdiction)")
    print("SCOTUS founded: \(scotusLive.startDate ?? "unknown")")
}


// MARK: - Section 4: Pagination

// /courts/ is page-based: use the next page number from the previous fetch to load page 2.
if let nextPage = (await runner.model).courtsPagination.nextPage {
    print("\n— Fetching page \(nextPage) —")
    await runner.handle(message: .listCourts(page: nextPage))
    let afterPage2 = await runner.model
    print("Courts accumulated: \(afterPage2.courts.count)")
}


// MARK: - Section 5: Fetch a Judge by ID
//
// Judge ID 1781 is a well-known entry in the CourtListener database.

print("\n— Fetching judge ID 1781 —")
await runner.handle(message: .fetchPerson(judgeID))

let judgeModel = await runner.model
if let judge = judgeModel.people[judgeID] {
    print("Judge: \(judge.fullName)")
    print("Gender: \(judge.gender)")
    print("Has photo: \(judge.hasPhoto)")
    print("Positions: \(judge.positions.count)")
}
