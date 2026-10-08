"""Build the long GDD from the game area docs, and check whether the GDDs are up to date.

The game area docs (every .md file in docs/ whose front matter has a gdd_order) are the
source of truth. Their structure is defined in docs/README.md ("How separate documents
are written"). This script turns them into docs/long-gdd.md: one chapter per game area
doc, in gdd_order order, made of its Summary, Decisions (without their date notes),
Content and References. Open questions are left out.

Usage, from the repo root (Python 3.9+, standard library only):

  python tools/generate_long_gdd.py           # regenerate docs/long-gdd.md
  python tools/generate_long_gdd.py --check   # change nothing; report what is stale

Exit codes: 0 everything in sync (or written), 1 something is stale (--check only),
2 a game area doc breaks the required structure (nothing is written).
"""

import argparse
import hashlib
import re
import sys
from pathlib import Path

DOCS_DIR = Path(__file__).resolve().parent.parent / "docs"
LONG_NAME = "long-gdd.md"
SHORT_README = Path("short-gdd") / "README.md"

REQUIRED_FIELDS = ["title", "gdd_order", "scope", "agents_work_on", "agents_read"]
SECTIONS = ["Summary", "Decisions", "Content", "Open questions", "References"]
PLACEHOLDERS = {"(To be written.)", "(None yet.)"}

SHORT_LINE_RE = re.compile(r"^Last updated from long GDD: (\S+)\s*$", re.M)
FINGERPRINT_ROW_RE = re.compile(r"^\| `([^`]+)` \| `([0-9a-f]{64})` \|$", re.M)
DATE_NOTE_RE = re.compile(r"\s*\((?=[^()]*\d{4}-\d{2}-\d{2})[^()]*\)(?=:?\s*$)")


class StructureError(Exception):
    pass


def normalized(text):
    return text.replace("\r\n", "\n")


def fingerprint(text):
    return hashlib.sha256(normalized(text).encode("utf-8")).hexdigest()


def parse_front_matter(text):
    """Return (fields, body_start_line) or (None, 0) when there is no front matter."""
    lines = normalized(text).split("\n")
    if not lines or lines[0] != "---":
        return None, 0
    fields = {}
    for i, line in enumerate(lines[1:], start=1):
        if line == "---":
            return fields, i + 1
        if ":" in line:
            key, value = line.split(":", 1)
            fields[key.strip()] = value.strip()
    return None, 0


def split_sections(lines, first_line):
    """Split the body into {section name: [lines]} by its ## headings, ignoring code fences.

    Raises StructureError listing every problem (missing, out of order or unknown headings).
    Line numbers in messages are 1-based.
    """
    sections, order, problems = {}, [], []
    current, in_fence = None, False
    for idx in range(first_line, len(lines)):
        line = lines[idx]
        if line.strip().startswith("```"):
            in_fence = not in_fence
        if not in_fence and line.startswith("## "):
            name = line[3:].strip()
            if name not in SECTIONS:
                problems.append(f"line {idx + 1}: unknown section heading '## {name}'")
                current = None
                continue
            if name in sections:
                problems.append(f"line {idx + 1}: section '## {name}' appears twice")
            current = name
            order.append(name)
            sections[name] = []
            continue
        if current is not None:
            sections[current].append(line)
    missing = [s for s in SECTIONS if s not in sections]
    if missing:
        problems.append("missing section(s): " + ", ".join("## " + s for s in missing))
    elif order != SECTIONS:
        problems.append("sections are not in the required order: " + ", ".join(order))
    if problems:
        raise StructureError(problems)
    return {name: "\n".join(body).strip() for name, body in sections.items()}


def load_docs(docs_dir):
    """Read and validate every game area doc. Returns (docs sorted by gdd_order, problems)."""
    docs, problems, orders = [], [], {}
    for path in sorted(Path(docs_dir).glob("*.md")):
        if path.name == LONG_NAME:
            continue
        raw = path.read_bytes().decode("utf-8")
        fields, body_start = parse_front_matter(raw)
        if fields is None or "gdd_order" not in fields:
            continue
        name = path.name
        missing = [f for f in REQUIRED_FIELDS if not fields.get(f)]
        if missing:
            problems.append(f"{name}: front matter is missing {', '.join(missing)}")
        try:
            order = int(fields.get("gdd_order", ""))
        except ValueError:
            problems.append(f"{name}: gdd_order is not a whole number")
            continue
        if order in orders:
            problems.append(f"{name}: gdd_order {order} is also used by {orders[order]}")
        orders[order] = name
        try:
            sections = split_sections(normalized(raw).split("\n"), body_start)
        except StructureError as exc:
            problems.extend(f"{name}: {p}" for p in exc.args[0])
            continue
        docs.append({"file": name, "title": fields.get("title", name), "order": order,
                     "scope": fields.get("scope", ""), "sections": sections, "raw": raw})
    docs.sort(key=lambda d: d["order"])
    return docs, problems


def is_placeholder(text):
    return text.strip() in PLACEHOLDERS or not text.strip()


