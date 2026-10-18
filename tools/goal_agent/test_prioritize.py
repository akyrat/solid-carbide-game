"""Tests for layer 1, priority scoring (prioritize.py), and for claude_call.py. No Claude calls: FakeClaude only."""

import json
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from goal_agent import claude_call, prioritize  # noqa: E402
from goal_agent.claude_call import FakeClaude, Pause  # noqa: E402


def sg(i, value=3, needs=()):
    return {"id": i, "title": f"Sub-goal {i}", "why": "w", "value": value, "criteria": ["c"], "needs": list(needs)}


class Ranking(unittest.TestCase):
    def ids(self, sub_goals):
        return [s["id"] for s in prioritize.rank(sub_goals)]

    def test_waited_on_beats_higher_value(self):
        # S2 (value 5) needs S1 (value 1): S1 is ranked first anyway
        self.assertEqual(self.ids([sg("S2", 5, ["S1"]), sg("S1", 1)]), ["S1", "S2"])

    def test_counts_the_whole_chain(self):
        # S3 has two waiting further down the chain (S2, then S1); S4 has one directly
        ranked = prioritize.rank([sg("S1", 5, ["S2"]), sg("S2", 5, ["S3"]), sg("S3", 1), sg("S4", 1), sg("S5", 5, ["S4"])])
        self.assertEqual([s["id"] for s in ranked], ["S3", "S2", "S4", "S1", "S5"])
        self.assertEqual(ranked[0]["waiting"], 2)
        self.assertEqual(ranked[0]["score"], "unblocks 2, value 1")
        self.assertEqual([s["rank"] for s in ranked], [1, 2, 3, 4, 5])

    def test_ties_by_value_then_order(self):
        self.assertEqual(self.ids([sg("S1", 2), sg("S2", 4), sg("S3", 4), sg("S4", 1)]), ["S2", "S3", "S1", "S4"])

    def test_cycle_is_refused(self):
        with self.assertRaises(Pause) as e:
            prioritize.rank([sg("S1", needs=["S2"]), sg("S2", needs=["S3"]), sg("S3", needs=["S1"])])
        self.assertIn("cycle", str(e.exception))
        self.assertIn("S1 -> S2 -> S3 -> S1", str(e.exception))

    def test_self_cycle_is_refused(self):
        with self.assertRaises(Pause):
            prioritize.rank([sg("S1", needs=["S1"])])

    def test_unknown_need_and_bad_value_are_refused(self):
        with self.assertRaises(Pause):
            prioritize.rank([sg("S1", needs=["S9"])])
        with self.assertRaises(Pause):
            prioritize.rank([sg("S1", value=7)])


class Plan(unittest.TestCase):
    def test_plan_asks_once_and_ranks(self):
        claude = FakeClaude({"plan": [{"goal_criteria": ["g"], "open_questions": ["q"],
                                       "sub_goals": [sg("S1", 5, ["S2"]), sg("S2", 1)]}]})
        plan = prioritize.plan(claude, "The board's goal", "root")
        self.assertEqual([s["id"] for s in plan["sub_goals"]], ["S2", "S1"])
        self.assertEqual(plan["open_questions"], ["q"])
        step, text, options = claude.calls[0]
        self.assertEqual(step, "plan")
        self.assertIn("The board's goal", text)
        self.assertIn("docs/short-gdd/short-gdd.md", text)
        self.assertIn("open_questions", text)        # docs leave it open -> a question, not an invented answer
        self.assertIn("Ideas come only from the board", text)

    def test_refusal_pauses(self):
        claude = FakeClaude({"plan": [{"goal_criteria": ["g"], "open_questions": [], "sub_goals": [sg("S1")],
                                       "_permission_denials": [{"tool_name": "Write"}]}]})
        with self.assertRaises(Pause):
            prioritize.plan(claude, "goal", "root")


class Claude(unittest.TestCase):
    def run_real(self, **options):
        done = mock.Mock(stdout=json.dumps({"structured_output": {}}), stderr="", returncode=0)
        with mock.patch.object(claude_call.subprocess, "run", return_value=done) as run:
            claude_call.RealClaude().ask("plan", "hello", {}, **options)
        return run.call_args[0][0]

    def test_tools_option_goes_on_the_command_line(self):
        cmd = self.run_real(tools="Read,Glob,Grep")
        self.assertEqual(cmd[cmd.index("--tools") + 1], "Read,Glob,Grep")

    def test_no_tools_option_leaves_the_command_unchanged(self):
        self.assertNotIn("--tools", self.run_real())

    def test_fake_claude_records_tools(self):
        claude = FakeClaude({"plan": [{}]})
        claude.ask("plan", "p", {}, tools="Read")
        self.assertEqual(claude.calls[0][2]["tools"], "Read")

    def test_plan_passes_only_read_tools(self):
        claude = FakeClaude({"plan": [{"goal_criteria": ["g"], "open_questions": [], "sub_goals": [sg("S1")]}]})
        prioritize.plan(claude, "goal", "root")
        self.assertEqual(claude.calls[0][2]["tools"], "Read,Glob,Grep")

    def test_real_claude_command_and_denials(self):
        out = {"type": "result", "is_error": False, "result": "", "structured_output": {"a": 1},
               "permission_denials": [{"tool_name": "Bash"}]}
        done = mock.Mock(stdout=json.dumps(out), stderr="", returncode=0)
        with mock.patch.object(claude_call.subprocess, "run", return_value=done) as run:
            answer = claude_call.RealClaude().ask("plan", "hello", {"type": "object"}, model="opus",
                                                  agent="qa-integration", session_id="abc", cwd="here")
        cmd = run.call_args[0][0]
        self.assertEqual(cmd[:6], ["claude", "-p", "hello", "--output-format", "json", "--json-schema"])
        for flag in ("--model", "--agent", "--session-id"):
            self.assertIn(flag, cmd)
        self.assertEqual(run.call_args[1]["cwd"], "here")
        self.assertEqual(answer.data, {"a": 1})
        self.assertEqual(answer.denials, [{"tool_name": "Bash"}])

    def test_parse_falls_back_to_result_text(self):
        self.assertEqual(claude_call.parse({"result": '{"b": 2}'}, "s"), {"b": 2})
        with self.assertRaises(Pause):
            claude_call.parse({"is_error": True, "result": "boom"}, "s")

    def test_fake_answers_in_order_then_runs_out(self):
        claude = FakeClaude({"gaps": [{"n": 1}, {"n": 2}]})
        self.assertEqual(claude.ask("gaps", "p", {}).data, {"n": 1})
        self.assertEqual(claude.ask("gaps", "p", {}).data, {"n": 2})
        with self.assertRaises(Pause):
            claude.ask("gaps", "p", {})


if __name__ == "__main__":
    unittest.main()
