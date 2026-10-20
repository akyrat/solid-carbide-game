"""Tests for task_status.py, the local task board server and the board_gate hook. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import contextlib
import importlib.util
import io
import json
import threading
import urllib.error
import urllib.request
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))

import taskboard_sync as tb  # noqa: E402
import task_status as ts  # noqa: E402
import board_inbox as bi  # noqa: E402

sys.path.insert(0, str(TOOLS / "taskboard"))
import server  # noqa: E402

_spec = importlib.util.spec_from_file_location("board_gate", TOOLS.parent / ".claude" / "hooks" / "board_gate.py")
gate = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(gate)


def task(tid, status="open", depends_on="", qa_rounds=0, criteria=("- [ ] It works (QA: pass / fail)",),
         notes="Written by the agent when it finishes.", review=None, lead=None, goal=None):
    review_line = f"\nThe board's review: {review}\n" if review else ""
    lead_line = "" if lead is None else ("lead:\n" if not lead else f"lead: {lead}\n")
    lead_line += "" if goal is None else (f"goal: {goal}\n" if goal else "goal:\n")
    return f"""---
id: {tid}
title: Task {tid}
status: {status}
from: project-lead
to: ui
{lead_line}epic: hud-menus
milestone: mvp
depends_on: [{depends_on}]
model: sonnet
qa_rounds: {qa_rounds}
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

Something to build.{review_line}

## Acceptance criteria

{chr(10).join(criteria)}

## Result notes

