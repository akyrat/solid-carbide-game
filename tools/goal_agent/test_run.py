"""Tests for the command line (run.py): `start` with the fixtures, `status`, and the runner's own commit.
Runs in temporary git repos with their own copy of the runner; FakeClaude only, no Claude calls."""

import contextlib
import io
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import taskboard_sync as tb  # noqa: E402
from goal_agent import goal_file, run, temp_repo  # noqa: E402
from goal_agent.claude_call import FakeClaude  # noqa: E402

FIXTURES = Path(__file__).resolve().parent / "fixtures"


class Start(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = temp_repo.make(self.tmp.name)
        # the sample fixture names T-161 (covered) and T-163 (in flight), as in the real repo
        temp_repo.add_ticket(self.root, "T-161", status="done", title="Guard false refusals")
        temp_repo.add_ticket(self.root, "T-163", status="open", title="Goal runner, part 2")
        temp_repo.git(self.root, "add", "-A")
        temp_repo.git(self.root, "commit", "-q", "-m", "T-161, T-163: tickets")

    def tearDown(self):
        self.tmp.cleanup()

    def cli(self, *args):
        done = subprocess.run([sys.executable, str(self.root / "tools" / "goal_agent" / "run.py"), *args],
                              cwd=str(self.root), capture_output=True, text=True, encoding="utf-8")
        return done.returncode, done.stdout + done.stderr

    def test_start_with_the_sample_fixture(self):
        code, out = self.cli("start", "Sample goal", "--plan-only", "--fake", "tools/goal_agent/fixtures/sample-goal.json")
        self.assertEqual(code, 0, out)
        goal = goal_file.find(self.root / "goals", "G-001")
        self.assertEqual(goal.get("status"), "planned")
        rows = goal_file.read_table(goal.section("Sub-goals"))
        self.assertEqual([r["id"] for r in rows], ["S1", "S2", "S3", "S4", "S5"])
        self.assertEqual([r["verdict"] for r in rows], ["missing", "missing", "missing", "in-flight", "covered"])
        self.assertEqual(rows[3]["tickets"], "T-163")
        self.assertIn("Ranked by code", goal.section("Scoring"))
        new = sorted((self.root / "tasks").glob("T-16[4-9]-*.md"))
        self.assertEqual([p.name[:5] for p in new], ["T-164", "T-165", "T-166"])
        for p in new:
            fields = tb.parse_header(p.read_text(encoding="utf-8"))
            self.assertEqual((fields["goal"], fields["lead"]), ("G-001", "Goal-G-001"))
        self.assertEqual(tb.parse_header((self.root / "tasks" / "T-163-ticket.md").read_text(encoding="utf-8"))["goal"],
                         "G-001", "the in-flight ticket is reused, not rewritten")
        # committed on master, only the goal's files, and nothing left over
        log = temp_repo.git(self.root, "log", "-1", "--name-only", "--format=%s")
        self.assertIn("G-001: planned", log)
        for name in ["goals/G-001-sample-goal.md", "tasks/T-163-ticket.md"] + [f"tasks/{p.name}" for p in new]:
            self.assertIn(name, log)
        self.assertEqual(temp_repo.git(self.root, "status", "--porcelain"), "")
        code, out = self.cli("status", "G-001")
        self.assertEqual(code, 0, out)
        self.assertIn("G-001: planned", out)
        self.assertIn("S3 Sample screen [missing] T-166", out)
        self.assertIn("T-166 [blocked]", out)
        self.assertIn("T-164 [open]", out)
        self.assertIn("T-163 [open]", out)

    def test_refused_twice_pauses_the_goal(self):
        code, out = self.cli("start", "Sample goal", "--fake", "tools/goal_agent/fixtures/refused-twice.json")
        self.assertEqual(code, 1, out)
        goal = goal_file.find(self.root / "goals", "G-001")
        self.assertEqual(goal.get("status"), "paused")
        self.assertIn("refused twice", goal.section("Pauses"))
        self.assertIn("not an agent", goal.section("Pauses"))
        self.assertEqual(list((self.root / "tasks").glob("T-164-*.md")), [], "no ticket written")
        self.assertIn("G-001: paused", temp_repo.git(self.root, "log", "-1", "--format=%s"))

    def start(self, claude, **kw):
        """run.start with its printed lines captured: (goal, output). Test output never shows a commit message."""
        with contextlib.redirect_stdout(io.StringIO()) as out:
            goal = run.start("Sample goal", self.root, claude, **kw)
        return goal, out.getvalue()

    def test_no_commit_during_a_merge(self):
        head = temp_repo.git(self.root, "rev-parse", "HEAD").strip()
        (self.root / ".git" / "MERGE_HEAD").write_text(head + "\n")   # what git leaves during a merge
        goal, out = self.start(FakeClaude(FIXTURES / "sample-goal.json"))
        self.assertEqual(goal.get("status"), "planned")
        self.assertEqual(temp_repo.git(self.root, "rev-parse", "HEAD").strip(), head, "nothing committed")
        self.assertIn("Not committed: a merge is in progress", out)
        self.assertIn(f"[test repository {self.root.resolve()}]", out)

    def test_start_passes_the_new_goals_id_to_the_planner(self):
        claude = FakeClaude(FIXTURES / "sample-goal.json")
        goal, _ = self.start(claude, commit=False)
        step, text, _ = claude.calls[0]
        self.assertEqual((step, goal.id), ("plan", "G-001"))
        self.assertIn("G-001", text)
        self.assertIn("playtest/G-001", text)

    def test_no_commit_off_master(self):
        temp_repo.git(self.root, "checkout", "-q", "-b", "task/T-999-elsewhere")
        head = temp_repo.git(self.root, "rev-parse", "HEAD").strip()
        _, out = self.start(FakeClaude(FIXTURES / "sample-goal.json"))
        self.assertEqual(temp_repo.git(self.root, "rev-parse", "HEAD").strip(), head)
        self.assertIn("not master", out)

    def test_commit_stages_only_the_goal_files(self):
        stray = self.root / "stray.txt"
        stray.write_text("someone else's work")
        temp_repo.git(self.root, "add", "stray.txt")
        _, out = self.start(FakeClaude(FIXTURES / "sample-goal.json"))
        self.assertEqual(out.strip(), f'Committed on master: G-001: planned, "Sample goal" (goal runner) '
                                      f"[test repository {self.root.resolve()}]")
        self.assertNotIn("stray.txt", temp_repo.git(self.root, "log", "-1", "--name-only", "--format=%s"))
        self.assertIn("A  stray.txt", temp_repo.git(self.root, "status", "--porcelain"))

    def test_start_records_the_session_that_starts_the_run(self):
        goal, _ = self.start(FakeClaude(FIXTURES / "sample-goal.json"), commit=False, session="Coursework")
        self.assertEqual(goal_file.find(self.root / "goals", "G-001").get("session"), "Coursework")
        self.assertIn("by the session Coursework", goal.section("Iteration log"))
        code, out = self.cli("start", "Sample goal", "--plan-only", "--session", "two words", "--fake",
                             "tools/goal_agent/fixtures/sample-goal.json")
        self.assertEqual(code, 2, out)
        self.assertIn("--session needs a session name", out)

    def test_a_test_repository_is_never_made_inside_the_real_one(self):
        with self.assertRaises(RuntimeError):
            temp_repo.make(temp_repo.REAL / "tmp-test-repo")
        self.assertFalse((temp_repo.REAL / "tmp-test-repo").exists())

    def test_help_lists_the_commands(self):
        code, out = self.cli("--help")
        self.assertEqual(code, 0)
        self.assertIn("start", out)
        self.assertIn("status", out)
        self.assertIn("resume", out)
        self.assertIn("{start,resume,status}", out)


class WholeRun(unittest.TestCase):
    """The command line through all four layers (T-163): start carries on into the loop, then status and resume."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = temp_repo.make(Path(self.tmp.name) / "repo")
        self.worktrees = str(Path(self.tmp.name) / "worktrees")

    def tearDown(self):
        self.tmp.cleanup()

    def cli(self, *args):
        done = subprocess.run([sys.executable, str(self.root / "tools" / "goal_agent" / "run.py"), *args,
                               "--worktrees", self.worktrees],
                              cwd=str(self.root), capture_output=True, text=True, encoding="utf-8")
        return done.returncode, done.stdout + done.stderr

    def test_start_builds_the_goal_and_status_shows_it(self):
        code, out = self.cli("start", "Sample goal", "--fake", "tools/goal_agent/fixtures/whole-goal.json")
        self.assertEqual(code, 0, out)
        self.assertIn("G-001 is ready to play", out)
        self.assertIn("G-001: ready-to-play", out)
        code, out = self.cli("status", "G-001")
        self.assertEqual(code, 0, out)
        self.assertIn("G-001: ready-to-play, \"Sample goal\" (iteration 2 of 20, art 0 of 0)", out)
        self.assertIn("Build: playtest/G-001 in", out)
        self.assertIn("T-002 [needs-playtest]", out)
        code, out = self.cli("resume", "G-001")
        self.assertIn("nothing to resume", out)

    def test_a_paused_goal_shows_its_pause_and_stays_paused_on_resume(self):
        code, out = self.cli("start", "Sample goal", "--max-iterations", "1", "--fake",
                             "tools/goal_agent/fixtures/whole-goal.json")
        self.assertEqual(code, 1, out)
        self.assertIn("G-001 paused (the goal reached its iteration cap)", out)
        code, out = self.cli("status", "G-001")
        self.assertIn("iteration 1 of 1", out)
        self.assertIn("Pauses (last: max-iterations", out)
        code, out = self.cli("resume", "G-001", "--fake", "tools/goal_agent/fixtures/whole-goal.json")
        self.assertEqual(code, 1, out)
        self.assertIn("stays paused", out)
        self.assertIsNone(goal_file.find(self.root / "goals", "G-001").get("session"), "a run that didn't resume")
        code, out = self.cli("resume", "G-001", "--force", "--session", "Coursework", "--fake",
                             "tools/goal_agent/fixtures/whole-goal.json")
        goal = goal_file.find(self.root / "goals", "G-001")
        self.assertEqual(goal.get("session"), "Coursework", out)
        self.assertIn("resumed by the session Coursework", goal.section("Iteration log"))


if __name__ == "__main__":
    unittest.main()
