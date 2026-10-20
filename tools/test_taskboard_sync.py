"""Tests for taskboard_sync.py. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import sys
import tempfile
import unittest
from unittest import mock
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import taskboard_sync as tb  # noqa: E402

TASK = """---
id: T-900
title: A test task
status: blocked
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-012, T-029]
documents_affected: []
files_to_read_first: [tasks/README.md]
files_expected_to_change: []
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
-->

## Description

Body text with status: in words.
"""


class TaskboardSyncTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.tasks = Path(self.tmp.name) / "tasks"
        self.tasks.mkdir()
        (self.tasks / "T-900-test.md").write_text(TASK.replace("\n", "\r\n"), encoding="utf-8", newline="")

    def tearDown(self):
        self.tmp.cleanup()

    def test_ticket_reads_the_header_with_lists(self):
        doc = tb.ticket(self.tasks / "T-900-test.md")
        self.assertEqual(doc["status"], "blocked")
        self.assertEqual(doc["depends_on"], ["T-012", "T-029"])
        self.assertEqual(doc["file"], "tasks/T-900-test.md")
        self.assertEqual(doc["file_status"], "blocked")
        self.assertEqual(doc["lead"], "")   # no lead line: no owner

    def test_ticket_reads_the_lead(self):
        path = self.tasks / "T-900-test.md"
        path.write_text(TASK.replace("to: ui\n", "to: ui\nlead: Tools\n"), encoding="utf-8")
        self.assertEqual(tb.ticket(path)["lead"], "Tools")
        path.write_text(TASK.replace("to: ui\n", "to: ui\nlead:\n"), encoding="utf-8")
        self.assertEqual(tb.ticket(path)["lead"], "")

    def test_ticket_reads_the_review_and_result_notes(self):
        body = ("Body.\n\nThe board's review: drive it and judge the feel.\n"
                "Board review files: [game/README.md, docs/drifting.md]\n\n## Result notes\n\nIt works.\n")
        (self.tasks / "T-900-test.md").write_text(TASK.replace("Body text with status: in words.\n", body), encoding="utf-8")
        doc = tb.ticket(self.tasks / "T-900-test.md")
        self.assertEqual(doc["review"], "drive it and judge the feel.")
        self.assertEqual(doc["review_files"], ["game/README.md", "docs/drifting.md"])
        self.assertEqual(doc["result_notes"], "It works.")
        self.assertEqual(doc["qa_rounds"], 0)

    def test_ticket_returns_updates_in_order_apart_from_the_result_notes(self):
        text = TASK + (
            "\n## Updates\n\n### 2026-10-14, Open → In progress\n\nFirst.\n\nStill first.\n\n"
            "### 2026-10-15, In progress → In QA\n\nSecond.\n\n"
            "## Result notes\n\nThe agent's notes.\n")
        (self.tasks / "T-900-test.md").write_text(text, encoding="utf-8")
        t = tb.ticket(self.tasks / "T-900-test.md")
        self.assertEqual([(u["date"], u["change"], u["text"]) for u in t["updates"]], [
            ("2026-10-14", "Open → In progress", "First.\n\nStill first."),
            ("2026-10-15", "In progress → In QA", "Second.")])
        self.assertEqual(t["result_notes"], "The agent's notes.")

    def test_ticket_without_updates_has_an_empty_list(self):
        self.assertEqual(tb.ticket(self.tasks / "T-900-test.md")["updates"], [])

    def test_tickets_now_prefers_the_task_branch_folder(self):
        folder = Path(self.tmp.name) / "worktrees" / "T-900"
        (folder / "tasks").mkdir(parents=True)
        (folder / "tasks" / "T-900-test.md").write_text(TASK.replace("status: blocked", "status: in-qa"), encoding="utf-8")
        tickets = tb.tickets_now(self.tasks, {"T-900": folder})
        self.assertEqual(len(tickets), 1)
        self.assertEqual(tickets[0]["status"], "in-qa")
        self.assertTrue(tickets[0]["folder"].endswith("T-900"))

    def test_tickets_now_reads_master_without_a_branch(self):
        tickets = tb.tickets_now(self.tasks, {})
        self.assertEqual([t["status"] for t in tickets], ["blocked"])

    def run_task_folders_as(self, os_name):
        done = mock.Mock(stdout="worktree C:/w/T-900\nbranch refs/heads/task/T-900-test\n")
        with mock.patch.object(tb.os, "name", os_name), mock.patch.object(tb.subprocess, "run", return_value=done) as run:
            folders = tb.task_folders()
        return folders, run.call_args.kwargs.get("creationflags")

    def test_task_folders_opens_no_window_on_windows(self):
        # The board's server has no console; without this flag git opens a terminal window on every refresh (T-110).
        folders, flags = self.run_task_folders_as("nt")
        self.assertEqual(flags, 0x08000000)
        self.assertEqual(folders, {"T-900": Path("C:/w/T-900")})

    def test_task_folders_passes_no_flags_elsewhere(self):
        _, flags = self.run_task_folders_as("posix")
        self.assertEqual(flags, 0)

    def add_file(self, base, rel, data=b"x"):
        path = Path(base) / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        return path

    def test_media_from_the_screenshots_folder_and_its_subfolders(self):
        root = Path(self.tmp.name)
        self.add_file(root, "art-archive/T-900/screenshots/a.png", b"12345")
        self.add_file(root, "art-archive/T-900/screenshots/run/clip.MP4")
        self.add_file(root, "art-archive/T-900/screenshots/notes.txt")    # not media
        self.add_file(root, "art-archive/T-900/raw.png")                  # not in screenshots/
        media = tb.ticket(self.tasks / "T-900-test.md")["media"]
        self.assertEqual(media, [
            {"path": "art-archive/T-900/screenshots/a.png", "kind": "image", "size": 5},
            {"path": "art-archive/T-900/screenshots/run/clip.MP4", "kind": "video", "size": 1}])

    def test_media_from_the_board_review_files_line(self):
        root = Path(self.tmp.name)
        self.add_file(root, "game/shot.webp")
        self.add_file(root, "art-archive/T-900/screenshots/a.gif")
        outside = self.add_file(Path(self.tmp.name).parent, f"outside-{Path(self.tmp.name).name}.png")
        self.addCleanup(outside.unlink)
        body = ("Board review files: [game/shot.webp, docs/x.md, game/missing.png, ../" + outside.name
                + ", " + str(outside) + ", art-archive/T-900/screenshots/a.gif]\n")
        (self.tasks / "T-900-test.md").write_text(TASK + body, encoding="utf-8")
        media = tb.ticket(self.tasks / "T-900-test.md")["media"]
        self.assertEqual([(m["path"], m["kind"]) for m in media],
                         [("art-archive/T-900/screenshots/a.gif", "image"), ("game/shot.webp", "image")])

    def test_media_of_an_open_task_come_from_its_folder(self):
        root = Path(self.tmp.name)
        self.add_file(root, "art-archive/T-900/screenshots/main.png")
        folder = root / "worktrees" / "T-900"
        (folder / "tasks").mkdir(parents=True)
        (folder / "tasks" / "T-900-test.md").write_text(TASK, encoding="utf-8")
        self.add_file(folder, "art-archive/T-900/screenshots/branch.webm")
        t = tb.tickets_now(self.tasks, {"T-900": folder})[0]
        self.assertEqual([(m["path"], m["kind"]) for m in t["media"]], [("art-archive/T-900/screenshots/branch.webm", "video")])
        t = tb.tickets_now(self.tasks, {})[0]
        self.assertEqual([m["path"] for m in t["media"]], ["art-archive/T-900/screenshots/main.png"])

    def test_no_media_is_an_empty_list(self):
        self.assertEqual(tb.ticket(self.tasks / "T-900-test.md")["media"], [])

    def test_safe_relative_refuses_escapes(self):
        base = Path(self.tmp.name)
        for bad in ["../x.png", "a/../../x.png", "/etc/x.png", "C:/x.png", "a\\..\\x.png", "", "a//b.png", "./a.png"]:
            self.assertIsNone(tb.safe_relative(base, bad), bad)
        self.assertEqual(tb.safe_relative(base, "a\\b.png"), "a/b.png")

    def test_real_task_files_all_parse(self):
        for path in tb.task_files():
            self.assertIsNotNone(tb.ticket(path), path.name)

    def test_ticket_reads_its_goal(self):
        path = self.tasks / "T-900-test.md"
        self.assertEqual(tb.ticket(path)["goal"], "")   # no goal line
        path.write_text(TASK.replace("to: ui\n", "to: ui\ngoal: G-007\n"), encoding="utf-8")
        self.assertEqual(tb.ticket(path)["goal"], "G-007")
        path.write_text(TASK.replace("to: ui\n", "to: ui\ngoal:\n"), encoding="utf-8")
        self.assertEqual(tb.ticket(path)["goal"], "")


def goal_text(gid="G-007", status="paused", pauses="None yet.", art_cap=30, art_used=4, iteration=3):
    """A goal file as the goal runner writes it (tools/goal_agent/goal_file.py)."""
    return (f"---\nid: {gid}\ntitle: Build the thing\nstatus: {status}\nart_cap: {art_cap}\nart_used: {art_used}\n"
            f"iteration: {iteration}\nmax_iterations: 20\ncreated: 2026-10-19\nlead: Goal-{gid}\n---\n\n"
            "## Goal\n\nBuild the thing, as written in the docs.\n\n"
            "## Goal acceptance criteria\n\n- [ ] It runs. (QA: pass / fail)\n\n"
            "## Tickets\n\n- T-901: one (S1, written)\n\n"
            "## Iteration log\n\n- 2026-10-19, iteration 0: started: planning.\n\n"
            f"## Pauses\n\n{pauses}\n\n")


def goal_task(task_id, goal="", status="open"):
    return f"---\nid: {task_id}\ntitle: Ticket {task_id}\nstatus: {status}\nto: ui\ngoal: {goal}\n---\n\nBody\n"


class GoalTests(unittest.TestCase):
    """T-202: the goal files as the board shows them."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        base = Path(self.tmp.name)
        self.goals, self.tasks, self.wt = base / "goals", base / "tasks", base / "worktrees" / "T-902"
        for folder in (self.goals, self.tasks, self.wt / "tasks"):
            folder.mkdir(parents=True)
        pauses = ("- 2026-10-18 [refusal]: The agent reported a refusal.\n"
                  "- 2026-10-19: Claude could not be run for step 'agent':\n  You've hit your session limit")
        (self.goals / "G-007-build-the-thing.md").write_text(goal_text(pauses=pauses), encoding="utf-8")
        (self.goals / "G-006-older.md").write_text(goal_text("G-006", "done", art_cap=0), encoding="utf-8")
        (self.goals / "README.md").write_text("# Goals\n", encoding="utf-8")
        (self.goals / "G-005-broken.md").write_text("no header here\n", encoding="utf-8")
        for task_id, goal, status in [("T-901", "G-007", "done"), ("T-902", "G-007", "open"), ("T-903", "G-007", "cancelled"),
                                      ("T-904", "G-006", "done"), ("T-905", "", "open")]:
            (self.tasks / f"{task_id}-t.md").write_text(goal_task(task_id, goal, status), encoding="utf-8")
        # T-902's branch is open: its task folder's copy (in QA) is the one that counts.
        (self.wt / "tasks" / "T-902-t.md").write_text(goal_task("T-902", "G-007", "in-qa"), encoding="utf-8")
        self.tickets = tb.tickets_now(self.tasks, {"T-902": self.wt})

    def test_goal_files_skip_other_files(self):
        self.assertEqual([p.name for p in tb.goal_files(self.goals)],
                         ["G-005-broken.md", "G-006-older.md", "G-007-build-the-thing.md"])
        self.assertEqual(tb.goal_files(Path(self.tmp.name) / "missing"), [])

    def test_goal_reads_the_header_and_goal_text(self):
        g = tb.goal(self.goals / "G-007-build-the-thing.md", self.tickets)
        self.assertEqual((g["id"], g["title"], g["status"], g["art_cap"], g["art_used"], g["iteration"], g["max_iterations"]),
                         ("G-007", "Build the thing", "paused", 30, 4, 3, 20))
        self.assertEqual((g["created"], g["lead"], g["file"]), ("2026-10-19", "Goal-G-007", "goals/G-007-build-the-thing.md"))
        self.assertEqual(g["goal_text"], "Build the thing, as written in the docs.")

    def test_goal_tickets_from_their_goal_lines_with_counts(self):
        g = tb.goal(self.goals / "G-007-build-the-thing.md", self.tickets)
        self.assertEqual(g["tickets"], ["T-901", "T-902", "T-903"])
        self.assertEqual(g["ticket_counts"], {"done": 1, "in-qa": 1, "cancelled": 1})   # T-902 from its task folder
        self.assertEqual((g["tickets_total"], g["tickets_finished"]), (3, 2))
        older = tb.goal(self.goals / "G-006-older.md", self.tickets)
        self.assertEqual((older["tickets"], older["ticket_counts"]), (["T-904"], {"done": 1}))

    def test_goal_pauses_and_latest_pause_when_paused(self):
        g = tb.goal(self.goals / "G-007-build-the-thing.md", self.tickets)
        self.assertEqual(g["pauses"], [
            {"date": "2026-10-18", "kind": "refusal", "reason": "The agent reported a refusal."},
            {"date": "2026-10-19", "kind": "stop", "reason": "Claude could not be run for step 'agent':\nYou've hit your session limit"}])
        self.assertEqual(g["latest_pause"], g["pauses"][-1])
        done = tb.goal(self.goals / "G-006-older.md", self.tickets)
        self.assertEqual((done["pauses"], done["latest_pause"]), ([], None))

    def test_latest_pause_only_while_paused(self):
        path = self.goals / "G-007-build-the-thing.md"
        path.write_text(goal_text(status="building", pauses="- 2026-10-18 [stop]: old"), encoding="utf-8")
        g = tb.goal(path, self.tickets)
        self.assertEqual(len(g["pauses"]), 1)
        self.assertIsNone(g["latest_pause"])

    def test_goal_build_folder(self):
        folder = Path(self.tmp.name) / "worktrees" / "G-007"
        g = tb.goal(self.goals / "G-007-build-the-thing.md", self.tickets, {"G-007": folder, "T-902": self.wt})
        self.assertEqual((g["has_build"], g["build_folder"]), (True, str(folder)))
        g = tb.goal(self.goals / "G-007-build-the-thing.md", self.tickets, {"T-902": self.wt})
        self.assertEqual((g["has_build"], g["build_folder"]), (False, ""))

    def test_goals_now_newest_first_skipping_unreadable_files(self):
        self.assertEqual([g["id"] for g in tb.goals_now(self.goals, self.tickets)], ["G-007", "G-006"])

    def test_long_pause_reasons_are_cut(self):
        p = tb.goal_pauses("- 2026-10-18 [stop]: " + "x" * (tb.PAUSE_REASON_MAX + 50))
        self.assertTrue(p[0]["reason"].startswith("x" * tb.PAUSE_REASON_MAX))
        self.assertIn("cut short", p[0]["reason"])

    def test_real_goal_files_all_parse(self):
        files = tb.goal_files(tb.ROOT / "goals")
        docs = tb.goals_now(tb.ROOT / "goals")
        self.assertEqual(len(docs), len(files))
        for d in docs:
            self.assertRegex(d["id"], r"^G-\d{3,}$")
            self.assertTrue(d["goal_text"], d["id"])


