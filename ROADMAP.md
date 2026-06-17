# Roadmap

Items are listed in rough priority order within each tier. Nothing here is committed — it reflects intent, not a schedule.

---

## Near-term

### User Login & Token Management

Currently the package requires callers to supply a pre-obtained `APIToken` manually. This item adds first-class authentication so the shell can acquire and manage the token on the caller's behalf.

**Scope:**

- `CourtListenerMessage.login(username: NonEmptyString, password: NonEmptyString)` — intent message
- `CourtListenerCommand.authenticate(username: NonEmptyString, password: NonEmptyString)` — effect
- `CourtListenerMessage.loginSucceeded(APIToken)` / `.loginFailed(CourtListenerError)` — response messages
- `CourtListenerError.invalidCredentials` — new typed error case for 400 from the token endpoint
- `CourtListenerModel.authState: AuthState` — sum type: `.unauthenticated`, `.authenticating`, `.authenticated(APIToken)`
- Secure storage: `KeychainTokenStore` actor (shell layer) — reads/writes token to Keychain; injected via protocol so tests use an in-memory variant
- `CourtListenerRunner` init variant that accepts a `TokenStore` and bootstraps the token at startup
- Logout: `CourtListenerMessage.logout` clears `authState` and wipes the stored token

**API endpoint:** `POST /api/rest/v4/api-token-auth/` — body `{"username": "…", "password": "…"}`, returns `{"token": "…"}`

**Architecture constraints:**
- Login request is a `Command`, not a direct API call — stays within the message loop
- Token is never stored in the `CourtListenerModel` in plaintext; `authState` holds the in-memory `APIToken` only for the session
- `KeychainTokenStore` lives in the shell target (`CourtListening`), not core
- All new error cases are typed; no `unknown(String)` fallback

---

## Medium-term

### Per-Resource Error Types

`CourtListenerError` is a single enum covering all domains. As the resource surface grows, callers have no way to distinguish a docket-specific decode failure from a court-specific one. Split into per-domain error enums (`CourtError`, `DocketError`, `PersonError`, …) that wrap a shared `NetworkError` base.

### Opinion Full-Text Retrieval

The current `Opinion` model carries metadata but not the opinion text itself (`plain_text`, `html`, `html_with_citations`). Add a `fetchOpinionText(OpinionID)` message/command pair that retrieves and caches the full text separately from the metadata model, avoiding large payloads in the main model dictionary.

### Search Across All Resource Types

The CourtListener `/api/rest/v4/search/` endpoint supports cross-resource queries (opinions, dockets, people, courts) with a rich filter set. Model a `SearchQuery` domain type and corresponding message/command/response cases.

---

## Long-term / Exploratory

### Webhook / Alert Integration

CourtListener offers email alerts for docket activity. Explore whether a local notification layer (delivered via `Command`) can mirror that, polling on a schedule and emitting `docketUpdated` messages when activity is detected.

### SwiftUI Binding Layer

A thin view-model layer (`@Observable` wrapper around `CourtListenerRunner`) that exposes `Binding`-compatible state for direct use in SwiftUI without manual `onChange` adaptors. Lives in a separate optional target so it doesn't pull UIKit/SwiftUI into the core library.
