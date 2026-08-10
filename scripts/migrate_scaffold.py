#!/usr/bin/env python3
"""
Mass-transplant: strip the legacy `Row > AppSidebar` boilerplate from
standard pages and wrap their content in `AppScaffold`.

The transform is fully mechanical and verified per file:
  1. Drop the legacy widget imports (background / app_sidebar / app_footer /
     app_header) and add `app_scaffold.dart`.
  2. Rewrite `AppSidebar.roleLabelFromId(` -> `roleLabelFromId(` (now living
     in `utils/session_util.dart`) and ensure that import exists.
  3. Replace the `Scaffold > AppBackground > SafeArea > Row > [Sidebar,
     Expanded > Padding(30) > Column(start) > [AppHeader, ..., AppFooter]]`
     block with a single `AppScaffold(currentRoute:, breadcrumb:, child:)`
     call. Instead of assuming a fixed closing-bracket sequence, a small
     delimiter scanner walks the real code (skipping strings/comments) and
     cuts exactly at the matching `);` of the `return Scaffold(` statement,
     so pages with extra nesting (e.g. `else ...[ ... ]` lists) work too.
  4. Post-checks per file: no leftover references to the removed widgets,
     balanced () [] {}, and the new import present. Failures leave the file
     untouched and are reported.

Usage:
    python3 scripts/migrate_scaffold.py                  # dry-run (default)
    python3 scripts/migrate_scaffold.py --apply          # write changes
    python3 scripts/migrate_scaffold.py --apply --files lib/pages/personel.dart

After running with --apply:
    dart format lib/pages lib/widget   # normalize the re-indented content
    flutter analyze                    # final gate
"""

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PAGES = ROOT / "lib" / "pages"

# All sidebar pages still on the legacy layout. dashboard.dart, pangaturan.dart
# and login_page.dart are already handled (or not applicable) and excluded.
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
    "inventaris.dart",
    "master_kategori_senjata.dart",
    "personel.dart",
    "placeholder_page.dart",
    "polda.dart",
    "polres.dart",
    "sarpras.dart",
    "satwa.dart",
    "senjata.dart",
    "user_page.dart",
]

REMOVE_IMPORTS = [
    "import '../widget/background.dart';",
    "import '../widget/app_sidebar.dart';",
    "import '../widget/app_footer.dart';",
    "import '../widget/app_header.dart';",
]

# Whitespace that may include `//` comment lines (the "/// CONTENT" banners).
_WS = r"\s*(?://[^\n]*\n\s*)*"

# Standard pages — matches the uniform HEAD of the build method, up to and
# including the closing `),` of the AppHeader block. Everything after is
# located with the delimiter scanner (nesting-agnostic).
_PAT_STANDARD = re.compile(
    r"return Scaffold\("
    + _WS
    + r"body: AppBackground\("
    + _WS
    + r"imagePath: 'assets/images/wp-putih-mabes\.png',"
    + _WS
    + r"child: SafeArea\("
    + _WS
    + r"child: Row\("
    + _WS
    + r"children: \["
    + _WS
    + r"(?:const\s+)?AppSidebar\(currentRoute: (?P<route>[^)]+)\),"
    + _WS
    + r"Expanded\("
    + _WS
    + r"child: Padding\("
    + _WS
    + r"padding: const EdgeInsets\.all\(30\),"
    + _WS
    + r"child: Column\("
    + _WS
    + r"crossAxisAlignment: CrossAxisAlignment\.start,"
    + _WS
    + r"children: (?P<list>\[)"
    + _WS
    + r"AppHeader\("
    + _WS
    + r"breadcrumb:\s*(?P<bc>.*?),\s*username:"
    + _WS
    + r"[^,\n]+,\s*role:"
    + _WS
    + r"[^,\n]+,\s*\),",
    re.DOTALL,
)

# Placeholder pages (no header/footer): content is Expanded > child widget.
_PAT_PLACEHOLDER = re.compile(
    r"return Scaffold\("
    + _WS
    + r"body: AppBackground\("
    + _WS
    + r"imagePath: 'assets/images/wp-putih-mabes\.png',"
    + _WS
    + r"child: SafeArea\("
    + _WS
    + r"child: Row\("
    + _WS
    + r"children: \["
    + _WS
    + r"AppSidebar\(currentRoute: (?P<route>[^)]+)\),"
    + _WS
    + r"Expanded\("
    + _WS
    + r"child:\s*",
    re.DOTALL,
)


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
            # Interpolation: scan until the matching '}'.
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
    """Given the index of an opening '[' or '(', return the index of its
    matching closer, skipping string literals and comments."""
    close_ch = "]" if open_ch == "[" else ")"
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


def _reindent(block: str, indent: int = 6) -> str:
    """Strip the common leading indentation and re-indent at `indent` spaces.
    Safe here because the pages contain no multi-line string literals."""
    lines = block.split("\n")
    indents = [len(l) - len(l.lstrip(" ")) for l in lines if l.strip()]
    base = min(indents) if indents else 0
    out = []
    for l in lines:
        if l.strip():
            out.append(" " * indent + l[base:])
        else:
            out.append("")
    return "\n".join(out)


