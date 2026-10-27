"""Tests for tools/merge_batch.py, on throwaway repos only (never the real checkout)."""

import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent / "goal_agent"))
import merge_batch as mb  # noqa: E402
import temp_repo  # noqa: E402

PASS = [f'"{sys.executable}" -c "import sys; sys.exit(0)"']
FAIL = [f'"{sys.executable}" -c "import sys; sys.exit(1)"']


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(text.encode("utf-8"))


class MergeBatchTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        base = Path(self.tmp.name)
        self.root = temp_repo.make(base / "repo")
        self.wts = base / "wts"
        self.log = base / "merge.log"
        # tasks/ in the temp repo holds the template and README; add the timeline
        write(self.root / "docs" / "timeline.md", "# Timeline\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "timeline")

    def git(self, *a, cwd=None):
        return temp_repo.git(cwd or self.root, *a)

    def ticket(self, tid, files, base_status="needs-playtest"):
        """A branch task/T-NNN-ticket with a worktree, its ticket file and `files` ({path: text}) committed."""
        path = temp_repo.add_ticket(self.root, tid, status=base_status)
        self.git("add", "-A")
        self.git("commit", "-q", "-m", f"{tid} ticket")
        wt = self.wts / tid
        self.git("worktree", "add", "-q", "-b", f"task/{tid}-ticket", str(wt))
        for rel, text in files.items():
            write(wt / rel, text)
        self.git("add", "-A", cwd=wt)
        self.git("commit", "-q", "-m", f"{tid} work", cwd=wt)
        return wt

    def run_batch(self, *args, tests=PASS):
        argv = [*args, "--root", str(self.root), "--log", str(self.log)]
        for t in tests:
            argv += ["--test-cmd", t]
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = mb.main(argv)
        return code, out.getvalue().splitlines()

    def head_count(self):
        return int(self.git("rev-list", "--count", "HEAD").strip())

    def clean(self):
        merge_head = (self.root / ".git" / "MERGE_HEAD").exists()
        return not merge_head and not self.git("status", "--porcelain", "--untracked-files=no").strip()

    def test_clean_batch_of_two(self):
        w1 = self.ticket("T-901", {"game/scripts/a.gd": "a\n"})
        w2 = self.ticket("T-902", {"game/scripts/b.gd": "b\n"})
        before = self.head_count()
        code, lines = self.run_batch("T-901", "T-902", "--note", "T-901=played, fine", "--entry", "T-902=Did b.")
        self.assertEqual(code, 0, lines)
        self.assertEqual([l for l in lines if l.startswith("T-9")], ["T-901: merged", "T-902: merged"])
        self.assertTrue((self.root / "game/scripts/a.gd").exists() and (self.root / "game/scripts/b.gd").exists())
        for tid in ("T-901", "T-902"):
            text = next((self.root / "tasks").glob(f"{tid}-*.md")).read_text(encoding="utf-8")
            self.assertIn("status: done", text)
        self.assertIn("played, fine", (self.root / "tasks" / "T-901-ticket.md").read_text(encoding="utf-8"))
        timeline = (self.root / "docs" / "timeline.md").read_text(encoding="utf-8")
        self.assertIn("- Tasks: T-901", timeline)
        self.assertIn("Did b.", timeline)
        self.assertFalse(w1.exists() or w2.exists())
        self.assertEqual(self.git("branch", "--list", "task/*").strip(), "")
        self.assertTrue(self.clean())
        self.assertGreater(self.head_count(), before + 3)   # each ticket: its work, the merge, and more
        self.assertIn("Full log:", lines[-1])
        self.assertTrue(self.log.exists())

    def test_conflict_stops_and_master_stays_clean(self):
        w3 = self.ticket("T-903", {"game/scripts/c.gd": "branch\n"})
        tip3 = self.git("rev-parse", "task/T-903-ticket").strip()
        write(self.root / "game/scripts/c.gd", "master\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "master edit")
        head = self.git("rev-parse", "HEAD").strip()
        w2 = self.ticket("T-904", {"game/scripts/d.gd": "d\n"})
        head = self.git("rev-parse", "HEAD").strip()
        code, lines = self.run_batch("T-903", "T-904")
        self.assertEqual(code, 1)
        self.assertRegex(lines[0], r"^T-903: stopped: merge conflict in game/scripts/c.gd")
        self.assertTrue(self.clean())
        self.assertEqual(self.git("rev-parse", "task/T-903-ticket").strip(), tip3)   # not left marked done
        self.assertIn("status: needs-playtest", (w3 / "tasks" / "T-903-ticket.md").read_text(encoding="utf-8"))
        self.assertEqual(self.git("rev-parse", "HEAD").strip(), head if lines[1].startswith("T-904: stopped") else self.git("rev-parse", "HEAD").strip())
        # master was clean, so the batch went on to the next ticket
        self.assertEqual(lines[1], "T-904: merged")
        self.assertFalse(w2.exists())
        self.assertTrue((self.root / "game/scripts/d.gd").exists())
        self.assertEqual(self.git("show", "HEAD:game/scripts/c.gd"), "master\n")

    def test_red_test_stops_before_commit(self):
        w = self.ticket("T-905", {"game/scripts/e.gd": "e\n"})
        head = self.git("rev-parse", "HEAD").strip()
        tip = self.git("rev-parse", "task/T-905-ticket").strip()
        code, lines = self.run_batch("T-905", tests=FAIL)
        self.assertEqual(code, 1)
        self.assertRegex(lines[0], r"^T-905: stopped: test failed")
        self.assertEqual(self.git("rev-parse", "HEAD").strip(), head)
        self.assertTrue(self.clean())
        self.assertFalse((self.root / "game/scripts/e.gd").exists())
        self.assertNotIn("T-905", (self.root / "docs" / "timeline.md").read_text(encoding="utf-8"))
        self.assertEqual(self.git("rev-parse", "task/T-905-ticket").strip(), tip)   # our done commit is gone
        self.assertIn("status: needs-playtest", (w / "tasks" / "T-905-ticket.md").read_text(encoding="utf-8"))
        self.assertEqual(self.git("status", "--porcelain", "--untracked-files=no", cwd=w).strip(), "")
        self.assertTrue(w.exists())   # worktree and branch are kept for the agent
        self.assertIn("task/T-905-ticket", self.git("branch", "--list", "task/*"))

    def test_never_commits_while_another_merge_is_in_progress(self):
        self.ticket("T-906", {"game/scripts/f.gd": "f\n"})
        other = self.ticket("T-907", {"game/scripts/g.gd": "g\n"})
        self.git("checkout", "-q", "-b", "side")
        write(self.root / "game/scripts/g.gd", "x\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "side")
        self.git("checkout", "-q", "master")
        self.git("merge", "--no-ff", "--no-commit", "side")   # another instance's merge
        self.assertTrue((self.root / ".git" / "MERGE_HEAD").exists())
        head = self.git("rev-parse", "HEAD").strip()
        code, lines = self.run_batch("T-906")
        self.assertEqual(code, 1)
        self.assertIn("merge is already in progress", lines[0])
        self.assertIn("master is not clean", lines[1])
        self.assertEqual(self.git("rev-parse", "HEAD").strip(), head)
        self.assertTrue((self.root / ".git" / "MERGE_HEAD").exists())   # left alone
        self.assertFalse((self.root / "game/scripts/f.gd").exists())
        self.assertTrue(other.exists())

    def test_stages_only_its_own_files(self):
        self.ticket("T-908", {"game/scripts/h.gd": "h\n"})
        write(self.root / "game/scripts/car.gd", "extends Node\n# someone else's edit\n")   # tracked, unrelated
        code, lines = self.run_batch("T-908")
        self.assertEqual(code, 0, lines)
        changed = self.git("diff", "--name-only", "HEAD~1", "HEAD").split()
        self.assertNotIn("game/scripts/car.gd", changed)
        self.assertIn("game/scripts/h.gd", changed)
        self.assertEqual(self.git("status", "--porcelain", "--untracked-files=no").strip(), "M game/scripts/car.gd")
        self.assertIn("someone else's edit", (self.root / "game/scripts/car.gd").read_text(encoding="utf-8"))

    def test_line_ending_only_import_noise_is_reverted(self):
        write(self.root / "game/art/x.png.import", "a=1\nb=2\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "import")
        self.ticket("T-909", {"game/scripts/i.gd": "i\n"})
        write(self.root / "game/art/x.png.import", "a=1\r\nb=2\r\n")
        code, lines = self.run_batch("T-909")
        self.assertEqual(code, 0, lines)
        self.assertTrue(self.clean())

    def test_refused_done_stops_ticket(self):
        self.ticket("T-910", {"game/scripts/j.gd": "j\n"}, base_status="in-progress")
        code, lines = self.run_batch("T-910")
        self.assertEqual(code, 1)
        self.assertIn("task_status refused", lines[0])
        self.assertTrue(self.clean())


if __name__ == "__main__":
    unittest.main()
