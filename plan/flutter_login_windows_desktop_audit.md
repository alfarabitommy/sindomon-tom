# Login Windows Desktop Failure — Diagnostic Audit & Fix

> Date: 2026-08-15 · Branch: `dev` · Scope: login flow only
> Symptom: login works in Postman & Flutter Web, fails in Windows Desktop (Debug/Release)
> with Snackbar **"Kredensial tidak valid. Silahkan periksa kembali."**

---

## 0. TL;DR Verdict

The Snackbar text is **hardcoded in three fallback branches** of `lib/widget/login_card.dart`
and is **never** taken from the backend response. The catch-all exception handler labels
*every* error — including network failures that never reach the backend — as "invalid
credentials". On Windows Release builds `debugPrint` is a no-op, so the real exception
(`SocketException`, timeout, TLS handshake, etc.) is printed nowhere: **that is why the
failure is "silent"**.

Two real client bugs were found and fixed (untrimmed credentials in the payload; no HTTP
timeout anywhere), plus the error handling was rebuilt so the true failure reason is now
visible and actionable. There is **no `.env`/dotenv** in this project — the base URL is a
compile-time constant, so hypothesis 1 is dismissed (with a `--dart-define` override added
as the canonical alternative).

---

## 1. Hypothesis-by-Hypothesis Findings

| # | Hypothesis | Verdict | Evidence |
|---|---|---|---|
| 1 | `.env` base URL misconfigured on Windows | **DISMISSED** (mitigation added) | No `.env` file or `flutter_dotenv` anywhere. `lib/config/api_config.dart` is a single `const String apiBaseUrl = "https://sindomon.cml-indonesia.com";` — identical compile-time value on every platform. A `String.fromEnvironment("API_BASE_URL", ...)` override was added so future builds can vary the URL via `--dart-define` without code edits. |
| 2 | Credentials not `.trim()`ed before sending | **CONFIRMED — real bug** | `login_card.dart` trimmed only for the *emptiness* checks; the payload sent raw `usernameController.text` / `passwordController.text`. Windows copy-paste with trailing space/newline → backend receives `"username "` → 401 → generic snackbar. **Fixed:** trim once, use trimmed values for both validation and payload. |
| 3 | `Content-Type: application/json` missing on dart:io | **DISMISSED** | Header was explicitly set at `login_card.dart:130` — `package:http` sends it identically on `BrowserClient` (web) and `IOClient` (dart:io). Hardened anyway: added `Accept` and a pinned `User-Agent` (`SINDOMON-Client/1.0`, kIsWeb-guarded since browsers forbid UA override). The default dart:io UA `Dart/3.x (dart:io)` was live-probed against the backend and accepted (see §3). |
| 4 | "Kredensial tidak valid" hardcoded instead of parsed | **CONFIRMED — root cause of the misleading UI** | The string appears in **three** places: the empty-fields branch, the generic `else` for any non-200/403 status, and the catch-all exception handler. The backend's real message (live-probed: `{"status":401,"message":"Username atau password salah.","data":{}}`) was discarded. **Fixed:** 401/400/422 now display the backend `message`; network exceptions show distinct connectivity/TLS/timeout texts; 403 keeps the "Akses Diblokir" device-verification dialog. |

---

## 2. Why It Works on Web/Postman but Fails on Windows Desktop

The request-building code is identical across platforms, so the difference must be in the
**transport layer** (browser/XHR vs `dart:io`), and every transport failure was being
misreported as "Kredensial tidak valid" by the catch-all branch. Candidate mechanisms,
ranked by likelihood on a Windows/corporate network:

1. **System proxy not honored.** `dart:io`'s `HttpClient` does **not** read the Windows
   WinINET proxy settings (browsers and Postman do). On proxied corporate/government
   networks the desktop app cannot reach the server at all → `SocketException`/hang →
   masked snackbar. dart:io only honors `http_proxy`/`https_proxy`/`no_proxy` environment
   variables (`findProxyFromEnvironment`).
