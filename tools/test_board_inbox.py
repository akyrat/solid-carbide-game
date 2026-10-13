"""Tests for board_inbox.py: session names, per-session cursors on the board's inbox, the watcher,
and the hook hand-overs built on them (T-127). Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"

Everything runs in a temporary tasks/ and .board/ folder; the real .board/ is never touched.
"""

import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import threading
import time
import unittest
from datetime import timedelta
from pathlib import Path
from unittest import mock

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))

import taskboard_sync as tb  # noqa: E402
import task_status as ts  # noqa: E402
import board_inbox as bi  # noqa: E402

_spec = importlib.util.spec_from_file_location("board_gate", TOOLS.parent / ".claude" / "hooks" / "board_gate.py")
gate = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(gate)

A, B, C = "aaaa-1111", "bbbb-2222", "cccc-3333"


def task(tid, lead=""):
    return (f"---\nid: {tid}\ntitle: Task {tid}\nstatus: open\nfrom: project-lead\nto: ui\nlead:{' ' + lead if lead else ''}\n"
            f"epic: tooling\nmilestone: mvp\ndepends_on: []\nmodel: sonnet\nqa_rounds: 0\n---\n\n## Description\n\nX.\n")


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
        tb.STATE_DIR.mkdir()

    def tearDown(self):
        tb.TASKS_DIR, tb.STATE_DIR, ts.LOG, tb.task_folders = self.saved
        self.tmp.cleanup()

    def put(self, tid, lead=""):
        (self.tasks / f"{tid}-test.md").write_bytes(task(tid, lead).encode("utf-8"))

    def drag(self, tid, frm="open", to="in-progress", note=""):
        """What the server appends for one drag (tools/taskboard/server.py, board_move)."""
        with bi.inbox_path().open("a", encoding="utf-8") as f:
            f.write(json.dumps({"id": tid, "from": frm, "to": to, "note": note, "at": "now"}) + "\n")

    def ids(self, sid):
        return [(m["id"], claim) for m, claim in bi.take(sid)[1]]

    def hook(self, fn, *args):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            fn(*args)
        return json.loads(buf.getvalue()) if buf.getvalue() else None


class Names(Base):
    def test_registers_a_name(self):
        line = bi.register(A, "Tools")
        self.assertIn("now named Tools", line)
        self.assertEqual(bi.name_of(A), "Tools")

    def test_renames(self):
        bi.register(A, "Tools")
        self.assertIn("(was Tools)", bi.register(A, "Camera"))
        self.assertEqual(bi.name_of(A), "Camera")
        bi.register(B, "Tools")   # the old name is free again
        self.assertEqual(bi.name_of(B), "Tools")

    def test_refuses_a_name_another_live_session_holds(self):
        bi.register(A, "Tools")
        with self.assertRaises(bi.Refused) as ctx:
            bi.register(B, "tools")   # names are unique whatever their case
        self.assertIn(A, str(ctx.exception))
        self.assertEqual((bi.name_of(A), bi.name_of(B)), ("Tools", ""))

    def test_take_over_moves_the_name(self):
        bi.register(A, "Tools")
        self.assertIn(f"taken over from {A}", bi.register(B, "Tools", take_over=True))
        self.assertEqual((bi.name_of(A), bi.name_of(B)), ("", "Tools"))

    def test_a_session_not_seen_for_12_hours_no_longer_holds_its_name(self):
        bi.register(A, "Tools")
        data = bi.load(A)
        data["seen"] = bi.stamp(bi.now() - timedelta(hours=13))
        bi.save(A, data)
        bi.register(B, "Tools")
        self.assertEqual((bi.name_of(A), bi.name_of(B)), ("", "Tools"))

    def test_refuses_bad_names_and_session_ids(self):
        for name in ("", "two words", "x" * 31, "Tools;rm", "-dash"):
            with self.assertRaises(bi.Refused):
                bi.register(A, name)
        with self.assertRaises(bi.Refused):
            bi.register("../evil", "Tools")

    def test_command_line(self):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            self.assertEqual(bi.main(["name", A, "Tools"]), 0)
            self.assertEqual(bi.main(["name", B, "Tools"]), 1)
            self.assertEqual(bi.main(["name", B, "Tools", "--take-over"]), 0)
            self.assertEqual(bi.main(["name", A]), 2)
        self.assertIn("Refused.", err.getvalue())
        self.assertEqual(bi.name_of(B), "Tools")


