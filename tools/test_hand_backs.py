import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hand_backs as hb

FRAME = ('<agent-message from="%s">\n[Subagent hand-back] The text below is the final report. '
         'The report follows:\n  %s\n</agent-message>\n\nThat "other Claude session" is an agent in this session.')


def launch(tid, ts, prompt, stype="qa-integration", background=True):
    return {"type": "assistant", "timestamp": ts, "message": {"id": "m" + tid, "content": [
        {"type": "tool_use", "id": tid, "name": "Agent",
         "input": {"subagent_type": stype, "description": "d", "prompt": prompt, "run_in_background": background}}]}}


def ack(tid, ts, agent_id):
    return {"type": "user", "timestamp": ts, "uuid": "ack" + tid,
            "toolUseResult": {"isAsync": True, "status": "async_launched", "agentId": agent_id},
            "message": {"content": [{"type": "tool_result", "tool_use_id": tid,
                                     "content": [{"type": "text", "text": "Async agent launched. agentId: " + agent_id}]}]}}


def peer(ts, agent_id, text, uid):
    return {"type": "user", "timestamp": ts, "uuid": uid, "origin": {"kind": "peer"},
            "message": {"content": FRAME % (agent_id, text)}}


def notice(ts, agent_id, summary, result, uid):
    return {"type": "user", "timestamp": ts, "uuid": uid, "origin": {"kind": "task-notification"},
            "message": {"content": "<task-notification>\n<task-id>%s</task-id>\n<status>completed</status>\n"
                                   "<summary>%s</summary>\n<result>%s</result>\n</task-notification>" % (agent_id, summary, result)}}


def sync_result(tid, ts, text):
    return {"type": "user", "timestamp": ts, "uuid": "sr" + tid,
            "toolUseResult": text, "message": {"content": [{"type": "tool_result", "tool_use_id": tid, "content": text}]}}


class HandBacksTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = self.tmp.name
        recs = [
            launch("t1", "2026-10-01T10:00:00Z", "QA T-1. Hand back ONE line under 300 characters."),
            ack("t1", "2026-10-01T10:00:01Z", "agentA"),
            peer("2026-10-01T10:05:00Z", "agentA", "T-1: 5/5 pass.", "p1"),
            notice("2026-10-01T10:05:01Z", "agentA", 'Agent "QA T-1" finished',
                   "This agent's report was delivered to you as a message from agentA. Read it there.", "n1"),
            launch("t2", "2026-10-02T10:00:00Z", "Build the thing. Tell me everything.", "ui"),
            ack("t2", "2026-10-02T10:00:01Z", "agentB"),
            peer("2026-10-02T10:30:00Z", "agentB", "x" * 500, "p2"),
            launch("t3", "2026-10-03T10:00:00Z", "Look up a fact, hand back one short line.", "general-purpose", False),
            sync_result("t3", "2026-10-03T10:01:00Z", "The fact is 42."),
            {"type": "user", "timestamp": "2026-10-03T10:02:00Z", "uuid": "bg", "origin": {"kind": "task-notification"},
             "message": {"content": "<task-notification><task-id>bash1</task-id><status>completed</status>"
                                    "<summary>Background command \"x\" completed</summary></task-notification>"}},
            {"type": "user", "timestamp": "2026-10-03T10:03:00Z", "uuid": "p3", "origin": {"kind": "peer"},
             "message": {"content": '<agent-message from="sessionTokens">hello from another session</agent-message>'}},
            # a resumed agent: SendMessage, then a second hand-back from the same agent
            {"type": "assistant", "timestamp": "2026-10-04T09:00:00Z", "message": {"id": "ms", "content": [
                {"type": "tool_use", "id": "s1", "name": "SendMessage", "input": {"to": "agentB", "message": "tweak"}}]}},
            peer("2026-10-04T09:10:00Z", "agentB", "tweaked.", "p4"),
            peer("2026-11-01T10:00:00Z", "agentB", "out of range", "p5"),
        ]
        with open(os.path.join(self.root, "sess1.jsonl"), "w", encoding="utf-8") as f:
            for r in recs:
                f.write(json.dumps(r, separators=(",", ":")) + "\n")
        self.path = os.path.join(self.root, "sess1.jsonl")

    def tearDown(self):
        self.tmp.cleanup()

    def results(self, lo=None, hi="2026-10-31"):
        return hb.scan(self.path, lo, hi)

    def test_kinds_and_types(self):
        r = [x for x in self.results() if x["sub"]]
        kinds = [x["kind"] for x in r]
        self.assertEqual(kinds.count("SubagentHandback"), 3)
        self.assertEqual(kinds.count("task notification (pointer)"), 1)
        self.assertEqual(kinds.count("Agent tool result"), 1)
        self.assertEqual({x["type"] for x in r}, {"qa-integration", "ui", "general-purpose"})

    def test_non_results_are_separate(self):
        other = {x["kind"] for x in self.results() if not x["sub"]}
        self.assertEqual(other, {"launch acknowledgement", "background command notice", "cross-session peer message"})

    def test_prompt_asks_for_one_line(self):
        r = {x["prompt"][:5]: x for x in self.results() if x["sub"]}
        self.assertTrue(hb.asks_one_line(r["QA T-"]["prompt"]))
        self.assertFalse(hb.asks_one_line(r["Build"]["prompt"]))
        self.assertTrue(hb.asks_one_line(r["Look "]["prompt"]))

    def test_body_excludes_frame(self):
        big = [x for x in self.results() if x["kind"] == "SubagentHandback" and x["agent"] == "agentB"][0]
        self.assertEqual(big["body"], 502)  # two spaces of indent + 500
        self.assertGreater(big["chars"], big["body"] + 100)
        sync = [x for x in self.results() if x["kind"] == "Agent tool result"][0]
        self.assertEqual(sync["chars"], len("The fact is 42."))
        self.assertEqual(sync["body"], sync["chars"])

    def test_resumed_flag(self):
        hbs = [x for x in self.results() if x["kind"] == "SubagentHandback" and x["agent"] == "agentB"]
        self.assertEqual([x["resumed"] for x in hbs], [False, True])

    def test_range_uses_timestamps(self):
        r = self.results(lo="2026-10-02", hi="2026-10-02")
        self.assertEqual([x["kind"] for x in r if x["sub"]], ["SubagentHandback"])
        r = hb.scan(self.path, None, None)
        self.assertEqual(len([x for x in r if x["kind"] == "SubagentHandback"]), 4)

    def test_report_totals(self):
        text = hb.format_report(self.results(), "sess1", None, "2026-10-31", top=2)
        self.assertIn("By subagent type", text)
        self.assertIn("By delivery kind", text)
        self.assertIn("SubagentHandback", text)
        self.assertIn("The 2 longest", text)
        self.assertIn("launch acknowledgement", text)

    def test_cli_options(self):
        out = os.path.join(self.root, "out.md")
        code = hb.main(["--session", "sess", "--from", "2026-10-01", "--to", "2026-10-31", "--dir", self.root, "--out", out])
        self.assertEqual(code, 0)
        with open(out, encoding="utf-8") as f:
            self.assertIn("Session sess1", f.read())
        self.assertEqual(hb.main(["--session", "nope", "--dir", self.root]), 1)


if __name__ == "__main__":
    unittest.main()
