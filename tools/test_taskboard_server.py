"""Tests for the Builds endpoints of tools/taskboard/server.py. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"

Godot is never started: the process start is replaced by a stub.
"""

import json
import sys
import tempfile
import threading
import unittest
import urllib.error
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


if __name__ == "__main__":
    unittest.main()
