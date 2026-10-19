"""Runs one Godot scene headless for a number of seconds and checks its output for errors (task T-196).

Usage, from the repo root:
    python game/tools/run_scene_headless.py <res://path/to/scene.tscn> [seconds, default 10]

GODOT_BIN comes from the environment, or from .env at the repo root (as game/tools/godot_env.sh).
The project is imported first (as game/tools/run_tests.sh). The scene runs with --headless for the given wall-clock seconds and is then stopped. Exit codes:
0 = it ran that long (or quit by itself) with no error lines; 1 = error lines in the output
(printed); 2 = bad arguments or no Godot.
"""

import os
import re
import subprocess
import sys

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
GAME_DIR = os.path.dirname(TOOLS_DIR)
REPO_ROOT = os.path.dirname(GAME_DIR)

# Lines Godot prints for errors and failed script loads.
ERROR_PATTERN = re.compile(r"(SCRIPT ERROR|USER ERROR|^ERROR:|Parse Error|Failed to load script)")
# How many error lines are printed at most.
MAX_SHOWN = 20


def godot_bin(env=None, env_file=None):
    """GODOT_BIN from the environment, else from the .env file's GODOT_BIN line, else None."""
    env = os.environ if env is None else env
    if env.get("GODOT_BIN"):
        return env["GODOT_BIN"]
    env_file = env_file or os.path.join(REPO_ROOT, ".env")
    if not os.path.isfile(env_file):
        return None
    value = None
    with open(env_file, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^\s*GODOT_BIN\s*=\s*(.*?)\s*$", line.rstrip("\r\n"))
            if m:
                value = m.group(1).strip().strip('"').strip("'")
    return value or None


def error_lines(output):
    """The lines of Godot's output that report an error."""
    return [line for line in output.splitlines() if ERROR_PATTERN.search(line.strip())]


def import_project(godot, seconds=300):
    """Imports the project first (as run_tests.sh), so the class cache and imported art exist."""
    try:
        subprocess.run([godot, "--headless", "--path", GAME_DIR, "--import"],
                       capture_output=True, text=True, timeout=seconds, errors="replace")
    except subprocess.TimeoutExpired:
        pass


def run(scene, seconds, godot):
    """Runs the scene; returns (output text, True if it was stopped at the time limit)."""
    import_project(godot)
    cmd = [godot, "--headless", "--path", GAME_DIR, scene]
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=seconds, errors="replace")
        return (p.stdout or "") + (p.stderr or ""), False
    except subprocess.TimeoutExpired as e:
        out = e.stdout or ""
        err = e.stderr or ""
        if isinstance(out, bytes):
            out = out.decode("utf-8", "replace")
        if isinstance(err, bytes):
            err = err.decode("utf-8", "replace")
        return out + err, True


def main(argv):
    if len(argv) < 2 or not argv[1].startswith("res://"):
        print(__doc__)
        return 2
    seconds = float(argv[2]) if len(argv) > 2 else 10.0
    godot = godot_bin()
    if not godot or not os.path.isfile(godot):
        print("GODOT_BIN is not set or does not exist (see README.md, 'Secrets and API keys').")
        return 2
    output, stopped = run(argv[1], seconds, godot)
    errors = error_lines(output)
    how = "stopped after %.0f s" % seconds if stopped else "quit by itself"
    if errors:
        print("%s: %s, %d error line(s):" % (argv[1], how, len(errors)))
        for line in errors[:MAX_SHOWN]:
            print("  " + line)
        if len(errors) > MAX_SHOWN:
            print("  ... and %d more" % (len(errors) - MAX_SHOWN))
        return 1
    print("%s: %s, no errors" % (argv[1], how))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
