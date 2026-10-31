"""Publish a browser build of master to the board's private itch.io page (T-448).

The Project Lead runs this only when the board asks ("push the latest build to itch"),
from the main checkout on master:

    python tools/publish_itch.py [--dry-run] [--repo DIR] [--butler PATH] [--godot PATH]

What it does, in order:
  1. Checks DIR (default: the repo this script is in) is on branch master, has a clean tree
     (line-ending-only noise in tracked files, like Godot's .import files, and Godot's untracked
     .uid and .import files, and untracked files under game/data/levels/, the board's own level
     files, are ignored; the Web preset leaves that folder out of the build) and has
     no merge in progress.
  2. Without --dry-run, checks .env has BUTLER_API_KEY and ITCH_TARGET (`<user>/<game>:html5`, here `jerry-of-rivia/solid-carbide:html5`)
     and that butler exists; if not, it stops and names what is missing. Nothing is exported.
  3. Exports the "Web" preset of game/export_presets.cfg (release, thread support off, so
     itch.io needs no SharedArrayBuffer) into <repo>/web-build/ (git-ignored), and checks the
     export made index.html, a .wasm and a .pck.
  4. Runs `butler push <build folder> <ITCH_TARGET> --userversion <short master commit>`
     and prints the version and the page link. --dry-run does everything except this push and
     only prints the command.

Setup: GODOT_BIN, BUTLER_API_KEY and ITCH_TARGET come from .env at the repo root (secrets only
there; the key is handed to butler through its environment and is never printed). butler is
looked for at --butler, then $BUTLER_BIN, then tools/bin/butler(.exe) (git-ignored), then PATH.
Godot's Web export templates for 4.6.2 must be installed (%APPDATA%/Godot/export_templates/).
No tests run (master is already tested). The itch page's settings (password, visibility)
are never touched.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

DEFAULT_REPO = Path(__file__).resolve().parent.parent
PRESET = "Web"
BUILD_DIR = "web-build"
BOARD_LEVELS = "game/data/levels/"  # the board's level files (T-471); the game's map is game/data/level/


class PublishError(Exception):
    pass


def git(repo, *args):
    return subprocess.run(["git", *args], cwd=str(repo), capture_output=True, text=True)


def read_env(repo):
    """The values from <repo>/.env (and the process environment for the keys we use)."""
    values = {}
    path = Path(repo) / ".env"
    if path.is_file():
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            m = re.match(r"\s*([A-Z_]+)\s*=\s*(.*?)\s*$", line)
            if m:
                v = m.group(2)
                if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
                    v = v[1:-1]
                values[m.group(1)] = v
    for k in ("BUTLER_API_KEY", "ITCH_TARGET", "GODOT_BIN"):
        if os.environ.get(k):
            values[k] = os.environ[k]
    return values


def check_repo(repo):
    """Raises PublishError unless the repo is on master, clean, with no merge in progress."""
    branch = git(repo, "rev-parse", "--abbrev-ref", "HEAD")
    if branch.returncode != 0:
        raise PublishError(f"{repo} is not a git repository")
    if branch.stdout.strip() != "master":
        raise PublishError(f"not on master (on '{branch.stdout.strip()}'): publish only master")
    if git(repo, "rev-parse", "-q", "--verify", "MERGE_HEAD").returncode == 0:
        raise PublishError("a merge is in progress: finish or abort it first")
    dirty = []
    for line in git(repo, "status", "--porcelain", "-uall").stdout.splitlines():
        if not line.strip():
            continue
        name = line[3:].strip().strip('"')
        if line.startswith("??"):
            if name.endswith((".uid", ".import")):
                continue  # Godot writes these on every import
            if name.startswith(BOARD_LEVELS):
                continue  # the board's own level files: never committed, never published, never read
            dirty.append(line)
        elif line[0] == " " and git(repo, "diff", "--ignore-cr-at-eol", "--quiet", "--", name).returncode == 0:
            continue  # line-ending-only noise in an unstaged file
        else:
            dirty.append(line)
    if dirty:
        raise PublishError("uncommitted changes: " + "; ".join(dirty[:5]))
    return git(repo, "rev-parse", "--short", "HEAD").stdout.strip()


def find_butler(repo, explicit=None):
    candidates = [explicit, os.environ.get("BUTLER_BIN"),
                  Path(repo) / "tools" / "bin" / "butler.exe", Path(repo) / "tools" / "bin" / "butler"]
    for c in candidates:
        if c and Path(c).is_file():
            return str(c)
    return shutil.which("butler")


def check_settings(env, butler):
    missing = [k for k in ("BUTLER_API_KEY", "ITCH_TARGET") if not env.get(k)]
    if butler is None:
        missing.append("butler (install it into tools/bin/ or pass --butler)")
    if missing:
        raise PublishError("cannot push, missing: " + ", ".join(missing))


def export_web(repo, godot):
    """Exports the Web preset of master's game/ into <repo>/web-build/ and returns that folder."""
    out = Path(repo) / BUILD_DIR
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    game = str(Path(repo) / "game")
    subprocess.run([godot, "--headless", "--path", game, "--import"], capture_output=True, text=True,
                   timeout=900)
    r = subprocess.run([godot, "--headless", "--path", game, "--export-release", PRESET,
                        str(out / "index.html")], capture_output=True, text=True, timeout=1800)
    if r.returncode != 0:
        raise PublishError("Godot export failed:\n" + (r.stdout + r.stderr)[-1500:])
    return out


