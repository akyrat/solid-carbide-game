"""Tests for the Builds and media endpoints of tools/taskboard/server.py. Run from the repo root:

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


if __name__ == "__main__":
    unittest.main()
