# Flutter Sidebar — Phase 3 Build Report (Dead Code Cleanup)

**Date:** 2025-07-14
**Status:** ✅ EXECUTED — 19 pages cleaned, 3 correctly kept, 0 failures

---

## 1. What Was Delivered

| Deliverable | Status |
|---|---|
| `scripts/cleanup_deadcode.py` — safe dead-code removal (regex + bracket-matching) | ✅ |
| Field removal: `String unLogin = "";` / `String roleLabel = "Operator";` | ✅ 19 pages |
| Method removal: `Future<void> loadUser() async { ... }` (brace-matched) | ✅ 19 pages |
| Call removal: `loadUser();` in `initState()` (+ now-empty `initState` override) | ✅ 19 pages |
| Import cleanup: unused `shared_preferences` import (9 add_* + inventaris) | ✅ 10 pages |
| Import cleanup: unused `session_util` import (left over from Phase 2) | ✅ 18 pages |
| This report | ✅ |

**Net result:** 24 files changed across Phases 1–3; `lib/pages/*` now contain **zero** references
to `unLogin` / `roleLabel` / `loadUser` outside `pangaturan.dart` (which legitimately renders
them in its profile cards).

---

## 2. Terminal Commands

```bash
# 1) Dry-run first (prints what would change, touches nothing)
python3 scripts/cleanup_deadcode.py

# 2) Apply the cleanup
python3 scripts/cleanup_deadcode.py --apply

# 3) Normalize formatting (Phase 2 left the migrated content re-indented)
dart format lib/pages lib/widget

# 4) Final gate — must be warning-free
flutter analyze
```

Optional: process a single file

```bash
python3 scripts/cleanup_deadcode.py --apply --files lib/pages/personel.dart
```

---

## 3. What the Script Removes (per file)

1. **Fields** — `String unLogin = "";` and `String roleLabel = "Operator";`
   (any initializer matched via `String <name> = [^;]+;`).
2. **`loadUser()` method** — located by signature
   `Future<void> loadUser() async {` and removed through the **brace-matched**
   closing `}`. The scanner is string/comment-aware (handles Dart `$`-interpolation
   with nested quotes), so `setState(() { ... });` bodies are safe.
3. **`loadUser();` call** inside `initState()`. If `initState` is left with only
   `super.initState();`, the whole override (including its `@override` line) is
   removed.
4. **Unused `shared_preferences` import** — removed only when no
   `SharedPreferences` token remains in the file (strict mode: `pangaturan.dart`
   and `dashboard.dart` are hard-excluded per spec).
5. **Unused `session_util` import** (Phase 2 fallout) — removed when neither
   `roleLabelFromId(` nor `clearSessionAndLogout(` is referenced anymore.

### Safety rules

- **Usage probe first:** a copy of the file is stripped of the fields + method +
  call, then checked for surviving `\bunLogin\b` / `\broleLabel\b` references.
  If any survive (e.g. `pangaturan.dart` renders them in its profile cards), the
  file is **kept untouched** — removing the fields would break real usage.
