#!/usr/bin/env python3
"""Old name of the sprite check (T-014): the checks live in style_rules.py (T-290).

Usage: python game/tools/check_sprite_rules.py SPRITE.png [--size 128] [--max-colors 30] [--frames N] [--rule6]
runs `style_rules.py art SPRITE.png --size 128 ... --greenbull` (rules 1 and 3; rule 6 is not
part of this old check unless --rule6 asks for it). Exits 0 when all rules hold, 1 otherwise.

       python game/tools/check_sprite_rules.py --rule6-report DIR [--against REV]
prints rule 6's result for every PNG under DIR, and with --against the result of the
style_rules.py at git revision REV next to it (T-298: the new rule 6 against master's).
"""
import subprocess
import sys
import types
from pathlib import Path

from style_rules import check, check_rows, check_sheet, decode_png, split_sheet  # noqa: F401
import style_rules

ROOT = Path(__file__).resolve().parents[2]


def rules_at(rev):
    """style_rules.py as it is at git revision `rev`, loaded as a module."""
    src = subprocess.run(["git", "show", "%s:game/tools/style_rules.py" % rev], cwd=ROOT,
                         capture_output=True, text=True, encoding="utf-8", check=True).stdout
    mod = types.ModuleType("style_rules_%s" % rev)
    exec(compile(src, "style_rules@%s" % rev, "exec"), mod.__dict__)
    return mod


def rule6(module, rows):
    """(ok, detail) of `module`'s rule 6 check on the rows, with no flag or allowed colour."""
    res = [c for c in module.art_checks(rows) if c["rule"] == 6]
    return (res[0]["ok"], res[0]["detail"]) if res else (True, "no rule 6 check")


def rule6_report(folder, against=None):
    """Rule 6 for every PNG under `folder`: a list of dicts with path, ok and detail, plus
    old_ok and old_detail from style_rules.py at revision `against` when given."""
    old = rules_at(against) if against else None
    out = []
    for p in sorted(Path(folder).resolve().rglob("*.png")):
        row = {"path": p.relative_to(ROOT).as_posix() if p.is_relative_to(ROOT) else str(p)}
        try:
            _, _, rows = decode_png(p.read_bytes())
        except ValueError as e:
            row.update(ok=None, detail="not checked: %s" % e)
            out.append(row)
            continue
        row["ok"], row["detail"] = rule6(style_rules, rows)
        if old:
            row["old_ok"], row["old_detail"] = rule6(old, rows)
        out.append(row)
    return out


def _mark(ok):
    return "-" if ok is None else ("pass" if ok else "FAIL")


def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    if args[:1] == ["--rule6-report"]:
        against = args[args.index("--against") + 1] if "--against" in args else None
        rows = rule6_report(args[1], against)
        for r in rows:
            line = "%s  now %s (%s)" % (r["path"], _mark(r["ok"]), r["detail"])
            if "old_ok" in r:
                line += "  %s %s (%s)" % (against, _mark(r["old_ok"]), r["old_detail"])
            print(line)
        return 0 if all(r["ok"] is not False for r in rows) else 1
    rule6_too = "--rule6" in args
    args = [a for a in args if a != "--rule6"]
    if "--size" not in args:
        args += ["--size", "128"]  # the old default
    return style_rules.main(["art"] + args + ([] if rule6_too else ["--greenbull"]))


if __name__ == "__main__":
    sys.exit(main())