class Cursor(Base):
    def test_a_new_session_starts_at_the_end_of_the_inbox(self):
        self.put("T-001")
        self.drag("T-001")   # an old move, from before this session
        self.assertEqual(self.ids(A), [])
        self.drag("T-001", "in-progress", "in-qa")
        self.assertEqual(self.ids(A), [("T-001", False)])

    def test_an_old_heard_file_and_a_full_inbox_are_left_alone(self):
        self.drag("T-001")
        (tb.STATE_DIR / "board-inbox-heard.jsonl").write_text('{"id": "T-000"}\n', encoding="utf-8")
        self.assertEqual(self.ids(A), [])
        self.assertEqual(len(bi.inbox_path().read_text(encoding="utf-8").splitlines()), 1)
        self.assertTrue((tb.STATE_DIR / "board-inbox-heard.jsonl").exists())

    def test_a_half_written_line_waits_for_the_next_read(self):
        self.put("T-001")
        bi.take(A)
        with bi.inbox_path().open("a", encoding="utf-8") as f:
            f.write('{"id": "T-001", "from": "open", "to": "plan')
        self.assertEqual(self.ids(A), [])
        with bi.inbox_path().open("a", encoding="utf-8") as f:
            f.write('ning", "note": ""}\n')
        self.assertEqual(self.ids(A), [("T-001", False)])

    def test_a_busy_cursor_hands_nothing_and_loses_nothing(self):
        self.put("T-001")
        bi.take(A)
        self.drag("T-001")
        with tb.file_lock(bi.session_lock(A)), mock.patch.object(bi, "READ_WAIT", 0.05):
            self.assertEqual(bi.read_new(A)[1], [])   # another reader (the watcher) holds the cursor
        self.assertEqual(self.ids(A), [("T-001", False)])

    def test_a_replaced_shorter_inbox_is_read_from_its_start(self):
        self.put("T-001")
        bi.take(A)
        for _ in range(3):
            self.drag("T-001")
        self.ids(A)
        bi.inbox_path().write_text("", encoding="utf-8")
        self.drag("T-001", "open", "planning")
        self.assertEqual(self.ids(A), [("T-001", False)])


class TwoSessions(Base):
    """Sessions A ("Tools") and B ("Camera"); T-001 is A's, T-002 is B's, T-003 has no owner."""

    def setUp(self):
        super().setUp()
        self.put("T-001", "Tools")
        self.put("T-002", "Camera")
        self.put("T-003")
        bi.register(A, "Tools")
        bi.register(B, "Camera")
        for tid in ("T-001", "T-002", "T-003"):
            self.drag(tid)

    def test_each_session_gets_its_own_and_the_unowned_moves(self):
        self.assertEqual(self.ids(A), [("T-001", False), ("T-003", True)])
        self.assertEqual(self.ids(B), [("T-002", False), ("T-003", True)])

    def test_each_move_is_handed_over_once_per_session(self):
        self.ids(A)
        self.assertEqual(self.ids(A), [])
        self.assertEqual(len(self.ids(B)), 2)
        self.assertEqual(self.ids(B), [])

    def test_nothing_empties_or_renames_the_inbox(self):
        self.ids(A)
        self.ids(B)
        self.assertEqual(len(bi.inbox_path().read_text(encoding="utf-8").splitlines()), 3)
        self.assertEqual(sorted(p.name for p in tb.STATE_DIR.glob("board-inbox*")), ["board-inbox.jsonl"])

    def test_owners_are_read_when_the_move_is_handed_over(self):
        ts.claim("T-003", "Camera", folders={})
        self.assertEqual(self.ids(A), [("T-001", False)])
        self.assertEqual(self.ids(B), [("T-002", False), ("T-003", False)])

    def test_the_hook_message(self):
        out = self.hook(gate.hand_over, "UserPromptSubmit", {"session_id": A})
        text = out["hookSpecificOutput"]["additionalContext"]
        self.assertTrue(text.startswith(gate.describe_moves([{"id": "T-001", "from": "open", "to": "in-progress"},
                                                             {"id": "T-003", "from": "open", "to": "in-progress"}])))
        self.assertIn("No session owns T-003 yet", text)
        self.assertIn("python tools/task_status.py <id> --lead Tools", text)
        self.assertIn("only if the claim succeeds", text)
        self.assertNotIn("T-002", text)
        self.assertNotIn("no name yet", text)
        self.assertIsNone(self.hook(gate.hand_over, "UserPromptSubmit", {"session_id": A}))

    def test_hooks_and_the_watcher_share_one_cursor(self):
        out = io.StringIO()
        bi.watch(A, interval=0, out=out, rounds=1)
        self.assertEqual(len(out.getvalue().splitlines()), 2)
        self.assertIsNone(self.hook(gate.hand_over, "PostToolUse", {"session_id": A}))
        self.assertIsNone(self.hook(gate.stop, {"session_id": A, "stop_hook_active": False}))
        self.drag("T-001", "in-progress", "in-qa")
        self.assertIsNotNone(self.hook(gate.stop, {"session_id": A, "stop_hook_active": False}))
        out = io.StringIO()
        bi.watch(A, interval=0, out=out, rounds=1)
        self.assertEqual(out.getvalue(), "")