{notes}
"""


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.tasks = root / "tasks"
        self.tasks.mkdir()
        self.saved = (tb.TASKS_DIR, tb.STATE_DIR, ts.LOG, tb.task_folders)
        tb.TASKS_DIR, tb.STATE_DIR = self.tasks, root / ".board"
        ts.LOG = tb.STATE_DIR / "moves.log"
        tb.task_folders = lambda root=None: {}
        self.root = root

    def tearDown(self):
        tb.TASKS_DIR, tb.STATE_DIR, ts.LOG, tb.task_folders = self.saved
        self.tmp.cleanup()

    def put(self, tid, **kw):
        path = self.tasks / f"{tid}-test.md"
        path.write_bytes(task(tid, **kw).encode("utf-8"))
        ts.gl.ledger_path().unlink(missing_ok=True)   # a test's setup is trusted: the ledger is seeded afresh
        return path

    def status(self, tid):
        return tb.parse_header((self.tasks / f"{tid}-test.md").read_text(encoding="utf-8"))["status"]

    def lead(self, tid):
        return tb.parse_header((self.tasks / f"{tid}-test.md").read_text(encoding="utf-8")).get("lead")

    def move(self, tid, new, note=None):
        return ts.move(tid, new, note, folders={})

    def refused(self, tid, new, note=None):
        with self.assertRaises(ts.Refused) as ctx:
            self.move(tid, new, note)
        return str(ctx.exception)


class StatusRules(Base):
    def test_cannot_start_before_dependencies_are_done(self):
        self.put("T-001", status="in-progress")
        self.put("T-002", depends_on="T-001")
        self.assertIn("T-001 (in-progress)", self.refused("T-002", "in-progress"))
        self.put("T-001", status="done")
        self.move("T-002", "in-progress")
        self.assertEqual(self.status("T-002"), "in-progress")

    def test_planning_from_to_do_and_blocked(self):
        self.put("T-001", status="in-progress")
        self.put("T-002")
        self.put("T-003", status="blocked", depends_on="T-001")
        self.move("T-002", "planning")
        self.move("T-003", "planning")   # refined while it still waits
        self.assertEqual((self.status("T-002"), self.status("T-003")), ("planning", "planning"))

    def test_planning_starts_only_when_dependencies_are_done(self):
        self.put("T-001", status="in-progress")
        self.put("T-002", status="planning", depends_on="T-001")
        self.assertIn("T-001 (in-progress)", self.refused("T-002", "in-progress"))
        self.put("T-001", status="done")
        self.move("T-002", "in-progress")
        self.assertEqual(self.status("T-002"), "in-progress")

    def test_planning_goes_back_to_open_or_blocked_or_is_cancelled(self):
        for back in ("open", "blocked"):
            self.put("T-001", status="planning")
            self.move("T-001", back)
            self.assertEqual(self.status("T-001"), back)
        self.put("T-001", status="planning")
        self.assertIn("--note", self.refused("T-001", "cancelled"))
        self.move("T-001", "cancelled", "Not wanted")
        self.assertEqual(self.status("T-001"), "cancelled")

    def test_planning_cannot_skip_the_work(self):
        self.put("T-001", status="planning")
        for skip in ("in-qa", "needs-playtest", "done", "flagged-for-review"):
            self.assertIn("Allowed now: in-progress, open, blocked, cancelled", self.refused("T-001", skip))

    def test_in_progress_goes_back_to_planning(self):
        self.put("T-001", status="in-progress")
        self.move("T-001", "planning")
        self.assertEqual(self.status("T-001"), "planning")

    def test_qa_needs_result_notes(self):
        self.put("T-001", status="in-progress")
        self.assertIn("result notes", self.refused("T-001", "in-qa"))
        self.put("T-001", status="in-progress", notes="Built it; tests pass.")
        self.move("T-001", "in-qa")

    def test_cannot_skip_qa(self):
        self.put("T-001", status="in-progress", notes="Built it.")
        self.assertIn("Allowed now: in-qa", self.refused("T-001", "done"))

    def test_qa_must_mark_every_criterion(self):
        self.put("T-001", status="in-qa", criteria=("- [x] A (QA: pass)", "- [ ] B (QA: pass / fail)"))
        self.assertIn("1 left", self.refused("T-001", "done"))

    def test_pass_without_review_is_done_and_counts_the_round(self):
        self.put("T-001", status="in-qa", criteria=("- [x] A (QA: pass)",))
        self.assertIn("so it is done", self.refused("T-001", "needs-playtest"))
        self.move("T-001", "done")
        fields = tb.parse_header((self.tasks / "T-001-test.md").read_text(encoding="utf-8"))
        self.assertEqual((fields["status"], fields["qa_rounds"]), ("done", "1"))

    def test_pass_with_review_waits_for_the_board(self):
        self.put("T-001", status="in-qa", criteria=("- [x] A (QA: pass)",), review="play the menu")
        self.assertIn("needs-playtest", self.refused("T-001", "done"))
        self.move("T-001", "needs-playtest")

    def test_first_fail_goes_back_second_fail_is_flagged(self):
        self.put("T-001", status="in-qa", criteria=("- [ ] A (QA: fail, crashes)",))
        self.assertIn("only once", self.refused("T-001", "flagged-for-review"))
        self.move("T-001", "in-progress")
        self.put("T-001", status="in-qa", qa_rounds=1, criteria=("- [ ] A (QA: fail, still crashes)",))
        self.assertIn("second time", self.refused("T-001", "in-progress"))
        self.move("T-001", "flagged-for-review")

    def test_done_is_final(self):
        self.put("T-001", status="done")
        self.assertIn("final", self.refused("T-001", "in-progress"))

    def test_cancel_needs_a_note_and_records_it(self):
        self.put("T-001")
        self.assertIn("--note", self.refused("T-001", "cancelled"))
        self.move("T-001", "cancelled", note="The board dropped the feature.")
        text = (self.tasks / "T-001-test.md").read_text(encoding="utf-8")
        self.assertIn("open → cancelled: The board dropped the feature.", text)
        self.assertNotIn("Written by the agent when it finishes.", text)

    def test_done_opens_tasks_waiting_only_on_it(self):
        self.put("T-001", status="needs-playtest")
        self.put("T-002", status="done")
        self.put("T-003", status="blocked", depends_on="T-001, T-002")
        self.put("T-004", status="blocked", depends_on="T-001, T-005")
        self.put("T-005", status="open")
        lines = self.move("T-001", "done")
        self.assertEqual((self.status("T-003"), self.status("T-004")), ("open", "blocked"))
        self.assertTrue(any("T-003" in l for l in lines))

    def test_keeps_crlf_line_endings(self):
        path = self.put("T-001")
        path.write_bytes(path.read_bytes().replace(b"\n", b"\r\n"))
        self.move("T-001", "blocked")
        self.assertNotIn(b"\r\r", path.read_bytes())
        self.assertEqual(path.read_bytes().count(b"\n"), path.read_bytes().count(b"\r\n"))

    def test_every_move_is_logged(self):
        self.put("T-001")
        self.move("T-001", "blocked")
        entry = json.loads(ts.LOG.read_text(encoding="utf-8").splitlines()[-1])
        self.assertEqual((entry["id"], entry["from"], entry["to"]), ("T-001", "open", "blocked"))


class QaMarks(unittest.TestCase):
    def verdicts_of(self, *lines):
        return ts.verdicts(task("T-001", criteria=tuple(f"- [ ] {l}" for l in lines)))

    def test_a_pass_mark_may_carry_a_note(self):
        passed, failed, unchecked = self.verdicts_of(
            "A (QA: pass)", "B (QA: pass; a note)", "C (QA: pass: a note)", "D (QA: PASS, note)",
            "E (QA: pass - note)", "F (QA: pass; full suite 850/850)")
        self.assertEqual((len(passed), len(failed), len(unchecked)), (6, 0, 0))

    def test_other_words_after_pass_stay_unmarked(self):
        passed, failed, unchecked = self.verdicts_of(
            "A (QA: pass / fail)", "B (QA: passed)", "C (QA: pass/fail)", "D no mark at all")
        self.assertEqual((len(passed), len(failed), len(unchecked)), (0, 0, 4))

    def test_a_fail_mark_still_wins_over_a_pass_note(self):
        passed, failed, _ = self.verdicts_of("A (QA: pass; x) (QA: fail: y)")
        self.assertEqual((len(passed), len(failed)), (0, 1))


UNMARKED = ("- [ ] It builds (QA: pass)", "- [ ] The sample looks right (QA: pass / fail)",
            "- [ ] It runs fast (QA: fail: 40 fps)", "- [ ] The board likes it")


class BoardOutOfQa(Base):
    """T-212: the board's drag may take a ticket out of QA while QA hasn't marked every criterion."""

    def setUp(self):
        super().setUp()
        self.put("T-001", status="in-qa", qa_rounds=1, criteria=UNMARKED, notes="Built it.")

    def text(self):
        return (self.tasks / "T-001-test.md").read_text(encoding="utf-8")

    def test_the_board_moves_it_to_in_progress_keeping_qa_rounds_with_its_explanation(self):
        ts.move("T-001", "in-progress", "It went to QA only for my sample review.", folders={}, by="board")
        fields = tb.parse_header(self.text())
        self.assertEqual((fields["status"], fields["qa_rounds"]), ("in-progress", "1"))
        self.assertIn("in-qa → in-progress: It went to QA only for my sample review.", self.text())

    def test_the_board_moves_it_to_planning(self):
        ts.move("T-001", "planning", None, folders={}, by="board")
        fields = tb.parse_header(self.text())
        self.assertEqual((fields["status"], fields["qa_rounds"]), ("planning", "1"))
        self.assertIn("the board took it out of QA with 2 acceptance criteria not marked", self.text())

    def test_the_command_line_is_still_refused(self):
        for new in ("in-progress", "planning"):
            with self.subTest(new=new):
                self.assertIn("Allowed now: cancelled", self.refused("T-001", new))
        self.assertEqual(self.status("T-001"), "in-qa")

    def test_the_board_still_cannot_skip_to_done(self):
        with self.assertRaises(ts.Refused):
            ts.move("T-001", "done", None, folders={}, by="board")

    def test_the_warning_lists_the_unmarked_and_failed_criteria_word_for_word(self):
        fields = tb.parse_header(self.text())
        w = ts.unmarked_warning(fields, self.text(), "in-progress", "board")
        self.assertEqual(w, {"unmarked": ["The sample looks right (QA: pass / fail)", "The board likes it"],
                             "failed": ["It runs fast (QA: fail: 40 fps)"]})
        self.assertIsNone(ts.unmarked_warning(fields, self.text(), "in-progress", "agent"))
        self.assertIsNone(ts.unmarked_warning(fields, self.text(), "done", "board"))

    def test_a_fully_marked_ticket_keeps_todays_rules(self):
        self.put("T-002", status="in-qa", criteria=("- [ ] A (QA: pass)",), notes="Built it.")
        self.assertIsNone(ts.unmarked_warning(tb.parse_header(task("T-002", status="in-qa")), task(
            "T-002", status="in-qa", criteria=("- [ ] A (QA: pass)",)), "in-progress", "board"))
        with self.assertRaises(ts.Refused):
            ts.move("T-002", "planning", None, folders={}, by="board")


class GoalDependencies(Base):
    """T-163: during a goal, a dependency waiting in needs-playtest counts as met for the same goal's tickets."""

    def test_a_needs_playtest_dependency_in_the_same_goal_lets_a_ticket_start(self):
        self.put("T-001", status="needs-playtest", goal="G-001")
        self.put("T-002", depends_on="T-001", goal="G-001")
        self.move("T-002", "in-progress")
        self.assertEqual(self.status("T-002"), "in-progress")
        self.put("T-003", status="blocked", depends_on="T-001", goal="G-001")
        self.move("T-003", "open")
        self.assertEqual(self.status("T-003"), "open")

    def test_a_different_or_empty_goal_still_needs_done(self):
        self.put("T-001", status="needs-playtest", goal="G-001")
        self.put("T-002", depends_on="T-001", goal="G-002")
        self.assertIn("T-001 (needs-playtest)", self.refused("T-002", "in-progress"))
        self.put("T-003", depends_on="T-001", goal="")
        self.assertIn("T-001 (needs-playtest)", self.refused("T-003", "in-progress"))
        self.put("T-004", depends_on="T-001")                 # no goal line at all
        self.assertIn("T-001 (needs-playtest)", self.refused("T-004", "in-progress"))
        self.put("T-005", status="needs-playtest", goal="")   # both empty: not a goal
        self.put("T-006", depends_on="T-005", goal="")
        self.assertIn("T-005 (needs-playtest)", self.refused("T-006", "in-progress"))

    def test_other_statuses_in_the_same_goal_still_wait(self):
        self.put("T-001", status="in-qa", goal="G-001")
        self.put("T-002", depends_on="T-001", goal="G-001")
        self.assertIn("T-001 (in-qa)", self.refused("T-002", "in-progress"))

    def test_moving_to_needs_playtest_unblocks_the_same_goals_waiting_tickets(self):
        self.put("T-001", status="in-qa", criteria=("- [x] A (QA: pass)",), review="play it", goal="G-001")
        self.put("T-002", status="done")
        self.put("T-003", status="blocked", depends_on="T-001, T-002", goal="G-001")   # waits on nothing now
        self.put("T-004", status="blocked", depends_on="T-001, T-005", goal="G-001")   # T-005 still open
        self.put("T-005", status="open", goal="G-001")
        self.put("T-006", status="blocked", depends_on="T-001", goal="G-002")          # another goal
        self.put("T-007", status="blocked", depends_on="T-001")                        # outside any goal
        lines = self.move("T-001", "needs-playtest")
        self.assertEqual([self.status(t) for t in ("T-003", "T-004", "T-006", "T-007")],
                         ["open", "blocked", "blocked", "blocked"])
        self.assertTrue(any("T-003" in l and "G-001" in l for l in lines), lines)

    def test_needs_playtest_outside_a_goal_unblocks_nothing(self):
        self.put("T-001", status="in-qa", criteria=("- [x] A (QA: pass)",), review="play it")
        self.put("T-002", status="blocked", depends_on="T-001")
        self.assertEqual(len(self.move("T-001", "needs-playtest")), 2)   # the move and qa_rounds only
        self.assertEqual(self.status("T-002"), "blocked")


