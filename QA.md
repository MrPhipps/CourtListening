# QA & Validation Script

This document is the human QA checklist for PR #1. Follow each section in order.
Sections 1–3 require no network access. Section 4 requires a CourtListener API token.

---

## Prerequisites

| Requirement | Minimum version |
|---|---|
| Xcode | 15.0 |
| macOS | 13.0 Ventura |
| Swift | 5.9 |
| CourtListener API token | Free tier — get one at https://www.courtlistener.com/profile/api/ |

Clone the branch if you haven't already:

```
git clone https://github.com/MrPhipps/CourtListening.git
cd CourtListening
git checkout claude/swift-package-playground-9zcrbx
```

---

## Section 1: Automated Test Suite

Run all tests from the package root. No network connection is required — all tests
use JSON fixtures or pure in-memory data.

```
swift test
```

**Expected result:** all tests pass with output ending in:

```
Test Suite 'All tests' passed
```

**What each test file covers:**

| File | Coverage |
|---|---|
| `DomainValidationTests` | Validated primitives: `CourtID`, `PersonID`, `APIToken`, `Cursor`, `EmailAddress`, `PhoneNumber`, `NonEmptyString` |
| `DecodingTests` | JSON fixture → domain model decoding, including polymorphic `count` field and unknown jurisdiction graceful degradation |
| `UpdateTests` | Pure `update(message:model:)` state transitions, concurrent command isolation, API usage window tracking |
| `RunnerIntegrationTests` | `CourtListenerRunner` with `.stubbed` and `.failing` transports |
| `NetworkingBehaviorTests` | Authorization header, URL construction, cursor query parameter, HTTP method — all via `.spy` transport |

**Spot-check a few test names to confirm they ran:**

- `DomainValidationTests.testPhoneNumberNormalisesLeadingPlus` — `"+1-800-555-0199"` → `"+18005550199"`
- `DomainValidationTests.testPhoneNumberDoesNotKeepEmbeddedPlus` — embedded `+` is stripped
- `UpdateTests.testCommandFailedRemovesOnlyThatCommand` — concurrent commands survive each other's failures
- `UpdateTests.testUsageRecordedResetsMinuteWindowAfter60Seconds` — tumbling window resets
- `NetworkingBehaviorTests.testAuthorizationHeaderIsPresentOnEveryRequest` — `Authorization: Token <value>` on every request
- `RunnerIntegrationTests.testNetworkFailureDoesNotIncrementUsage` — network failures don't consume free-tier quota

---

## Section 2: Playground — Sections 1–2 (no token required)

1. Open `CourtListening.xcworkspace` in Xcode (not `Package.swift` directly — the workspace is required for the playground).
2. In the Project Navigator, expand `CourtListeningDemo.playground` and open `Contents.swift`.
3. Select **My Mac** as the run destination.
4. Execute the playground (**Editor → Run Playground** or ⌥⌘↩).

**Expected console output for Section 1 (Domain Types):**

```
✅ Empty CourtID rejected: CourtID cannot be blank
✅ Whitespace CourtID rejected: CourtID cannot be blank
✅ Zero PersonID rejected: PersonID must be positive
✅ Short token rejected
```

**Expected console output for Section 2 (Pure Functional Core):**

```
— After .fetchCourt —
Active commands: [fetchCourt(id: CourtID(rawValue: "scotus"))]
Commands to execute: [fetchCourt(id: CourtID(rawValue: "scotus"))]

— After .courtReceived —
Courts stored: 1
SCOTUS short name: Supreme Court
Active commands cleared: true

— After .commandFailed(.unauthorized, .fetchCourt) —
Last error: The operation couldn't be completed. (CourtListeningCore.CourtListenerError error 1.)
Active commands: 0 (only the failed command cleared)

— After .courtsPageReceived —
Courts stored: 2
Total count: 3359
Has more pages: true
```

The exact error description string for `lastError` may vary; what matters is it is non-nil and the active commands count is `0`.

---

## Section 3: Type Safety — Compiler Rejection Checks

These checks confirm that invalid states are unrepresentable at compile time, not just at runtime.

In a scratch Swift file (or in a playground), attempt each snippet and confirm Xcode shows the
described error **without running the code**:

### 3a. Raw string where CourtID is required

```swift
import CourtListeningCore
// Should not compile — CourtID is not a String:
let _ : CourtID = "scotus"
```

**Expected:** `cannot convert value of type 'String' to type 'CourtID'`

### 3b. Using a String as a Cursor

```swift
import CourtListeningCore
import CourtListening
// People/dockets/opinions are cursor-based; courts is page-based (Int).
let msg = CourtListenerMessage.listPeople(cursor: "cD0xNjIyMw==")
```

**Expected:** `cannot convert value of type 'String' to expected argument type 'Cursor?'`

### 3c. Using a raw Int as PersonID

```swift
import CourtListeningCore
let _ : PersonID = 1781
```

**Expected:** `cannot convert value of type 'Int' to type 'PersonID'`

### 3d. Validated types throw at runtime for invalid inputs

Add this to a playground and run:

```swift
import CourtListeningCore

// All four should print the "rejected" line:
do { try CourtID("") } catch { print("CourtID(\"\") rejected ✅") }
do { try PersonID(0) } catch { print("PersonID(0) rejected ✅") }
do { try APIToken("short") } catch { print("APIToken(\"short\") rejected ✅") }
do { try EmailAddress("notanemail") } catch { print("EmailAddress invalid ✅") }
do { try PhoneNumber("123") } catch { print("PhoneNumber too short ✅") }
do { try Cursor("") } catch { print("Cursor(\"\") rejected ✅") }
```

**Expected:** all six lines print with ✅.

---

## Section 4: Live API (token required)

Replace the placeholder token in `CourtListeningDemo.playground/Contents.swift` at line 106:

```swift
// Before:
let apiToken = try APIToken("REPLACE_ME_WITH_YOUR_TOKEN_AT_LEAST_TEN_CHARS")

// After (use your real token):
let apiToken = try APIToken("your_actual_courtlistener_token")
```

Re-run the playground. The playground runs top-to-bottom; Sections 3–5 execute automatically.

### Section 3 — List Courts

**Expected console output (values will vary by API response):**

```
— Fetching first page of courts from live API —
Courts fetched: <N>          ← should be > 0
Total courts in API: 3359
Has next page: true
SCOTUS full name: Supreme Court of the United States
SCOTUS jurisdiction: federal
SCOTUS founded: 1789-09-24
```

Validation checklist:
- [ ] `Courts fetched` is a positive integer
- [ ] `Total courts in API` is a positive integer
- [ ] `Has next page: true` (there are always multiple pages)
- [ ] SCOTUS fields match known values

### Section 4 — Pagination

**Expected:**

```
— Fetching page 2 —
Courts accumulated: <M>    ← should be greater than Section 3's court count
```

`/courts/` uses page-number pagination (`?page=N`), not cursors — the request must send
`?page=2`. (Cursor pagination applies to people/dockets/opinions/parties/attorneys.)

Validation checklist:
- [ ] `courtsPagination.nextPage` is a positive integer after page 1
- [ ] `Courts accumulated` is strictly greater than the count after page 1

### Section 5 — Fetch a Judge

**Expected (judge ID 1781 is Ruth Bader Ginsburg):**

```
— Fetching judge ID 1781 —
Judge: Ruth Bader Ginsburg
Gender: female
Has photo: true
Positions: <N>    ← should be > 0
```

Validation checklist:
- [ ] Name is non-empty
- [ ] Gender is a known value (not a raw code like `"f"`)
- [ ] Positions count is > 0

### Section 4 — 401 Error Path (without a valid token)

To validate the error path, revert to the placeholder token and re-run:

```swift
let apiToken = try APIToken("REPLACE_ME_WITH_YOUR_TOKEN_AT_LEAST_TEN_CHARS")
```

**Expected:** Sections 3–5 run but produce:

```
Courts fetched: 0
```

The playground should not crash. `liveModel.lastError` will be set to `.unauthorized`. This
demonstrates that invalid tokens produce a typed error, not a crash or unhandled exception.

---

## Section 5: API Usage Tracking (manual verification)

After running Sections 3–5 of the playground with a real token (three API calls total),
add the following lines at the end of the playground and re-run:

