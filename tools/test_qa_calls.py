import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import qa_calls as qc


def asst(mid, ts, tools=(), cr=100):
    blocks = [{"type": "tool_use", "id": tid, "name": name, "input": inp} for tid, name, inp in tools]
    return {"type": "assistant", "timestamp": ts,
            "message": {"id": mid, "model": "claude-sonnet-5-5", "content": blocks or [{"type": "text", "text": "x"}],
                        "usage": {"input_tokens": 0, "cache_creation_input_tokens": 1,
                                  "cache_read_input_tokens": cr, "output_tokens": 1}}}


def result(tid, ts, text="ok", err=False):
    return {"type": "user", "timestamp": ts, "message": {"content": [
        {"type": "tool_result", "tool_use_id": tid, "is_error": err, "content": text}]}}


def write(root, session, agent, agent_type, records, description=""):
    sd = os.path.join(root, session, "subagents")
    os.makedirs(sd, exist_ok=True)
    with open(os.path.join(sd, f"agent-{agent}.jsonl"), "w", encoding="utf-8") as f:
        for r in records:
            f.write(json.dumps(r, separators=(",", ":")) + "\n")  # compact, as Claude Code writes them
    with open(os.path.join(sd, f"agent-{agent}.meta.json"), "w", encoding="utf-8") as f:
        json.dump({"agentType": agent_type, "description": description}, f)


class ClassifyTest(unittest.TestCase):
    def test_kinds(self):
        c = qc.classify
        self.assertEqual(c("Bash", {"command": "cd /c/w/T-1 && bash game/tools/run_tests.sh 2>&1 | tail -5"}), "test run")
        self.assertEqual(c("Bash", {"command": 'python -m unittest discover -s tools -p "test_*.py"'}), "test run")
        self.assertEqual(c("Monitor", {"command": "until grep -q OK x.log; do sleep 5; done"}), "poll / wait")
        self.assertEqual(c("BashOutput", {"bash_id": "b1"}), "poll / wait")
        self.assertEqual(c("Bash", {"command": "sleep 100; cat out.txt"}), "poll / wait")
        self.assertEqual(c("Bash", {"command": "echo waiting"}), "poll / wait")
        self.assertEqual(c("Bash", {"command": 'tail -5 "C:/Temp/x/tasks/b0jl.output"'}), "poll / wait")
        self.assertEqual(c("Read", {"file_path": "C:/Temp/x/tasks/b0jl.output"}), "poll / wait")
        self.assertEqual(c("Bash", {"command": "cd /c/w/T-1 && python tools/qa_check.py T-1 --no-marks"}), "qa_check.py")
        self.assertEqual(c("Read", {"file_path": "C:/w/T-1/art-archive/T-1/screenshots/hud.png"}), "screenshots / images")
        self.assertEqual(c("Bash", {"command": "bash game/tools/screenshot.sh res://tests/fixtures/x.tscn out.png"}),
                         "screenshots / images")
        self.assertEqual(c("Read", {"file_path": "C:/w/T-1/tasks/T-1-the-thing.md"}), "ticket and diff")
        self.assertEqual(c("Bash", {"command": "cd /c/w/T-1 && git diff master...HEAD --stat"}), "ticket and diff")
        self.assertEqual(c("Bash", {"command": 'cd /c/w/T-1 && git commit -qm "QA pass, screenshots ok"'}), "git")
        self.assertEqual(c("Edit", {"file_path": "C:\\w\\T-1\\tasks\\T-1-the-thing.md"}), "ticket edit")
        self.assertEqual(c("Bash", {"command": "cd /c/w/T-1 && sed -i 's/x/y/' tasks/T-1-the-thing.md"}), "ticket edit")
        self.assertEqual(c("Bash", {"command": "python tools/task_status.py T-1 --reply hi"}), "ticket edit")
        self.assertEqual(c("Grep", {"pattern": "func"}), "read / search other files")
        self.assertEqual(c("SubagentHandback", {"message": "T-1 done"}), "other")


class CollectTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = self.tmp.name
        qa = [
            {"type": "user", "timestamp": "2026-10-28T10:00:00Z", "message": {"content": "QA for T-77, the thing."}},
            asst("q1", "2026-10-28T10:00:01Z", [("t1", "Bash", {"command": "bash game/tools/run_tests.sh"})], cr=1000),
            result("t1", "2026-10-28T10:00:02Z"),
            asst("q2", "2026-10-28T10:00:03Z", [("t2", "Monitor", {"command": "until [ -s f.output ]; do sleep 5; done"}),
                                                ("t3", "Bash", {"command": "sleep 120; cat f.output"})]),
            result("t3", "2026-10-28T10:00:04Z", "Blocked: sleep 120 followed by: cat. To wait for a condition, use Monitor", True),
            asst("q2", "2026-10-28T10:00:03Z", [("t2", "Monitor", {"command": "until [ -s f.output ]; do sleep 5; done"})]),
            asst("q3", "2026-10-28T10:00:05Z", [("t4", "Bash", {"command": "python tools/qa_check.py T-77 --no-marks"})]),
            asst("q4", "2026-10-28T10:00:06Z", [("t5", "Read", {"file_path": "art-archive/T-77/screenshots/a.png"})]),
            asst("q5", "2026-10-28T10:00:07Z", [("t6", "Edit", {"file_path": "tasks/T-77-the-thing.md"})]),
            result("t6", "2026-10-28T10:00:08Z", "File has not been read yet. Read it first", True),
            asst("q6", "2026-10-29T10:00:00Z", [("t7", "Bash", {"command": "git status"})]),  # out of range below
        ]
        write(self.root, "s1", "aaa111", "qa-integration", qa, "QA T-77 round 1")
        write(self.root, "s1", "bbb222", "ui", [asst("u1", "2026-10-28T10:00:00Z")])  # not QA: ignored

    def tearDown(self):
        self.tmp.cleanup()

    def test_one_run_grouped(self):
        runs = qc.collect(self.root, "2026-10-28", "2026-10-28")
        self.assertEqual(len(runs), 1)
        r = runs[0]
        self.assertEqual(r["ticket"], "T-77")
        self.assertEqual(r["calls"], 5)  # q2 repeated (streamed) counts once; q6 is out of range
        self.assertEqual(r["cache_read"], 1000 + 4 * 100)
        self.assertEqual(r["tools"]["test run"], 1)
        self.assertEqual(r["tools"]["poll / wait"], 2)
        self.assertEqual(r["tools"]["qa_check.py"], 1)
        self.assertEqual(r["tools"]["screenshots / images"], 1)
        self.assertEqual(r["tools"]["ticket edit"], 1)
        self.assertEqual(r["tools"]["git"], 0)
        self.assertEqual(r["fails"], {"poll / wait": 1, "ticket edit": 1})
        self.assertEqual(r["fail_kind"], {"sleep blocked": 1, "edit before read": 1})

    def test_ticket_from_prompt_when_description_has_none(self):
        self.assertEqual(qc.ticket_of({"description": "Merge HUD tickets"}, "Merge T-12 and T-13"), "T-12")
        self.assertEqual(qc.ticket_of({}, None), "?")

    def test_report_and_detail(self):
        text = qc.report(qc.collect(self.root, None, None, ["aaa"]), None, None)
        self.assertIn("1 QA runs on 1 tickets: 6 calls", text)
        self.assertIn("| poll / wait | 2 |", text)
        self.assertIn("### Detail: aaa111", text)
        self.assertIn("FAIL sleep blocked", text)

    def test_main_writes_out(self):
        out = os.path.join(self.root, "out", "r.md")
        self.assertEqual(qc.main(["--dir", self.root, "--from", "2026-10-28T00:00:00Z", "--to", "2026-10-28T23:59:59Z",
                                  "--out", out]), 0)
        with open(out, encoding="utf-8") as f:
            self.assertIn("5 calls", f.read())


if __name__ == "__main__":
    unittest.main()