class Replies(Base):
    """python tools/task_status.py T-NNN [status] --reply "text": the Project Lead's reply on the ticket"""

    TEXT = "First paragraph, with **Markdown**.\n\nSecond paragraph.\n\n- a list item"

    def main(self, *argv):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = ts.main(list(argv))
        return code, out.getvalue() + err.getvalue()

    def read(self, tid):
        return (self.tasks / f"{tid}-test.md").read_text(encoding="utf-8")

    def test_a_move_with_a_reply_adds_an_update_before_the_result_notes(self):
        self.put("T-001", status="in-progress", notes="The agent did it.")
        code, text = self.main("T-001", "in-qa", "--reply", self.TEXT)
        self.assertEqual(code, 0, text)
        body = self.read("T-001")
        self.assertEqual(self.status("T-001"), "in-qa")
        self.assertIn(f"### {ts.date.today().isoformat()}, In progress → In QA\n\n{self.TEXT}\n", body)
        self.assertLess(body.index("## Updates"), body.index("## Result notes"))
        updates = tb.parse_updates(body)
        self.assertEqual(len(updates), 1)
        self.assertEqual((updates[0]["change"], updates[0]["text"]), ("In progress → In QA", self.TEXT))

    def test_a_reply_without_a_move_uses_the_current_lane_and_keeps_the_status(self):
        self.put("T-001", status="in-progress")
        code, text = self.main("T-001", "--reply", "Moved by the board.")
        self.assertEqual(code, 0, text)
        self.assertEqual(self.status("T-001"), "in-progress")
        self.assertEqual(tb.parse_updates(self.read("T-001"))[0]["change"], "In progress")

    def test_an_older_file_without_updates_gets_the_section_and_keeps_its_notes(self):
        self.put("T-001", status="in-progress", notes="Notes line one.\n\nNotes line two.")
        before = tb.review_parts(self.read("T-001"))[2]
        self.assertNotIn("## Updates", self.read("T-001"))
        self.main("T-001", "--reply", "Hello")
        body = self.read("T-001")
        self.assertEqual(body.count("## Updates"), 1)
        self.assertEqual(tb.review_parts(body)[2], before)
        self.assertEqual(body.count("## Result notes"), 1)

    def test_replies_are_appended_newest_last(self):
        self.put("T-001", status="open")
        self.main("T-001", "planning", "--reply", "one")
        self.main("T-001", "--reply", "two")
        self.main("T-001", "in-progress", "--reply", "three")
        body = self.read("T-001")
        self.assertEqual(body.count("## Updates"), 1)
        self.assertEqual([u["text"] for u in tb.parse_updates(body)], ["one", "two", "three"])
        self.assertEqual([u["change"] for u in tb.parse_updates(body)],
                         ["Open → Planning", "Planning", "Planning → In progress"])
        self.assertLess(body.index("## Updates"), body.index("## Result notes"))

    def test_a_refused_move_posts_no_reply(self):
        self.put("T-001", status="open")
        code, _ = self.main("T-001", "done", "--reply", "nope")
        self.assertEqual(code, 1)
        self.assertNotIn("## Updates", self.read("T-001"))

    def test_an_empty_reply_is_refused(self):
        self.put("T-001")
        self.assertEqual(self.main("T-001", "--reply", "  ")[0], 1)
        self.assertEqual(self.main("T-001", "--reply")[0], 2)

    def test_crlf_files_stay_crlf(self):
        path = self.put("T-001", status="in-progress")
        path.write_bytes(path.read_bytes().replace(b"\n", b"\r\n"))
        self.main("T-001", "--reply", "a\n\nb")
        data = path.read_bytes()
        self.assertEqual(data.count(b"\n"), data.count(b"\r\n"))
        self.assertEqual(tb.parse_updates(data.decode("utf-8"))[0]["text"], "a\n\nb")


