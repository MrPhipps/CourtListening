# CourtListening

A Swift package that wraps the [CourtListener](https://www.courtlistener.com) REST API v4, built on the Functional Core / Imperative Shell architecture with algebraic data types. Designed for case research, legal document collection, and eventual on-device ML-driven analysis.

**Status:** Beta — personal use. API token required (free tier available).

---

## Requirements

| Platform | Minimum |
|---|---|
| macOS | 13.0 Ventura |
| iOS | 16.0 |
| Swift | 5.9 |
| Xcode | 15.0 |

---

## Installation

### Swift Package Manager

In `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/MrPhipps/CourtListening", branch: "main")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "CourtListening", package: "CourtListening")
        ]
    )
]
```

Two library products are available:

| Product | Use when |
|---|---|
| `CourtListeningCore` | You want the pure domain types, model, and `update()` function only — no networking |
| `CourtListening` | You want the full shell: `CourtListenerRunner`, async execution, live HTTP transport |

---

## Quick Start

### Get an API Token

Register at [courtlistener.com](https://www.courtlistener.com/sign-in/) and retrieve your token from [Profile → API](https://www.courtlistener.com/profile/api/). Free tier: 5 requests/min, 50/hr, 125/day.

### List Courts

```swift
import CourtListening
import CourtListeningCore

let token = try APIToken("your_token_here")
let runner = CourtListenerRunner(token: token)

await runner.handle(message: .listCourts(cursor: nil))

let model = await runner.model
for (id, court) in model.courts {
    print("\(id.rawValue): \(court.fullName)")
}
```

### Paginate

```swift
// Fetch page 1
await runner.handle(message: .listCourts(cursor: nil))

// Fetch page 2 using the cursor from the model
if let cursor = (await runner.model).courtsPagination.nextCursor {
    await runner.handle(message: .listCourts(cursor: cursor))
}
```

### Fetch a Person

```swift
let judgeID = try PersonID(1781)
await runner.handle(message: .fetchPerson(judgeID))

if let judge = (await runner.model).people[judgeID] {
    print(judge.fullName)
}
```

### Pure Core (no network)

The `CourtListeningCore` target runs entirely synchronously. Drive state transitions directly without a runner:

```swift
import CourtListeningCore

var model = CourtListenerModel.initial
let id = try CourtID("scotus")

let (newModel, commands) = update(message: .fetchCourt(id), model: model)
// commands == [.fetchCourt(id: id)]
// newModel.activeCommands contains .fetchCourt(id: id)
```

---

## Architecture

The package is structured as two targets following the **Functional Core / Imperative Shell** pattern:

```
CourtListeningCore  (pure — no URLSession, no async, no side effects)
└── Domain/
│   ├── Primitives/   Validated value types: CourtID, PersonID, APIToken,
│   │                 Cursor, EmailAddress, PhoneNumber, NonEmptyString, ResourceURL
│   ├── Models/       Codable domain structs: Court, Person, Docket, Opinion, …
│   └── Errors/       CourtListenerError, NetworkError (typed, exhaustive)
└── Core/
    ├── CourtListenerMessage   All inbound intents + response variants (sum type)
    ├── CourtListenerCommand   All outbound effects as data (sum type)
    ├── CourtListenerModel     Complete app state (Codable, Sendable)
    └── update()               Pure (Model, Message) → (Model, [Command])

CourtListening  (shell — imports Core, adds all async/networking)
└── Shell/
│   ├── CourtListenerRunner    Actor; drives the message loop
│   ├── CommandExecutor        Executes Commands, returns Messages
│   └── HTTPTransport          Protocol + CourtListenerTransport enum
└── Networking/
    ├── Endpoints              URL construction (pure)
    └── ResponseDecoder        JSON → domain types (pure)
```

### Key Properties

- **All state changes** flow through `update(message:model:) -> (CourtListenerModel, [CourtListenerCommand])`. Nothing else mutates the model.
- **All side effects** are `CourtListenerCommand` enum cases — data describing what to do, not imperative calls.
- **No mocks** — the transport is `CourtListenerTransport`, an enum with `.live`, `.stubbed`, `.failing`, and `.spy` cases. Tests use `.stubbed` with real captured JSON fixtures.
- **No primitives in the public API** — every identifier and validated value is a domain type with a throwing initializer.
- **Effects and errors are typed. Always.** — `CourtListenerError` and `NetworkError` are exhaustive enums; no `unknown(String)` catch-alls.

### Data Flow

```
User intent
    ↓
CourtListenerMessage   (e.g. .listCourts(cursor: nil))
    ↓
update()               Pure function; returns new model + commands
    ↓
[CourtListenerCommand] (e.g. [.listCourts(cursor: nil)])
    ↓
CourtListenerRunner    Actor; executes commands concurrently via TaskGroup
    ↓
CourtListenerMessage   (e.g. .courtsPageReceived(page))
    ↓
update()               Loop continues until commands list is empty
```

### API Usage Tracking

The model tracks usage against CourtListener's free-tier rate limits in `model.apiUsage`:

```swift
APIUsage.minuteLimit  // 5
APIUsage.hourLimit    // 50
APIUsage.dayLimit     // 125

model.apiUsage.minuteRemaining   // requests remaining in current minute window
model.apiUsage.isAtMinuteLimit   // true if quota exhausted
```

Usage is recorded automatically after every request that reaches the server (including 4xx/5xx responses). Network-level failures (no server contact) do not consume quota.

---

## Testing

```
swift test
```

No network access required — all tests use either pure in-memory data or JSON fixtures captured from the live API.

| Test file | What it covers |
|---|---|
| `DomainValidationTests` | Validated primitives: `CourtID`, `PersonID`, `APIToken`, `Cursor`, `EmailAddress`, `PhoneNumber`, `NonEmptyString` |
| `DecodingTests` | JSON fixture → domain model; polymorphic `count` field; unknown jurisdiction graceful degradation |
| `UpdateTests` | Pure `update()` state transitions; concurrent command isolation; API usage window math |
| `RunnerIntegrationTests` | `CourtListenerRunner` with `.stubbed` and `.failing` transports |
| `NetworkingBehaviorTests` | Authorization header; URL construction; cursor query parameter; HTTP method |

See `QA.md` for the human QA and live API validation script.

---

## Playground

Open `CourtListening.xcworkspace` in Xcode (not `Package.swift` directly). The playground walks through:

- **Section 1–2**: Domain types and pure `update()` — no token needed
- **Section 3**: Live court listing
- **Section 4**: Cursor-based pagination
- **Section 5**: Fetch a judge by ID

Replace the placeholder token at line 106 of `CourtListeningDemo.playground/Contents.swift` with your real token before running Sections 3–5.

---

## Roadmap

See `ROADMAP.md`. Near-term: user login and token management. Long-term: document collection, ML-driven information mining and analysis.