def check_build(folder):
    folder = Path(folder)
    names = [p.name for p in folder.iterdir()] if folder.is_dir() else []
    missing = []
    if "index.html" not in names:
        missing.append("index.html")
    if not any(n.endswith(".wasm") for n in names):
        missing.append("a .wasm file")
    if not any(n.endswith(".pck") for n in names):
        missing.append("a .pck file")
    if missing:
        raise PublishError("the export is missing " + ", ".join(missing))
    return sorted(names)


def butler_command(butler, folder, target, version):
    return [butler, "push", str(folder), target, "--userversion", version]


def page_link(target):
    user, _, rest = target.partition("/")
    game = rest.split(":")[0]
    return f"https://{user}.itch.io/{game}"


def redact(text, key):
    return text.replace(key, "***") if key else text


def run(argv, out=print, exporter=export_web):
    ap = argparse.ArgumentParser(description="Publish a browser build of master to itch.io.")
    ap.add_argument("--dry-run", action="store_true", help="do everything except the push")
    ap.add_argument("--repo", default=str(DEFAULT_REPO), help="the checkout to publish (default: this one)")
    ap.add_argument("--butler", help="path to butler")
    ap.add_argument("--godot", help="path to the Godot editor (default: GODOT_BIN from .env)")
    args = ap.parse_args(argv)
    repo = Path(args.repo).resolve()
    try:
        version = check_repo(repo)
        env = read_env(repo)
        butler = find_butler(repo, args.butler)
        if args.dry_run:
            for k in ("BUTLER_API_KEY", "ITCH_TARGET"):
                if not env.get(k):
                    out(f"note: {k} is not set (needed for a real push)")
        else:
            check_settings(env, butler)
        godot = args.godot or env.get("GODOT_BIN")
        if not godot or not Path(godot).is_file():
            raise PublishError("GODOT_BIN is not set in .env (or points to nothing)")
        folder = exporter(repo, godot)
        names = check_build(folder)
        out(f"Build ready in {folder}: {', '.join(names)}")
        target = env.get("ITCH_TARGET") or "<user>/<game>:html5"
        cmd = butler_command(butler or "butler", folder, target, version)
        if args.dry_run:
            out("Dry run, would run: " + " ".join(cmd))
            return 0
        sub_env = dict(os.environ, BUTLER_API_KEY=env["BUTLER_API_KEY"])
        r = subprocess.run(cmd, env=sub_env, capture_output=True, text=True)
        out(redact(r.stdout + r.stderr, env["BUTLER_API_KEY"]).rstrip())
        if r.returncode != 0:
            raise PublishError(f"butler push failed (exit {r.returncode})")
        out(f"Pushed version {version}. Page: {page_link(target)}")
        return 0
    except PublishError as e:
        out(f"STOPPED: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(run(sys.argv[1:]))