```swift
print("\n— API Usage —")
print("Requests this minute: \(judgeModel.apiUsage.requestsThisMinute)")
print("Requests this hour:   \(judgeModel.apiUsage.requestsThisHour)")
print("Requests this day:    \(judgeModel.apiUsage.requestsThisDay)")
print("Minute remaining:     \(judgeModel.apiUsage.minuteRemaining) / \(judgeModel.apiUsage.minuteLimit)")
print("At minute limit:      \(judgeModel.apiUsage.isAtMinuteLimit)")
```

**Expected (three calls made — listCourts page 1, listCourts page 2, fetchPerson):**

```
— API Usage —
Requests this minute: 3
Requests this hour:   3
Requests this day:    3
Minute remaining:     2 / 5
At minute limit:      false
```

Exact counts depend on how quickly you ran the playground relative to the rolling window;
the key invariant is `requestsThisMinute + minuteRemaining == apiUsage.minuteLimit`.
(Limits are per-session config now, defaulting to the documented base tier; your account's
actual tier — possibly higher during a promo — is enforced server-side via HTTP 429.)

---

## Pass Criteria

| Check | Status |
|---|---|
| `swift test` — all tests pass | |
| Playground Sections 1–2 — expected output matches | |
| Type safety — compiler rejects raw primitives | |
| Live API — SCOTUS name and jurisdiction correct | |
| Live API — pagination cursor non-empty and accumulates courts | |
| Live API — judge 1781 name non-empty and positions > 0 | |
| Error path — invalid token produces `.unauthorized`, no crash | |
| Usage tracking — `requests + remaining == minuteLimit` | |

---

## Appendix: Live API validation findings (2026-07)

The domain models were validated against the live CourtListener v4 API (authenticated,
including OPTIONS requests for enum `choices`). Findings below were **fixed** on branch
`claude/courtlistening-swiftui-auth`; each is covered by a regression test built from
real API JSON so it cannot silently recur.

| # | Severity | Finding | Fix |
|---|---|---|---|
| 1 | 🔴 High | `Party.docket` was a required top-level `URL`, but the live `/parties/` response has **no top-level `docket`** (it lives under `party_types[]`). Every party decode threw `keyNotFound` → `fetchParties` always failed. | Removed the absent top-level `docket`/`date_terminated`. Added `parties-list.json` real-shape fixture + `testPartiesListDecodesWithoutTopLevelDocket`. `party_types` to be modeled when docket-detail surfaces party roles. |
| 2 | 🔴 High | `/courts/` is **page-based** (`?page=N`, integer `count`) but the courts request sent `?cursor=`, which CL ignores → pagination never advanced past page 1. | Flipped the courts path from `Cursor?` to `page: Int?`. `testCourtsPaginationAppendsPageParameter` asserts `?page=` and rejects any cursor param. |
| 3 | 🟠 Med | `PrecedentialStatus` raw values used the API `display_name`, not the `value` field: `"Separate Opinion"`/`"Relating-to orders"` decoded as `.unknown`; `precedential`/`nonPrecedential` were dead cases. | Values corrected to `"Separate"`/`"Relating-to"`; dead cases removed. `testPrecedentialStatusDecodesAPIValues`. |
| 4 | 🟡 Low | `OpinionType` was missing the API value `"100trialcourt"` (Trial Court Document). | Added `trialCourtDocument`. `testOpinionTypeDecodesTrialCourtAndRealMisspelling`. |
| 5 | 🟡 Low | `APIUsage` hardcoded 5/50/125, but limits vary by tier/promotion and are enforced server-side (429 + `wait_until`). | Made limits injectable per-session config with base-tier defaults; preserved across `recording()`. |

**Validated correct (no change):** `ResponseCount` polymorphism (`.total` for courts vs
`.deferred` for cursor endpoints), cursor pagination on dockets/parties/attorneys/people/
opinions, the `Attorney` model, snake_case field mappings, `OpinionType`'s 12 other values
(including the API's real misspelling `015unamimous`), and `.unknown` enum fallbacks.

**Security note:** an API token was exposed in a working session while validating live
endpoints — reset it at `/profile/api-token/reset/`. Ensure any local `env.md` holding
tokens/cookies is git-ignored and never committed.
