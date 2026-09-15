# Sa'n Tayo — Codebase Flow Guide

This is a working map of the repo so you can keep building alone. Two apps share one API contract.

---

## 1. Big picture

```
san_tayo/
├── frontend/     Flutter (mobile + web shell)
└── backend/      Laravel API (Sanctum tokens)
```

| Layer | Role |
|--------|------|
| **Flutter UI** | Screens, navigation, local session |
| **`api_request`** | Only HTTP entry point from the app |
| **Laravel routes** | URL → controller |
| **Controller** | Thin: take request, call repo, return JSON |
| **Repository** | Pass-through to Process |
| **Process** | Real business logic |
| **Models / `api` library** | DB and helpers |

**Rule of thumb:** UI never talks to DB. Controllers never contain business logic. New features follow the same stack.

---

## 2. Response contract (memorize this)

Every API response looks like:

```json
{ "code": 1, "title": "Success!", "msg": "...", "data": { ... } }
```

| Field | Meaning |
|--------|---------|
| `code == 1` | Success — proceed |
| `code == 0` | Logical failure (validation, bad password, forbidden) |
| `data` | Payload (token, account, list, etc.) |

Frontend wraps that in `ApiResponse` and adds:

| Extra field | Meaning |
|-------------|---------|
| `is_network_error == true` | Never reached a usable server response (offline, timeout, garbage body) |
| `is_network_error == false` | Server answered (even if `code == 0`) |

**Why it matters:** splash uses this so offline ≠ “token revoked.” Never treat `code == 0` alone as “log the user out.”

---

## 3. Frontend map

### Entry

`lib/main.dart`

- Phone → `SplashScreen`
- Web/desktop → `WebSkeleton` (mostly placeholder today)
- Theme: maroon primary `0xFF800000`, cream surface, Poppins + MoreSugar wordmark

### Folder roles

```
lib/core/
├── config/
│   ├── api_config.dart      ← base_url, client_key, timeout
│   └── api_endpoints.dart   ← path constants only
├── models/
│   └── api_response.dart
├── network/
│   ├── api_client.dart      ← api_request(), global auth_token
│   └── session.dart         ← secure storage + rolling 30-day window
├── mobile/
│   ├── splash_screen.dart   ← session restore + routing
│   ├── sign_in_up.dart      ← SignIn / SignUp / OTP (one file, 3 classes)
│   └── dashboard.dart       ← Placeholder (next real work)
└── web/
    ├── skeleton.dart
    ├── sign_in_up.dart
    └── dashboard.dart
```

### How every API call works

```dart
final res = await api_request('POST', ApiEndpoints.auth_login, body: params);
if (res.code == 1 && res.data != null) {
  // success
}
```

`api_client.dart` always sends:

- `X-Client-Key: ApiConfig.client_key`
- `Authorization: Bearer …` if `auth_token` is set

**Device networking gotcha:** `api_config.dart` hardcodes Android to `http://192.168.1.7:8000/api`. On a physical phone, that must be your PC’s LAN IP, and Laravel must listen on `0.0.0.0:8000`. Emulator usually uses `10.0.2.2`.

### Session (what persists login)

`session.dart` stores three keys in `flutter_secure_storage`:

1. `auth_token`
2. `last_seen_at` (ISO timestamp)
3. `account` (JSON cache)

| Function | When to use |
|----------|-------------|
| `save_session(token, account)` | After successful login / OTP verify |
| `load_session()` | Splash on open |
| `clear_session()` | Server rejected token, or future logout |
| `cache_account(...)` | After successful `/auth/me` |
| `session_is_expired(...)` | Pure 30-day check (tested in `test/session_test.dart`) |

Opening the app re-stamps `last_seen_at` → rolling 30 days. Sanctum token expiry stays `null` on purpose.

### Splash routing (source of truth for “am I logged in?”)

