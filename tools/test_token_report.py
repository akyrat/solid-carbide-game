import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import token_report as tr


def asst(mid, ts, cr=100, cc=10, inp=1, out=5, model="claude-opus-5-5", blocks=None):
    return {"type": "assistant", "timestamp": ts, "uuid": "u" + mid + ts,
            "message": {"id": mid, "model": model,
                        "content": blocks or [{"type": "text", "text": "hello"}],
                        "usage": {"input_tokens": inp, "cache_creation_input_tokens": cc,
                                  "cache_read_input_tokens": cr, "output_tokens": out}}}


def write(path, records):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        for r in records:
            f.write(json.dumps(r, separators=(",", ":")) + "\n")


class TokenReportTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = self.tmp.name
        main = [
            asst("m1", "2026-10-01T10:00:00Z"),
            asst("m1", "2026-10-01T10:00:01Z"),  # same message id again (streamed): counted once
            asst("m2", "2026-10-02T10:00:00Z", cr=200),
            asst("m3", "2026-10-03T10:00:00Z", cr=300, blocks=[
                {"type": "tool_use", "id": "t1", "name": "Edit", "input": {"file_path": "x"}}]),
            {"type": "user", "timestamp": "2026-10-03T10:00:05Z", "uuid": "ur1", "message": {"content": [
                {"type": "tool_result", "tool_use_id": "t1", "is_error": True,
                 "content": "File has not been read yet. Read it first"}]}},
            {"type": "system", "subtype": "compact_boundary", "timestamp": "2026-10-03T11:00:00Z"},
            asst("m4", "2026-10-05T10:00:00Z", cr=400),
        ]
        write(os.path.join(self.root, "sess1.jsonl"), main)
        sub = [asst("s1", "2026-10-02T12:00:00Z", cr=50, model="claude-sonnet-5-5"),
               asst("m2", "2026-10-02T10:00:00Z", cr=200)]  # a copied message: not counted again in totals
        write(os.path.join(self.root, "sess1", "subagents", "agent-a1.jsonl"), sub)
        with open(os.path.join(self.root, "sess1", "subagents", "agent-a1.meta.json"), "w") as f:
            json.dump({"agentType": "qa-integration"}, f)

    def tearDown(self):
        self.tmp.cleanup()

    def test_dedup_by_message_id(self):
        agg, files = tr.run(self.root, None, None)
        main = [s for s in files if s["scope"] == "main"][0]
        self.assertEqual(main["calls"], 4)  # m1 once, m2, m3, m4
        total = sum(c["calls"] for c in agg.usage.values())
        self.assertEqual(total, 5)  # plus s1; the copied m2 is not counted twice
        self.assertEqual(sum(c["cache_read"] for c in agg.usage.values()), 100 + 200 + 300 + 400 + 50)

    def test_date_range(self):
        agg, files = tr.run(self.root, "2026-10-02", "2026-10-03")
        main = [s for s in files if s["scope"] == "main"][0]
        self.assertEqual(main["calls"], 2)  # m2 and m3 only
        self.assertEqual(main["cache_read"], 500)
        self.assertEqual(main["compactions"], 1)
        agg2, _ = tr.run(self.root, "2026-10-04", None)
        self.assertEqual(sum(c["calls"] for c in agg2.usage.values()), 1)
        agg3, _ = tr.run(self.root, None, "2026-09-30")
        self.assertEqual(sum(c["calls"] for c in agg3.usage.values()), 0)

    def test_subagent_type_and_errors(self):
        agg, files = tr.run(self.root, None, None)
        types = {k[1] for k in agg.usage if k[0] == "sub"}
        self.assertEqual(types, {"qa-integration"})
        self.assertEqual(agg.errors["edit before read"], 1)

    def test_only_filter(self):
        agg, files = tr.run(self.root, None, None, only=["nomatch"])
        self.assertEqual(files, [])

    def test_report_and_tickets(self):
        tasks = os.path.join(self.root, "tasks")
        os.makedirs(tasks)
        with open(os.path.join(tasks, "T-001-a.md"), "w") as f:
            f.write("---\nid: T-001\nto: ui\nmodel: sonnet\nqa_rounds: 2\nstatus: done\n---\n- [x] a (QA: fail; x)\n")
        tickets = tr.read_tickets(tasks)
        self.assertEqual(tickets[0]["to"], "ui")
        self.assertTrue(tickets[0]["failed"])
        agg, files = tr.run(self.root, None, None)
        text = tr.report(agg, files, tickets, None, None)
        for h in ("## 1.", "## 2.", "## 3.", "## 4.", "## 5.", "fail rate"):
            self.assertIn(h, text)

    def test_in_range_with_time(self):
        self.assertTrue(tr.in_range("2026-10-28T01:43:02Z", "2026-10-28T01:43:02Z", None))
        self.assertFalse(tr.in_range("2026-10-28T01:43:01Z", "2026-10-28T01:43:02Z", None))
        self.assertTrue(tr.in_range("2026-10-28T05:00:00Z", "2026-10-28", "2026-10-28T06:00:00Z"))
        self.assertFalse(tr.in_range("2026-10-28T07:00:00Z", "2026-10-28", "2026-10-28T06:00:00Z"))

    def test_in_range(self):
        self.assertTrue(tr.in_range("2026-10-03T00:00:00Z", "2026-10-03", "2026-10-03"))
        self.assertFalse(tr.in_range("2026-10-04T00:00:00Z", None, "2026-10-03"))


if __name__ == "__main__":
    unittest.main()
