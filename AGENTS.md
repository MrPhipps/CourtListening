# AGENTS.md — CourtListening

A **search-first legal research app** (iOS/iPadOS, Swift 6) over the CourtListener REST API v4.
You search case law, triage results, open a case, read its documents, and listen to its oral
arguments. Everything else is in service of that.

---

## CRITICAL — read before changing anything

| # | Rule | Why it exists |
|---|---|---|
| 1 | **Search is the front door, not a tab afterthought.** This is a research workspace. A courts/judges list is a lookup table, never the destination. | Prior agents built a courts browser and bolted search on. That is not the product. |
| 2 | **`main` is the only truth. Rebase on `origin/main` before you write a line.** Never branch from the initial commit. | Two divergent histories were built in parallel; one agent re-fixed bugs the other had already fixed, byte for byte. |
| 3 | **Effects and errors are typed. Always.** Domain-modelled enums for every effect and every error. No `Error` existential, no `unknown(String)` catch-all, no raw primitives in command or error payloads. | Standing mandate from the project owner. Non-negotiable. |
| 4 | **Full-text search is `/v4/search/?q=&type=` — a *different endpoint* from the filter endpoints.** `/v4/dockets/?search=` silently drops your term. | This exact bug is why search appears to do nothing. |
| 5 | **Every PR ships a human QA script.** See `QA.md` for the established shape. | Standing mandate from the project owner. |

---

## Product intent

The owner's own statement of intent, which governs all scope decisions:

> "I want to code a wrapper for courts & CourtListener's APIs to research cases &
> collect/display documents easier. maybe some light machine learning model driven
> information mining & analysis, but last I checked their API documentation I don't think
> I'd sell it. Beta tests tho..."

Read that as three ranked jobs:

1. **Research cases** — federated search, triage, drill into a case. *This is the app.*
2. **Collect & display documents** — read and keep what you find.
3. **Light ML information mining** — later. Do not build toward it yet.

Not commercial. Personal tool plus beta testers. Prefer depth on job 1 over breadth.

**Decided product direction** (confirmed with the owner — do not re-litigate):

| Decision | Value |
|---|---|
| Front door | Search-first research workspace |
| Search scope | **Federated** — one query, results grouped by Opinions, Dockets/filings, Oral arguments, Judges |
| Audio | **Full in-app player** — scrubber, play/pause, speed, background audio, Now Playing, queue |
| Platform priority | **iOS / iPadOS.** macOS builds, but iOS is what gets judged |

---

## Branch discipline

- Work on a branch off **`origin/main`**. Push there; never push to `main` without explicit permission.
- `git fetch origin main && git rebase origin/main` before starting and before pushing.
- Before "fixing" anything, `git log origin/main -- <path>` and read the current file on `main`.
  A bug you remember may already be fixed there.
- **Do not add `Co-Authored-By` or session-link trailers to commits.** The owner has explicitly
  declined them.
- Abandoned: `claude/swift-package-playground-9zcrbx` — a library-only fork off the initial commit
  with no app in it. Do not merge it or build on it.

---

## Architecture — Functional Core / Imperative Shell

Four targets, strictly layered. Detailed rules live in `CONTRIBUTING.md`; this is the boundary map.

| Target | Contains | Hard rule |
|---|---|---|
| `CourtListeningCore` | Domain types, `CourtListenerMessage`, `CourtListenerCommand`, `CourtListenerModel`, `update()` | Pure and synchronous. No `URLSession`, no `async`, no side effects. |
| `CourtListening` | `CourtListenerRunner` (actor), `CourtListenerTransport`, `CommandExecutor`, `Endpoints`, `ResponseDecoder` | All I/O lives here and nowhere else. |
| `CourtListeningUI` | `CourtListenerStore` (`@MainActor @Observable`), `SessionStore`, Keychain, views, `Design` | Views read a snapshot and send messages. No networking in a view. |
| `App/` | `CourtListeningApp` (XcodeGen, `project.yml`) | Shell only. No logic. |

Data flow, in one line:

```
intent → update(message:model:) → (newModel, [Command]) → shell executes → response Message → update(...)
```

Rules that follow from it:
- **All** state change goes through `update()`. Nothing else mutates the model.
- Commands are **data**, never closures or actions.
- Every shared type is `Sendable`. `SWIFT_STRICT_CONCURRENCY: complete`.
- `CourtListenerModel` is a `Sendable` value snapshot. It never becomes an `@Observable` class;
  only the thin `CourtListenerStore` wrapper is observable.
- **No mocks.** Test via `CourtListenerTransport` cases — `.live`, `.stubbed`, `.failing`, `.spy` —
  plus JSON fixtures captured from the live API.
- **No `Impl` suffix.** Also no `Mgr`, `Svc`, `Helper`. Name what the type *is*.
- No raw `String`/`Int` in any public API. Use validated primitives (`CourtID`, `DocketID`,
  `NonEmptyString`, `Cursor`, `APIToken`, …), each with a throwing `init`.