class Lead(Base):
    """python tools/task_status.py T-NNN [status] --lead <Name> [--take-over]"""

    def main(self, *argv):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = ts.main(list(argv))
        return code, out.getvalue() + err.getvalue()

    def test_sets_an_empty_owner(self):
        self.put("T-001", lead="")
        code, text = self.main("T-001", "--lead", "Tools")
        self.assertEqual(code, 0, text)
        self.assertEqual((self.lead("T-001"), self.status("T-001")), ("Tools", "open"))
        entry = json.loads(ts.LOG.read_text(encoding="utf-8").splitlines()[-1])
        self.assertEqual((entry["id"], entry["lead"], entry["from_lead"]), ("T-001", "Tools", ""))

    def test_adds_the_line_when_a_task_file_has_none(self):
        path = self.put("T-001")
        self.assertIsNone(self.lead("T-001"))
        self.assertEqual(self.main("T-001", "--lead", "Tools")[0], 0)
        self.assertEqual(self.lead("T-001"), "Tools")
        self.assertIn("to: ui\nlead: Tools\nepic:", path.read_text(encoding="utf-8"))

    def test_with_a_status_move_in_the_same_call(self):
        self.put("T-001", lead="")
        code, text = self.main("T-001", "in-progress", "--lead", "Tools")
        self.assertEqual(code, 0, text)
        self.assertEqual((self.lead("T-001"), self.status("T-001")), ("Tools", "in-progress"))

    def test_refuses_a_different_owner_without_take_over(self):
        self.put("T-001", lead="Camera")
        code, text = self.main("T-001", "--lead", "Tools")
        self.assertEqual(code, 1)
        self.assertIn("belongs to Camera", text)
        self.assertIn("--take-over", text)
        self.assertEqual(self.lead("T-001"), "Camera")

    def test_a_refused_claim_does_not_move_the_task(self):
        self.put("T-001", lead="Camera")
        self.assertEqual(self.main("T-001", "in-progress", "--lead", "Tools")[0], 1)
        self.assertEqual((self.lead("T-001"), self.status("T-001")), ("Camera", "open"))

    def test_a_refused_move_does_not_claim(self):
        self.put("T-001", lead="")
        self.assertEqual(self.main("T-001", "done", "--lead", "Tools")[0], 1)
        self.assertEqual((self.lead("T-001"), self.status("T-001")), ("", "open"))

    def test_take_over_accepts_a_different_owner(self):
        self.put("T-001", lead="Camera")
        code, text = self.main("T-001", "--lead", "Tools", "--take-over")
        self.assertEqual(code, 0, text)
        self.assertIn("Camera → Tools", text)
        self.assertEqual(self.lead("T-001"), "Tools")

    def test_claiming_again_is_fine(self):
        self.put("T-001", lead="Tools")
        code, text = self.main("T-001", "--lead", "Tools")
        self.assertEqual(code, 0)
        self.assertIn("already belongs to Tools", text)

    def test_refuses_a_bad_name_and_usage_errors(self):
        self.put("T-001", lead="")
        self.assertEqual(self.main("T-001", "--lead", "two words")[0], 1)
        self.assertEqual(self.main("T-001", "--lead")[0], 2)
        self.assertEqual(self.main("T-001", "--take-over")[0], 2)
        self.assertEqual(self.lead("T-001"), "")

    def test_keeps_crlf_line_endings(self):
        path = self.put("T-001", lead="")
        path.write_bytes(path.read_bytes().replace(b"\n", b"\r\n"))
        self.main("T-001", "--lead", "Tools")
        self.assertNotIn(b"\r\r", path.read_bytes())
        self.assertEqual(path.read_bytes().count(b"\n"), path.read_bytes().count(b"\r\n"))
        self.assertIn(b"lead: Tools\r\n", path.read_bytes())


