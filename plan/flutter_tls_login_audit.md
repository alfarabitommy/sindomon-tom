# TLS Login Failure — Network & Auth-Flow Security Audit

> **Date:** 2026-08-18 · **Repo:** sindomon-tom (branch HEAD `ebcc570`)
> **Symptom reported:** SnackBar — *"Koneksi aman (TLS) ke server gagal. Periksa pengaturan sertifikat atau koneksi Anda."*
> **Scope:** login/network layer only · **Read-only audit, no code modified.**

---

## 0. TL;DR Verdict

The app's own network layer is **clean**: there is **no custom TLS configuration anywhere** —
no `HttpOverrides`, no `badCertificateCallback`, no `SecurityContext`, no certificate pinning,
no custom `HttpClient`. The login request goes through the stock `package:http` `IOClient` →
`dart:io HttpClient` with the **default trust store**, against a correct `https://` URL that
redirects nowhere.

Therefore the failure is **not caused by app-level misconfiguration**. The snackbar fires from a
generic `catch (e)` that pattern-matches the exception *text* for `Handshake` / `CERTIFICATE` /
`TLS` — i.e. a real `HandshakeException` (dart:io `TlsException` family) is escaping the TLS
layer. In order of probability, the root cause is:

1. **Environment-specific TLS interception / broken network path on the user's machine**
   (corporate/government DPI, proxy, antivirus TLS inspection, or the IPv4-vs-IPv6 asymmetry
   already documented in `plan/flutter_login_windows_desktop_audit.md` §2.2).
2. **Client clock skew** — the server certificate is only ~3 weeks old
   (`NotBefore: 2026-07-30 12:43:15 GMT`); a wrong clock yields
   `CERTIFICATE_VERIFY_FAILED: certificate is not yet valid`.
3. **Incomplete server certificate chain** — the server sends only up to the
   *Let's Encrypt ISRG Root YR* intermediate and omits the `ISRG Root X1` root. Dart does **not**
   fetch missing issuers via AIA (browsers/Postman do), so any client whose trust store lacks
   `ISRG Root X1` fails with `unable to get local issuer certificate`.

**Do NOT "fix" this with `badCertificateCallback: (_) => true`** — that silently disables all
certificate verification and exposes credentials + JWT to MITM. Correct fixes are in §8.

---

## 1. Exact Error-Message Trace

| Step | File:Line | What happens |
|---|---|---|
| 1 | `lib/widget/login_card.dart:116-134` | `http.post(Uri.parse("$apiBaseUrl/api/v1/auth/login"), ...)` with 20 s timeout. |
| 2 | `package:http` 1.6.0 (`io_client.dart:153-156`) | `IOClient.send()` wraps **only** `SocketException` and `HttpException` into `ClientException`. A `HandshakeException` / `TlsException` is **not wrapped** — it propagates raw. |
| 3 | `lib/widget/login_card.dart:241-245` | `on TimeoutException` → timeout snackbar. |
| 4 | `lib/widget/login_card.dart:246-255` | `on http.ClientException` → *"Tidak dapat terhubung ke server…"* (DNS/socket/proxy failures). |
| 5 | `lib/widget/login_card.dart:256-266` | Generic `catch (e, st)`; `debugPrint('Login error: $e\n$st')`, then: |
| 6 | `lib/widget/login_card.dart:261-263` | `text.contains('Handshake') || text.contains('CERTIFICATE') || text.contains('TLS')` |
| 7 | `lib/widget/login_card.dart:265` | Shows the exact reported snackbar: `"Koneksi aman (TLS) ke server gagal. Periksa pengaturan sertifikat atau koneksi Anda."` |

**Implication:** the user sees this message **only** when a real TLS-layer exception
(`HandshakeException`, `TlsException`, or anything whose `toString()` contains those tokens)
escapes from dart:io. It is not a 4xx/5xx response, not a timeout, not a plain socket failure.

**Diagnostic gap:** in Release builds `debugPrint` is stripped (`plan/flutter_login_windows_desktop_audit.md` §0),
so the actual exception class and OS error code are currently invisible. The likely raw strings are:

- `HandshakeException: Handshake error in client (OS Error: CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate(handshake.cc:393))`
  → trust store / MITM-CA / incomplete chain.
- `HandshakeException: Handshake error in client (OS Error: CERTIFICATE_VERIFY_FAILED: certificate is not yet valid(...))`
  → client clock before 2026-07-30.