2. **Dual-stack IPv4/IPv6 asymmetry, no Happy Eyeballs.** The host resolves to both
   `A 203.175.9.114` and `AAAA 2001:df1:7800:2::7:c2a6`. Live probe from the audit
   environment: **IPv4 times out (HTTP 000), IPv6 answers HTTP 200.** Chrome and Postman
   race both families and fall back in milliseconds; `dart:io` tries addresses
   sequentially and a blackholed first attempt can hang for the full OS connect timeout
   (2+ minutes on Windows). With **no `.timeout()` anywhere in the app**, the HUD could
   block indefinitely — and after the OS gave up, the catch-all still said "invalid
   credentials".
3. **TLS trust-store mismatch — unlikely here.** The chain is public Let's Encrypt
   (`ISRG Root X1`), which Dart's bundled trust store contains. Ruled out by probe.
   (Would matter if the backend later moves behind a private/enterprise CA.)
4. **Backend device-verification.** The app already has a 403 branch
   ("Perangkat Anda belum terverifikasi…"). If the backend rejects desktop requests with
   401 instead of 403 (e.g., UA/fingerprint heuristics), the user sees the credentials
   snackbar instead of the blocking dialog. The live probe showed the `Dart (dart:io)` UA
   is *not* rejected at HTTP level, but device-binding behavior for real accounts could
   not be tested without valid credentials. **Recommendation:** verify in backend logs
   which status the desktop attempts receive (403 ⇒ device binding; 401 ⇒ credentials;
   no log entry ⇒ network/proxy/TLS).

---

## 3. Live Probe Evidence (read-only, dummy credentials)

```text
POST /api/v1/auth/login  {"username":"probe_audit","password":"probe_audit"}
→ HTTP 401  {"status":401,"message":"Username atau password salah.","data":{}}
  (identical response for default curl UA and "Dart/3.7 (dart:io)" UA, repeated 3x each)

curl -4 → HTTP 000 (timeout, exit 28)   vs   curl -6 → HTTP 200          (same host)
openssl chain: www.sindomon.cml-indonesia.com → Let's Encrypt YR1 → ISRG Root YR1 → ISRG Root X1
getent ahosts: 203.175.9.114 (A) + 2001:df1:7800:2::7:c2a6 (AAAA)
```

---

## 4. The Patch

### 4.1 `lib/widget/login_card.dart` (rewritten `login()` + `_showError()` helper)

| Change | Why |
|---|---|
| `username = usernameController.text.trim()` used for **both** validation and payload; **password sent verbatim** | H2 fix — no more `"username "` payloads; passwords are secrets and are never silently mutated (trimming them could lock out accounts whose password contains intentional whitespace) |
| `.timeout(const Duration(seconds: 20))` on the POST | App had **zero** HTTP timeouts; a hung connect could block forever behind the HUD |
| Headers: `Content-Type: application/json` + `Accept: application/json` + `User-Agent: SINDOMON-Client/1.0` (only when `!kIsWeb`) | H3 hardening — stable client identity across engines |
| Envelope decoded defensively (non-JSON body tolerated); `message` accepted only when it is a `String` | Gateway HTML/empty error pages no longer throw `FormatException`; nested non-string `message` values are ignored |
| SnackBar text capped at 160 chars | Backend-controlled text is reflected in `_showError()` — unbounded server messages can no longer dominate the UI (phishing-style text) |
| `data.user` accepted as **Map or single-element List** | Backend history shipped both shapes (see `plan/flutter_login_fix_plan.md`); a shape mismatch can never again masquerade as bad credentials |
| HTTP 200 with empty/missing token → treated as failure | Contract §8.7 gap: app previously navigated with an empty session |
| 401/400/422 → show backend `message` (fallback to the classic text) | H4 fix — "Username atau password salah." is far more actionable |
| 403 → unchanged "Akses Diblokir" device-verification dialog | Preserved behavior |
| Other statuses → "Gagal masuk (HTTP xxx)" or backend message | No more mislabeling 500s as bad credentials |
| `catch` split: `TimeoutException` → timeout text; `http.ClientException` → "Tidak dapat terhubung ke server. Periksa koneksi internet atau proxy Anda."; TLS/Handshake/Certificate pattern → TLS text; generic → unexpected-error text | Connectivity problems are **no longer reported as invalid credentials** — the key diagnostic win |
| `debugPrint("Login → POST $apiBaseUrl/api/v1/auth/login")` at request start | In Debug builds the console now shows which URL is hit (Release keeps it silent) |