class Hook(Base):
    def setUp(self):
        super().setUp()
        self.path = self.put("T-001")

    def decision(self, tool, tool_input):
        import contextlib, io
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            gate.pre_edit(tool, tool_input) if tool != "Bash" else gate.pre_shell(tool_input)
        return json.loads(buf.getvalue())["hookSpecificOutput"]["permissionDecision"] if buf.getvalue() else "allow"

    def test_refuses_a_direct_status_edit(self):
        edit = {"file_path": str(self.path), "old_string": "status: open\n", "new_string": "status: done\n"}
        self.assertEqual(self.decision("Edit", edit), "deny")

    def test_allows_other_edits_to_a_task_file(self):
        edit = {"file_path": str(self.path), "old_string": "Something to build.", "new_string": "Something else."}
        self.assertEqual(self.decision("Edit", edit), "allow")

    def test_the_status_comment_line_is_not_the_status(self):
        edit = {"file_path": str(self.path), "old_string": "status: open | in-progress", "new_string": "status: open | doing"}
        self.assertEqual(self.decision("Edit", edit), "allow")

    def test_refuses_a_rewrite_that_changes_qa_rounds(self):
        content = self.path.read_text(encoding="utf-8").replace("qa_rounds: 0", "qa_rounds: 1")
        self.assertEqual(self.decision("Write", {"file_path": str(self.path), "content": content}), "deny")

    def test_new_tasks_start_open_or_blocked(self):
        new = str(self.tasks / "T-009-new.md")
        self.assertEqual(self.decision("Write", {"file_path": new, "content": task("T-009", status="blocked")}), "allow")
        self.assertEqual(self.decision("Write", {"file_path": new, "content": task("T-009", status="done")}), "deny")

    def test_refuses_a_direct_lead_edit(self):
        self.put("T-001", lead="")
        edit = {"file_path": str(self.path), "old_string": "lead:\n", "new_string": "lead: Tools\n"}
        self.assertEqual(self.decision("Edit", edit), "deny")
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            gate.pre_edit("Edit", edit)
        self.assertIn("task_status.py T-001 --lead Tools", buf.getvalue())
        ts.claim("T-001", "Tools", folders={})
        edit = {"file_path": str(self.path), "old_string": "lead: Tools\n", "new_string": "lead:\n"}
        self.assertEqual(self.decision("Edit", edit), "deny")

    def test_adding_an_empty_lead_line_is_allowed(self):
        edit = {"file_path": str(self.path), "old_string": "to: ui\n", "new_string": "to: ui\nlead:\n"}
        self.assertEqual(self.decision("Edit", edit), "allow")

    def test_a_new_task_starts_without_a_lead(self):
        new = str(self.tasks / "T-009-new.md")
        self.assertEqual(self.decision("Write", {"file_path": new, "content": task("T-009", lead="")}), "allow")
        self.assertEqual(self.decision("Write", {"file_path": new, "content": task("T-009", lead="Tools")}), "deny")

    def test_refuses_sed_on_a_lead_line(self):
        cmd = {"command": "sed -i 's/lead:/lead: Tools/' tasks/T-001-test.md"}
        self.assertEqual(self.decision("Bash", cmd), "deny")
        self.assertEqual(self.decision("Bash", {"command": "python tools/task_status.py T-001 --lead Tools"}), "allow")

    def test_refuses_sed_on_a_status_line(self):
        cmd = {"command": "sed -i 's/status: open/status: done/' tasks/T-001-test.md"}
        self.assertEqual(self.decision("Bash", cmd), "deny")
        self.assertEqual(self.decision("Bash", {"command": "python tools/task_status.py T-001 blocked"}), "allow")

    def test_read_only_commands_may_mention_the_status_line(self):
        for command in [
            'grep -n "^status:" tasks/T-001-x.md',
            "sed -n '1,10p' tasks/T-001-x.md | grep \"status:\"",
            "head -5 tasks/T-001-x.md | grep qa_rounds:",
            "grep -n '^status:' tasks/T-052*.md 2>/dev/null",
            "cat tasks/T-001-x.md | awk '/^status:/ {print $2}'",
            "rg 'status: (open|done)' tasks/T-001-x.md",
            'Select-String -Path tasks/T-001-x.md -Pattern "^status:"',
            'Get-Content tasks/T-001-x.md | Select-String "qa_rounds:" | Select-Object -First 1',
            'cd tasks && grep -h "^status:" T-001-x.md; tail -3 tasks/T-001-x.md',
        ]:
            with self.subTest(command=command):
                self.assertEqual(self.decision("Bash", {"command": command}), "allow")

    def test_commands_that_could_write_the_status_line_are_still_refused(self):
        for command in [
            "sed -i 's/status: open/status: done/' tasks/T-001-x.md",
            "sed -n 's/status: open/status: done/w tasks/T-001-x.md' tasks/T-001-x.md",
            'echo "status: done" >> tasks/T-001-x.md',
            'grep -v "status:" tasks/T-001-x.md > tasks/T-001-y.md',
            'cat tasks/T-001-x.md | tee tasks/T-001-x.md  # status:',
            "perl -pi -e 's/status: open/status: done/' tasks/T-001-x.md",
            "python -c \"import pathlib; p=pathlib.Path('tasks/T-001-x.md'); p.write_text('status: done')\"",
            "awk '{sub(/status: open/, \"status: done\")} 1' tasks/T-001-x.md > t && mv t tasks/T-001-x.md",
            'Set-Content tasks/T-001-x.md "status: done"',
            '(Get-Content tasks/T-001-x.md) -replace "status: open","status: done" | Set-Content tasks/T-001-x.md',
            'grep status: tasks/T-001-x.md && rm tasks/T-001-x.md',
            'grep status: $(echo tasks/T-001-x.md)',
            'grep "status:" tasks/T-001-x.md; python tools/other.py',
            "grep 'status: tasks/T-001-x.md",
            'cat tasks/T-001-x.md | grep lead: > tasks/T-001-x.md',
        ]:
            with self.subTest(command=command):
                self.assertEqual(self.decision("Bash", {"command": command}), "deny")