def tool(name, **args):
    """A stream-json assistant event calling one tool."""
    return {"type": "assistant", "message": {"content": [{"type": "tool_use", "id": "t", "name": name, "input": args}]}}


def bash(command):
    return tool("Bash", command=command, description="x")


class PhraseTests(unittest.TestCase):
    """T-203: the rules that turn the runner's events into plain phrases (no AI)."""

    def test_reading_and_editing_name_the_file(self):
        wt = "C:\\solid-carbide-worktrees\\T-196\\"
        self.assertEqual(tb.event_phrase(tool("Read", file_path=wt + "docs\\level-design.md")), "Reading `docs/level-design.md`")
        self.assertEqual(tb.event_phrase(tool("Read", file_path="C:/solid-carbide-game/tasks/README.md")), "Reading `tasks/README.md`")
        self.assertEqual(tb.event_phrase(tool("Edit", file_path=wt + "game\\scripts\\level\\ground_height.gd")),
                         "Editing `game/scripts/level/ground_height.gd`")
        deep = wt + "game/scripts/level/elevation/some/very/deep/folder/ground_height.gd"
        self.assertEqual(tb.event_phrase(tool("Edit", file_path=deep)), "Editing `ground_height.gd`")
        self.assertEqual(tb.event_phrase(tool("Write", file_path="D:/elsewhere/notes.txt")), "Writing `notes.txt`")

    def test_running_tests(self):
        for cmd in ("bash game/tools/run_tests.sh", "powershell -ExecutionPolicy Bypass -File game/tools/run_tests.ps1",
                    "bash game/tools/run_tests.sh -gselect=test_ground"):
            self.assertEqual(tb.event_phrase(bash(cmd)), "Running the game's tests", cmd)
        for cmd in ('python -m unittest discover -s tools -p "test_*.py"', "python game/tools/test_pixel_sheet.py"):
            self.assertEqual(tb.event_phrase(bash(cmd)), "Running the tools' tests", cmd)

    def test_screenshots_pixellab_and_committing(self):
        self.assertEqual(tb.event_phrase(bash("bash game/tools/screenshot.sh res://tests/fixtures/x.tscn screenshots/a.png 40")),
                         "Taking screenshots")
        self.assertEqual(tb.event_phrase(bash("python game/tools/pixellab_client.py rotate car")), "Calling PixelLab")
        self.assertEqual(tb.event_phrase(tool("mcp__pixellab__create_character", description="car")), "Calling PixelLab")
        self.assertEqual(tb.event_phrase(bash('git commit -m "T-196: ground height"')), "Committing")
        self.assertEqual(tb.event_phrase(bash("git -C C:/w/T-196 commit -q -m x")), "Committing")
        self.assertEqual(tb.event_phrase(bash("git status --short")), "Using git")

    def test_an_unknown_tool_gets_a_generic_phrase(self):
        self.assertEqual(tb.event_phrase(tool("FrobnicateWidget", x=1)), "Using FrobnicateWidget")
        self.assertEqual(tb.event_phrase(tool("mcp__someserver__do_thing")), "Using do_thing")
        self.assertEqual(tb.event_phrase(bash("ls -la")), "Running a command")
        self.assertEqual(tb.event_phrase(tool("Grep", pattern="x")), "Searching the files")

    def test_thinking_starting_finishing_and_events_without_a_phrase(self):
        self.assertEqual(tb.event_phrase({"type": "assistant", "message": {"content": [{"type": "thinking", "thinking": "hm"}]}}),
                         "Thinking")
        self.assertEqual(tb.event_phrase({"type": "assistant", "message": {"content": [{"type": "text", "text": "Now"}]}}),
                         "Thinking")
        self.assertEqual(tb.event_phrase({"type": "system", "subtype": "init"}), "Starting")
        self.assertEqual(tb.event_phrase({"type": "result", "is_error": False}), "Finished")
        self.assertIsNone(tb.event_phrase({"type": "user", "message": {"content": [{"type": "tool_result"}]}}))
        self.assertIsNone(tb.event_phrase({"type": "stream_event"}))
        self.assertIsNone(tb.event_phrase("not an event"))

    def test_qa_and_the_goal_check_say_so(self):
        self.assertEqual(tb.step_phrase("qa", "Thinking"), "QA checking")
        self.assertEqual(tb.step_phrase("qa", "Running the game's tests"), "QA checking: running the game's tests")
        self.assertEqual(tb.step_phrase("goal-check", "Starting"), "Goal check")
        self.assertEqual(tb.step_phrase("agent", "Committing"), "Committing")


