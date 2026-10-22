"""Tests for the Builds, media and goals endpoints of tools/taskboard/server.py. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"

Godot is never started: the process start is replaced by a stub.
"""

import json
import sys
import tempfile
import threading
import unittest
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent / "taskboard"))

import server  # noqa: E402

REAL_GODOT_BIN = server.godot_bin
TASK = "---\nid: T-901\ntitle: A build\nstatus: needs-playtest\nlead: Tools\n---\n\nBody\n"


def add_creator(folder):
    scene = Path(folder) / "game" / "scenes" / "level_creator" / "level_creator.tscn"
    scene.parent.mkdir(parents=True, exist_ok=True)
    scene.write_text("", encoding="utf-8")


class Fixture(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        base = Path(self.tmp.name)
        self.main, self.wt, self.bare = base / "main", base / "wt-T-901", base / "other"
        for folder in (self.main, self.wt):
            (folder / "game").mkdir(parents=True)
            (folder / "game" / "project.godot").write_text("", encoding="utf-8")
        (self.bare / "game").mkdir(parents=True)
        (self.main / "tasks").mkdir()
        (self.main / "tasks" / "T-901-a-build.md").write_text(TASK, encoding="utf-8")
        self.godot = base / "godot.exe"
        self.godot.write_text("", encoding="utf-8")
        self.listing = [(self.main, "master"), (self.wt, "task/T-901-a-build"), (self.bare, "task/T-902-x")]
        patches = [mock.patch.object(server, "worktrees", lambda root=None: self.listing),
                   mock.patch.object(server.tb, "ROOT", self.main),
                   mock.patch.object(server, "godot_bin", lambda root=None: str(self.godot))]
        for p in patches:
            p.start()
            self.addCleanup(p.stop)


class BuildsTests(Fixture):
    def test_entries(self):
        entries = server.builds()
        self.assertEqual([e["id"] for e in entries], ["master", "wt-T-901", "other"])
        e = entries[1]
        self.assertEqual((e["folder"], e["branch"], e["ticket_id"], e["ticket_title"], e["ticket_status"], e["has_project"]),
                         (str(self.wt), "task/T-901-a-build", "T-901", "A build", "needs-playtest", True))
        self.assertEqual(entries[0]["ticket_id"], "")
        self.assertEqual((e["lead"], entries[0]["lead"]), ("Tools", ""))
        self.assertFalse(entries[2]["has_project"])
        self.assertEqual(entries[2]["ticket_title"], "")

    def test_whether_each_folder_has_the_creator_scene(self):
        self.assertEqual([e["has_creator"] for e in server.builds()], [False, False, False])
        add_creator(self.wt)
        add_creator(self.bare)   # a scene without game/project.godot cannot be started
        self.assertEqual([e["has_creator"] for e in server.builds()], [False, True, False])

    def test_godot_bin_reads_only_that_key(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertEqual(REAL_GODOT_BIN(d), "")
            (Path(d) / ".env").write_text("PIXELLAB_API_KEY=secret" + chr(10) + 'GODOT_BIN="C:/g/godot.exe"' + chr(10), encoding="utf-8")
            self.assertEqual(REAL_GODOT_BIN(d), "C:/g/godot.exe")


class LaunchTests(Fixture):
    def run_launch(self, entry_id, mode):
        with mock.patch.object(server, "start_detached") as start:
            code, body = server.launch(entry_id, mode)
        return code, body, start

    def test_play_and_editor_arguments(self):
        game = str(self.wt / "game")
        code, _, start = self.run_launch("wt-T-901", "play")
        self.assertEqual(code, 200)
        start.assert_called_once_with([str(self.godot), "--path", game])
        code, _, start = self.run_launch("wt-T-901", "editor")
        self.assertEqual(code, 200)
        start.assert_called_once_with([str(self.godot), "--editor", "--path", game])

    def test_creator_arguments(self):
        add_creator(self.wt)
        code, _, start = self.run_launch("wt-T-901", "creator")
        self.assertEqual(code, 200)
        start.assert_called_once_with([str(self.godot), "--path", str(self.wt / "game"),
                                       "res://scenes/level_creator/level_creator.tscn"])

    def test_creator_refused_without_the_scene(self):
        add_creator(self.bare)
        for entry_id in ("master", "other"):   # no scene; scene but no project.godot
            code, body, start = self.run_launch(entry_id, "creator")
            self.assertEqual(code, 409)
            self.assertIn("error", body)
            start.assert_not_called()

    def test_refusals_start_nothing(self):
        for entry_id, mode, expected in [("nope", "play", 404), ("wt-T-901", "run", 400), ("other", "play", 409)]:
            code, body, start = self.run_launch(entry_id, mode)
            self.assertEqual(code, expected)
            self.assertIn("error", body)
            start.assert_not_called()

    def test_godot_bin_missing_or_wrong(self):
        for value in ("", str(self.godot) + ".missing"):
            with mock.patch.object(server, "godot_bin", lambda root=None, v=value: v):
                code, body, start = self.run_launch("master", "play")
            self.assertEqual(code, 500)
            self.assertIn("GODOT_BIN", body["error"])
            start.assert_not_called()

    def test_detached_without_console(self):
        with mock.patch.object(server.os, "name", "nt"), mock.patch.object(server.subprocess, "Popen") as popen:
            server.start_detached(["g"])
        flags = popen.call_args.kwargs["creationflags"]
        self.assertTrue(flags & 0x08000000)   # CREATE_NO_WINDOW
        self.assertTrue(flags & 0x00000200)   # CREATE_NEW_PROCESS_GROUP
        with mock.patch.object(server.os, "name", "posix"), mock.patch.object(server.subprocess, "Popen") as popen:
            server.start_detached(["g"])
        self.assertTrue(popen.call_args.kwargs["start_new_session"])
        self.assertNotIn("creationflags", popen.call_args.kwargs)


class HttpTests(Fixture):
    def setUp(self):
        super().setUp()
        self.httpd = server.make_server(0)
        self.port = self.httpd.server_address[1]
        threading.Thread(target=self.httpd.serve_forever, daemon=True).start()
        self.addCleanup(self.httpd.server_close)
        self.addCleanup(self.httpd.shutdown)
        start = mock.patch.object(server, "start_detached")
        self.start = start.start()
        self.addCleanup(start.stop)

    def post(self, body, headers=None, host=None):
        h = {"Content-Type": "application/json", "X-Board": "1"} if headers is None else headers
        if host:
            h = {**h, "Host": host}
        req = urllib.request.Request(f"http://127.0.0.1:{self.port}/api/launch", data=json.dumps(body).encode(), method="POST", headers=h)
        try:
            with urllib.request.urlopen(req) as r:
                return r.status, json.loads(r.read())
        except urllib.error.HTTPError as e:
            return e.code, json.loads(e.read())

    def test_get_builds(self):
        with urllib.request.urlopen(f"http://127.0.0.1:{self.port}/api/builds") as r:
            data = json.loads(r.read())
        self.assertEqual(len(data["builds"]), 3)
        self.assertNotIn("GODOT", json.dumps(data))

    def test_valid_launch(self):
        self.assertEqual(self.post({"id": "master", "mode": "play"})[0], 200)
        self.start.assert_called_once()

    def test_creator_launch_takes_no_scene_from_the_request(self):
        add_creator(self.wt)
        code, _ = self.post({"id": "wt-T-901", "mode": "creator", "scene": "res://other.tscn",
                             "args": ["--script", "x.gd"], "folder": "C:/Windows"})
        self.assertEqual(code, 200)
        self.start.assert_called_once_with([str(self.godot), "--path", str(self.wt / "game"),
                                            "res://scenes/level_creator/level_creator.tscn"])

    def test_creator_refused_outside_the_worktree_list(self):
        for entry_id in ("C:/Windows", "../wt-T-901", "nope", "master"):
            code, _ = self.post({"id": entry_id, "mode": "creator"})
            self.assertTrue(400 <= code < 500, code)
        self.start.assert_not_called()

    def test_refused_requests(self):
        cases = [
            self.post({"id": "master", "mode": "play"}, headers={"Content-Type": "application/json"}),
            self.post({"id": "master", "mode": "play"}, host="example.com"),
            self.post({"id": "C:/Windows/notepad.exe", "mode": "play"}),
            self.post({"id": "master", "mode": "debug"}),
            self.post({"id": "other", "mode": "play"}),
            self.post({"id": "master"}),
        ]
        for code, _ in cases:
            self.assertTrue(400 <= code < 500, code)
        self.start.assert_not_called()


PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 24
MP4 = b"\x00\x00\x00\x18ftypmp42" + b"\x01" * 40


def media_task(task_id, review_files=None):
    line = f"Board review files: [{', '.join(review_files)}]\n" if review_files else ""
    return f"---\nid: {task_id}\ntitle: Media {task_id}\nstatus: in-progress\n---\n\nBody\n{line}"


class MediaTests(unittest.TestCase):
    """T-201: a ticket's screenshots and recordings in /api/tickets, and the media endpoint."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        base = Path(self.tmp.name)
        self.main, self.wt = base / "main", base / "wt-T-912"
        self.write(base, "secret.png", PNG)                                   # outside every checkout
        self.write(self.main, "tasks/T-911-shots.md", media_task("T-911", ["game/review.gif", "docs/plan.md", "../secret.png"]).encode())
        self.write(self.main, "art-archive/T-911/screenshots/a.png", PNG)
        self.write(self.main, "art-archive/T-911/screenshots/run/clip.mp4", MP4)
        self.write(self.main, "art-archive/T-911/screenshots/notes.txt", b"text")
        self.write(self.main, "art-archive/T-911/raw.png", PNG)               # in the archive, not in screenshots/
        self.write(self.main, "game/review.gif", b"GIF89a")
        self.write(self.main, "docs/plan.md", b"# plan")
        self.write(self.main, "tasks/T-912-branch.md", media_task("T-912").encode())
        self.write(self.main, "art-archive/T-912/screenshots/old.png", PNG)   # master's copy: the open branch wins
        self.write(self.wt, "tasks/T-912-branch.md", media_task("T-912").encode())
        self.write(self.wt, "art-archive/T-912/screenshots/new.webp", b"RIFF0000WEBP")
        self.write(self.main, "tasks/T-913-none.md", media_task("T-913").encode())
        folders = {"T-912": self.wt}
        patches = [mock.patch.object(server.tb, "ROOT", self.main),
                   mock.patch.object(server.tb, "TASKS_DIR", self.main / "tasks"),
                   mock.patch.object(server.tb, "STATE_DIR", base / "state"),
                   mock.patch.object(server.tb, "task_folders", lambda root=None: folders)]
        for p in patches:
            p.start()
            self.addCleanup(p.stop)
        self.httpd = server.make_server(0)
        self.port = self.httpd.server_address[1]
        threading.Thread(target=self.httpd.serve_forever, daemon=True).start()
        self.addCleanup(self.httpd.server_close)
        self.addCleanup(self.httpd.shutdown)

    @staticmethod
    def write(base, rel, data):
        path = Path(base) / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)

    def get(self, path, headers=None):
        req = urllib.request.Request(f"http://127.0.0.1:{self.port}{path}", headers=headers or {})
        try:
            with urllib.request.urlopen(req) as r:
                return r.status, r.headers, r.read()
        except urllib.error.HTTPError as e:
            return e.code, e.headers, e.read()

    def media(self, task_id, rel, headers=None):
        query = urllib.parse.urlencode({"id": task_id, "path": rel})
        return self.get(f"/api/media?{query}", headers)

    def tickets(self):
        code, _, body = self.get("/api/tickets")
        self.assertEqual(code, 200)
        return {t["id"]: t for t in json.loads(body)["tickets"]}

    def test_tickets_list_media_from_screenshots_and_review_files(self):
        t = self.tickets()["T-911"]
        self.assertEqual(t["media"], [
            {"path": "art-archive/T-911/screenshots/a.png", "kind": "image", "size": len(PNG)},
            {"path": "art-archive/T-911/screenshots/run/clip.mp4", "kind": "video", "size": len(MP4)},
            {"path": "game/review.gif", "kind": "image", "size": 6}])

    def test_tickets_list_media_from_an_open_task_folder(self):
        self.assertEqual([m["path"] for m in self.tickets()["T-912"]["media"]], ["art-archive/T-912/screenshots/new.webp"])

    def test_ticket_without_media_lists_none(self):
        self.assertEqual(self.tickets()["T-913"]["media"], [])

    def test_serves_a_listed_png_and_mp4_with_their_content_type(self):
        code, headers, body = self.media("T-911", "art-archive/T-911/screenshots/a.png")
        self.assertEqual((code, headers["Content-Type"], body), (200, "image/png", PNG))
        code, headers, body = self.media("T-911", "art-archive/T-911/screenshots/run/clip.mp4")
        self.assertEqual((code, headers["Content-Type"], body), (200, "video/mp4", MP4))
        code, _, body = self.media("T-912", "art-archive/T-912/screenshots/new.webp")
        self.assertEqual((code, body), (200, b"RIFF0000WEBP"))

    def test_serves_a_byte_range_of_a_recording(self):
        code, headers, body = self.media("T-911", "art-archive/T-911/screenshots/run/clip.mp4", {"Range": "bytes=4-11"})
        self.assertEqual((code, body, headers["Content-Range"]), (206, MP4[4:12], f"bytes 4-11/{len(MP4)}"))
        code, _, _ = self.media("T-911", "art-archive/T-911/screenshots/run/clip.mp4", {"Range": "bytes=999-"})
        self.assertEqual(code, 416)

    def test_refuses_dot_dot_paths(self):
        for rel in ["../secret.png", "art-archive/T-911/screenshots/../raw.png", "art-archive\\T-911\\..\\..\\..\\secret.png"]:
            code, headers, body = self.media("T-911", rel)
            self.assertEqual(code, 400, rel)
            self.assertIn("error", json.loads(body))

    def test_refuses_non_media_files(self):
        for rel in ["art-archive/T-911/screenshots/notes.txt", "docs/plan.md", "tasks/T-911-shots.md"]:
            self.assertEqual(self.media("T-911", rel)[0], 415, rel)

    def test_refuses_files_outside_the_tickets_places(self):
        cases = [("T-911", "art-archive/T-911/raw.png"),             # in the archive, but not a screenshot
                 ("T-911", "art-archive/T-912/screenshots/old.png"),  # another ticket's
                 ("T-912", "art-archive/T-912/screenshots/old.png"),  # master's copy while the branch is open
                 ("T-913", "art-archive/T-911/screenshots/a.png"),
                 ("T-911", str(Path(self.tmp.name) / "secret.png")),  # absolute
                 ("T-911", "/secret.png"),
                 ("T-999", "art-archive/T-999/screenshots/a.png"),    # no such ticket
                 ("../T-911", "art-archive/T-911/screenshots/a.png")]
        for task_id, rel in cases:
            code, _, body = self.media(task_id, rel)
            self.assertTrue(400 <= code < 500, (task_id, rel, code))
            self.assertNotEqual(body, PNG)

    def test_media_only_on_localhost(self):
        code, _, _ = self.media("T-911", "art-archive/T-911/screenshots/a.png", {"Host": "example.com"})
        self.assertEqual(code, 403)

    def test_version_changes_when_a_screenshot_is_added(self):
        before = server.version()
        self.write(self.main, "art-archive/T-913/screenshots/b.jpg", b"jpg")
        self.assertNotEqual(server.version(), before)


def goal_text(gid, status, pauses="None yet."):
    return (f"---\nid: {gid}\ntitle: Goal {gid}\nstatus: {status}\nart_cap: 50\nart_used: 7\niteration: 2\n"
            f"max_iterations: 20\ncreated: 2026-10-19\nlead: Goal-{gid}\n---\n\n## Goal\n\nThe goal of {gid}.\n\n"
            f"## Iteration log\n\nNone yet.\n\n## Pauses\n\n{pauses}\n\n")


def goal_task(task_id, goal, status):
    return f"---\nid: {task_id}\ntitle: Ticket {task_id}\nstatus: {status}\nto: ui\ngoal: {goal}\n---\n\nBody\n"


class GoalsTests(unittest.TestCase):
    """T-202: GET /api/goals and GET /api/goal-file, against goals/ in the main checkout."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        base = Path(self.tmp.name)
        # The server is run from a task folder (wt-T-922); the goals are read from the main checkout.
        self.main, self.wt, self.build = base / "main", base / "wt-T-922", base / "G-008"
        MediaTests.write(self.main, "goals/G-008-paused-goal.md",
                         goal_text("G-008", "paused", "- 2026-10-18 [refusal]: first\n- 2026-10-19 [stop]: session limit").encode())
        MediaTests.write(self.main, "goals/G-007-done-goal.md", goal_text("G-007", "done").encode())
        MediaTests.write(self.main, "goals/README.md", b"# Goals\n")
        MediaTests.write(self.wt, "goals/G-008-paused-goal.md", goal_text("G-008", "building").encode())   # an old copy
        for task_id, goal, status in [("T-921", "G-008", "done"), ("T-922", "G-008", "open"), ("T-923", "G-007", "cancelled"),
                                      ("T-924", "", "open")]:
            MediaTests.write(self.wt, f"tasks/{task_id}-t.md", goal_task(task_id, goal, status).encode())
        # T-922 lives in its open task folder, where it is in QA.
        task_wt = base / "wt-T-922-branch"
        MediaTests.write(task_wt, "tasks/T-922-t.md", goal_task("T-922", "G-008", "in-qa").encode())
        (self.build / "game").mkdir(parents=True)
        self.listing = [(self.main, "master"), (self.wt, "task/T-930-x"), (self.build, "playtest/G-008")]
        folders = {"T-922": task_wt}
        patches = [mock.patch.object(server, "worktrees", lambda root=None: self.listing),
                   mock.patch.object(server.tb, "ROOT", self.wt),
                   mock.patch.object(server.tb, "TASKS_DIR", self.wt / "tasks"),
                   mock.patch.object(server.tb, "STATE_DIR", base / "state"),
                   mock.patch.object(server.tb, "task_folders", lambda root=None: folders)]
        for p in patches:
            p.start()
            self.addCleanup(p.stop)
        self.httpd = server.make_server(0)
        self.port = self.httpd.server_address[1]
        threading.Thread(target=self.httpd.serve_forever, daemon=True).start()
        self.addCleanup(self.httpd.server_close)
        self.addCleanup(self.httpd.shutdown)

    def get(self, path, headers=None):
        req = urllib.request.Request(f"http://127.0.0.1:{self.port}{path}", headers=headers or {})
        try:
            with urllib.request.urlopen(req) as r:
                return r.status, r.headers, r.read()
        except urllib.error.HTTPError as e:
            return e.code, e.headers, e.read()

    def goals(self):
        code, _, body = self.get("/api/goals")
        self.assertEqual(code, 200)
        data = json.loads(body)
        self.assertEqual(data["version"], server.version())
        return data["goals"]

    def test_goals_come_from_the_main_checkout_newest_first(self):
        goals = self.goals()
        self.assertEqual([g["id"] for g in goals], ["G-008", "G-007"])
        self.assertEqual(goals[0]["status"], "paused")   # the main checkout's copy, not the task folder's

    def test_header_fields_and_goal_text(self):
        g = self.goals()[0]
        self.assertEqual({k: g[k] for k in ("id", "title", "status", "art_cap", "art_used", "iteration", "max_iterations")},
                         {"id": "G-008", "title": "Goal G-008", "status": "paused", "art_cap": 50, "art_used": 7,
                          "iteration": 2, "max_iterations": 20})
        self.assertEqual((g["goal_text"], g["file"]), ("The goal of G-008.", "goals/G-008-paused-goal.md"))

    def test_tickets_with_a_count_per_status_including_an_open_task_folder(self):
        g8, g7 = self.goals()
        self.assertEqual(g8["tickets"], ["T-921", "T-922"])
        self.assertEqual(g8["ticket_counts"], {"done": 1, "in-qa": 1})
        self.assertEqual((g8["tickets_total"], g8["tickets_finished"]), (2, 1))
        self.assertEqual((g7["tickets"], g7["ticket_counts"], g7["tickets_finished"]), (["T-923"], {"cancelled": 1}, 1))

    def test_latest_pause_when_paused(self):
        g8, g7 = self.goals()
        self.assertEqual([p["kind"] for p in g8["pauses"]], ["refusal", "stop"])
        self.assertEqual(g8["latest_pause"], {"date": "2026-10-19", "kind": "stop", "reason": "session limit"})
        self.assertIsNone(g7["latest_pause"])

    def test_whether_the_build_folder_exists(self):
        g8, g7 = self.goals()
        self.assertEqual((g8["has_build"], g8["build_folder"]), (True, str(self.build)))
        self.assertEqual((g7["has_build"], g7["build_folder"]), (False, ""))
        self.assertIn("G-008", [b["id"] for b in server.builds()])   # Play and Open in editor use this Builds entry

    def test_goals_on_tickets(self):
        code, _, body = self.get("/api/tickets")
        goals = {t["id"]: t["goal"] for t in json.loads(body)["tickets"]}
        self.assertEqual(goals, {"T-921": "G-008", "T-922": "G-008", "T-923": "G-007", "T-924": ""})

    def test_no_goals_folder_is_an_empty_list(self):
        for p in sorted((self.main / "goals").iterdir()):
            p.unlink()
        (self.main / "goals").rmdir()
        self.assertEqual(self.goals(), [])

    def test_goal_file_full_text(self):
        code, headers, body = self.get("/api/goal-file?id=G-008")
        self.assertEqual((code, headers["Content-Type"]), (200, "text/plain; charset=utf-8"))
        self.assertEqual(body.decode("utf-8"), (self.main / "goals" / "G-008-paused-goal.md").read_text(encoding="utf-8"))
        for bad, expected in [("G-999", 404), ("../tasks/T-921", 400), ("README", 400), ("", 400)]:
            self.assertEqual(self.get("/api/goal-file?" + urllib.parse.urlencode({"id": bad}))[0], expected, bad)
        self.assertEqual(self.get("/api/goal-file?id=G-008", {"Host": "example.com"})[0], 403)

    def test_version_changes_when_a_goal_file_changes(self):
        before = server.version()
        MediaTests.write(self.main, "goals/G-008-paused-goal.md", goal_text("G-008", "building").encode())
        self.assertNotEqual(server.version(), before)
        before = server.version()
        MediaTests.write(self.main, "goals/G-009-new.md", goal_text("G-009", "planning").encode())
        self.assertNotEqual(server.version(), before)


class GoalsPageTests(unittest.TestCase):
    """T-202: the page has the Goals strip, the goal detail, the Goal filter and the goal label on cards."""

    def test_page_parts(self):
        page = server.PAGE.read_text(encoding="utf-8")
        for part in ['id="goals"', 'id="goal-detail"', 'id="goal-filters"', "/api/goals", "/api/goal-file",
                     "tbp-goal-filter", "tbp-goals-finished", "Finished goals", "chip goal-tag", "tickets done"]:
            self.assertIn(part, page, part)


def iso_at(stamp):
    return server.iso(stamp)


class ActivityTests(unittest.TestCase):
    """T-203: the Now data on in-progress and in-QA tickets, and on building goals' cards."""

    NOW = 1_800_000_000          # a fixed "now" for the ages

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        base = Path(self.tmp.name)
        self.main, self.state, self.wt = base / "main", base / "main" / ".board", base / "wt-T-931"
        tasks = [("T-931", "in-progress", "G-010"), ("T-932", "in-qa", ""), ("T-933", "done", "G-010"),
                 ("T-934", "in-progress", "G-010")]
        for task_id, status, goal in tasks:
            MediaTests.write(self.main, f"tasks/{task_id}-t.md", goal_task(task_id, goal, status).encode())
        MediaTests.write(self.wt, "tasks/T-931-t.md", goal_task("T-931", "G-010", "in-progress").encode())
        MediaTests.write(self.main, "goals/G-010-live.md", goal_text("G-010", "building").encode())
        n = self.NOW
        log = [(n - 900, "agent", {"type": "system", "subtype": "init"}),
               (n - 600, "agent", {"type": "assistant", "message": {"content": [
                   {"type": "tool_use", "name": "Read", "input": {"file_path": "C:/solid-carbide-worktrees/T-931/docs/level-design.md"}}]}}),
               (n - 120, "agent", {"type": "assistant", "message": {"content": [
                   {"type": "tool_use", "name": "Bash", "input": {"command": "bash game/tools/run_tests.sh"}}]}}),
               (n - 30, "agent", {"type": "user", "message": {"content": [{"type": "tool_result", "content": "ok"}]}})]
        for at, step, event in log:
            server.tb.append_activity(self.state / "activity", "T-931", step, event, at=iso_at(at))
        moves = [{"id": "T-931", "from": "open", "to": "in-progress", "at": iso_at(n - 3600)},
                 {"id": "T-932", "from": "in-progress", "to": "in-qa", "at": iso_at(n - 1200)},
                 {"id": "T-934", "from": "open", "to": "in-progress", "at": iso_at(n - 7200)}]
        (self.state / "moves.log").write_text("".join(json.dumps(m) + "\n" for m in moves), encoding="utf-8")
        old = n - 3 * 3600
        for task_id in ("T-932", "T-934"):
            p = self.main / "tasks" / f"{task_id}-t.md"
            server.os.utime(p, (old, old))
        p = self.wt / "tasks" / "T-931-t.md"
        server.os.utime(p, (n - 5000, n - 5000))
        folders = {"T-931": self.wt}
        signals = {str(self.wt): (3, n - 60)}
        patches = [mock.patch.object(server, "worktrees", lambda root=None: [(self.main, "master"), (self.wt, "task/T-931-t")]),
                   mock.patch.object(server.tb, "ROOT", self.main),
                   mock.patch.object(server.tb, "TASKS_DIR", self.main / "tasks"),
                   mock.patch.object(server.tb, "STATE_DIR", base / "state"),
                   mock.patch.object(server.tb, "task_folders", lambda root=None: folders),
                   mock.patch.object(server, "branch_signals", lambda folder, branch: signals.get(str(folder), (0, None))),
                   mock.patch.object(server.time, "time", lambda: n)]
        for p in patches:
            p.start()
            self.addCleanup(p.stop)

    def tickets(self):
        return {t["id"]: t for t in server.tickets_payload()["tickets"]}

    def test_a_runner_ticket_carries_its_phrase_age_lane_time_commits_and_last_activity(self):
        n = self.tickets()["T-931"]["now"]
        self.assertEqual((n["phrase"], n["phrase_since"], n["phrase_age_s"], n["step"]),
                         ("Running the game's tests", iso_at(self.NOW - 120), 120, "agent"))
        self.assertEqual((n["in_lane_since"], n["in_lane_s"]), (iso_at(self.NOW - 3600), 3600))
        self.assertEqual((n["commits"], n["last_commit_at"]), (3, iso_at(self.NOW - 60)))
        self.assertEqual((n["last_activity_at"], n["last_activity_s"], n["quiet"]), (iso_at(self.NOW - 30), 30, False),
                         "the newest of the log, the branch's last commit and the task file")
        self.assertEqual([s["phrase"] for s in n["timeline"]],
                         ["Starting", "Reading `docs/level-design.md`", "Running the game's tests"])

    def test_without_a_log_the_free_signals_and_the_quiet_mark(self):
        t = self.tickets()
        n = t["T-932"]["now"]
        self.assertEqual((n["phrase"], n["timeline"], n["commits"]), ("", [], 0))
        self.assertEqual((n["in_lane_s"], n["last_activity_s"], n["quiet"]), (1200, 3 * 3600, True))
        self.assertIsNone(t["T-933"]["now"], "only in-progress and in-QA tickets")

    def test_a_ticket_quiet_for_ten_minutes(self):
        with mock.patch.object(server.time, "time", lambda: self.NOW + 569):
            self.assertFalse(self.tickets()["T-931"]["now"]["quiet"])
        with mock.patch.object(server.time, "time", lambda: self.NOW + 570):
            self.assertTrue(self.tickets()["T-931"]["now"]["quiet"], "600 seconds after its last event")

    def test_a_building_goal_shows_the_ticket_being_worked_on(self):
        g = server.goals_payload()["goals"][0]
        self.assertEqual({k: g["now"][k] for k in ("ticket", "ticket_index", "tickets_total", "iteration", "phrase", "quiet")},
                         {"ticket": "T-931", "ticket_index": 1, "tickets_total": 3, "iteration": 2,
                          "phrase": "Running the game's tests", "quiet": False})

    def test_the_goal_check_shows_on_the_goal_card(self):
        server.tb.append_activity(self.state / "activity", "G-010", "goal-check", {"type": "system", "subtype": "init"},
                                  at=iso_at(self.NOW - 5))
        g = server.goals_payload()["goals"][0]
        self.assertEqual((g["now"]["ticket"], g["now"]["phrase"]), ("", "Goal check"))

    def test_a_goal_not_building_has_no_now(self):
        MediaTests.write(self.main, "goals/G-010-live.md", goal_text("G-010", "paused").encode())
        self.assertIsNone(server.goals_payload()["goals"][0]["now"])

    def test_a_deleted_log_breaks_nothing(self):
        (self.state / "activity" / "T-931.jsonl").unlink()
        n = self.tickets()["T-931"]["now"]
        self.assertEqual((n["phrase"], n["commits"], n["last_activity_s"]), ("", 3, 60))
        (self.state / "activity").rmdir()
        self.assertEqual(self.tickets()["T-931"]["now"]["timeline"], [])

    def test_the_version_follows_new_activity(self):
        before = server.version()
        log = self.state / "activity" / "T-931.jsonl"
        server.tb.append_activity(self.state / "activity", "T-931", "agent", {"type": "system", "subtype": "init"})
        later = log.stat().st_mtime + 2 * server.ACTIVITY_TICK
        server.os.utime(log, (later, later))
        self.assertNotEqual(server.version(), before)

    def test_the_main_state_folder_can_be_pointed_elsewhere(self):
        with mock.patch.dict(server.os.environ, {"BOARD_MAIN_STATE": str(Path(self.tmp.name) / "sample")}):
            self.assertEqual(server.main_state(), Path(self.tmp.name) / "sample")
            self.assertEqual(server.activity_files(), {})
        with mock.patch.dict(server.os.environ, {}, clear=False):
            server.os.environ.pop("BOARD_MAIN_STATE", None)
            server._MAIN.pop(self.main, None)
            self.assertEqual(server.main_state(), self.main / ".board")


class BranchSignalTests(unittest.TestCase):
    """T-203: the commits on a ticket's own branch, from git (a temporary repo)."""

    def git(self, *args):
        import subprocess
        subprocess.run(["git", "-C", str(self.repo), *args], check=True, capture_output=True)

    def test_commits_only_on_the_tasks_branch(self):
        with tempfile.TemporaryDirectory() as d:
            self.repo = Path(d)
            self.git("init", "-q", "-b", "master")
            self.git("config", "user.email", "t@example.com")
            self.git("config", "user.name", "t")
            for i, branch in enumerate([None, "task/T-940-x", None, None]):
                if branch:
                    self.git("checkout", "-q", "-b", branch)
                (self.repo / f"f{i}.txt").write_text(str(i))
                self.git("add", "-A")
                self.git("commit", "-q", "-m", f"c{i}")
            self.assertEqual(server.branch_signals(self.repo, "task/T-940-x")[0], 3)
            self.assertIsInstance(server.branch_signals(self.repo, "task/T-940-x")[1], int)
            self.git("checkout", "-q", "master")
            self.assertEqual(server.branch_signals(self.repo, "master"), (0, None), "master's commit is on the branch too")
            self.assertEqual(server.branch_signals(self.repo, ""), (0, None))
            self.assertEqual(server.branch_signals(Path(d) / "missing", "task/T-940-x"), (0, None))


class ActivityPageTests(unittest.TestCase):
    """T-203: the page has the Now line, the detail timeline, the goal cards' current ticket and the quiet mark."""

    def test_page_parts(self):
        page = server.PAGE.read_text(encoding="utf-8")
        for part in ['id="detail-now"', "function nowLine", "function renderNow", "function goalNowLine", "data-now=",
                     "data-goal-now=", "chip quiet", "QUIET_S = 600", "class=\"timeline\"", "ticket ${n.ticket_index} of ${n.tickets_total}, iteration ${n.iteration}",
                     "last activity", "tickNow"]:
            self.assertIn(part, page, part)


if __name__ == "__main__":
    unittest.main()