class AgentModel(Base):
    def decision(self, tool_input):
        import contextlib, io
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            gate.pre_agent(tool_input)
        return json.loads(buf.getvalue())["hookSpecificOutput"]["permissionDecision"] if buf.getvalue() else "allow"

    def agent(self, prompt, agent="ui", model=None):
        call = {"subagent_type": agent, "prompt": prompt, "description": "x"}
        if model:
            call["model"] = model
        return self.decision(call)

    def test_a_sonnet_task_needs_sonnet(self):
        self.put("T-001")
        self.assertEqual(self.agent("Work on task T-001"), "deny")
        self.assertEqual(self.agent("Work on task T-001", model="opus"), "deny")
        self.assertEqual(self.agent("Work on task T-001", model="sonnet"), "allow")

    def test_an_opus_task_needs_opus(self):
        path = self.put("T-002")
        path.write_bytes(path.read_bytes().replace(b"model: sonnet", b"model: opus"))
        self.assertEqual(self.agent("Continue task T-002", model="sonnet"), "deny")
        self.assertEqual(self.agent("Continue task T-002", model="opus"), "allow")

    def test_qa_always_runs_on_sonnet(self):
        # Board, 2026-10-15: QA runs on sonnet even before a playtest, to cut its token use.
        self.put("T-003")
        self.put("T-004", review="play it")
        self.assertEqual(self.agent("QA round 1 for task T-003", agent="qa-integration", model="sonnet"), "allow")
        self.assertEqual(self.agent("QA round 1 for task T-003", agent="qa-integration", model="opus"), "deny")
        self.assertEqual(self.agent("QA round 1 for task T-004", agent="qa-integration", model="sonnet"), "allow")
        self.assertEqual(self.agent("QA round 1 for task T-004", agent="qa-integration", model="opus"), "deny")
        self.assertEqual(self.agent("QA round 1 for task T-004", agent="qa-integration"), "deny")

    def test_the_first_task_id_counts(self):
        self.put("T-005")
        self.assertEqual(self.agent("Work on task T-005; T-117 already has the marks", model="sonnet"), "allow")

    def test_no_task_unknown_task_or_fork_is_not_checked(self):
        self.assertEqual(self.agent("Find where the HUD is built"), "allow")
        self.assertEqual(self.agent("Work on task T-999"), "allow")
        self.put("T-006")
        self.assertEqual(self.agent("Work on task T-006", agent="fork"), "allow")

    def test_the_refusal_names_the_task_and_the_model(self):
        import contextlib, io
        self.put("T-007")
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            gate.pre_agent({"subagent_type": "ui", "prompt": "Work on task T-007"})
        reason = json.loads(buf.getvalue())["hookSpecificOutput"]["permissionDecisionReason"]
        self.assertIn("T-007", reason)
        self.assertIn("sonnet", reason)


