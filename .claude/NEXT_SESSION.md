# Handoff → next assistant (local machine, with Xcode + API token)

Written 2026-11-17 from a cloud session that **could not compile and could not
authenticate**. Everything below is split into *verified* and *unverified*. Trust the
split; it is the whole value of this document.

Read `AGENTS.md` first — it is the standing contract (product intent, architecture,
branch rules). This file is only the delta: what I confirmed, what I couldn't, and what
to build next.

> **Do not name `HANDOFF.md` or `AGENTS.md` as new untracked files.** `.gitignore` line 9
> still ignores `HANDOFF.md` at **any** depth. `AGENTS.md` was un-ignored on this branch.

---

## Branch & PR state — act on this first

| Item | State | Action |
|---|---|---|
| `main` @ `79f53f7` | **The only truth.** Content-wise a strict superset of *both* open PRs. | Base everything here. |
| **PR #1** (`claude/swift-package-playground-9zcrbx`) | Branched off the *initial commit*. Library only, no app. `main` already contains every fix in it — including a byte-identical blank-URL `Court` decoder fix written independently. | **Close it.** Merge nothing. |
| **PR #4** (`claude/courtlistening-swiftui-auth`, draft) | 247 lines **behind** `main` (predates the xcschemes and the Search tab). `git diff main..branch` is pure deletion. | **Close it.** Merging would revert `main`. |
| `claude/agents-md` | AGENTS.md + the `.gitignore` un-ignore. | Already cherry-picked here; close or ignore. |
| `claude/topics-search-and-player` (this branch) | AGENTS.md only. No feature code — I stopped rather than ship Swift I could not compile. | Build on it. |

There is **nothing to synthesize between the two branches.** `main` already is the
synthesis; the divergence was duplicated effort, not parallel value.

---

## Verified against the live API (2026-11-17)

Evidence: direct unauthenticated HTTPS calls from the cloud container.

| Fact | Evidence |
|---|---|
| `/v4/courts/` is **public**, no token | `HTTP 200`, `count: 3363` |
| `/v4/search/` **requires auth** | `HTTP 401 {"detail":"Authentication credentials were not provided."}` |
| `/v4/audio/` **requires auth** | `HTTP 401`, same body |
| `Court.pacer_court_id` exists, `Int?` | `ca1 → 1`, `ca9 → 9`, `scotus → null`, `afcca → null` |
| `Court.url` really is `""` sometimes | `usafctmilrev` → `"url": ""`. Confirms the empty-string-URL decoder rule. |
| `/courts/` is page-based with integer `count` | `count: 3363`, `next: ".../courts/?page=2"`, `previous: null` |
| `pacer_has_rss_feed`, `pacer_rss_entry_types` exist on Court | `ca2 → true, "orders, opinions"` |

Also verified by reading the repo:
- **No `AVKit` / `AVFoundation` / `MediaPlayer` import anywhere on `main`.** No `AVPlayer`,
  `AVAudioPlayer`, `AVQueuePlayer`, `MPNowPlaying*`, `MPRemoteCommand*` reference either.
  There is no player. `AudioRow`'s "Play" is a `Link` to Safari.
- `Endpoints.dockets(query:)` sends `/dockets/?search=` — `/dockets/` has no `search` param.
- `DocketSearchView` renders `store.model.dockets.values` sorted by `dateModified` — the whole
  cache, not a result set.

## NOT verified — do these first, you have the token and Xcode

1. **`swift build` / `swift test` on `main`.** Last known run was 90/91 and that was on the
   *abandoned* branch. Status on `main` is unknown. No Swift toolchain exists in the cloud
   container and `download.swift.org` is proxy-blocked, so this has never been checked.
2. **The `/v4/search/` response schema, per `type`.** This is the single biggest unknown and
   the reason I wrote no search code. The shape differs per `type` (`o`, `r`, `rd`, `oa`, `p`)
   and I could not read even one example. **Probe it before writing a decoder.**
3. **The oral-argument audio file host.** `Audio.localPathMP3` holds a relative path like
   `mp3/2026/07/16/in_re_catron_cl.mp3`. The host is *probably* `storage.courtlistener.com`,
   but that is a **guess I could not confirm** — `/audio/` returned 401. Confirm before
   building the player's fallback.
4. **Whether `Docket.pacer_case_id` is decoded.** `Court.pacer_court_id` is confirmed to exist
   in the API; I did not confirm the docket-side field or whether our `Docket` model decodes it.

Probe script to start from (needs your token in the `Authorization: Token <value>` header):
`/tmp` copy is gone — rewrite it; it just GETs `/v4/search/?q=&type=` and prints
`results[0]` field names and types for each type code.

---

## Build order

### 1. Oral-argument player — the central feature

The owner's words: *"Playing oral arguments, one of the central features of the application."*
Confirmed scope: **full in-app player** — scrubber, play/pause, speed, background audio,
Now Playing / lock screen, queue.

- New `CourtListeningUI` component owning an `AVPlayer`. It is shell state, not domain state:
  keep it out of `CourtListenerModel`, which must stay a pure `Sendable` value snapshot.
- Playback source: `Audio.downloadURL` when present, else the CourtListener-hosted file built
  from `localPathMP3` (**host unverified — see above**). Today the button vanishes when
  `downloadURL` is blank, which is common; the fallback is what makes playback actually work.
