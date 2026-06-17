# Session State — CourtListening

This document captures the full context of the development session for handoff.
Generated before context compaction. Resume from here after QA feedback.

---

## Project Identity

**Repo:** `MrPhipps/CourtListening` (GitHub)
**Active branch:** `claude/swift-package-playground-9zcrbx`
**Open PR:** #1 — awaiting human QA and code review on the user's laptop
**Base branch:** `main`

---

## What Was Built

A complete Swift Package wrapping the CourtListener REST API v4, following the
Functional Core / Imperative Shell (FCIS) architecture. The package is production-ready
pending QA sign-off.

### Two library targets

| Target | Contents |
|---|---|
| `CourtListeningCore` | Pure domain types, model, `update()` — zero networking, zero async |
| `CourtListening` | Shell: `CourtListenerRunner` actor, `CourtListenerTransport` enum, `CommandExecutor`, `Endpoints`, `ResponseDecoder` |

### Domain primitives (all validated, throwing inits)

`CourtID`, `DocketID`, `ClusterID`, `OpinionID`, `PartyID`, `AttorneyID`, `PersonID`,
`APIToken`, `Cursor`, `EmailAddress`, `PhoneNumber`, `NonEmptyString`, `ResourceURL<Resource>`

### Domain models

`Court`, `Docket`, `OpinionCluster`, `Opinion`, `Person`, `Position`, `Party`, `Attorney`,
`PaginatedResponse<T>`, `PaginationState`, `APIUsage`, `DocketQuery`

### Enums