- `HandshakeException: Connection terminated during handshake`
  → a firewall/proxy/DPI or the blackholed IPv4 path RSTs the connection mid-handshake.

---

## 2. HTTP Client Configuration Audit

- **Client library:** `http: ^1.2.2`, resolved to **1.6.0** (`pubspec.yaml:23`, `pubspec.lock:315-322`). No Dio, no dio, no custom HTTP service class — 30+ call sites use the top-level `http.get/post/put/delete` (package default `IOClient` on dart:io).
- **Global repo grep** for `HttpOverrides`, `badCertificateCallback`, `SecurityContext`, `allowBadCertificates`, `dart:io` client construction: **zero hits** in `lib/`, `test/`, `android/`, `ios/`, `windows/`, `linux/`, `macos/`.
- **No SSL pinning** of any kind (good that none exists broken, but also nothing to misconfigure).
- **No proxy handling:** dart:io does not read Windows WinINET proxy settings; it only honors `http_proxy`/`https_proxy`/`no_proxy` env vars (previously flagged in `plan/flutter_login_windows_desktop_audit.md` §2.1).
- **No timeouts** on any other call site (login alone got `.timeout(20s)` in the Aug-15 patch).

**Conclusion:** nothing in the app can be rejecting the certificate "by itself". The handshake
fails at the platform/OS trust boundary, i.e. between dart:io's BoringSSL and (a) the peer's
certificate chain or (b) the network path.

---

## 3. Platform-Specific Network Rules

| Platform | File | Finding |
|---|---|---|
| Android | `android/app/src/main/AndroidManifest.xml` | **`<uses-permission android:name="android.permission.INTERNET"/>` is MISSING in the main manifest.** Debug/profile manifests have it (`android/app/src/debug|profile/AndroidManifest.xml`), so release APKs cannot open any socket at all. Not a TLS error, but a release-blocking network bug. |
| Android | `network_security_config.xml` | **Does not exist.** No custom trust anchors, no cleartext overrides. Default: system trust store, cleartext blocked (fine for an https-only app). |
| iOS | `ios/Runner/Info.plist` | **No `NSAppTransportSecurity` key at all** → ATS default = HTTPS required. No `NSAllowsArbitraryLoads` (good). App is https-only, so no conflict. |
| macOS | `macos/Runner/DebugProfile.entitlements` | Has `app-sandbox`, `cs.allow-jit`, **`network.server`** — but **`com.apple.security.network.client` is absent** (outgoing connections from the sandbox). |
| macOS | `macos/Runner/Release.entitlements` | Only `app-sandbox`. Same missing `network.client`; sandboxed release builds may be unable to make any outgoing connection (surfaces as socket error, not TLS, but worth fixing). |
| Windows | `windows/runner/*`, `windows/CMakeLists.txt` | Nothing TLS-specific. Dart/BoringSSL provides TLS; trust anchors come from the OS root store loaded by dart:io (not the same code path browsers use). |
| Web | `web/` | On web the browser handles TLS; this snackbar branch is unreachable for pure browser TLS failures (XHR throws `ClientException`-style `Failed to fetch`). The reported error therefore comes from a **desktop (dart:io) build** — consistent with the Windows CI artifact. |

---

## 4. API Endpoints & Mixed-Content Audit

- Base URL: `lib/config/api_config.dart:16-19` —
  `const apiBaseUrl = String.fromEnvironment("API_BASE_URL", defaultValue: "https://sindomon.cml-indonesia.com");`
- Startup guard: `lib/main.dart:12-18` — throws `StateError` at boot if the scheme is not `https://` (no downgrade possible even via `--dart-define`).
- CI: `.github/workflows/build-windows.yml:22` builds with `--dart-define=API_BASE_URL=https://sindomon.cml-indonesia.com`.
- Login endpoint: `$apiBaseUrl/api/v1/auth/login` — **no trailing slash, no redirects** (live probe below).
- No stored/runtime-configurable URL: grep for prefs keys storing URLs → none; every endpoint derives from `apiBaseUrl`.
- Only external URL in the app: ArcGIS map tiles (`lib/pages/dashboard.dart:214`, https) — unrelated to login.

**Live endpoint probes (from this audit machine, 2026-08-18):**