def strip_date_notes(text):
    """Remove the date note that ends each decision bullet, keeping a trailing colon."""
    out = []
    for line in text.split("\n"):
        if line.lstrip().startswith("- "):
            line = DATE_NOTE_RE.sub("", line)
        out.append(line)
    return "\n".join(out)


def shift_headings(text, levels=1):
    """Push every Markdown heading down by `levels`, leaving code fences alone."""
    out, in_fence = [], False
    for line in text.split("\n"):
        if line.strip().startswith("```"):
            in_fence = not in_fence
        if not in_fence and re.match(r"^#{1,5} ", line):
            line = "#" * levels + line
        out.append(line)
    return "\n".join(out)


def anchor(text):
    slug = re.sub(r"[^\w\- ]", "", text.lower()).strip()
    return re.sub(r" ", "-", slug)


def render(docs):
    out = [
        "# Solid Carbide: Long GDD",
        "",
        "The whole game design in one document, condensed from the game area docs in this folder: each chapter is one game area doc's Summary, Decisions, Content and References. Open questions stay in their own game area docs.",
        "",
        "**Generated, do not edit by hand.** Change the game area doc instead, then regenerate with `python tools/generate_long_gdd.py`. The short GDD condenses this document (`short-gdd/`).",
        "",
        "## Contents",
        "",
    ]
    for i, d in enumerate(docs, start=1):
        heading = f"{i}. {d['title']}"
        out.append(f"{i}. [{d['title']}](#{anchor(heading)})")
    for i, d in enumerate(docs, start=1):
        s = d["sections"]
        out += ["", f"## {i}. {d['title']}", ""]
        out += [f"*Source: [{d['file']}]({d['file']}). {d['scope']}*", ""]
        wrote = False
        if not is_placeholder(s["Summary"]):
            out += [shift_headings(s["Summary"]), ""]
            wrote = True
        if not is_placeholder(s["Decisions"]):
            out += ["### Decisions", "", shift_headings(strip_date_notes(s["Decisions"])), ""]
            wrote = True
        if not is_placeholder(s["Content"]):
            out += ["### Content", "", shift_headings(s["Content"]), ""]
            wrote = True
        if not is_placeholder(s["References"]):
            out += ["### References", "", shift_headings(s["References"]), ""]
            wrote = True
        if not wrote:
            out += ["Not written yet.", ""]
    out += ["## Source fingerprints", "",
            "Used by `python tools/generate_long_gdd.py --check` to tell which game area docs changed since this file was generated.", "",
            "| Game area doc | SHA-256 |", "|---|---|"]
    for d in docs:
        out.append(f"| `{d['file']}` | `{fingerprint(d['raw'])}` |")
    return "\n".join(out).rstrip("\n") + "\n"


def read_fingerprints(long_text):
    return dict(FINGERPRINT_ROW_RE.findall(normalized(long_text)))


def check(docs, docs_dir):
    """Return a list of stale items (empty when everything is in sync)."""
    stale = []
    long_path = Path(docs_dir) / LONG_NAME
    if not long_path.exists():
        return ["the long GDD has never been generated"]
    long_text = long_path.read_bytes().decode("utf-8")
    recorded = read_fingerprints(long_text)
    current = {d["file"]: fingerprint(d["raw"]) for d in docs}
    for name, fp in current.items():
        if name not in recorded:
            stale.append(f"{name}: added since the long GDD was generated")
        elif recorded[name] != fp:
            stale.append(f"{name}: changed since the long GDD was generated")
    for name in recorded:
        if name not in current:
            stale.append(f"{name}: removed since the long GDD was generated")
    short_readme = Path(docs_dir) / SHORT_README
    match = SHORT_LINE_RE.search(normalized(short_readme.read_bytes().decode("utf-8"))) if short_readme.exists() else None
    if not match:
        stale.append("short GDD: no 'Last updated from long GDD:' line in short-gdd/README.md")
    elif match.group(1) != fingerprint(long_text):
        stale.append("short GDD: not yet updated from the current long GDD")
    return stale


def main(argv=None, docs_dir=DOCS_DIR):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="change nothing; report what is stale")
    args = parser.parse_args(argv)
    docs, problems = load_docs(docs_dir)
    if problems:
        for p in problems:
            print(f"structure problem: {p}", file=sys.stderr)
        print("nothing was written" if not args.check else "fix these first", file=sys.stderr)
        return 2
    if args.check:
        stale = check(docs, docs_dir)
        for s in stale:
            print(f"stale: {s}")
        if not stale:
            print(f"in sync: {len(docs)} game area docs, the long GDD and the short GDD")
        return 1 if stale else 0
    text = render(docs)
    long_path = Path(docs_dir) / LONG_NAME
    if long_path.exists() and long_path.read_bytes().decode("utf-8") == text:
        print(f"{LONG_NAME} already up to date ({len(docs)} chapters)")
    else:
        long_path.write_bytes(text.encode("utf-8"))
        print(f"wrote {LONG_NAME} ({len(docs)} chapters)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