```
load_session()
  ├─ no live session → GET /health
  │     ├─ reachable   → SignInUp()
  │     └─ unreachable → SignInUp(is_offline: true)
  └─ has session → GET /auth/me
        ├─ code 1              → Dashboard (+ refresh cache)
        ├─ network error       → Dashboard (keep cached session)
        └─ server rejected     → clear_session() → SignInUp()
```

Pure helper: `decide_start(...)` in `splash_screen.dart` — extend tests if you change this matrix.

### Auth UI flow

All in `sign_in_up.dart`:

| Screen | Class | API |
|--------|-------|-----|
| Sign In | `SignInUp` | `POST /auth/login` |
| Sign Up | `SignUp` | `POST /auth/register` → push OTP |
| OTP | `OtpVerification` | `POST /auth/verify-otp`, `POST /auth/resend-otp` |

Shared end of happy path:

```dart
await save_session(data['token'], data['account']);
→ Dashboard (pushAndRemoveUntil)
```

Offline Sign In: fields disabled, toast, **Retry** re-probes `/health`.

---

## 4. Backend map

### Request pipeline

```
HTTP
 → routes/api.php
 → middleware (client.key → auth:sanctum → auth.level:…)
 → Controller (thin)
 → Repository (thin)
 → *Process (logic)
 → Model / api:: helpers / Cache / Mail
 → { code, title, msg, data }
```

Bindings live in `RepositoryServiceProvider.php`. Add a new domain there when you add a new repo.

### Middleware cheatsheet

| Alias | File | Checks |
|-------|------|--------|
| `client.key` | `VerifyClientKey` | Header `X-Client-Key` == `CLIENT_API_KEY` in `.env` |
| `auth:sanctum` | Laravel | Bearer token |
| `auth.level:user` / `business,admin` / `admin` | `EnsureAuthLevel` | Account’s `auth_level.level` |

`/health` is **outside** `client.key` so the app can probe reachability without a key.

### Auth levels

`AuthLevelModel`:

| Level | Meaning |
|-------|---------|
| `unverified` | Registered, OTP not done — **no token** |
| `user` | Normal student/user |
| `business` | Can manage listings |
| `admin` | Approve/reject |

Must exist in DB (`otp_unverified_manual.sql` if you only seeded admin/business/user).

### Auth Process behavior

| Endpoint | Result |
|----------|--------|
| `POST /auth/register` | Creates account as `unverified`, emails OTP, **no token**, `needs_verification: true` |
| `POST /auth/verify-otp` | Promotes to `user`, issues Sanctum token |
| `POST /auth/resend-otp` | New OTP + cooldown |
| `POST /auth/login` | Token if verified; if unverified → `code 0` + `needs_verification: true` (no token) |
| `GET /auth/me` | Current account (needs Bearer) |
| `POST /auth/logout` | Deletes current token |

OTP helpers live in `app/Libraries/api.php` (`otp_generate`, `otp_store`, `otp_check`, …). With `MAIL_MAILER=log`, codes appear in `storage/logs/laravel.log`.

### Important UUID gotcha

`account.id` is DB-generated (`DEFAULT (UUID())`). Eloquent with `$incrementing = false` does **not** reload that id after `create`. Register reloads by email if `id` is empty. Same pattern if you insert other UUID tables the same way. **Listing** ids are app-generated (PHP supplies UUID) because child rows need the FK in the same request.

### Domain already on the API (UI not wired yet)

Public (client key only):

- Lookups: barangays, food-types, listing-statuses
- Browse: `GET /listings`, `GET /listings/{id}` (approved + active)

Authenticated:

- Landmarks CRUD (business/admin for write)
- Listing CRUD + images/menu/food-types (soft delete + restore)
- Admin approve/reject
- `POST /account/upgrade-business` (user → business)

Logic: `ListingProcess`, `LandmarkProcess`, `AccountProcess`. Controllers/repos already exist — next frontend work is calling these from Dashboard.

---

## 5. Database mental model

```
auth_level ← account → listing → listing_img / listing_menu / listing_food_type
barangay → landmark → listing
food_type → listing_food_type
personal_access_tokens (Sanctum)
```