---

## CourtListener API v4 — facts learned the hard way

Do not re-derive these. Each one has already cost a debugging cycle.

| Fact | Consequence for your code |
|---|---|
| **Search ≠ filter.** Full text is `/v4/search/?q=<term>&type=<o\|r\|oa\|p>`. The resource endpoints (`/dockets/`, `/opinions/`) only *filter* by field. | Federated search issues one `/search/` request per type. Never pass `search=` to `/dockets/`. |
| `/dockets/` filter param is **`court`**, not `court_id`. | A wrong param name is ignored silently, not rejected. |
| **Pagination is not uniform.** `/courts/` is page-based (`?page=N`) with an integer `count`. Cursor endpoints return `count` as a **URL string**. | Modelled as `ResponseCount.total(Int)` / `.deferred(URL)`. Keep both paths alive. |
| **URL-typed fields arrive as `""`.** `JSONDecoder` throws `dataCorrupted` on an empty string in a `URL` field — it does *not* yield `nil`. | Decode as `String?`, then `URL(string:)`, blank → `nil`. Already done in `Court.websiteURL` and `Audio.downloadURL`. Apply to every new URL field. |
| `Audio.download_url` is frequently blank; `local_path_mp3` holds a CourtListener-relative path. | The player must fall back to the CourtListener-hosted file. **Verify the storage host against the live API before relying on it** — it is not yet confirmed in this repo. |
| Free tier: **5 req/min, 50/hr, 125/day**. | `APIUsage` tracks tumbling windows; `usageRecorded(at:)` is emitted after every request that reached the server. Fan-out fetches burn quota fast — batch deliberately. |
| Auth is `Authorization: Token <value>`, injected in `CommandExecutor.fetch`, not in the transport. | Keeps `.spy` recording fully-authenticated requests. Do not move it into `.live`. |

---

## Known broken — do not report these as working

Verified by reading `origin/main` at `79f53f7`. Fix or leave alone, but do not claim done.

| Area | Actual state |
|---|---|
| **Audio playback** | **No player exists.** No `AVKit`/`AVFoundation` import anywhere in the repo. `AudioRow`'s "Play" is a `Link` that ejects to Safari, and it is gated on `downloadURL`, which is often blank — so the button frequently isn't rendered at all. `local_path_mp3` is decoded and never used. |
| **Docket search** | Hits `/v4/dockets/?search=` — wrong endpoint, term discarded. |
| **Search results** | `DocketSearchView` renders `store.model.dockets.values` sorted by `dateModified` — the entire accumulated cache, not a result set. No relevance order, no result pagination, results blend with previously-viewed dockets. |
| **Navigation** | Two tabs (Courts, Search) for a model that already supports opinions, people, parties, attorneys and audio. No surface for most of it. |
| **`UsageHUD`** | Mounted as `safeAreaInset(edge: .bottom)` on the `TabView`, wedging it between content and the tab bar. |
| **Sign out** | A destructive toolbar button in the *Courts* navigation bar. Belongs on an account/settings surface. |
| **Test suite** | Last known run was **90/91** on the abandoned library branch. Status on `main` is **unverified** — no Swift toolchain in the cloud container; `swift test` must be run on the owner's machine. |

---

## UI rules (iOS/iPadOS first)

- Target iOS 26 / macOS 26, one universal target, `supportedDestinations: [iOS, macOS]`.
- Branch **layout** per platform if needed; do not fork app logic with `#if os`.
- Views are driven by the observed `CourtListenerModel` snapshot. No view owns domain state.
- Styling goes through `Design` (`Design.Spacing`, `Design.Font`, `Design.Color`). No literals.
- Every view ships a `#Preview` backed by `TestData` / `CourtListenerStore.preview(_:)` — previews
  must never touch the network.

---

## Commands

```bash
swift build                 # library targets
swift test                  # full suite — run on a machine with a Swift toolchain
cd App && xcodegen generate # regenerate the app project from project.yml
```

Cloud containers have **no Swift toolchain**. Never report a build or test as passing from one —
say it is unverified and ask for a local run.

---

## PR requirements

1. A human QA script, in the shape of `QA.md` — numbered steps, expected output, pass/fail boxes.
2. `swift build` and `swift test` clean, **verified on a real toolchain**, or explicitly flagged unverified.
3. No new raw primitives in a public API; no new untyped errors.
4. Update `CHANGELOG.md`.
5. Do not open a PR unless asked.

---

## Reference

| Document | Holds |
|---|---|
| `CONTRIBUTING.md` | Full architecture rules, naming tables, how to add a resource |
| `ROADMAP.md` | Vision and tiered backlog |
| `QA.md` | The human QA script shape |
| `.claude/SESSION_STATE.md` | Historical session handoff — **predates the app; treat as archive, not current state** |