```text
POST /api/v1/auth/login   {"username":"probe","password":"probe"}
  → HTTP 401, 0 redirects, url effective = https://sindomon.cml-indonesia.com/api/v1/auth/login
POST /api/v1/auth/login/  (trailing slash)
  → HTTP 401, 0 redirects   (no 30x loop, no scheme downgrade)
Server: Apache, HTTP/2 (ALPN), access-control-allow-origin: *
```

---

## 5. Live TLS Probe of the Server

```text
openssl s_client -connect sindomon.cml-indonesia.com:443 -servername sindomon.cml-indonesia.com
  → TLSv1.3, TLS_AES_256_GCM_SHA384, Verify return code: 0 (ok)
  → TLSv1.2 also negotiated: ECDHE-RSA-AES256-GCM-SHA384, Verify ok

Certificate chain as sent by the server (3 certs):
  0  CN=www.sindomon.cml-indonesia.com        issuer: Let's Encrypt YR1
  1  C=US,O=Let's Encrypt,CN=YR1              issuer: ISRG Root YR
  2  C=US,O=ISRG,CN=Root YR                   issuer: ISRG Root X1
     (ISRG Root X1 itself is NOT sent)

Validity: NotBefore Jul 30 12:43:15 2026 GMT → NotAfter Oct 28 12:43:14 2026 GMT
SAN:      "sindomon.cml-indonesia.com" matches host ✓
IPv4 203.175.9.114:443  → handshake OK, HTTP 200 (today)
IPv6 2001:df1:7800:2::7:c2a6:443 → handshake OK (curl negotiated fine)
```