class LocalBoard(Base):
    """The server on a free port, reading a temporary tasks/ folder."""

    def setUp(self):
        super().setUp()
        self.put("T-001", status="in-progress", notes="Built it.")
        self.put("T-002", status="blocked", depends_on="T-001")
        self.srv = server.make_server(0)
        self.port = self.srv.server_address[1]
        threading.Thread(target=self.srv.serve_forever, daemon=True).start()

    def tearDown(self):
        self.srv.shutdown()
        self.srv.server_close()
        super().tearDown()

    def call(self, path, body=None, headers=None):
        req = urllib.request.Request(f"http://127.0.0.1:{self.port}{path}",
                                     data=None if body is None else json.dumps(body).encode("utf-8"),
                                     headers=headers or {}, method="GET" if body is None else "POST")
        try:
            with urllib.request.urlopen(req, timeout=5) as r:
                return r.status, json.loads(r.read())
        except urllib.error.HTTPError as e:
            return e.code, json.loads(e.read())

    def move(self, tid, status, note=""):
        return self.call("/api/move", {"id": tid, "status": status, "note": note},
                         {"X-Board": "1", "Content-Type": "application/json"})

    def test_shows_the_task_files(self):
        code, body = self.call("/api/tickets")
        self.assertEqual(code, 200)
        self.assertEqual({t["id"]: t["status"] for t in body["tickets"]}, {"T-001": "in-progress", "T-002": "blocked"})

    def test_version_changes_when_a_task_file_changes(self):
        before = self.call("/api/version")[1]["version"]
        ts.move("T-001", "in-qa", folders={})
        self.assertNotEqual(self.call("/api/version")[1]["version"], before)

    def test_a_drag_moves_the_task_file_and_tells_the_project_lead(self):
        bi.take("s1")   # the session's cursor starts at the end of the inbox
        code, body = self.move("T-001", "in-qa")
        self.assertEqual((code, body["ok"]), (200, True))
        self.assertEqual(self.status("T-001"), "in-qa")
        self.assertEqual(json.loads(ts.LOG.read_text(encoding="utf-8").splitlines()[-1])["by"], "board")
        _, moves = bi.take("s1")
        self.assertEqual([(m["id"], m["from"], m["to"]) for m, _ in moves], [("T-001", "in-progress", "in-qa")])
        self.assertEqual(bi.take("s1")[1], [])   # heard once
        self.assertEqual(len(bi.inbox_path().read_text(encoding="utf-8").splitlines()), 1)   # never emptied

    def test_a_drag_that_breaks_a_rule_is_refused_with_the_reason(self):
        bi.take("s1")
        code, body = self.move("T-002", "in-progress")
        self.assertEqual(code, 409)
        self.assertIn("T-001 (in-progress)", body["error"])
        self.assertEqual(self.status("T-002"), "blocked")
        self.assertEqual(bi.take("s1")[1], [])

    def test_tickets_and_builds_carry_the_lead(self):
        ts.claim("T-001", "Tools", folders={})
        leads = {t["id"]: t["lead"] for t in self.call("/api/tickets")[1]["tickets"]}
        self.assertEqual(leads, {"T-001": "Tools", "T-002": ""})

    def test_cancelling_from_the_board_asks_for_a_note(self):
        self.assertIn("a note", self.move("T-002", "cancelled")[1]["error"])
        self.assertEqual(self.move("T-002", "cancelled", "Dropped by the board.")[0], 200)

    def test_t212_move_check_and_the_confirmed_drag_out_of_qa(self):
        self.put("T-003", status="in-qa", criteria=UNMARKED, notes="Built it.")
        before = (self.tasks / "T-003-test.md").read_bytes()
        code, body = self.call("/api/move-check?id=T-003&status=in-progress")
        self.assertEqual(code, 200)
        self.assertEqual(body["warning"]["unmarked"], ["The sample looks right (QA: pass / fail)", "The board likes it"])
        self.assertEqual(body["warning"]["failed"], ["It runs fast (QA: fail: 40 fps)"])
        self.assertIsNone(self.call("/api/move-check?id=T-001&status=in-qa")[1]["warning"])
        self.assertEqual(self.call("/api/move-check?id=T-003&status=nonsense")[0], 400)
        self.assertEqual(self.call("/api/move-check?id=T-404&status=planning")[0], 404)
        bi.take("s1")
        # not confirmed (or the pop-up cancelled): nothing changes, and the answer carries the warning
        code, body = self.move("T-003", "in-progress", "why")
        self.assertEqual((code, body["warning"]["unmarked"][1]), (409, "The board likes it"))
        self.assertEqual((self.tasks / "T-003-test.md").read_bytes(), before)
        self.assertEqual(bi.take("s1")[1], [])
        # going ahead: moved, qa_rounds kept, the explanation in the notes and with the move in the inbox
        code, _ = self.call("/api/move", {"id": "T-003", "status": "planning", "note": "Only a sample review.",
                                          "confirm_unmarked": True}, {"X-Board": "1", "Content-Type": "application/json"})
        self.assertEqual(code, 200)
        text = (self.tasks / "T-003-test.md").read_text(encoding="utf-8")
        self.assertEqual((tb.parse_header(text)["status"], tb.parse_header(text)["qa_rounds"]), ("planning", "0"))
        self.assertIn("in-qa → planning: Only a sample review.", text)
        _, moves = bi.take("s1")
        self.assertEqual([(m["id"], m["to"], m["note"]) for m, _ in moves], [("T-003", "planning", "Only a sample review.")])

    def test_t212_other_refused_drags_are_unchanged(self):
        self.put("T-004", status="in-qa", criteria=UNMARKED, notes="Built it.")
        code, body = self.call("/api/move", {"id": "T-004", "status": "done", "confirm_unmarked": True},
                               {"X-Board": "1", "Content-Type": "application/json"})
        self.assertEqual(code, 409)
        self.assertNotIn("warning", body)
        self.assertEqual(self.status("T-004"), "in-qa")

    def test_t212_the_page_has_the_warning(self):
        with urllib.request.urlopen(f"http://127.0.0.1:{self.port}/", timeout=5) as r:
            page = r.read().decode("utf-8")
        for part in ('id="qawarn"', 'id="qawarn-note"', 'id="qawarn-go"', 'id="qawarn-cancel"', "/api/move-check",
                     "confirm_unmarked"):
            self.assertIn(part, page)

    def test_refuses_writes_without_the_board_header(self):
        code, _ = self.call("/api/move", {"id": "T-001", "status": "in-qa"}, {"Content-Type": "application/json"})
        self.assertEqual(code, 403)
        self.assertEqual(self.status("T-001"), "in-progress")

    def test_refuses_other_host_names(self):
        code, _ = self.call("/api/tickets", headers={"Host": "evil.example"})
        self.assertEqual(code, 403)

    def test_serves_the_page(self):
        with urllib.request.urlopen(f"http://127.0.0.1:{self.port}/", timeout=5) as r:
            self.assertIn(b"<title>Solid Carbide Task Board</title>", r.read())


