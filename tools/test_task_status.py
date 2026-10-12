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

sys.path.insert(0, str(TOOLS / "taskboard"))
import server  # noqa: E402

_spec = importlib.util.spec_from_file_location("board_gate", TOOLS.parent / ".claude" / "hooks" / "board_gate.py")
gate = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(gate)


def task(tid, status="open", depends_on="", qa_rounds=0, criteria=("- [ ] It works (QA: pass / fail)",),
         notes="Written by the agent when it finishes.", review=None):
    review_line = f"\nThe board's review: {review}\n" if review else ""
    return f"""---
id: {tid}
title: Task {tid}
status: {status}
from: project-lead
to: ui
epic: hud-menus
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
        return path

    def status(self, tid):
        return tb.parse_header((self.tasks / f"{tid}-test.md").read_text(encoding="utf-8"))["status"]

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

    def test_refuses_sed_on_a_status_line(self):
        cmd = {"command": "sed -i 's/status: open/status: done/' tasks/T-001-test.md"}
        self.assertEqual(self.decision("Bash", cmd), "deny")
        self.assertEqual(self.decision("Bash", {"command": "python tools/task_status.py T-001 blocked"}), "allow")


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
        code, body = self.move("T-001", "in-qa")
        self.assertEqual((code, body["ok"]), (200, True))
        self.assertEqual(self.status("T-001"), "in-qa")
        self.assertEqual(json.loads(ts.LOG.read_text(encoding="utf-8").splitlines()[-1])["by"], "board")
        moves = gate.take_inbox()
        self.assertEqual([(m["id"], m["from"], m["to"]) for m in moves], [("T-001", "in-progress", "in-qa")])
        self.assertEqual(gate.take_inbox(), [])   # heard once

    def test_a_drag_that_breaks_a_rule_is_refused_with_the_reason(self):
        code, body = self.move("T-002", "in-progress")
        self.assertEqual(code, 409)
        self.assertIn("T-001 (in-progress)", body["error"])
        self.assertEqual(self.status("T-002"), "blocked")
        self.assertEqual(gate.take_inbox(), [])

    def test_cancelling_from_the_board_asks_for_a_note(self):
        self.assertIn("a note", self.move("T-002", "cancelled")[1]["error"])
        self.assertEqual(self.move("T-002", "cancelled", "Dropped by the board.")[0], 200)

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

    def run_hook(self, fn, *args):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            fn(*args)
        return json.loads(buf.getvalue()) if buf.getvalue() else None

    def test_next_prompt_carries_the_moves(self):
        out = self.run_hook(gate.hand_over, "UserPromptSubmit")
        self.assertIn("T-001 open → in-progress", out["hookSpecificOutput"]["additionalContext"])
        self.assertIsNone(self.run_hook(gate.hand_over, "UserPromptSubmit"))

    def test_stop_gives_one_more_turn_for_new_moves(self):
        out = self.run_hook(gate.stop, {"stop_hook_active": False})
        self.assertEqual(out["decision"], "block")
        self.assertIsNone(self.run_hook(gate.stop, {"stop_hook_active": False}))

    def test_stop_never_loops(self):
        self.assertIsNone(self.run_hook(gate.stop, {"stop_hook_active": True}))


if __name__ == "__main__":
    unittest.main()