**Notes on the chain:**
- Verifies cleanly for any client whose trust store contains `ISRG Root X1` (Windows 10/11,
  Dart's bundled Mozilla-derived roots, Android ≥ 7, iOS ≥ 10 all do).
- Because the root is omitted, verification relies entirely on the client's local store —
  Dart cannot use AIA to download the missing issuer the way browsers/Postman can.
- Prior audit (`plan/flutter_login_windows_desktop_audit.md` §3) recorded **IPv4 blackholed,
  IPv6-only success** from its environment; today IPv4 works from this machine. The
  IPv4/IPv6 path asymmetry is real and environment-dependent — and dart:io tries resolved
  addresses **sequentially** (no Happy Eyeballs).

---

## 6. Root-Cause Analysis (ranked)

### R1 — TLS interception / broken path on the user's network (MOST LIKELY)
Police/government deployment → DPI boxes, filtering proxies, AV/EDR TLS inspection are common.
Mechanisms that all produce exactly this snackbar:
- Interceptor presents a CA that is not in dart:io's effective trust store →
  `CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate`. Browsers work because
  they use WinINET/SCHANNEL with the machine store + WPAD proxy; dart:io does not use WinINET
  and may not pick up the same anchors.
- Firewall/proxy terminates the connection mid-handshake → `Connection terminated during handshake`.
- The documented IPv4 blackhole (`203.175.9.114`) — if the OS resolves it first and the firewall
  RSTs during handshake on that path, dart:io has no Happy-Eyeballs fallback.

### R2 — Client clock skew
Cert `NotBefore` is **2026-07-30** (issued only ~3 weeks ago). Any client machine with a clock
before that (dead CMOS battery, wrong date) fails with `certificate is not yet valid`.
This is the cheapest thing to check on the affected machine.

### R3 — Incomplete server chain (low, but real)
Server omits `ISRG Root X1`. Breaks only clients with stale/missing roots that cannot AIA-fetch
(Dart cannot). Worth fixing server-side regardless (nginx/Apache `fullchain.pem` instead of
`chain.pem`), because it hardens compatibility for all non-browser clients.

### R4 — Antivirus/EDR BoringSSL incompatibility on the client
Some AV web-shields inject a fake cert or break BoringSSL handshakes for non-browser processes.

### R5 — App-level TLS config (RULED OUT)
No pinning, no `badCertificateCallback`, no `HttpOverrides`, no `SecurityContext` anywhere.

---

## 7. Files Involved

| File | Role |
|---|---|
| `lib/widget/login_card.dart:116-134, 241-266` | Login request + the exact error-message branch (line 265). |
| `lib/config/api_config.dart:16-19` | `apiBaseUrl` constant (https default + `--dart-define` override). |
| `lib/main.dart:12-18` | Startup fail-closed https guard. |
| `pubspec.yaml:23` / `pubspec.lock:315-322` | `http` 1.6.0 — default `IOClient`, no custom client. |
| `~/.pub-cache/.../http-1.6.0/lib/src/io_client.dart:153-156` | Why `HandshakeException` escapes unwrapped (generic catch path). |
| `android/app/src/main/AndroidManifest.xml` | Missing `INTERNET` permission (release builds). |
| `android/app/src/debug/AndroidManifest.xml`, `.../profile/AndroidManifest.xml` | INTERNET present only in debug/profile. |
| `ios/Runner/Info.plist` | No ATS key → https enforced by default (OK). |
| `macos/Runner/DebugProfile.entitlements`, `Release.entitlements` | Missing `com.apple.security.network.client`. |
| `plan/flutter_login_windows_desktop_audit.md` | Prior Aug-15 audit: IPv4 blackhole, WinINET proxy gap, error-masking fix that introduced this TLS branch. |
| `.github/workflows/build-windows.yml:22` | CI build pins the production URL via dart-define. |

---

## 8. Suggested Fixes

### A. Diagnostics first (no security trade-off)
1. **Surface the real exception.** In `login_card.dart`'s TLS branch, include
   `e.runtimeType` + the first 120 chars of `e.toString()` in the snackbar **or** append to a
   log file (`File(log)` works in Release where `debugPrint` is stripped). This instantly
   distinguishes `CERTIFICATE_VERIFY_FAILED` (trust) from `Connection terminated` (path) from
   `certificate is not yet valid` (clock).
2. Replace the fragile string matching with typed catches:
   `on HandshakeException catch (e)` → TLS message incl. `e.osError`; keep `TlsException` as fallback.
3. **On the failing machine:**
   ```powershell
   # clock check — cert is only valid from 2026-07-30
   Get-Date
   # does the OS/browser trust the chain from that network?
   curl.exe -v https://sindomon.cml-indonesia.com/api/v1/auth/login
   certutil -verify -urlfetch https://sindomon.cml-indonesia.com/api/v1/auth/login
   # IPv4 vs IPv6 path
   ping -4 sindomon.cml-indonesia.com ; ping -6 sindomon.cml-indonesia.com
   openssl s_client -connect sindomon.cml-indonesia.com:443 -servername sindomon.cml-indonesia.com -showcerts
   # (compare the presented chain/cert with §5 — a different issuer ⇒ MITM appliance)
   ```
4. Check backend access logs: a request reaching Apache means TLS completed (problem is
   elsewhere); no log entry means the handshake never finished.

### B. Correct code hardening (if/when you modify code)
1. **Never** `badCertificateCallback: (_) => true`. If the deployment network genuinely uses a
   private CA (R1), ship that **specific** CA as an asset and load it via
   `SecurityContext()..setTrustedCertificatesBytes(...)` for the app's `HttpClient` — all other
   roots stay enforced, hostname verification stays on. Even better: pin the leaf/SPKI of
   `www.sindomon.cml-indonesia.com`.
2. Add **Windows system-proxy support** (dart:io ignores WinINET) or document `HTTPS_PROXY` for
   the deployment; add explicit proxy config behind a `--dart-define` if the police network
   requires one.
3. Happy Eyeballs mitigation: set a short `connectionTimeout` on `HttpClient` so a blackholed
   IPv4 attempt fails over quickly; consider pinning DNS/address families via a diagnostic
   setting (not default).
4. Add **Release-build file logging** around every network call (login at minimum).
5. Platform fixes: add `INTERNET` permission to the main Android manifest (release APK is
   currently network-dead); add `com.apple.security.network.client` to both macOS entitlements.
6. Server-side (backend team): serve `fullchain.pem` (include `ISRG Root X1`) so non-AIA
   clients never depend on local roots alone; keep TLS 1.2 enabled (it is).

### C. Rollout check
Rebuild/verify on the failing machine with fix A1 first — the captured exception string is the
single piece of evidence that turns this ranked analysis into a confirmed root cause.

---

## 9. What Was Verified vs Not

**Verified (this machine, 2026-08-18):** server reachable over IPv4 and IPv6; TLS 1.2 and 1.3
negotiate; cert chain validates; SAN matches; login POST returns 401 with 0 redirects; no TLS
customization anywhere in the repo; `http` 1.6.0 does not wrap `HandshakeException`.

**Not verifiable from this machine:** the user's actual network path, machine clock, AV/proxy
state, and the exact `HandshakeException` text (no Flutter SDK installed here) — fix A1 captures it.
