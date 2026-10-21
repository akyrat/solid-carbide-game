"""Tests for layer 2's ticket side (tickets.py): every refusal rule, ticket ids, writing and claiming, and the
status guard at `git commit`. All in temporary git repos (temp_repo.py); the real tasks/ is never touched."""

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import taskboard_sync as tb  # noqa: E402
from goal_agent import temp_repo, tickets  # noqa: E402
from goal_agent.claude_call import Pause  # noqa: E402

REAL = temp_repo.REAL


def draft(key="D1", **over):
    d = {"key": key, "title": f"Draft {key}", "to": "game-data", "epic": "tooling", "milestone": "mvp",
         "model": "sonnet", "user_facing_text": "no", "changes_visuals": "no", "depends_on": [],
         "documents_affected": [], "files_to_read_first": ["tasks/README.md"], "files_expected_to_change": [],
         "description": "Do the thing.", "acceptance_criteria": ["It works"], "review": ""}
    d.update(over)
    return d


VISUAL_READS = ["tasks/README.md", "docs/visual-style.md", "docs/extended-narrative.md"]


class Refusals(unittest.TestCase):
    """One test per rule in the ticket's list (T-162, tickets.py). check() runs on the real repo's rules."""

    def reasons(self, drafts, existing=None):
        return tickets.check(drafts, existing or {}, REAL)

    def assertRefused(self, drafts, words, existing=None):
        reasons = self.reasons(drafts, existing)
        self.assertTrue(any(words in r for r in reasons), f"{words!r} not in {reasons}")

    def test_a_good_set_passes(self):
        self.assertEqual(self.reasons([draft()]), [])

    def test_to_must_be_an_agent_or_project_lead(self):
        self.assertRefused([draft(to="nobody")], "not an agent")
        self.assertEqual(self.reasons([draft(to="project-lead")]), [])

    def test_model_must_be_sonnet_or_opus(self):
        self.assertRefused([draft(model="haiku")], "`model`")

    def test_epic_and_milestone_must_be_in_the_tables(self):
        self.assertRefused([draft(epic="space")], "`epic`")
        self.assertRefused([draft(milestone="someday")], "`milestone`")
        self.assertEqual(self.reasons([draft(epic="local-coop", milestone="final-release")]), [])

    def test_visuals_need_both_docs(self):
        self.assertRefused([draft(changes_visuals="yes", review="look", files_to_read_first=["docs/visual-style.md"])],
                           "docs/extended-narrative.md")
        self.assertRefused([draft(changes_visuals="yes", review="look", files_to_read_first=["docs/extended-narrative.md"])],
                           "docs/visual-style.md")
        self.assertEqual(self.reasons([draft(changes_visuals="yes", review="look", files_to_read_first=VISUAL_READS)]), [])

    def test_text_needs_the_narrative_doc(self):
        text = draft("D2", to="narrative-theme", epic="narrative")
        self.assertRefused([text, draft(user_facing_text="yes", review="read", depends_on=["D2"])],
                           "lacks docs/extended-narrative.md")

    def test_text_needs_a_narrative_ticket_first(self):
        reads = ["docs/extended-narrative.md"]
        self.assertRefused([draft(user_facing_text="yes", review="read", files_to_read_first=reads)],
                           "narrative-theme ticket")
        text = draft("D2", to="narrative-theme", epic="narrative")
        self.assertEqual(self.reasons([text, draft(user_facing_text="yes", review="read", files_to_read_first=reads,
                                                   depends_on=["D2"])]), [])
        existing = {"T-050": {"id": "T-050", "to": "narrative-theme", "status": "done"}}
        self.assertEqual(self.reasons([draft(user_facing_text="yes", review="read", files_to_read_first=reads,
                                             depends_on=["T-050"])], existing), [])

    def test_art_must_depend_on_its_functional_ticket(self):
        art = dict(to="asset-generation", epic="art", changes_visuals="yes", review="look", files_to_read_first=VISUAL_READS)
        self.assertRefused([draft(**art)], "functional ticket")
        self.assertEqual(self.reasons([draft("D1"), draft("D2", depends_on=["D1"], **art)]), [])

    def test_art_needs_a_review_line(self):
        art = dict(to="asset-generation", epic="art", changes_visuals="yes", files_to_read_first=VISUAL_READS)
        self.assertRefused([draft("D1"), draft("D2", depends_on=["D1"], review="", **art)], "review")

    def test_what_the_player_meets_needs_a_review_line(self):
        self.assertRefused([draft(changes_visuals="yes", files_to_read_first=VISUAL_READS)], "sees, reads or hears")
        self.assertRefused([draft(to="sfx", epic="sound")], "sees, reads or hears")

    def test_empty_acceptance_criteria(self):
        self.assertRefused([draft(acceptance_criteria=[])], "no acceptance criteria")
        self.assertRefused([draft(acceptance_criteria=["  "])], "no acceptance criteria")

    def test_criteria_only_the_project_lead_can_meet_are_recognised(self):
        lead_only = {
            "The long GDD is regenerated": "the long GDD",
            "docs/long-gdd.md includes the new section": "the long GDD",
            "python tools/generate_long_gdd.py --check passes": "the long GDD",
            "The short GDD's fingerprint is updated": "the short GDD",
            "The staleness check passes": "the docs staleness check",
            "The docs are not stale": "the docs staleness check",
            "A timeline entry lists the documents touched": "the timeline",
            "docs/timeline.md has the decision": "the timeline",
            "The branch is merged into playtest/G-004": "merging",
            "Merged into master after QA": "merging",
        }
        for criterion, what in lead_only.items():
            self.assertEqual(tickets.lead_only(criterion), what, criterion)
        for criterion in ("The car drifts at 60 px/s", "The HUD shows the timer", "docs/drifting.md lists the tuning",
                          "The tests in game/tests pass", "The enemies merge into a swarm of 5"):
            self.assertIsNone(tickets.lead_only(criterion), criterion)

    def test_a_draft_with_only_lead_only_criteria_is_refused_with_why(self):
        self.assertRefused([draft(acceptance_criteria=["The long GDD is regenerated", "The staleness check passes"])],
                           "only the Project Lead can meet")
        self.assertRefused([draft(acceptance_criteria=["A timeline entry is added"])], "QA would fail it")
        self.assertEqual(self.reasons([draft(acceptance_criteria=["It works", "The long GDD is regenerated"])]), [],
                         "a draft with a checkable criterion left is accepted; the other is dropped when written")

    def test_the_prompts_say_why(self):
        from goal_agent import gaps, prioritize
        for text in (gaps.prompt("Goal", [], {}, ([], [])), prioritize.prompt("Goal", "G-001")):
            for words in ("long GDD", "short GDD", "staleness check", "timeline", "merging", "only the Project Lead",
                          "QA would fail it"):
                self.assertIn(words.lower(), text.lower(), words)

    def test_depends_on_must_name_a_draft_or_a_ticket(self):
        self.assertRefused([draft(depends_on=["T-999"])], "neither another draft nor an existing ticket")
        self.assertEqual(self.reasons([draft(depends_on=["T-999"])], {"T-999": {"to": "ui", "status": "open"}}), [])