- Listing `active` = soft deactivate of the whole listing  
- Child rows use `deleted_at` for soft delete; scheduled event purges after 30 days  
- Only `listing.id` is app-supplied UUID; most others are DB `DEFAULT (UUID())`

---

## 6. Conventions (so your code matches)

### Backend PHP

- 2 spaces, `snake_case`, `==` not `===`
- Every Process method starts with `$rs = ['code' => 0, ...]` and always `return $rs`
- Validate early; Query Builder with `?` placeholders
- New function docblock: `@uses` / `@author: Kai Yaneza` / `Date:`

### Frontend Dart

- Same snake_case (lints for constant names are relaxed)
- Always `api_request` — don’t invent ad-hoc HTTP
- Add paths only in `api_endpoints.dart`
- Auth UI helpers stay in `sign_in_up.dart` until that file becomes unmanageable

---

## 7. How to add a feature without getting lost

**Example: “List approved food places on Dashboard”**

1. Confirm backend: `GET /listings` already exists → read `ListingController` → `ListingProcess`.
2. Add `listings = '/listings'` to `api_endpoints.dart` if missing.
3. In `dashboard.dart`, call `api_request('GET', ApiEndpoints.listings)`.
4. Check `res.code == 1`; render `res.data`.
5. If offline and you need data, decide: fail soft, or use a cache pattern like `cached_account`.

**Example: “Logout button”**

1. Call `POST /auth/logout` with current token.
2. Always `await clear_session()` afterward.
3. Navigate to `SignInUp()` with `pushAndRemoveUntil`.

**Example: “New protected endpoint”**

1. Process method → repo interface + impl → controller method  
2. Route under the right middleware group  
3. Bind nothing new if reusing an existing repo; new domain → register in `RepositoryServiceProvider`  
4. Frontend: endpoint constant + `api_request`

---

## 8. Local run checklist

1. Backend: `php artisan serve --host=0.0.0.0 --port=8000`
2. `.env` `CLIENT_API_KEY` **must match** `ApiConfig.client_key`
3. DB seeded + `unverified` auth level present + Sanctum tokens table
4. Frontend: set `base_url` for your device; `flutter run`
5. OTP: check `backend/storage/logs/laravel.log` if mail is log driver

Tests worth knowing:

- Frontend: `flutter test` → `test/session_test.dart`
- Backend: `tests/Unit/OtpTest.php`

---

## 9. What’s done vs what’s next

| Done | Not done / thin |
|------|------------------|
| Register → OTP → token | Dashboard UI (still `Placeholder`) |
| Login + persistent session | Logout UI |
| Offline splash / locked Sign In | Web auth parity |
| Client key + Sanctum + auth levels | Wiring listings/landmarks into Flutter |
| Listing/landmark APIs on backend | Password recovery |

---

## 10. Quick “where do I look?” index

| I want to… | Open |
|------------|------|
| Change maroon / fonts | `frontend/lib/main.dart` |
| Fix phone can’t reach API | `frontend/lib/core/config/api_config.dart` |
| Add an API path | `api_endpoints.dart` + `routes/api.php` |
| Change login/OTP UI | `frontend/lib/core/mobile/sign_in_up.dart` |
| Change boot / session gate | `splash_screen.dart` + `session.dart` |
| Change register/login rules | `AuthProcess.php` |
| Change OTP TTL/cooldown | `api.php` OTP helpers |
| Change who can create listings | `routes/api.php` `auth.level` + `EnsureAuthLevel` |
| Shared validation / response builders | `SharedFunction.php` |
| Account shape returned to app | `api::format_account` |

---

Keep this loop in your head: **screen → `api_request` → route → Process → `$rs` → `code`/`data` → UI**. If something fails, ask which layer broke: network (`is_network_error`), client key (403 Unauthorized client), auth (401/no user), auth level (403 not allowed), or Process (`code == 0` + `msg`).
