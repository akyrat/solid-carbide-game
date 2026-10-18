"""Tests for the command line (run.py): `start` with the fixtures, `status`, and the runner's own commit.
Runs in temporary git repos with their own copy of the runner; FakeClaude only, no Claude calls."""

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

    def test_no_commit_during_a_merge(self):
        head = temp_repo.git(self.root, "rev-parse", "HEAD").strip()
        (self.root / ".git" / "MERGE_HEAD").write_text(head + "\n")   # what git leaves during a merge
        goal = run.start("Sample goal", self.root, FakeClaude(FIXTURES / "sample-goal.json"))
        self.assertEqual(goal.get("status"), "planned")
        self.assertEqual(temp_repo.git(self.root, "rev-parse", "HEAD").strip(), head, "nothing committed")

    def test_no_commit_off_master(self):
        temp_repo.git(self.root, "checkout", "-q", "-b", "task/T-999-elsewhere")
        head = temp_repo.git(self.root, "rev-parse", "HEAD").strip()
        run.start("Sample goal", self.root, FakeClaude(FIXTURES / "sample-goal.json"))
        self.assertEqual(temp_repo.git(self.root, "rev-parse", "HEAD").strip(), head)

    def test_commit_stages_only_the_goal_files(self):
        stray = self.root / "stray.txt"
        stray.write_text("someone else's work")
        temp_repo.git(self.root, "add", "stray.txt")
        run.start("Sample goal", self.root, FakeClaude(FIXTURES / "sample-goal.json"))
        self.assertNotIn("stray.txt", temp_repo.git(self.root, "log", "-1", "--name-only", "--format=%s"))
        self.assertIn("A  stray.txt", temp_repo.git(self.root, "status", "--porcelain"))

    def test_help_lists_the_commands(self):
        code, out = self.cli("--help")
        self.assertEqual(code, 0)
        self.assertIn("start", out)
        self.assertIn("status", out)


if __name__ == "__main__":
    unittest.main()