`Jurisdiction`, `Gender`, `DateGranularity`, `OpinionType`, `PrecedentialStatus`,
`ResponseCount` (`.total(Int)` / `.deferred(URL)` — handles CL's polymorphic count field)

### Core layer

- `CourtListenerMessage` — exhaustive sum type (intents + responses + `commandFailed` + `usageRecorded`)
- `CourtListenerCommand` — exhaustive sum type (all effects as data); `Hashable` for `Set`
- `CourtListenerModel` — full app state; `Codable`, `Sendable`; includes `apiUsage: APIUsage`
- `update(message:model:)` — pure, synchronous, exhaustive

### Shell layer

- `CourtListenerRunner` — `actor`; `withTaskGroup` for concurrent command execution; holds `APIToken` for auth header injection
- `CourtListenerTransport` — `.live`, `.stubbed([URL: Data])`, `.failing(NetworkError)`, `.spy(RequestCapture, [URL: Data])`
- `CommandExecutor` — executes commands, emits `[CourtListenerMessage]` (result + `usageRecorded`); exhaustive error handling

### Errors

- `CourtListenerError` — 9 typed cases; NO `.unknown(String)` catch-all
- `NetworkError` — 4 typed cases; `mapNetworkError` is exhaustive

### Tests (all synchronous except shell tests)

- `DomainValidationTests` — 30+ tests
- `DecodingTests` — JSON fixture decoding
- `UpdateTests` — pure `update()`, concurrent command isolation, API usage windows
- `RunnerIntegrationTests` — `.stubbed` / `.failing` transport
- `NetworkingBehaviorTests` — `.spy` transport verifying auth header, URLs, cursor params

### Documentation

- `README.md` — full installation, quick start, architecture, test guide
- `QA.md` — human QA script (5 sections, pass/fail checklist)
- `ROADMAP.md` — vision + near/medium/long-term items
- `CHANGELOG.md` — all changes in this PR
- `CONTRIBUTING.md` — architecture rules, naming conventions, PR requirements
- `Swift_Architectural_Best_Practices.md` — uploaded best practices doc (in Claude uploads, not repo)

---

## Commit History (oldest → newest)

| Hash | Description |
|---|---|
| `29af2e8` | Initial commit |
| `a1a4e86` | Add CourtListening Swift Package with FCIS architecture |
| `12f9d7e` | Track API usage, fix rate limit handling, fix pagination cursor clearing |
| `ad8a99f` | Type all effects and errors — no raw primitives in commands or error context |
| `75f2e1f` | Fix PhoneNumber normalisation bug and Attorney double-decode |
| `add0c04` | Add QA.md — human validation script for PR #1 |
| `d80e1bb` | Fix best-practices violations found in pre-QA review |
| `961544a` | Add ROADMAP.md with login/token management as first near-term item |
| `f3d6b74` | Update ROADMAP with vision statement and ML/document items from original tweet |
| *(this)* | Add SDLC artifacts: README, CHANGELOG, CONTRIBUTING, SESSION_STATE |

---

## Key Architectural Decisions (non-negotiable mandates)

1. **Effects and errors are typed. Always.** — No `unknown(String)`, no raw primitives in commands or error context
2. **No primitives in the public API** — all public params/fields use validated domain types
3. **No `Impl` suffix** — type names describe what the type IS (`CourtListenerTransport`, not `HTTPTransportImpl`)
4. **No mocks** — enum transport cases (`.stubbed`, `.failing`, `.spy`) + JSON fixtures
5. **All shared types `Sendable`**
6. **Every PR includes a human QA script**
7. **All state changes via `update()`** — nothing else mutates the model

---

## Known Limitations / Out of Scope for This PR

- `Person.slug` is still `String` — planned upgrade to `NonEmptyString` (not blocking)
- `positions`/`educations` on `Person` are `[URL]` — phantom `ResourceURL<T>` migration planned
- No user authentication flow (login/token management) — first item in ROADMAP near-term tier
- `swift build` / `swift test` not verified in the remote environment (no Swift toolchain available) — must be validated locally during QA

---

## What QA Needs to Do

Follow `QA.md` completely. Critical paths:

1. `swift test` — all tests pass, zero warnings
2. Playground Sections 1–2 (no token) — verify exact console output
3. Type safety — compiler rejects raw primitives (Section 3 of QA.md)
4. Live API with real token — SCOTUS name/jurisdiction, pagination accumulation, judge 1781
5. Error path — placeholder token produces `.commandFailed(.unauthorized)`, no crash
6. Usage tracking — `requests + remaining == APIUsage.minuteLimit`

---

## If QA Finds Issues

Bring findings back to this session (or a new session with this file as context).
The branch is `claude/swift-package-playground-9zcrbx`. All fixes go on this branch.
Do not merge to `main` until QA passes.

---

## Roadmap State

| Tier | Item | Status |
|---|---|---|
| Near-term | User login & token management | Not started — spec in ROADMAP.md |
| Medium-term | Per-resource error types | Not started |
| Medium-term | Opinion full-text retrieval | Not started |
| Medium-term | Search across all resource types | Not started |
| Long-term | Document collection & local storage | Not started |
| Long-term | ML-driven information mining & analysis | Not started |
| Long-term | Webhook / alert integration | Not started |
| Long-term | SwiftUI binding layer | Not started |

---

## Files Modified This Session (full list)

```
Sources/CourtListeningCore/Domain/Primitives/
  APIToken.swift
  CourtID.swift
  Cursor.swift                        ← NEW
  EmailAddress.swift                  ← NEW
  IntegerIdentifiers.swift
  NonEmptyString.swift                ← NEW
  PhoneNumber.swift                   ← FIXED (normalisation bug)
  ResourceURL.swift                   ← NEW

Sources/CourtListeningCore/Domain/Models/
  APIUsage.swift                      ← NEW
  Attorney.swift                      ← FIXED (double-decode, typed contact fields)
  Court.swift
  DateGranularity.swift
  Docket.swift
  DocketQuery.swift                   ← UPDATED (NonEmptyString? fields)
  Gender.swift
  Jurisdiction.swift
  Opinion.swift
  OpinionCluster.swift
  OpinionType.swift
  PaginatedResponse.swift
  PaginationState.swift
  Party.swift
  Person.swift
  Position.swift
  ResponseCount.swift

Sources/CourtListeningCore/Domain/Errors/
  CourtListenerError.swift            ← UPDATED (removed .unknown, typed rateLimited/notFound)
  NetworkError.swift

Sources/CourtListeningCore/Core/
  CourtListenerCommand.swift          ← UPDATED (Cursor? everywhere)
  CourtListenerMessage.swift          ← UPDATED (commandFailed, usageRecorded, Cursor?)
  CourtListenerModel.swift            ← UPDATED (apiUsage, opinionsPagination)
  Update.swift                        ← UPDATED (all new message cases)

Sources/CourtListening/Shell/
  CourtListenerRunner.swift
  CommandExecutor.swift               ← UPDATED (exhaustive errors, usageRecorded)
  HTTPTransport.swift                 ← UPDATED (.live parameterless)

Sources/CourtListening/Networking/
  Endpoints.swift                     ← FIXED (cursor.rawValue in opinions)
  ResponseDecoder.swift

Tests/CourtListeningCoreTests/
  DomainValidationTests.swift
  DecodingTests.swift
  UpdateTests.swift

Tests/CourtListeningTests/
  RunnerIntegrationTests.swift
  NetworkingBehaviorTests.swift

CourtListeningDemo.playground/Contents.swift

README.md                             ← EXPANDED
CHANGELOG.md                         ← NEW
CONTRIBUTING.md                      ← NEW
QA.md                                ← NEW
ROADMAP.md                           ← NEW
.claude/SESSION_STATE.md             ← THIS FILE
```
