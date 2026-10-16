#!/usr/bin/env python3
"""Checks every sound under a folder has complete metadata and a CC0 or CC BY licence.

Usage: python game/tools/check_sfx_licenses.py [folder]   (default game/audio)
Prints one line per sound; exit 0 if all pass, 1 otherwise. Also lists CC BY credits with --credits.
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import freesound as fs

def check(folder):
    rows, bad = [], 0
    for root, _, files in os.walk(folder):
        for f in sorted(files):
            if not f.lower().endswith((".wav", ".ogg", ".mp3")):
                continue
            path = os.path.join(root, f)
            jp = os.path.splitext(path)[0] + ".json"
            problem = None
            meta = {}
            if not os.path.exists(jp):
                problem = "no metadata json"
            else:
                with open(jp, encoding="utf-8") as fh:
                    meta = json.load(fh)
                issues = fs.validate_metadata(meta)
                if issues:
                    problem = "bad metadata: " + "; ".join(issues)
                if not problem and not fs.is_license_allowed(meta.get("license_name", "")) \
                        and not fs.is_license_allowed(meta.get("license_url", "")):
                    problem = "license not allowed: %s" % meta.get("license_name")
            bad += bool(problem)
            rows.append((path, meta, problem))
    return rows, bad

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    rows, bad = check(args[0] if args else "game/audio")
    for p, m, pr in rows:
        print(("FAIL %s (%s)" % (p, pr)) if pr else "OK   %s  [%s]" % (p, m["license_name"]))
        if "--credits" in sys.argv and not pr and m["license_name"].startswith("CC BY"):
            print("     credit: \"%s\" by %s (%s), %s" % (m["name"], m["username"], m["freesound_url"], m["license_name"]))
    print("%d sounds, %d problems" % (len(rows), bad))
    sys.exit(1 if bad or not rows else 0)