### 4.2 `lib/config/api_config.dart`

```dart
const String apiBaseUrl = String.fromEnvironment(
  "API_BASE_URL",
  defaultValue: "https://sindomon.cml-indonesia.com",
);
```

Production default unchanged. Per-build override, e.g.:
`flutter build windows --dart-define=API_BASE_URL=https://staging.example.com`

### 4.3 `lib/main.dart` — startup fail-closed guard

`main()` now rejects any non-`https://` `apiBaseUrl` (possible only via a bad
`--dart-define` override) by throwing before `runApp` — credentials/JWTs can
never be sent over cleartext, even on misconfigured builds.

### 4.4 Security-review follow-ups applied

- `password` is sent **verbatim** (trim applied to username only) — secrets are
  never silently mutated (MEDIUM availability finding).
- HTTPS enforced at startup (MEDIUM cleartext-downgrade finding).
- Backend `message` reflected in SnackBars only when `String`, capped at 160
  chars (LOW reflected-content finding).
- **Not applied (out of this diff's scope):** JWT remains in plaintext
  SharedPreferences — pre-existing app-wide pattern; `flutter_secure_storage`
  (DPAPI on Windows) is the recommended migration.

---

## 5. Verification Steps (on a machine with the Flutter SDK — not available in this audit environment)

1. `flutter analyze` — expect no errors (static review performed manually; toolchain absent here).
2. **Debug-mode desktop repro:** run `flutter run -d windows` with the console visible and
   attempt the failing login. The console will now print the URL hit plus the *real*
   exception class on failure (previously it printed only in Debug and was still mislabeled
   in the UI).
3. Failure-message matrix now observable in the UI:
   - backend 401 with bad creds → `"Username atau password salah."`
   - unreachable network → `"Tidak dapat terhubung ke server. Periksa koneksi internet atau proxy Anda."`
   - hang > 20 s → `"Koneksi ke server timeout. Silahkan coba lagi."`
4. Copy-paste a credential with trailing spaces on Windows → login must now succeed.
5. If the desktop attempt still fails: correlate with backend access logs —
   - **no request logged** → network/proxy/IPv4-vs-IPv6 issue on that machine (see §2.1-2.2; try setting `HTTPS_PROXY` env var, or test IPv4 connectivity to `sindomon.cml-indonesia.com` from that machine);
   - **request logged with 401** → credentials/trimming (fixed) or backend account state;
   - **request logged with 403** → device-binding flow, escalate to Super Admin.

---

## 6. Recommendations (not part of this patch)

- **Windows system-proxy support:** dart:io ignores WinINET proxy settings. If the
  deployment network requires a proxy, either document the `HTTPS_PROXY` environment
  variable workaround or add explicit proxy configuration (win32 registry read /
  `HttpOverrides.global`) — this is the most probable true desktop-only blocker on
  corporate networks.
- **Release-build logging:** `debugPrint` is stripped in Release. For field diagnosis,
  add file-based logging (e.g. `logger`/`file`) around the login call.
- **Backend device-verification UX:** the static "Perangkat Terverifikasi" card in
  `pangaturan.dart` is a placeholder; the 403 login branch implies a real
  device-binding backend — wire the two together.
- **Global:** the rest of the app (30+ call sites) still has no HTTP timeouts and no
  401 forced-logout — tracked in `docs/frontend-consumption-guideline.md` §1.2/§4.1.

---

## 7. Files Changed

| File | Change |
|---|---|
| `lib/widget/login_card.dart` | Rewritten `login()` — username trim, 20s timeout, pinned headers, tolerant parsing, real error surfacing (message type-guard + 160-char cap); added `_showError()`; new imports `dart:async`, `kIsWeb` |
| `lib/config/api_config.dart` | `String.fromEnvironment("API_BASE_URL", ...)` build-time override, default unchanged |
| `lib/main.dart` | Startup fail-closed guard: non-`https://` base URL aborts before `runApp` |

## 8. Files Read (no changes)

`lib/pages/login_page.dart`, `lib/main.dart`, `lib/utils/session_util.dart`,
`lib/utils/hud_loading.dart`, `lib/pages/pangaturan.dart`, `pubspec.yaml`,
`docs/frontend-consumption-guideline.md`, `plan/flutter_login_fix_plan.md`.