- **Word boundaries:** `roleLabelFromId(` never matches `roleLabel` (this is why
  `user_page.dart`'s DataTable usage is safe).
- **Bracket matching, not line counting:** method bodies are matched with a
  delimiter scanner, never by assuming a fixed closing sequence.
- **Post-checks per file:** no leftover `unLogin|roleLabel|loadUser`, `SharedPreferences`
  token ↔ import consistency, and full `() [] {}` balance. Any failure leaves the
  file untouched and is reported.

---

## 4. Execution Results

```
CLEANED  add_amunisi.dart … add_user.dart        (9 add_* pages: fields+method+initState+prefs import)
CLEANED  amunisi.dart, personel.dart, polda.dart, polres.dart, sarpras.dart,
         satwa.dart, senjata.dart, user_page.dart, master_kategori_senjata.dart
                                                 (fields+method+call; prefs import kept — APIs use it)
CLEANED  inventaris.dart                         (fields+method+initState+prefs import)
CLEANED  18 × unused session_util import
KEEP     pangaturan.dart                         (unLogin/roleLabel read by profile cards)
KEEP     dashboard.dart                          (nothing to remove)
KEEP     placeholder_page.dart                   (nothing to remove)
------------------------------------------------------------
OK: 19   KEPT: 3   FAILED: 0   mode: APPLY
```

### Post-cleanup verification sweep (all 22 pages)

- ✅ Zero `unLogin` / `roleLabel` / `loadUser` references (except `pangaturan`, which keeps its trio).
- ✅ `SharedPreferences` token ↔ import consistent everywhere.
- ✅ `session_util` import present **only** in `dashboard.dart`, `pangaturan.dart`, `user_page.dart`
  (the three files that still call `roleLabelFromId(` / `clearSessionAndLogout(`).
- ✅ Full `() [] {}` balance in every file.
- ⚠️ `dart format` / `flutter analyze` not runnable here (no Dart SDK) — run the commands
  in §2 on a dev machine. The only cosmetic residue: occasional double blank lines where
  blocks were removed and non-normalized indent from the Phase 2 transplant; `dart format`
  resolves both.

---

## 5. Complete Script (`scripts/cleanup_deadcode.py`)

```python
#!/usr/bin/env python3
"""
Phase 3: dead-code cleanup for AppScaffold-migrated pages.

Since `AppScaffold` now owns the header (it reads `username_login` /
`roleid_login` itself), the migrated pages still carry dead boilerplate:

    1. `String unLogin = "";`        (field declaration)
    2. `String roleLabel = "Operator";` (field declaration)
    3. `Future<void> loadUser() async { ... }`  (method, brace-matched)
    4. `loadUser();`                 (call inside `initState()`)
    5. `shared_preferences` import, when nothing references `SharedPreferences`
       anymore (strict removal excludes pangaturan.dart / dashboard.dart).

Safety rules:
  - Files where `unLogin` / `roleLabel` are READ anywhere else (e.g.
    pangaturan.dart renders them in its profile cards) are KEPT untouched —
    removing the fields would break real usage.
  - Word-boundary matching: `roleLabelFromId(` is NOT `roleLabel`.
  - Method bodies are located by brace-matching (string/comment-aware), never
    by counting fixed closing lines.
  - Post-checks per file: no leftover references, `SharedPreferences` token
    consistent with the import, and full () [] {} balance preserved.
    Failures leave the file untouched and are reported.

Usage:
    python3 scripts/cleanup_deadcode.py                  # dry-run (default)
    python3 scripts/cleanup_deadcode.py --apply          # write changes
    python3 scripts/cleanup_deadcode.py --apply --files lib/pages/personel.dart

Afterwards:
    dart format lib/pages lib/widget
    flutter analyze
"""

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PAGES = ROOT / "lib" / "pages"

# All AppScaffold-migrated pages (dashboard/pangaturan included — they are
# classified by the checks: dashboard has nothing to remove, pangaturan keeps
# its fields because the profile cards render them).
TARGETS = [
    "add_amunisi.dart",
    "add_inventaris_page.dart",
    "add_personel_page.dart",
    "add_polda.dart",
    "add_polres.dart",
    "add_sarpras.dart",
    "add_satwa.dart",
    "add_senjata.dart",
    "add_user.dart",
    "amunisi.dart",
    "dashboard.dart",
    "inventaris.dart",
    "master_kategori_senjata.dart",
    "pangaturan.dart",
    "personel.dart",
    "placeholder_page.dart",
    "polda.dart",
    "polres.dart",
    "sarpras.dart",
    "satwa.dart",
    "senjata.dart",
    "user_page.dart",
]

# Strict import removal is skipped for these files even if no `SharedPreferences`
# token remains (they may still need the package for other API flows).
IMPORT_EXCLUDE = {"pangaturan.dart", "dashboard.dart"}

PREF_IMPORT = "import 'package:shared_preferences/shared_preferences.dart';"

FIELD_UNLOGIN = re.compile(r"^[ \t]*String unLogin = [^;]+;\r?\n", re.MULTILINE)
FIELD_ROLELABEL = re.compile(r"^[ \t]*String roleLabel = [^;]+;\r?\n", re.MULTILINE)
LOADUSER_SIG = re.compile(r"^[ \t]*Future<void> loadUser\(\) async \{", re.MULTILINE)
LOADUSER_CALL = re.compile(r"^[ \t]*loadUser\(\);\r?\n", re.MULTILINE)
INITSTATE_SIG = re.compile(r"^[ \t]*void initState\(\) \{", re.MULTILINE)


def _skip_string(text: str, i: int) -> int:
    """Skip a '...' or \"...\" literal starting at i; returns index after it.
    Handles escapes, raw newlines, and Dart string interpolation `${...}`
    (including nested quoted strings inside the interpolation)."""
    quote = text[i]
    j = i + 1
    n = len(text)
    while j < n:
        c = text[j]
        if c == "\\":
            j += 2
            continue
        if c == quote:
            return j + 1
        if c == "$" and j + 1 < n and text[j + 1] == "{":
            depth = 1
            j += 2
            while j < n and depth > 0:
                cc = text[j]
                if cc in "'\"":
                    j = _skip_string(text, j)
                    continue
                if cc == "{":
                    depth += 1
                elif cc == "}":
                    depth -= 1
                j += 1
            continue
        if c == "\n":  # unterminated (raw newline) — bail out
            return j
        j += 1
    return j


def _scan_matching(text: str, open_pos: int, open_ch: str) -> int:
    """Index of the matching closer for the opening char at open_pos."""
    close_ch = {"{": "}", "[": "]", "(": ")"}[open_ch]
    depth = 1
    i = open_pos + 1
    n = len(text)
    while i < n:
        c = text[i]
        if c in "'\"":
            i = _skip_string(text, i)
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            j = text.find("\n", i)
            i = n if j == -1 else j
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            j = text.find("*/", i + 2)
            i = n if j == -1 else j + 2
            continue
        if c == open_ch:
            depth += 1
        elif c == close_ch:
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError("unbalanced: no matching %r for position %d" % (close_ch, open_pos))


def _strip_strings_comments(src: str) -> str:
    """Single-pass strip of strings and comments (order-safe, interpolation-aware)."""
    out = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            j = src.find("\n", i)
            i = n if j == -1 else j
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            j = src.find("*/", i + 2)
            i = n if j == -1 else j + 2
            continue
        if c in "'\"":
            i = _skip_string(src, i)
            out.append("''")
            continue
        out.append(c)
        i += 1
    return "".join(out)


def _balanced(src: str) -> bool:
    s = _strip_strings_comments(src)
    for a, b in [("(", ")"), ("[", "]"), ("{", "}")]:
        if s.count(a) != s.count(b):
            return False
    return True


def _remove_block(text: str, sig: re.Pattern) -> tuple[str, bool]:
    """Remove a `sig { ... }` block (signature line through its matching `}`)."""
    m = sig.search(text)
    if not m:
        return text, False
    open_pos = text.find("{", m.start())
    if open_pos < 0:
        return text, False
    try:
        close = _scan_matching(text, open_pos, "{")
    except ValueError:
        return text, False
    line_start = text.rfind("\n", 0, m.start()) + 1
    return text[:line_start] + text[close + 1 :], True


def _collapse_blank_lines(text: str) -> str:
    return re.sub(r"\n{3,}", "\n\n", text)


def _transform(text: str, name: str) -> tuple[str | None, str | None]:
    """Return (new_text, error). error is set when the file must not change."""
    original = text

    # ---- 0. Drop the session_util import when nothing references it anymore
    # (Phase 2 added it only for loadUser's roleLabelFromId call). ----
    if not re.search(r"\broleLabelFromId\(|\bclearSessionAndLogout\(", text):
        text = re.sub(
            r"^[ \t]*import '../utils/session_util\.dart';\r?\n",
            "",
            text,
            flags=re.MULTILINE,
        )

    # ---- 1. Usage probe: would unLogin/roleLabel still be referenced if we
    # removed the declaration + loadUser? If yes, keep everything (the fields
    # are read somewhere, e.g. pangaturan's profile cards). ----
    probe = FIELD_UNLOGIN.sub("", text)
    probe = FIELD_ROLELABEL.sub("", probe)
    probe, _ = _remove_block(probe, LOADUSER_SIG)
    probe = LOADUSER_CALL.sub("", probe)
    if re.search(r"\bunLogin\b|\broleLabel\b", probe):
        return text, "KEEP: unLogin/roleLabel still used outside dead boilerplate"

    # ---- 2. Remove the field declarations. ----
    text = FIELD_UNLOGIN.sub("", text)
    text = FIELD_ROLELABEL.sub("", text)

    # ---- 3. Remove the loadUser() method (brace-matched). ----
    text, removed = _remove_block(text, LOADUSER_SIG)
    if not removed:
        return text, "loadUser() method not found/not removable"

    # ---- 4. Remove the loadUser(); call inside initState(); if initState is
    # left with only super.initState(), drop the whole override. ----
    m = INITSTATE_SIG.search(text)
    if m:
        open_pos = text.find("{", m.start())
        try:
            close = _scan_matching(text, open_pos, "{")
        except ValueError:
            close = -1
        if close > 0:
            block = text[m.start() : close + 1]
            new_block = LOADUSER_CALL.sub("", block)
            if new_block != block:
                body = new_block[new_block.index("{") + 1 : new_block.rindex("}")]
                if body.strip() == "super.initState();":
                    # Remove the whole override incl. its @override line.
                    start = m.start()
                    before = text[:start]
                    ov = re.search(r"@override[ \t]*\n[ \t]*$", before)
                    if ov:
                        start = ov.start()
                    line_start = text.rfind("\n", 0, start) + 1
                    end = close + 1
                    if text[end : end + 1] == "\n":
                        end += 1
                        if text[end : end + 1] == "\n":  # blank line
                            end += 1
                    text = text[:line_start] + text[end:]
                else:
                    text = text[: m.start()] + new_block + text[close + 1 :]

    # ---- 5. Drop the shared_preferences import when no longer referenced.
    # IMPORT_EXCLUDE files are never touched here even if the token is gone. ----
    if name not in IMPORT_EXCLUDE and not re.search(r"\bSharedPreferences\b", text):
        text = re.sub(
            r"^[ \t]*import 'package:shared_preferences/shared_preferences\.dart';\r?\n",
            "",
            text,
            flags=re.MULTILINE,
        )

    text = _collapse_blank_lines(text)

    # ---- 6. Post-checks. ----
    leftovers = re.findall(r"\b(unLogin|roleLabel|loadUser)\b", text)
    if leftovers:
        return original, f"leftover references: {sorted(set(leftovers))}"
    has_prefs = re.search(r"\bSharedPreferences\b", text)
    has_import = PREF_IMPORT in text
    if has_prefs and not has_import:
        return original, "SharedPreferences used but import removed"
    if not _balanced(text):
        return original, "unbalanced () [] {} after transform"

    return text, None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--apply", action="store_true", help="write changes to disk")
    ap.add_argument(
        "--files",
        nargs="+",
        default=None,
        help="subset of files to process (paths or bare filenames)",
    )
    args = ap.parse_args()

    targets = args.files or TARGETS
    failed = []
    ok = []
    kept = []

    for name in targets:
        path = Path(name)
        if not path.is_absolute():
            path = PAGES / path.name
        if not path.exists():
            failed.append((name, "file not found"))
            continue

        text = path.read_text()
        new_text, error = _transform(text, path.name)
        if error:
            if new_text != text:
                # Partial cleanup (e.g. an unused import dropped) — apply it.
                if args.apply:
                    path.write_text(new_text)
                print(f"CLEANED  {path.name}  (partial: {error})")
                ok.append(name)
            else:
                kept.append((name, error))
            continue

        if new_text != text:
            if args.apply:
                path.write_text(new_text)
                print(f"CLEANED  {path.name}")
            else:
                print(f"CLEANED  {path.name}  (dry-run, would rewrite)")
            ok.append(name)
        else:
            print(f"NOOP     {path.name}")
            ok.append(name)

    print("-" * 60)
    print(
        f"OK: {len(ok)}   KEPT: {len(kept)}   FAILED: {len(failed)}   "
        f"mode: {'APPLY' if args.apply else 'DRY-RUN'}"
    )
    for name, reason in kept:
        print(f"KEEP  {name}: {reason}")
    for name, reason in failed:
        print(f"FAIL  {name}: {reason}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())

```
