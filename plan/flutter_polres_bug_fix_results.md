# Flutter Polres CRUD — Bug Fix Results

**Date:** 2026-08-03
**Status:** ✅ Complete — `flutter analyze` passes with zero issues in modified files

---

## Issues Fixed

### Issue 1: Dropdown Type Error

| Detail | Value |
|--------|-------|
| **File** | `lib/widget/form_input_polres.dart:228` |
| **Error** | `TypeError: 1: type 'int' is not a subtype of type 'String'` |
| **Root cause** | `int.parse(polda["id"])` assumes `polda["id"]` is a String, but backend now returns it as an int |
| **Fix** | `int.parse(polda["id"])` → `int.tryParse(polda["id"].toString()) ?? 0` |

### Issue 2: Missing `/master/` Prefix in POST

| Detail | Value |
|--------|-------|
| **File** | `lib/widget/form_input_polres.dart:86` |
| **Root cause** | `POST /api/v1/polres` missing the `/master/` module prefix required by API spec |
| **Fix** | `POST /api/v1/polres` → `POST /api/v1/master/polres` |

---

## Full API Endpoint Audit

All `http.get`, `http.post`, `http.put`, `http.delete` calls across both Polres files:

| # | File | Method | URL | Status |
|---|------|--------|-----|--------|
| 1 | `polres.dart:44` | GET | `/api/v1/master/polres` | ✅ |
| 2 | `polres.dart:83` | DELETE | `/api/v1/master/polres/$id` | ✅ |
| 3 | `form_input_polres.dart:31` | GET | `/api/v1/polda` | ✅ Polda resource (dropdown lookup), not Polres |
| 4 | `form_input_polres.dart:86` | POST | `/api/v1/master/polres` | ✅ Fixed |
| 5 | `form_input_polres.dart:76` | PUT | `/api/v1/master/polres/$id` | ✅ |

---

## Static Analysis

```
$ flutter analyze
4 issues found. (ran in 5.3s)
```

All 4 issues are pre-existing `info`-level `use_build_context_synchronously` warnings in `lib/widget/login_card.dart` — **zero issues in the modified Polres files.**
