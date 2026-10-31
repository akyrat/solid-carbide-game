import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import publish_itch as p  # noqa: E402

KEY = "SECRETKEY123"


def git(repo, *a):
    subprocess.run(["git", *a], cwd=str(repo), check=True, capture_output=True)


def make_repo(tmp, branch="master"):
    git(tmp, "init", "-q", "-b", branch)
    git(tmp, "config", "user.email", "t@t")
    git(tmp, "config", "user.name", "t")
    git(tmp, "config", "commit.gpgsign", "false")
    git(tmp, "config", "core.autocrlf", "false")
    (Path(tmp) / "a.txt").write_text("a\n")
    git(tmp, "add", "a.txt")
    git(tmp, "commit", "-q", "-m", "init")
    return Path(tmp)


def fake_exporter(repo, godot):
    out = Path(repo) / "web-build"
    out.mkdir(exist_ok=True)
    for n in ("index.html", "index.wasm", "index.pck"):
        (out / n).write_text("x")
    return out


class RepoChecks(unittest.TestCase):
    def setUp(self):
        self.d = tempfile.TemporaryDirectory()
        self.repo = make_repo(self.d.name)

    def tearDown(self):
        self.d.cleanup()

    def test_clean_master_returns_short_commit(self):
        self.assertRegex(p.check_repo(self.repo), r"^[0-9a-f]{7,}$")

    def test_refuses_off_master(self):
        git(self.repo, "checkout", "-q", "-b", "other")
        with self.assertRaisesRegex(p.PublishError, "not on master"):
            p.check_repo(self.repo)

    def test_refuses_uncommitted_change(self):
        (self.repo / "a.txt").write_text("changed\n")
        with self.assertRaisesRegex(p.PublishError, "uncommitted"):
            p.check_repo(self.repo)

    def test_refuses_untracked_file(self):
        (self.repo / "new.txt").write_text("n")
        with self.assertRaises(p.PublishError):
            p.check_repo(self.repo)

    def test_ignores_godot_uid_files(self):
        (self.repo / "x.gd.uid").write_text("uid://abc")
        (self.repo / "y.png.import").write_text("i")
        p.check_repo(self.repo)

    def test_ignores_line_ending_only_noise(self):
        (self.repo / "a.txt").write_bytes(b"a\r\n")
        p.check_repo(self.repo)

    def test_refuses_merge_in_progress(self):
        git(self.repo, "checkout", "-q", "-b", "side")
        (self.repo / "a.txt").write_text("side\n")
        git(self.repo, "commit", "-q", "-am", "side")
        git(self.repo, "checkout", "-q", "master")
        (self.repo / "a.txt").write_text("master\n")
        git(self.repo, "commit", "-q", "-am", "master")
        subprocess.run(["git", "merge", "side"], cwd=str(self.repo), capture_output=True)
        with self.assertRaisesRegex(p.PublishError, "merge"):
            p.check_repo(self.repo)


class Settings(unittest.TestCase):
    def test_missing_key_and_target_named(self):
        with self.assertRaises(p.PublishError) as c:
            p.check_settings({}, "butler")
        self.assertIn("BUTLER_API_KEY", str(c.exception))
        self.assertIn("ITCH_TARGET", str(c.exception))

    def test_missing_only_target(self):
        with self.assertRaises(p.PublishError) as c:
            p.check_settings({"BUTLER_API_KEY": "k"}, "butler")
        self.assertIn("ITCH_TARGET", str(c.exception))
        self.assertNotIn("BUTLER_API_KEY", str(c.exception))

    def test_command_and_link(self):
        self.assertEqual(p.butler_command("b", "dir", "me/game:html5", "abc1234"),
                         ["b", "push", "dir", "me/game:html5", "--userversion", "abc1234"])
        self.assertEqual(p.page_link("me/game:html5"), "https://me.itch.io/game")

    def test_check_build(self):
        with tempfile.TemporaryDirectory() as d:
            (Path(d) / "index.html").write_text("x")
            with self.assertRaisesRegex(p.PublishError, r"\.wasm"):
                p.check_build(d)


class FullRun(unittest.TestCase):
    def setUp(self):
        for k in ("BUTLER_API_KEY", "ITCH_TARGET", "GODOT_BIN"):
            os.environ.pop(k, None)
        self.d = tempfile.TemporaryDirectory()
        self.repo = make_repo(self.d.name)
        (self.repo / ".gitignore").write_text("web-build/\n.env\nstub*\nbutler.*\n")
        (self.repo / ".env").write_text(
            f"BUTLER_API_KEY={KEY}\nITCH_TARGET=me/game:html5\nGODOT_BIN={sys.executable}\n")
        git(self.repo, "add", ".gitignore")
        git(self.repo, "commit", "-q", "-m", "ignore")
        # a stub "butler" that echoes its arguments and the key it received
        stub = self.repo / "stubbutler.py"
        stub.write_text("import os,sys\nprint(' '.join(sys.argv[1:]))\n"
                        "print('key:'+os.environ['BUTLER_API_KEY'])\n")
        if os.name == "nt":
            self.bat = self.repo / "butler.bat"
            self.bat.write_text(f'@"{sys.executable}" "{stub}" %*\n')
        else:
            self.bat = self.repo / "butler.sh"
            self.bat.write_text(f'#!/bin/sh\nexec "{sys.executable}" "{stub}" "$@"\n')
            self.bat.chmod(0o755)

    def tearDown(self):
        self.d.cleanup()

    def go(self, *extra):
        lines = []
        code = p.run(["--repo", str(self.repo), "--butler", str(self.bat), *extra],
                     out=lines.append, exporter=fake_exporter)
        return code, "\n".join(lines)

    def test_dry_run_does_not_push(self):
        code, out = self.go("--dry-run")
        self.assertEqual(code, 0)
        self.assertIn("Dry run, would run", out)
        self.assertNotIn("key:", out)
        self.assertNotIn(KEY, out)

    def test_push_runs_exact_command_and_hides_key(self):
        code, out = self.go()
        self.assertEqual(code, 0, out)
        version = p.check_repo(self.repo)
        folder = (self.repo / "web-build").resolve()
        self.assertIn(f"push {folder} me/game:html5 --userversion {version}", out)
        self.assertNotIn(KEY, out)
        self.assertIn("key:***", out)
        self.assertIn("https://me.itch.io/game", out)

    def test_missing_key_stops_before_export(self):
        (self.repo / ".env").write_text("ITCH_TARGET=me/game:html5\n")
        called = []
        lines = []
        code = p.run(["--repo", str(self.repo), "--butler", str(self.bat)], out=lines.append,
                     exporter=lambda *a: called.append(1))
        self.assertEqual(code, 1)
        self.assertIn("BUTLER_API_KEY", "\n".join(lines))
        self.assertFalse(called)

    def test_off_master_stops(self):
        git(self.repo, "checkout", "-q", "-b", "feature")
        code, out = self.go("--dry-run")
        self.assertEqual(code, 1)
        self.assertIn("not on master", out)


if __name__ == "__main__":
    unittest.main()
