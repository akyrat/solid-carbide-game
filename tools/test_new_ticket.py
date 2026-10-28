"""Tests for new_ticket.py, on throwaway git repos only. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
REPO = TOOLS.parent
sys.path.insert(0, str(TOOLS))

import new_ticket as nt  # noqa: E402
import taskboard_sync as tb  # noqa: E402

CRITERIA = ["It works.", "It is described in tasks/README.md."]


def sh(root, *args):
    return subprocess.run(args, cwd=root, capture_output=True, text=True, encoding="utf-8", check=True).stdout


def make_repo(with_docs=False):
    """A throwaway repo with a copy of the tools, the template, a timeline and one old ticket."""
    root = Path(tempfile.mkdtemp(prefix="newticket-"))
    (root / "tools").mkdir()
    for p in TOOLS.glob("*.py"):
        shutil.copy(p, root / "tools" / p.name)
    (root / "tasks").mkdir()
    shutil.copy(REPO / "tasks/_TEMPLATE.md", root / "tasks/_TEMPLATE.md")
    (root / "docs").mkdir()
    if with_docs:
        for p in (REPO / "docs").glob("*.md"):
            if p.name != "timeline.md":
                shutil.copy(p, root / "docs" / p.name)
        (root / "docs/short-gdd").mkdir()
        shutil.copy(REPO / "docs/short-gdd/README.md", root / "docs/short-gdd/README.md")
    (root / "docs/timeline.md").write_text("# Timeline\n\n## 2026-01-01: Old\n- Tasks: T-040\n", encoding="utf-8")
    old = (root / "tasks/_TEMPLATE.md").read_text(encoding="utf-8").replace("T-000", "T-041").replace("Short, specific title", "Old")
    (root / "tasks/T-041-old.md").write_text(old, encoding="utf-8")
    (root / ".gitignore").write_text(".board/\n__pycache__/\n", encoding="utf-8")
    for cmd in (["init", "-q", "-b", "master"], ["config", "user.name", "t"], ["config", "user.email", "t@t"]):
        sh(root, "git", *cmd)
    sh(root, "git", "add", "-A")
    sh(root, "git", "commit", "-q", "-m", "T-043: a commit that mentions a higher number")
    return root


def ticket(n):
    return {"title": f"Ticket {n}", "slug": f"ticket-{n}", "description": f"Do thing {n}.", "criteria": CRITERIA,
            "epic": "token-spend", "documents_affected": ["tasks/README.md"],
            "files_expected_to_change": ["tools/x.py"],
            "timeline": {"title": f"Thing {n}", "decision": f"The board wants thing {n}.", "documents": ["tasks/README.md"]}}


def spec(n=2, **extra):
    s = {"lead": "Tokens", "commit_message": "T-044, T-045: tickets", "date": "2026-10-28",
         "common_criteria": ["All tests pass."], "tickets": [ticket(i) for i in range(1, n + 1)]}
    s.update(extra)
    return s


class NewTicketTests(unittest.TestCase):
    def setUp(self):
        self.root = make_repo()
        self.addCleanup(shutil.rmtree, self.root, True)

    def test_two_tickets_one_commit(self):
        lines = nt.run(spec(), self.root)
        self.assertEqual(len(lines), 2)
        self.assertTrue(lines[0].startswith("T-044 ") and lines[1].startswith("T-045 "))
        self.assertEqual(sh(self.root, "git", "rev-list", "--count", "HEAD").strip(), "2")
        files = sorted(sh(self.root, "git", "show", "--name-only", "--format=", "HEAD").split())
        self.assertEqual(files, ["docs/timeline.md", "tasks/T-044-ticket-1.md", "tasks/T-045-ticket-2.md"])
        self.assertEqual(sh(self.root, "git", "status", "--porcelain").strip(), "")
        template = (self.root / "tasks/_TEMPLATE.md").read_text(encoding="utf-8")
        for n, slug in ((44, "ticket-1"), (45, "ticket-2")):
            text = (self.root / f"tasks/T-0{n}-{slug}.md").read_text(encoding="utf-8")
            fields = tb.parse_header(text)
            self.assertEqual(fields["id"], f"T-0{n}")
            self.assertEqual(fields["lead"], "Tokens")
            self.assertEqual(fields["status"], "open")
            self.assertEqual(fields["epic"], "token-spend")
            self.assertEqual(fields["documents_affected"], ["tasks/README.md"])
            for part in (template[template.index("<!--"):template.index("-->") + 3],
                         "## Description", "## Acceptance criteria", "## Updates", "## Style review", "## Result notes",
                         "- [ ] All tests pass. (QA: pass / fail)", "Written by the agent when it finishes."):
                self.assertIn(part, text)
            tl = (self.root / "docs/timeline.md").read_text(encoding="utf-8")
            self.assertEqual(tl.count(f"- Tasks: T-0{n}\n"), 1)
        # the status script can read it
        out = sh(self.root, sys.executable, "tools/task_status.py", "T-044")
        self.assertIn("lead Tokens", out)

    def test_numbers_come_from_git_log_and_branches(self):
        sh(self.root, "git", "branch", "task/T-050-elsewhere")
        lines = nt.run(spec(1), self.root)
        self.assertTrue(lines[0].startswith("T-051 "))

    def test_refuses_while_merge_in_progress(self):
        sh(self.root, "git", "checkout", "-q", "-b", "other")
        (self.root / "f.txt").write_text("a", encoding="utf-8")
        sh(self.root, "git", "add", "f.txt")
        sh(self.root, "git", "commit", "-q", "-m", "other")
        sh(self.root, "git", "checkout", "-q", "master")
        (self.root / "f.txt").write_text("b", encoding="utf-8")
        sh(self.root, "git", "add", "f.txt")
        sh(self.root, "git", "commit", "-q", "-m", "master side")
        subprocess.run(["git", "merge", "--no-commit", "other"], cwd=self.root, capture_output=True)
        self.assertTrue(nt.merge_in_progress(self.root))
        head = sh(self.root, "git", "rev-parse", "HEAD")
        with self.assertRaises(nt.Refused) as cm:
            nt.run(spec(), self.root)
        self.assertIn("merge is in progress", str(cm.exception))
        self.assertEqual(sh(self.root, "git", "rev-parse", "HEAD"), head)
        self.assertFalse(list((self.root / "tasks").glob("T-04[4-9]*")))
        # the command line refuses too
        (self.root / "in.json").write_text(json.dumps(spec()), encoding="utf-8")
        r = subprocess.run([sys.executable, "tools/new_ticket.py", "in.json"], cwd=self.root, capture_output=True, text=True)
        self.assertEqual(r.returncode, 1)

    def test_bad_input_writes_nothing(self):
        bad = spec()
        del bad["tickets"][1]["timeline"]
        with self.assertRaises(nt.Refused):
            nt.run(bad, self.root)
        with self.assertRaises(nt.Refused):
            nt.run(spec(bogus=1), self.root)
        self.assertFalse(list((self.root / "tasks").glob("T-04[4-9]*")))
        self.assertEqual(sh(self.root, "git", "rev-list", "--count", "HEAD").strip(), "1")

    def test_dry_run_writes_nothing(self):
        lines = nt.run(spec(), self.root, dry_run=True)
        self.assertEqual(len(lines), 2)
        self.assertEqual(sh(self.root, "git", "status", "--porcelain").strip(), "")

    def test_unrelated_changes_stay_out_of_the_commit(self):
        (self.root / "docs/other.md").write_text("unrelated", encoding="utf-8")
        sh(self.root, "git", "add", "docs/other.md")
        nt.run(spec(1), self.root)
        files = sh(self.root, "git", "show", "--name-only", "--format=", "HEAD").split()
        self.assertNotIn("docs/other.md", files)

    def test_command_line_prints_one_line_per_ticket(self):
        (self.root / "in.json").write_text(json.dumps(spec()), encoding="utf-8")
        r = subprocess.run([sys.executable, "tools/new_ticket.py", "in.json"], cwd=self.root, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(len(r.stdout.strip().splitlines()), 2)


class RegenerationTests(unittest.TestCase):
    def test_decision_docs_regenerate_the_gdds_and_join_the_commit(self):
        root = make_repo(with_docs=True)
        self.addCleanup(shutil.rmtree, root, True)
        doc = root / "docs/weapons.md"
        doc.write_text(doc.read_text(encoding="utf-8") + "\nAn extra line.\n", encoding="utf-8")
        nt.run(spec(1, decision_docs=["docs/weapons.md"]), root)
        files = sh(root, "git", "show", "--name-only", "--format=", "HEAD").split()
        for f in ("docs/weapons.md", "docs/long-gdd.md", "docs/short-gdd/README.md", "docs/timeline.md"):
            self.assertIn(f, files)
        self.assertEqual(sh(root, "git", "status", "--porcelain").strip(), "")
        r = subprocess.run([sys.executable, "tools/generate_long_gdd.py", "--check"], cwd=root, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)


if __name__ == "__main__":
    unittest.main()