def _strip_strings_comments(src: str) -> str:
    """Single-pass strip of strings and comments (order-safe: comments inside
    strings like 'https://' are never touched, and Dart `${...}` interpolation
    with nested quotes is handled by [_skip_string])."""
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


def _transform(text: str) -> tuple[str | None, str | None]:
    """Return (new_text, error). error is set when the file does not match."""
    original = text

    # 1. Drop legacy imports.
    lines = [l for l in text.split("\n") if l.strip() not in REMOVE_IMPORTS]
    text = "\n".join(lines)

    # 2. Rewrite roleLabelFromId references to the shared util.
    had_label_ref = "AppSidebar.roleLabelFromId(" in text
    text = text.replace("AppSidebar.roleLabelFromId(", "roleLabelFromId(")

    # 3. Locate the `return Scaffold(` statement boundaries.
    sm = re.search(r"return Scaffold\(", text)
    if not sm:
        return original, "no `return Scaffold(` found"
    stmt_open = sm.end() - 1  # the '(' of Scaffold(
    try:
        stmt_close = _scan_matching(text, stmt_open, "(")  # the ')' of ');'
    except ValueError as e:
        return original, str(e)
    if text[stmt_close + 1 : stmt_close + 2] != ";":
        return original, "statement not terminated by ');'"

    # 4. Match the head variant and cut the boilerplate.
    m = _PAT_STANDARD.search(text)
    if m:
        route = m.group("route").strip()
        bc = " ".join(m.group("bc").split())
        list_open = m.start("list")  # outer Column children '['
        try:
            list_close = _scan_matching(text, list_open, "[")
        except ValueError as e:
            return original, str(e)
        if list_close > stmt_close:
            return original, "outer children list extends past Scaffold close"
        # Everything from after the AppHeader to the outer list close, minus
        # the AppFooter widget (inner `],` closers stay where they belong).
        content = text[m.end() : list_close]
        content = re.sub(
            r"\s*(?:const\s+)?AppFooter\(\),", "", content, count=1
        ).strip("\n")
        replacement = (
            "return AppScaffold(\n"
            f"  currentRoute: {route},\n"
            f"  breadcrumb: {bc},\n"
            "  child: Column(\n"
            "    crossAxisAlignment: CrossAxisAlignment.start,\n"
            "    children: [\n"
            f"{_reindent(content)}\n"
            "    ],\n"
            "  ),\n"
            ");"
        )
        cut_start = m.start()
    else:
        m = _PAT_PLACEHOLDER.search(text)
        if not m:
            return original, "no matching Scaffold boilerplate (standard or placeholder)"
        route = m.group("route").strip()
        # The child widget of Expanded ends right before Expanded's ')'.
        # rfind returns the 'E' of "Expanded(" — shift to the '(' itself.
        expanded_open = (
            text.rfind("Expanded(", m.start(), m.end()) + len("Expanded(") - 1
        )
        try:
            expanded_close = _scan_matching(text, expanded_open, "(")
        except ValueError as e:
            return original, str(e)
        widget = text[m.end() : expanded_close].strip()
        if widget.endswith(","):
            # Drop the trailing comma (Expanded's `,`) — the template adds one.
            widget = widget[:-1].rstrip()
        replacement = (
            "return AppScaffold(\n"
            f"  currentRoute: {route},\n"
            "  showHeaderFooter: false,\n"
            f"  child: {_reindent(widget)},\n"
            ");"
        )
        cut_start = m.start()

    text = text[:cut_start] + replacement + text[stmt_close + 2 :]

    # 5. Ensure imports.
    needed = []
    if "import '../widget/app_scaffold.dart';" not in text:
        needed.append("import '../widget/app_scaffold.dart';")
    if had_label_ref and "import '../utils/session_util.dart'" not in text:
        needed.append("import '../utils/session_util.dart';")
    if needed:
        import_lines = [i for i, l in enumerate(text.split("\n")) if l.startswith("import ")]
        last = import_lines[-1] if import_lines else 0
        lines = text.split("\n")
        lines[last + 1 : last + 1] = needed
        text = "\n".join(lines)

    # 6. Post-checks.
    leftovers = re.findall(r"\b(AppBackground|AppHeader|AppFooter|AppSidebar)\b", text)
    if leftovers:
        return original, f"leftover references: {sorted(set(leftovers))}"
    if "AppScaffold(" not in text:
        return original, "AppScaffold( call missing after transform"
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

    for name in targets:
        path = Path(name)
        if not path.is_absolute():
            path = PAGES / path.name
        if not path.exists():
            failed.append((name, "file not found"))
            continue

        text = path.read_text()
        new_text, error = _transform(text)
        if error:
            failed.append((name, error))
            continue

        if new_text != text:
            if args.apply:
                path.write_text(new_text)
                print(f"PASS  {path.name}  (rewritten)")
            else:
                print(f"PASS  {path.name}  (dry-run, would rewrite)")
            ok.append(name)
        else:
            print(f"SKIP  {path.name}  (no change needed)")
            ok.append(name)

    print("-" * 60)
    print(f"OK: {len(ok)}   FAILED: {len(failed)}   mode: {'APPLY' if args.apply else 'DRY-RUN'}")
    for name, reason in failed:
        print(f"FAIL  {name}: {reason}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