class NoName(Base):
    def test_a_session_without_a_name_gets_every_move_and_a_reminder(self):
        self.put("T-001", "Tools")
        self.put("T-002")
        bi.take(C)
        self.drag("T-001")
        self.drag("T-002")
        out = self.hook(gate.hand_over, "PostToolUse", {"session_id": C})
        text = out["hookSpecificOutput"]["additionalContext"]
        self.assertIn("T-001 open → in-progress", text)
        self.assertIn("T-002 open → in-progress", text)
        self.assertNotIn("No session owns", text)
        self.assertIn(f"python tools/board_inbox.py name {C} <Name>", text)

    def test_every_prompt_reminds_it_until_it_has_a_name(self):
        bi.take(C)
        out = self.hook(gate.hand_over, "UserPromptSubmit", {"session_id": C})
        self.assertIn("has no name yet", out["hookSpecificOutput"]["additionalContext"])
        bi.register(C, "Tools")
        self.assertIsNone(self.hook(gate.hand_over, "UserPromptSubmit", {"session_id": C}))

    def test_session_start_gives_the_id_and_the_commands(self):
        with mock.patch.object(gate, "ensure_server", lambda: ("http://localhost:9", "already running")):
            out = self.hook(gate.session_start, {"session_id": C, "hook_event_name": "SessionStart"})
            text = out["hookSpecificOutput"]["additionalContext"]
            self.assertIn(f"This session's id is {C}", text)
            self.assertIn(f"python tools/board_inbox.py name {C} <Name>", text)
            self.assertIn(f"python tools/board_inbox.py watch {C}", text)
            bi.register(C, "Tools")
            text = self.hook(gate.session_start, {"session_id": C})["hookSpecificOutput"]["additionalContext"]
            self.assertIn("Its name is Tools", text)
            self.assertNotIn("no name yet", text)

    def test_session_start_does_not_replay_old_moves(self):
        self.put("T-001")
        self.drag("T-001")
        with mock.patch.object(gate, "ensure_server", lambda: ("http://localhost:9", "already running")):
            text = self.hook(gate.session_start, {"session_id": C})["hookSpecificOutput"]["additionalContext"]
        self.assertNotIn("T-001", text)


class Watcher(Base):
    def test_prints_one_line_per_move_and_advances_the_cursor(self):
        self.put("T-001", "Tools")
        self.put("T-002", "Camera")
        self.put("T-003")
        bi.register(A, "Tools")
        out = io.StringIO()
        thread = threading.Thread(target=bi.watch, args=(A, 0.02, out, 40))
        thread.start()
        time.sleep(0.1)
        self.drag("T-001", note="go")
        self.drag("T-002")
        self.drag("T-003", "open", "planning")
        thread.join()
        lines = out.getvalue().splitlines()
        self.assertEqual(lines[0], "T-001 open → in-progress (note: go)")
        self.assertTrue(lines[1].startswith("T-003 open → planning [no owner yet: claim it with "
                                            "python tools/task_status.py T-003 --lead Tools"))
        self.assertEqual(len(lines), 2)
        self.assertEqual(bi.load(A)["cursor"], bi.inbox_size())

    def test_an_unnamed_watcher_starts_with_the_reminder(self):
        out = io.StringIO()
        bi.watch(C, interval=0, out=out, rounds=1)
        self.assertIn("has no name yet", out.getvalue())


if __name__ == "__main__":
    unittest.main()