class ActivityLogTests(unittest.TestCase):
    """T-203: the activity logs: written one event per line, read from the end only, capped in size."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.dir = Path(self.tmp.name) / "activity"

    def test_append_and_read_back_with_a_summary(self):
        events = [("12:00:00", "agent", {"type": "system", "subtype": "init"}),
                  ("12:00:05", "agent", tool("Read", file_path="C:/solid-carbide-worktrees/T-1/docs/drifting.md")),
                  ("12:00:06", "agent", {"type": "user", "message": {"content": [{"type": "tool_result", "content": "x" * 9000}]}}),
                  ("12:00:09", "agent", tool("Read", file_path="C:/solid-carbide-worktrees/T-1/docs/drifting.md")),
                  ("12:01:00", "agent", bash("bash game/tools/run_tests.sh")),
                  ("12:03:00", "qa", {"type": "assistant", "message": {"content": [{"type": "thinking", "thinking": "."}]}})]
        for clock, step, event in events:
            tb.append_activity(self.dir, "T-001", step, event, at=f"2026-10-19T{clock}Z")
        path = self.dir / "T-001.jsonl"
        self.assertEqual(len(path.read_text(encoding="utf-8").splitlines()), 6)
        self.assertLess(path.stat().st_size, 3000, "long tool output is not kept")
        s = tb.activity_summary(tb.read_activity(path))
        self.assertEqual([x["phrase"] for x in s["timeline"]],
                         ["Starting", "Reading `docs/drifting.md`", "Running the game's tests", "QA checking"])
        self.assertEqual((s["phrase"], s["since"], s["step"], s["last_at"]),
                         ("QA checking", "2026-10-19T12:03:00Z", "qa", "2026-10-19T12:03:00Z"))
        self.assertEqual(s["timeline"][1]["at"], "2026-10-19T12:00:05Z", "a repeated phrase keeps its first time")

    def test_the_timeline_keeps_the_last_twenty(self):
        for i in range(30):
            tb.append_activity(self.dir, "T-002", "agent", tool("Edit", file_path=f"C:/w/f{i}.gd"), at=f"2026-10-19T12:{i:02d}:00Z")
        s = tb.activity_summary(tb.read_activity(self.dir / "T-002.jsonl"))
        self.assertEqual(len(s["timeline"]), 20)
        self.assertEqual((s["timeline"][0]["phrase"], s["phrase"]), ("Editing `f10.gd`", "Editing `f29.gd`"))

    def test_reading_only_the_end(self):
        path = self.dir / "T-003.jsonl"
        for i in range(200):
            tb.append_activity(self.dir, "T-003", "agent", tool("Edit", file_path=f"C:/w/f{i}.gd"), at="2026-10-19T12:00:00Z")
        entries = tb.read_activity(path, max_bytes=2000)
        self.assertTrue(0 < len(entries) < 20)
        self.assertEqual(entries[-1]["event"]["message"]["content"][0]["input"]["file_path"], "C:/w/f199.gd")
        with mock.patch("builtins.open", wraps=open) as opened:
            tb.read_activity(path, max_bytes=2000)
        self.assertEqual(opened.call_count, 1)

    def test_bad_lines_and_a_missing_or_deleted_log(self):
        self.assertEqual(tb.read_activity(self.dir / "T-009.jsonl"), [])
        self.assertIsNone(tb.activity_summary([]))
        self.dir.mkdir(parents=True)
        (self.dir / "T-004.jsonl").write_text('not json\n{"at": "2026-10-19T12:00:00Z", "step": "agent", "event": '
                                              '{"type": "system", "subtype": "init"}}\n{"half', encoding="utf-8")
        self.assertEqual(len(tb.read_activity(self.dir / "T-004.jsonl")), 1)
        (self.dir / "T-004.jsonl").unlink()
        self.assertTrue(tb.append_activity(self.dir, "T-004", "agent", {"type": "system", "subtype": "init"}))

    def test_only_ticket_and_goal_ids_name_a_log(self):
        for bad in ("../x", "T-1/../../y", "README", "", None):
            self.assertIsNone(tb.append_activity(self.dir, bad, "agent", {"type": "system"}), bad)
        self.assertTrue(tb.append_activity(self.dir, "G-004", "goal-check", {"type": "system"}))

    def test_a_log_is_capped_in_size(self):
        with mock.patch.object(tb, "ACTIVITY_MAX_BYTES", 5000), mock.patch.object(tb, "ACTIVITY_KEEP_BYTES", 2000):
            for i in range(300):
                tb.append_activity(self.dir, "T-005", "agent", tool("Edit", file_path=f"C:/w/f{i}.gd"), at="2026-10-19T12:00:00Z")
        path = self.dir / "T-005.jsonl"
        self.assertLessEqual(path.stat().st_size, 5000)
        entries = tb.read_activity(path)
        self.assertEqual(len(entries), len(path.read_text(encoding="utf-8").splitlines()), "it starts on a whole line")
        self.assertEqual(entries[-1]["event"]["message"]["content"][0]["input"]["file_path"], "C:/w/f299.gd")


if __name__ == "__main__":
    unittest.main()