class Repo(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = temp_repo.make(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()


class Ids(Repo):
    def test_next_id_counts_tasks_branches_and_master_log(self):
        self.assertEqual(tickets.next_number(self.root), 1)
        temp_repo.add_ticket(self.root, "T-005")
        self.assertEqual(tickets.next_number(self.root), 6)
        temp_repo.git(self.root, "branch", "task/T-009-on-a-branch")
        self.assertEqual(tickets.next_number(self.root), 10)
        temp_repo.git(self.root, "commit", "-q", "--allow-empty", "-m", "Merge task/T-014-merged-and-gone")
        self.assertEqual(tickets.next_number(self.root), 15)


class Writing(Repo):
    def write(self, drafts, existing=None):
        return tickets.write(drafts, existing or {}, self.root, "G-001")

    def test_written_tickets_follow_the_template_and_are_claimed(self):
        temp_repo.add_ticket(self.root, "T-010", status="done")
        temp_repo.add_ticket(self.root, "T-011", status="in-progress")
        existing = {t["id"]: t for t in tb.tickets_now(self.root / "tasks", {})}
        written = self.write([draft("D1", depends_on=["T-010"]), draft("D2", depends_on=["D1"]),
                              draft("D3", depends_on=["T-011"], review="play it", changes_visuals="yes",
                                    files_to_read_first=["docs/visual-style.md", "docs/extended-narrative.md"])],
                             existing)
        self.assertEqual([written[k][0] for k in ("D1", "D2", "D3")], ["T-012", "T-013", "T-014"])
        template = tb.parse_header((self.root / "tasks" / "_TEMPLATE.md").read_text(encoding="utf-8"))
        statuses = {}
        for key, (tid, path) in written.items():
            text = path.read_text(encoding="utf-8")
            fields = tb.parse_header(text)
            self.assertEqual(list(fields), list(template), "same header lines, in the template's order")
            self.assertEqual(fields["goal"], "G-001")
            self.assertEqual(fields["lead"], "Goal-G-001")
            self.assertEqual(fields["qa_rounds"], "0")
            self.assertEqual(fields["files_to_read_first"][0], "tasks/README.md")
            self.assertIn("- [ ] It works (QA: pass / fail)", text)
            self.assertIn("## Updates", text)
            self.assertTrue(text.rstrip().endswith("Written by the agent when it finishes."))
            statuses[key] = fields["status"]
        self.assertEqual(statuses, {"D1": "open", "D2": "blocked", "D3": "blocked"})
        self.assertEqual(tb.parse_header(written["D2"][1].read_text(encoding="utf-8"))["depends_on"], ["T-012"])
        self.assertIn("The board's review: play it", written["D3"][1].read_text(encoding="utf-8"))

    def test_lead_only_criteria_are_dropped_from_the_written_ticket(self):
        dropped = []
        criteria = ["It works", "The long GDD is regenerated", "The short GDD's fingerprint is updated",
                    "The staleness check passes", "A timeline entry is added", "The branch is merged into master"]
        written = tickets.write([draft(acceptance_criteria=criteria)], {}, self.root, "G-001", dropped=dropped)
        text = written["D1"][1].read_text(encoding="utf-8")
        section = text.split("## Acceptance criteria", 1)[1].split("\n## ", 1)[0]
        self.assertEqual(section.strip(), "- [ ] It works (QA: pass / fail)")
        self.assertEqual([(tid, what) for tid, _, what in dropped],
                         [("T-001", "the long GDD"), ("T-001", "the short GDD"), ("T-001", "the docs staleness check"),
                          ("T-001", "the timeline"), ("T-001", "merging")])
        self.assertIn('T-001: "The long GDD is regenerated" (the long GDD)', tickets.dropped_note(dropped))
        self.assertEqual(tickets.dropped_note([]), "")

    def test_a_refused_claim_pauses(self):
        def refuse(root, tid, name):
            raise Pause("refused")
        with self.assertRaises(Pause) as e:
            tickets.write([draft()], {}, self.root, "G-001", claim=refuse)
        self.assertIn("not committed", str(e.exception))

    def test_reused_ticket_gets_the_goal_line(self):
        path = temp_repo.add_ticket(self.root, "T-020", status="in-progress")
        other = temp_repo.add_ticket(self.root, "T-021", status="open", goal="G-009")
        now = {t["id"]: t for t in tb.tickets_now(self.root / "tasks", {})}
        self.assertEqual(tickets.mark_reused(self.root, now["T-020"], "G-001"), path)
        self.assertEqual(tb.parse_header(path.read_text(encoding="utf-8"))["goal"], "G-001")
        self.assertIsNone(tickets.mark_reused(self.root, now["T-021"], "G-001"))
        self.assertEqual(tb.parse_header(other.read_text(encoding="utf-8"))["goal"], "G-009")
        self.assertIsNone(tickets.mark_reused(self.root, dict(now["T-020"], folder="C:/worktree"), "G-002"))


class Guard(Repo):
    """Does a ticket file the script writes pass the status guard at `git commit`? The temp repo has its own copy
    of the hook (.claude/hooks/board_gate.py) and the ledger (tools/guard_ledger.py), so this asks the real code."""

    def hook_on_commit(self):
        event = {"hook_event_name": "PreToolUse", "tool_name": "Bash", "cwd": str(self.root),
                 "tool_input": {"command": "git commit -m tickets"}}
        done = subprocess.run([sys.executable, str(self.root / ".claude" / "hooks" / "board_gate.py")],
                              input=json.dumps(event), capture_output=True, text=True, encoding="utf-8")
        return done.stdout.strip()

    def test_written_and_claimed_tickets_pass_the_guard(self):
        written = tickets.write([draft("D1"), draft("D2", depends_on=["D1"])], {}, self.root, "G-001")
        self.assertTrue((self.root / ".board" / "blessed-states.jsonl").exists(), "the claim created the ledger")
        self.assertEqual(self.hook_on_commit(), "", "untracked")
        temp_repo.git(self.root, "add", "--", *[str(p.relative_to(self.root)) for _, p in written.values()])
        self.assertEqual(self.hook_on_commit(), "", "staged")

    def test_the_guard_does_refuse_a_hand_edit(self):
        written = tickets.write([draft("D1")], {}, self.root, "G-001")
        path = written["D1"][1]
        path.write_text(path.read_text(encoding="utf-8").replace("status: open", "status: done"), encoding="utf-8")
        self.assertIn("deny", self.hook_on_commit())


if __name__ == "__main__":
    unittest.main()
