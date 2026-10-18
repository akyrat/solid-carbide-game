"""Tests for layer 2, gap detection (gaps.py): the scan, verdict checks, and one retry before pausing."""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from goal_agent import gaps, temp_repo  # noqa: E402
from goal_agent.claude_call import FakeClaude, Pause  # noqa: E402
from goal_agent.test_tickets import draft  # noqa: E402

SUB_GOALS = [{"id": "S1", "title": "One", "criteria": ["c"], "needs": []},
             {"id": "S2", "title": "Two", "criteria": ["c"], "needs": []}]


def verdicts(*items):
    return {"verdicts": [dict({"tickets": [], "code": [], "drafts": []}, **v) for v in items]}


GOOD = verdicts({"sub_goal": "S1", "verdict": "in-flight", "tickets": ["T-003"]},
                {"sub_goal": "S2", "verdict": "missing", "drafts": [draft("D1")]})
BAD = verdicts({"sub_goal": "S1", "verdict": "in-flight", "tickets": ["T-003"]},
               {"sub_goal": "S2", "verdict": "missing", "drafts": [draft("D1", to="nobody")]})


class GapDetection(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = temp_repo.make(self.tmp.name)
        temp_repo.add_ticket(self.root, "T-003", status="in-progress", title="Already in flight")

    def tearDown(self):
        self.tmp.cleanup()

    def test_detect_passes_only_read_tools(self):
        claude = FakeClaude({"gaps": [GOOD]})
        gaps.detect(claude, "goal", SUB_GOALS, self.root)
        self.assertEqual(claude.calls[0][2]["tools"], "Read,Glob,Grep")

    def test_code_index_skips_addons_cache_and_art(self):
        files, heads = gaps.code_index(self.root)
        self.assertEqual(files, ["README.md", "scripts/car.gd"])
        self.assertEqual(heads, ["# Game", "## Setup"])

    def test_prompt_shows_tickets_and_code(self):
        claude = FakeClaude({"gaps": [GOOD]})
        gaps.detect(claude, "goal", SUB_GOALS, self.root)
        text = claude.calls[0][1]
        self.assertIn("T-003 [in-progress] ui, tooling: Already in flight", text)
        self.assertIn("scripts/car.gd", text)

    def test_accepted_first_time(self):
        claude = FakeClaude({"gaps": [GOOD]})
        found, existing = gaps.detect(claude, "goal", SUB_GOALS, self.root)
        self.assertEqual(len(claude.calls), 1)
        self.assertEqual(found[0]["tickets"], ["T-003"])
        self.assertIn("T-003", existing)

    def test_refused_set_is_retried_once_with_the_reasons(self):
        claude = FakeClaude({"gaps": [BAD, GOOD]})
        gaps.detect(claude, "goal", SUB_GOALS, self.root)
        self.assertEqual(len(claude.calls), 2)
        self.assertIn("not an agent", claude.calls[1][1])

    def test_refused_twice_pauses_with_the_reasons(self):
        claude = FakeClaude({"gaps": [BAD, BAD, GOOD]})
        with self.assertRaises(Pause) as e:
            gaps.detect(claude, "goal", SUB_GOALS, self.root)
        self.assertEqual(len(claude.calls), 2)
        self.assertIn("refused twice", str(e.exception))
        self.assertIn("not an agent", str(e.exception))

    def test_verdict_checks(self):
        existing = {"T-003": {}}
        reasons = gaps.check_verdicts(verdicts({"sub_goal": "S1", "verdict": "covered"},
                                               {"sub_goal": "S1", "verdict": "missing"},
                                               {"sub_goal": "S9", "verdict": "in-flight", "tickets": ["T-404"]})["verdicts"],
                                      SUB_GOALS, existing)
        text = "\n".join(reasons)
        for words in ("S1 needs exactly one verdict", "S2 needs exactly one verdict", "covered but names no tickets",
                      "missing but no ticket drafts", "not a sub-goal", "T-404, which is not an existing ticket"):
            self.assertIn(words, text)

    def test_refusal_pauses(self):
        claude = FakeClaude({"gaps": [dict(GOOD, _permission_denials=[{"tool_name": "Write"}])]})
        with self.assertRaises(Pause):
            gaps.detect(claude, "goal", SUB_GOALS, self.root)


if __name__ == "__main__":
    unittest.main()