class Handover(Base):
    """The hooks hand the board's moves to the Project Lead."""

    def setUp(self):
        super().setUp()
        tb.STATE_DIR.mkdir()
        (tb.STATE_DIR / "board-inbox.jsonl").write_text(json.dumps(
            {"id": "T-001", "from": "open", "to": "in-progress", "note": "", "at": "now"}) + "\n", encoding="utf-8")
        bi.save("s1", {"cursor": 0, "name": "Tools"})
        self.put("T-001", status="in-progress", lead="Tools")
        self.data = {"session_id": "s1"}

    def run_hook(self, fn, *args):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            fn(*args)
        return json.loads(buf.getvalue()) if buf.getvalue() else None

    def test_next_prompt_carries_the_moves(self):
        out = self.run_hook(gate.hand_over, "UserPromptSubmit", self.data)
        self.assertIn("T-001 open → in-progress", out["hookSpecificOutput"]["additionalContext"])
        self.assertIsNone(self.run_hook(gate.hand_over, "UserPromptSubmit", self.data))

    def test_stop_gives_one_more_turn_for_new_moves(self):
        out = self.run_hook(gate.stop, {"stop_hook_active": False, **self.data})
        self.assertEqual(out["decision"], "block")
        self.assertIsNone(self.run_hook(gate.stop, {"stop_hook_active": False, **self.data}))

    def test_a_move_to_planning_asks_for_the_open_questions(self):
        text = gate.describe_moves([{"id": "T-002", "from": "open", "to": "planning"}])
        self.assertIn("T-002 open → planning", text)
        self.assertIn("planning, read the ticket and bring its open questions to the board", text)

    def test_stop_never_loops(self):
        self.assertIsNone(self.run_hook(gate.stop, {"stop_hook_active": True, **self.data}))

    def test_the_message_for_an_owned_move_reads_as_before(self):
        out = self.run_hook(gate.hand_over, "PostToolUse", self.data)
        self.assertEqual(out["hookSpecificOutput"]["additionalContext"],
                         gate.describe_moves([{"id": "T-001", "from": "open", "to": "in-progress", "note": ""}]))


if __name__ == "__main__":
    unittest.main()