- iOS needs `AVAudioSession` `.playback` and `UIBackgroundModes: [audio]` in `App/project.yml`
  (`INFOPLIST_KEY_UIBackgroundModes`), plus `MPRemoteCommandCenter` + `MPNowPlayingInfoCenter`.
- `Audio.duration` is whole seconds; `AudioRow.durationLabel` already formats `m:ss`.

### 2. Top-level topics

The owner's words: *"some top level topics that cover a variety of noteworthy legal subjects
that people using the app for now, just me, are interested in."* Single user. Curated, not
user-managed. This is the app's front door alongside search.

Pure Core data — a `LegalTopic` value type (name, SF Symbol, query) plus a static curated
list. Zero API risk; build it even before search works. Starting set drawn from the owner's
stated interests (§1983, body cameras, depositions):

| Topic | Suggested `q` |
|---|---|
| §1983 Civil Rights | `"42 U.S.C. 1983" OR "section 1983"` |
| Police Body Cameras | `"body camera" OR "body-worn camera" OR bodycam` |
| Qualified Immunity | `"qualified immunity"` |
| Excessive Force | `"excessive force"` |
| Monell / Municipal Liability | `Monell OR "municipal liability"` |
| Depositions & Discovery | `deposition AND ("Rule 30" OR "discovery dispute")` |
| Fourth Amendment — Search & Seizure | `"Fourth Amendment" AND ("search and seizure" OR warrantless)` |
| First Amendment Retaliation | `"First Amendment" AND retaliation` |
| Brady / Officer Credibility | `Brady AND ("police misconduct" OR "officer credibility")` |
| Eighth Amendment — Conditions | `"Eighth Amendment" AND ("deliberate indifference" OR "conditions of confinement")` |

CourtListener `q` supports quoted phrases and boolean `AND`/`OR`. **Verify each query returns
sensible hits before shipping the list** — these are untested.

### 3. Federated search — mind the quota

Confirmed scope: one query, results grouped by Opinions, Dockets/filings, Oral arguments, Judges.

**Critical constraint, easy to miss:** `/search/` takes one `type` per request, so federated
search is **4 requests per query** — and the free tier is **5 requests/minute**. A single
search nearly exhausts the per-minute budget, and a second one inside a minute will start
returning rate-limit errors. This will *look* like the broken search the owner already
rejected. Mitigate deliberately: run types sequentially and render each group as it lands,
let the user narrow types, cache aggressively, and surface `APIUsage` state in the UI before
firing. Decide this before writing the view.

Also: delete the `search=` param from `Endpoints.dockets(query:)` — `/dockets/` only *filters*
(`court`, `docket_number`, `case_name`); it is not a text search. And give search results their
own ordered result-set in the model rather than reading the whole `dockets` cache.

### 4. PACER + court-website cross-reference

The owner's words: *"cross-reference PACER as well as the court's websites of the various
jurisdictions across the country."*

Pure URL-building over already-decoded fields — low risk, high value, no new decoding.

- **Court website:** `Court.websiteURL` is already decoded. Resolve `Docket.courtID → Court →
  websiteURL`. Handle the `""` → `nil` case (confirmed to occur).
- **CourtListener/RECAP docket page:** `https://www.courtlistener.com/docket/<docket_id>/<slug>/`
- **PACER direct — UNVERIFIED PATTERNS, confirm before shipping:**
  - District: `https://ecf.<court_id>.uscourts.gov/cgi-bin/DktRpt.pl?<pacer_case_id>`
  - Appellate: `https://ecf.<court_id>.uscourts.gov/n/beam/servlet/TransportRoom`
  - Gate the link on `pacer_court_id != nil` — it is `null` for SCOTUS, military and state
    courts, which have no PACER presence at all.
- PACER requires its own paid login. Treat these as outbound links; do not attempt PACER auth.

### 5. Navigation rebuild (iOS/iPadOS first)

Current: 2 tabs for a model supporting opinions, people, parties, attorneys, audio. Plus
`UsageHUD` wedged between content and tab bar via `safeAreaInset(edge: .bottom)`, and "Sign
Out" as a red destructive button in the *Courts* toolbar.

Target shape: **Topics · Search · Listen · Library · Settings** (sign-out belongs in Settings).
Courts/judges become lookup tables reached from a result, not top-level destinations.

---

## Standing rules (full detail in `AGENTS.md`)

- Effects and errors are **typed, always** — domain enums, no `Error` existential, no
  `unknown(String)`, no raw primitives in command or error payloads.
- `update(message:model:)` is the only thing that mutates the model. Commands are data.
- No mocks — `CourtListenerTransport` cases `.stubbed` / `.failing` / `.spy` + JSON fixtures.
- No `Impl` / `Mgr` / `Svc` suffixes. No raw `String`/`Int` in a public API.
- Every PR ships a human QA script in the shape of `QA.md`.
- **No `Co-Authored-By` or session-link trailers in commits** — the owner declined them.
- Never report a build or test as passing from an environment without a Swift toolchain.

## Context worth knowing

The owner's stated reason this project stalled: *"This app is falling off the radar, mainly
due to my dissatisfaction with earlier versions."* The earlier dissatisfaction was concrete —
search that silently did nothing, a Play button that opened Safari or vanished, and two tabs
where a research tool was expected. Prefer one feature that genuinely works end to end over
four that demo. The player needs no new API schema, so it is the fastest route to something
that visibly works.
