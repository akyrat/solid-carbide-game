"""Tests for RealClaude (claude_call.py, T-203): the headless command streams with `--output-format stream-json`,
each event goes into the activity log as it arrives, and the answer and refusals are the same as before.
subprocess.Popen is replaced by a fake process: nothing calls Claude or the network."""

import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import taskboard_sync as tb  # noqa: E402
from goal_agent import build  # noqa: E402
from goal_agent.claude_call import Pause, RealClaude  # noqa: E402


class Prompt(io.StringIO):
    """Standard input that keeps what was written after it is closed."""

    def close(self):
        self.sent = self.getvalue()
        super().close()


class FakeProc:
    """A `claude -p --output-format stream-json` process: prints `events` one line at a time. Before each
    line it calls `before(i)`, so a test can look at the activity log just before event i arrives."""

    def __init__(self, events, before=None, returncode=0, stderr="", raw=None):
        self.stdin = Prompt()
        self.stderr = io.StringIO(stderr)
        self.returncode = returncode
        self.lines = raw if raw is not None else [json.dumps(e) for e in events]
        self.before = before or (lambda i: None)
        self.stdout = self.read()
        self.killed = False

    def read(self):
        for i, line in enumerate(self.lines):
            self.before(i)
            yield line + "\n"

    def wait(self):
        return self.returncode

    def kill(self):
        self.killed = True


INIT = {"type": "system", "subtype": "init", "cwd": "C:/solid-carbide-worktrees/T-001", "session_id": "abc"}
READ = {"type": "assistant", "message": {"content": [
    {"type": "tool_use", "name": "Read", "input": {"file_path": "C:/solid-carbide-worktrees/T-001/docs/level-design.md"}}]}}
RESULT_OK = {"type": "user", "message": {"content": [{"type": "tool_result", "content": "x" * 5000}]}}
DENIAL = {"tool_name": "Bash", "tool_use_id": "t1", "tool_input": {"command": "rm -rf game"}}


def result(structured=None, text=None, denials=(), is_error=False):
    out = {"type": "result", "subtype": "success", "is_error": is_error, "permission_denials": list(denials)}
    if structured is not None:
        out["structured_output"] = structured
    if text is not None:
        out["result"] = text
    return out


