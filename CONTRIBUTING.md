# Contributing

This document describes the architecture rules, naming conventions, and process requirements for all changes to this package. Read it before opening a PR.

---

## Architecture: Functional Core / Imperative Shell

The package is split into two targets. The boundary between them is strict.

### `CourtListeningCore` — Pure

- Zero `import Foundation` beyond `Codable`, `Date`, and `URL`
- Zero `URLSession`, zero `async`/`await`, zero `Date()` calls, zero randomness
- All state changes flow through `update(message:model:) -> (CourtListenerModel, [CourtListenerCommand])`
- Nothing else mutates the model

### `CourtListening` — Shell

- All `async`/`await`, all networking, all `Date()` calls live here
- Executes `CourtListenerCommand` values; feeds resulting `CourtListenerMessage` values back into `update()`
- `CourtListenerRunner` is an `actor` — all mutable state is actor-isolated

### Data Flow

```
Message → update() → (Model, [Command]) → Shell executes Commands → new Messages → update() → …
```

Side effects are `Command` enum cases — **data describing what to do**, not imperative calls. The shell is responsible for the how.

---

## Non-Negotiable Rules

These were established as project mandates and are enforced on every PR.

### 1. Effects and errors are typed. Always.

Every `CourtListenerCommand` case carries typed associated values — no raw `String`, `Int`, or `Any` where a domain type is available. Every `CourtListenerError` case is exhaustive and specific. No generic catch-alls that convert errors to strings.

```swift
// ✅
case notFound(URL?)
case rateLimited(until: Date?)
case serverError(statusCode: Int)

// ❌
case unknown(String)
```

### 2. No primitives in the public API.

All public function parameters, return values, and model fields use validated domain types, not raw `String` or `Int`. Every domain type has a throwing initializer that validates at construction time.

```swift
// ✅
func fetchCourt(_ id: CourtID) async
var searchTerm: NonEmptyString?

// ❌
func fetchCourt(_ id: String) async
var searchTerm: String?
```

### 3. No `Impl` suffix — or any meta-suffix.

Type names describe what the type **is**, not its role as an implementation. Never use `Impl`, `Mgr`, `Svc`, `Helper`, or `Wrapper` as a suffix.

```swift
// ✅
enum CourtListenerTransport: HTTPTransport { ... }
enum AppDatabase: Database { ... }

// ❌
enum HTTPTransportImpl: HTTPTransport { ... }
enum DatabaseImpl: Database { ... }
```

### 4. No mocks — enum implementations only.

Tests use enum cases on the transport (`.stubbed`, `.failing`, `.spy`) backed by real captured JSON fixtures. Never introduce a mock class.

```swift
// ✅
let transport = CourtListenerTransport.stubbed(responses: [url: data])
let transport = CourtListenerTransport.failing(.requestFailed(URLError(.notConnectedToInternet)))

// ❌
class MockTransport: HTTPTransport { ... }
```

### 5. All shared types must conform to `Sendable`.

Every type that crosses actor boundaries — messages, commands, model, errors, domain primitives — must be `Sendable`. The Swift compiler enforces this; don't suppress the warning.

---

## Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Enum implementation of a protocol | Full descriptive noun, no suffix | `CourtListenerTransport`, `AppDatabase` |
| Domain primitive | The domain concept | `CourtID`, `EmailAddress`, `Cursor` |
| Error enum | Domain + `Error` | `CourtListenerError`, `NetworkError` |
| Message enum | Domain + `Message` | `CourtListenerMessage` |
| Command enum | Domain + `Command` | `CourtListenerCommand` |
| Actor shell | Domain + `Runner` | `CourtListenerRunner` |
| Test data namespace | `TestData` nested enum | `Court.TestData.supremeCourt` |
| Model variants for tests | `TestVariants` nested enum | `CourtListenerModel.TestVariants.withError` |

---

## Adding a New Resource

When adding support for a new CourtListener resource (e.g. `Tag`, `Citation`):

1. **Core: domain type** — add a validated ID type in `Sources/CourtListeningCore/Domain/Primitives/`
2. **Core: model struct** — add a `Codable, Sendable` struct in `Sources/CourtListeningCore/Domain/Models/` with explicit `CodingKeys`
3. **Core: message cases** — add intent and response cases to `CourtListenerMessage`
4. **Core: command cases** — add effect cases to `CourtListenerCommand`; update `Hashable` conformance
5. **Core: update()** — add `case` branches in `Update.swift`; exhaustive switch is compiler-enforced
6. **Core: model fields** — add storage dictionary to `CourtListenerModel`; update `initial`
7. **Shell: executor** — add `case` branch in `CommandExecutor.executeOrThrow()`
8. **Shell: endpoints** — add URL constructor in `Endpoints.swift`
9. **Tests: fixtures** — add a real captured JSON fixture in `Tests/CourtListeningCoreTests/Fixtures/`
10. **Tests: decoding** — add decoding tests in `DecodingTests.swift`
11. **Tests: update** — add `update()` tests in `UpdateTests.swift` using `TestData`
12. **Tests: integration** — add runner test in `RunnerIntegrationTests.swift` using `.stubbed` transport

---

## Pull Request Requirements

Every PR must include:

1. **Automated tests pass** — `swift test` with zero failures and zero warnings
2. **Human QA script** — a `QA.md` update (or new section) covering:
   - Steps a human reviewer can follow to validate the change
   - Expected console/UI output for each step
   - Pass/fail criteria
3. **Changelog entry** — add a section to `CHANGELOG.md` describing what was added, changed, or fixed
4. **No new primitives in the public API** — any new public parameter or field uses a domain type
5. **No new mock classes** — use enum transport cases and `TestData` namespaces

---

## Running Tests

```
swift test
```

No network access required. Fixture JSON is committed under `Tests/*/Fixtures/`.

For live API validation, follow the steps in `QA.md` (requires a CourtListener API token).
