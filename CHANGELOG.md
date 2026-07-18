# Changelog

All notable changes are documented here. Entries map to commits on `claude/swift-package-playground-9zcrbx`.

---

## [Unreleased] — PR #1

### Added

**Package foundation**
- `CourtListeningCore` target: pure domain types, model, `update()` function
- `CourtListening` target: `CourtListenerRunner` actor shell, `CourtListenerTransport` enum, `CommandExecutor`, `Endpoints`, `ResponseDecoder`
- `CourtListening.xcworkspace` + `CourtListeningDemo.playground` (5-section interactive walkthrough)

**Domain primitives** (all validated, throwing initializers)
- `CourtID`, `DocketID`, `ClusterID`, `OpinionID`, `PartyID`, `AttorneyID`, `PersonID` — string- and integer-backed identifiers
- `APIToken` — requires ≥ 10 characters
- `Cursor` — typed pagination cursor; blank/whitespace unrepresentable
- `EmailAddress` — requires `@` and `.`
- `PhoneNumber` — normalises to digits + leading `+`; minimum 7 digits
- `NonEmptyString` — rejects blank strings
- `ResourceURL<Resource>` — phantom-typed resource link

**Domain models** (Codable, Sendable)
- `Court`, `Docket`, `OpinionCluster`, `Opinion`, `Person`, `Position`, `Party`, `Attorney`
- `Jurisdiction`, `Gender`, `DateGranularity`, `OpinionType`, `PrecedentialStatus` — typed enums with `.unknown` graceful degradation for unrecognised API values
- `PaginatedResponse<T>` with `ResponseCount` — handles CourtListener's polymorphic `count` field (integer for page-based, URL for cursor-based pagination)
- `PaginationState` with typed `Cursor?` next cursor
- `APIUsage` — pure rolling-window tracking against free-tier rate limits (5/min, 50/hr, 125/day)
- `DocketQuery` with `NonEmptyString?` search fields

**Message / Command / Model**
- `CourtListenerMessage` — exhaustive sum type covering all intents and responses for courts, dockets, clusters, opinions, people, parties, attorneys, plus `commandFailed(CourtListenerError, CourtListenerCommand)` and `usageRecorded(at: Date)`
- `CourtListenerCommand` — exhaustive sum type for all effects; `Hashable` for use in `Set<CourtListenerCommand>`
- `CourtListenerModel` — full application state; `Codable`, `Sendable`
- `update(message:model:)` — pure, synchronous; exhaustive switch over all message cases

**Shell**
- `CourtListenerRunner` — `actor`; drives `withTaskGroup` for concurrent command execution; holds `APIToken` for auth header injection
- `CourtListenerTransport` — enum: `.live`, `.stubbed([URL: Data])`, `.failing(NetworkError)`, `.spy(RequestCapture, [URL: Data])`
- `RequestCapture` — actor that records authenticated `URLRequest`s for spy-transport tests
- `CommandExecutor` — `mapNetworkError` is exhaustive over all `NetworkError` cases; emits `.usageRecorded` after every request that reaches the server

**Errors**
- `CourtListenerError` — typed, exhaustive; cases: `invalidIdentifier`, `invalidToken`, `unauthorized`, `forbidden`, `notFound(URL?)`, `rateLimited(until: Date?)`, `serverError(statusCode: Int)`, `decodingFailed(String)`, `networkUnavailable`
- `NetworkError` — `invalidURL`, `requestFailed(URLError)`, `unexpectedStatusCode(Int)`, `noData`

**Tests**
- `DomainValidationTests` — 30+ tests covering all validated primitives
- `DecodingTests` — JSON fixture decoding including polymorphic count and unknown jurisdiction
- `UpdateTests` — pure `update()` tests including concurrent command isolation and API usage window math
- `RunnerIntegrationTests` — runner with `.stubbed` and `.failing` transports; usage tracking
- `NetworkingBehaviorTests` — auth header, URL construction, cursor pagination, 401 error path

**JSON fixtures** (real API captures)
- `courts-list.json`, `court-scotus.json`, `people-list.json`, `court-unknown-jurisdiction.json`

**Documentation**
- `QA.md` — human QA and live API validation script (5 sections, pass/fail checklist)
- `ROADMAP.md` — vision statement, near/medium/long-term items
- `README.md` — installation, quick start, architecture overview, test guide

### Fixed

- `PhoneNumber` normalisation: embedded `+` signs in non-leading position are now stripped correctly
- `Attorney` decoding: contact fields decoded once via constructor closure (eliminates double-decode)
- `Endpoints.opinions()`: missing `.rawValue` on `Cursor` (was a compile error for opinions pagination)
- Pagination cursor clearing: `courtsPageReceived` now clears all `listCourts` active commands regardless of cursor value, not only the `cursor: nil` variant
- `commandFailed(error, command)` replaces the old `failed(error)` — removes only the specific failing command from `activeCommands`, preserving concurrent commands
- `mapNetworkError` is now exhaustive; `unexpectedStatusCode` maps to `.serverError`, `noData` and `invalidURL` map to `.decodingFailed`
- Generic `catch` in `CommandExecutor.execute()` maps to `.decodingFailed` instead of the removed `.unknown`

### Removed

- `CourtListenerError.unknown(String)` — generic catch-all replaced by typed error cases throughout
- `CourtListenerMessage.failed(CourtListenerError)` — replaced by `commandFailed(CourtListenerError, CourtListenerCommand)`
- `CourtListenerTransport.live(token: APIToken)` — token moved to `CommandExecutor` so `.spy` records fully-authenticated requests