class Streaming(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.dir = Path(self.tmp.name) / ".board" / "activity"
        self.log = self.dir / "T-001.jsonl"

    def lines(self):
        return self.log.read_text(encoding="utf-8").splitlines() if self.log.exists() else []

    def ask(self, proc, **kw):
        with mock.patch("subprocess.Popen", return_value=proc) as popen:
            answer = RealClaude(self.dir).ask("agent", "Work on task T-001", build.AGENT_SCHEMA, model="opus",
                                              agent="ui", session_id="abc", cwd="C:/w/T-001",
                                              permission_mode="acceptEdits", timeout=5, **kw)
        return answer, popen

    def test_the_command_streams_with_stream_json(self):
        answer, popen = self.ask(FakeProc([INIT, result({"summary": "s"})]), activity="T-001")
        cmd, kw = popen.call_args[0][0], popen.call_args[1]
        self.assertEqual(cmd[:2], ["claude", "-p"])
        self.assertEqual(cmd[cmd.index("--output-format") + 1], "stream-json")
        self.assertIn("--verbose", cmd)               # the CLI needs it to stream with --print
        for flag, value in (("--model", "opus"), ("--agent", "ui"), ("--session-id", "abc"),
                            ("--permission-mode", "acceptEdits")):
            self.assertEqual(cmd[cmd.index(flag) + 1], value)
        self.assertNotIn("Work on task T-001", cmd)
        self.assertNotIn("--add-dir", cmd)
        self.assertEqual(popen.return_value.stdin.sent, "Work on task T-001")   # the prompt on standard input
        self.assertEqual(kw["cwd"], "C:/w/T-001")

    def test_each_event_is_written_as_it_arrives(self):
        seen = []
        proc = FakeProc([INIT, READ, RESULT_OK, result({"summary": "s"})], before=lambda i: seen.append(len(self.lines())))
        self.ask(proc, activity="T-001")
        self.assertEqual(seen, [0, 1, 2, 3], "event i arrives with the i events before it already in the log")
        entries = [json.loads(l) for l in self.lines()]
        self.assertEqual([e["event"]["type"] for e in entries], ["system", "assistant", "user", "result"])
        self.assertEqual({e["step"] for e in entries}, {"agent"})
        self.assertTrue(all(tb.parse_time(e["at"]) for e in entries))
        self.assertEqual(entries[2]["event"]["message"]["content"], [{"type": "tool_result", "is_error": False}],
                         "a tool's output is not copied into the log")

    def test_the_same_structured_answer_and_refusals_as_before(self):
        answer, _ = self.ask(FakeProc([INIT, READ, result({"summary": "s", "blocked": False}, denials=[DENIAL])]),
                             activity="T-001")
        self.assertEqual(answer.data, {"summary": "s", "blocked": False})
        self.assertEqual(answer.denials, [DENIAL])
        answer, _ = self.ask(FakeProc([result(text='{"summary": "from text"}')]), activity="T-001")
        self.assertEqual((answer.data, answer.denials), ({"summary": "from text"}, []))

    def test_errors_pause_as_before(self):
        with self.assertRaises(Pause) as e:
            self.ask(FakeProc([INIT, result(text="You've hit your limit", is_error=True)]), activity="T-001")
        self.assertIn("reported an error", str(e.exception))
        with self.assertRaises(Pause) as e:
            self.ask(FakeProc([], raw=["not json"], returncode=1, stderr="claude: bad flag"), activity="T-001")
        self.assertIn("gave no JSON", str(e.exception))
        self.assertIn("bad flag", str(e.exception))
        with self.assertRaises(Pause) as e:
            self.ask(FakeProc([result(text="plain words, not JSON")]))
        self.assertIn("not the structured JSON", str(e.exception))
        with mock.patch("subprocess.Popen", side_effect=OSError("no claude")):
            with self.assertRaises(Pause) as e:
                RealClaude(self.dir).ask("agent", "p", {}, activity="T-001")
        self.assertIn("could not be run", str(e.exception))

    def test_without_an_id_nothing_is_logged(self):
        answer, _ = self.ask(FakeProc([INIT, result({"summary": "s"})]))
        self.assertEqual(answer.data, {"summary": "s"})
        self.assertFalse(self.dir.exists())

    def test_a_deleted_log_is_started_again(self):
        def delete(i):
            if i == 2 and self.log.exists():
                self.log.unlink()
        answer, _ = self.ask(FakeProc([INIT, READ, READ, result({"summary": "s"})], before=delete), activity="T-001")
        self.assertEqual(answer.data, {"summary": "s"})
        self.assertEqual(len(self.lines()), 2)

    def test_the_default_log_folder_is_the_checkouts_board_folder(self):
        self.assertEqual(RealClaude().activity_dir, Path(build.__file__).resolve().parents[2] / ".board" / "activity")


class Callers(unittest.TestCase):
    def test_the_headless_sessions_name_their_ticket_or_goal(self):
        """build.ask_headless passes the id through; FakeClaude records it (the loop's tests check the ids)."""
        from goal_agent.claude_call import FakeClaude
        claude = FakeClaude({"agent": [{"summary": "s", "art_generations_used": 0, "refusals": [], "blocked": False}]})

        class B:
            pass
        b = B()
        b.claude, b.root, b.lead = claude, Path(tempfile.gettempdir()), "Goal-G-001"
        with mock.patch.object(build, "register_session", return_value="sid"):
            build.ask_headless(b, "agent", "p", build.AGENT_SCHEMA, "ui", "opus", "C:/w", activity="T-007")
        self.assertEqual(claude.calls[0][2]["activity"], "T-007")


if __name__ == "__main__":
    unittest.main()
