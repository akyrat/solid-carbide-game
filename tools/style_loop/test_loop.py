"""Tests for the style loop (T-291): loop.py and run.py. FakeClaude only: nothing calls Claude or PixelLab.
Each test works in task_status.sandbox, so only the status script finds and writes the test's ticket (its
helpers, write_section and the style loop's flag, are tested in tools/test_task_status.py).

  python -m unittest discover -s tools -p "test_*.py"
"""

import contextlib
import io
import json
import struct
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import taskboard_sync as tb  # noqa: E402
import task_status as ts  # noqa: E402
from goal_agent.claude_call import FakeClaude, Pause  # noqa: E402
from style_loop import loop, run  # noqa: E402

FIXTURES = Path(__file__).resolve().parent / "fixtures"

TASK = """---
id: T-901
title: "A text task"
status: in-progress
from: project-lead
to: narrative-theme
lead: Tools
epic: hud-menus
milestone: mvp
depends_on: []
qa_rounds: 0
---

## Description

Something to write.

## Acceptance criteria

- [ ] It reads well (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket.

## Style review

Only for art and text tasks: one entry per round of the style loop, written by the loop's tool.

## Result notes

Written by the agent when it finishes.
"""


def png_bytes(rows):
    """An 8-bit RGBA PNG of `rows` (lists of (r, g, b, a)), for the art tests."""
    h, w = len(rows), len(rows[0])
    raw = b"".join(b"\x00" + bytes(c for p in row for c in p) for row in rows)

    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def sprite(colour):
    """A 4x4 sprite: transparent corners, a 2x2 block of `colour` in the middle."""
    clear, c = (0, 0, 0, 0), tuple(colour) + (255,)
    return [[clear] * 4, [clear, c, c, clear], [clear, c, c, clear], [clear] * 4]


def evaluation(score, reason="r", rules=()):
    return {"score": score, "reason": reason, "rules_broken": list(rules)}


class Base(unittest.TestCase):
    def setUp(self):
        # the status script's own sandbox holds the test's task; only task_status.py finds and writes it
        self.root = self.enterContext(ts.sandbox(text=TASK, keep=False))
        saved = tempfile.tempdir
        tempfile.tempdir = str(self.root)   # a fake run's own sandbox goes inside this one, and goes with it
        self.addCleanup(setattr, tempfile, "tempdir", saved)

    def spec(self, kind="text", **kw):
        kw.setdefault("text_kind", "popup" if kind == "text" else None)
        return loop.Spec(kind=kind, task="T-901", root=ts.task_checkout("T-901"), brief="A combo popup.",
                         brief_name="brief.md", **kw)

    def ticket(self):
        return ts.find("T-901")[0]

    def status(self):
        return ts.header(self.ticket()).get("status")

    def text(self):
        return self.ticket().read_text(encoding="utf-8")

    def section(self):
        text = self.text()
        return text.split("## Style review", 1)[1].split("\n## ", 1)[0]

    def rounds_in_record(self):
        return self.section().split("### Round ")[1:]


class TextLoop(Base):
    def test_scores_4_6_9_stop_after_the_third_version_and_keep_it(self):
        claude = FakeClaude(FIXTURES / "text-4-6-9.json")
        kept, rounds = loop.run(claude, self.spec())
        self.assertEqual((kept.n, kept.score, kept.version), (3, 9, "SAMPLE COMBO!"))
        self.assertEqual([r.score for r in rounds], [4, 6, 9])
        self.assertEqual([c[0] for c in claude.calls],
                         ["generate", "evaluate", "refine", "evaluate", "refine", "evaluate"])
        self.assertEqual(self.status(), "in-progress", "a kept version at 8 flags nothing")

    def test_the_style_review_has_every_round_with_its_parts(self):
        loop.run(FakeClaude(FIXTURES / "text-4-6-9.json"), self.spec())
        fixture = json.loads((FIXTURES / "text-4-6-9.json").read_text(encoding="utf-8"))
        answers = fixture["generate"] + fixture["refine"]
        rounds = self.rounds_in_record()
        self.assertEqual(len(rounds), 3)
        for i, (body, answer, verdict) in enumerate(zip(rounds, answers, fixture["evaluate"]), start=1):
            self.assertTrue(body.startswith(f"{i}\n"))
            self.assertIn(f'- Version {i}: "{answer["text"]}"', body)
            self.assertIn("- Script checks: ", body)
            self.assertIn(f"- Score: {verdict['score']}/10", body)
            self.assertIn(f"- Reason: {verdict['reason']}", body)
            if i == 1:
                self.assertNotIn("What changed", body)
            else:
                self.assertIn(f"- What changed: {answer['changed']}", body)
        self.assertIn("**Kept:** version 3, score 9/10", rounds[-1])
        self.assertIn("rule 4, popup: in capitals", rounds[0], "round 1's failed script check is named")
        self.assertNotIn("Only for art and text tasks", self.text(), "the template's line is replaced")

    def test_the_rest_of_the_task_file_is_untouched(self):
        loop.run(FakeClaude(FIXTURES / "text-4-6-9.json"), self.spec())
        text = self.text()
        before, after = TASK.split("## Style review")[0], TASK.split("## Result notes")[1]
        self.assertTrue(text.startswith(before))
        self.assertTrue(text.endswith("## Result notes" + after))

    def test_the_generator_is_one_session_resumed_and_the_evaluator_is_the_style_evaluator(self):
        claude = FakeClaude(FIXTURES / "text-4-6-9.json")
        loop.run(claude, self.spec())
        gen = [c for c in claude.calls if c[0] in ("generate", "refine")]
        session = gen[0][2]["session_id"]
        self.assertTrue(session)
        self.assertEqual([c[2].get("resume") for c in gen[1:]], [session, session])
        self.assertTrue(all(c[2]["agent"] == "narrative-theme" for c in gen))
        for step, prompt, options in claude.calls:
            if step == "evaluate":
                self.assertEqual(options["agent"], "style-evaluator")
                self.assertNotIn("resume", options)
                self.assertIn("A combo popup.", prompt)
        refine_prompt = gen[1][1]
        self.assertIn("scored version 1 4/10", refine_prompt)
        self.assertIn(json.loads((FIXTURES / "text-4-6-9.json").read_text())["evaluate"][0]["reason"], refine_prompt)

    def test_never_reaching_8_keeps_the_best_of_4_versions_and_flags_the_task(self):
        claude = FakeClaude(FIXTURES / "text-never-8.json")
        kept, rounds = loop.run(claude, self.spec())
        self.assertEqual([r.score for r in rounds], [5, 7, 6, 4])
        self.assertEqual(len([c for c in claude.calls if c[0] == "refine"]), 3)
        self.assertEqual((kept.n, kept.score), (2, 7))
        self.assertEqual(self.status(), "flagged-for-review")
        self.assertIn("in-progress → flagged-for-review: the style loop kept version 2", self.text())
        log = [json.loads(l) for l in ts.LOG.read_text(encoding="utf-8").splitlines()]
        self.assertEqual((log[-1]["from"], log[-1]["to"], log[-1]["by"]), ("in-progress", "flagged-for-review", "style-loop"))
        self.assertEqual(len(self.rounds_in_record()), 4)
        self.assertIn("**Kept:** version 2, score 7/10", self.section())
        self.assertIn("flagged for the board's review", self.section())

    def test_a_tie_keeps_the_earliest_version(self):
        fixture = {"generate": [{"text": "A!", "changed": "c"}], "refine": [{"text": "B!", "changed": "c"}] * 3,
                   "evaluate": [evaluation(5), evaluation(6), evaluation(6), evaluation(3)]}
        kept, _ = loop.run(FakeClaude(fixture), self.spec(), flag=lambda spec, kept: None)
        self.assertEqual(kept.n, 2)

    def test_the_kept_text_goes_to_out_when_given(self):
        out = self.root / "text" / "popup.txt"
        loop.run(FakeClaude(FIXTURES / "text-4-6-9.json"), self.spec(out=out))
        self.assertEqual(out.read_text(encoding="utf-8"), "SAMPLE COMBO!\n")

    def test_no_text_or_no_score_stops_the_loop(self):
        with self.assertRaises(Pause):
            loop.run(FakeClaude({"generate": [{"text": " ", "changed": ""}]}), self.spec())
        with self.assertRaises(Pause):
            loop.run(FakeClaude({"generate": [{"text": "A!", "changed": ""}], "evaluate": [{"reason": "r"}]}),
                     self.spec())

    def test_each_round_is_written_as_it_ends(self):
        """A run stopped half way still leaves the rounds it finished."""
        fixture = {"generate": [{"text": "A!", "changed": "c"}], "evaluate": [evaluation(3)]}
        with self.assertRaises(Pause):
            loop.run(FakeClaude(fixture), self.spec())
        self.assertEqual(len(self.rounds_in_record()), 1)
        self.assertNotIn("**Kept:**", self.section())

    def test_refusals_are_recorded_on_the_round(self):
        fixture = {"generate": [{"text": "A!", "changed": "c", "_permission_denials": [{"tool_name": "Bash"}]}],
                   "evaluate": [evaluation(9)]}
        loop.run(FakeClaude(fixture), self.spec())
        self.assertIn('- Refused: {"tool_name": "Bash"}', self.section())


class ArtLoop(Base):
    def made(self, name, colour):
        path = self.root / "made" / name
        path.parent.mkdir(exist_ok=True)
        path.write_bytes(png_bytes(sprite(colour)))
        return path

    def fixture(self, scores):
        files = [self.made(f"try{i}.png", (20 * i, 60, 120)) for i in range(1, len(scores) + 1)]
        return {"generate": [{"file": str(files[0]), "changed": "first"}],
                "refine": [{"file": str(f), "changed": f"version {i}"} for i, f in enumerate(files[1:], start=2)],
                "evaluate": [evaluation(s) for s in scores]}, files

    def test_every_art_version_is_saved_in_the_archive_and_the_kept_one_goes_to_out(self):
        fixture, files = self.fixture([3, 5, 7, 6])
        out = self.root / "game" / "art" / "thing.png"
        kept, rounds = loop.run(FakeClaude(fixture), self.spec("art", out=out, size=(4, 4)),
                                flag=lambda spec, kept: None)
        archive = self.root / "art-archive" / "T-901" / "style-loop"
        self.assertEqual(sorted(p.name for p in archive.iterdir()), ["v1.png", "v2.png", "v3.png", "v4.png"])
        for i, f in enumerate(files, start=1):
            self.assertEqual((archive / f"v{i}.png").read_bytes(), f.read_bytes())
            self.assertTrue(f.exists(), "the agent's own file is left where it is")
        self.assertEqual(kept.n, 3)
        self.assertEqual(out.read_bytes(), files[2].read_bytes())
        self.assertIn("- Version 1: `art-archive/T-901/style-loop/v1.png`", self.section())
        self.assertEqual({c["rule"] for c in rounds[0].checks}, {1, 3, 6})
        self.assertTrue(all(c["ok"] for r in rounds for c in r.checks))

    def test_the_evaluator_is_shown_the_image_and_the_generator_where_to_save(self):
        fixture, _ = self.fixture([9])
        claude = FakeClaude(fixture)
        loop.run(claude, self.spec("art", out=self.root / "o.png"))
        (_, gen_prompt, gen_opts), (_, eval_prompt, eval_opts) = claude.calls
        self.assertEqual(gen_opts["agent"], "asset-generation")
        self.assertIn(str(self.root / "art-archive" / "T-901" / "style-loop" / "v1.png"), gen_prompt)
        self.assertIn(f"The image is {self.root / 'art-archive/T-901/style-loop/v1.png'}", eval_prompt)
        self.assertEqual(eval_opts["tools"], "Read,Glob,Grep")

    def test_an_earlier_run_is_never_overwritten(self):
        archive = self.root / "art-archive" / "T-901" / "style-loop"
        archive.mkdir(parents=True)
        (archive / "v1.png").write_bytes(b"earlier run")
        fixture, _ = self.fixture([9])
        kept, _ = loop.run(FakeClaude(fixture), self.spec("art", out=self.root / "o.png"))
        self.assertEqual((archive / "v1.png").read_bytes(), b"earlier run")
        self.assertEqual(kept.version, "art-archive/T-901/style-loop/v1-2.png")

    def test_a_file_saved_straight_into_the_archive_is_used_as_it_is(self):
        root = self.root

        class Agent(FakeClaude):
            """Saves each version where the prompt asks, as the real agent does, and names it (or not)."""
            def ask(self, step, prompt, schema, **options):
                answer = super().ask(step, prompt, schema, **options)
                if step in ("generate", "refine"):
                    target = root / "art-archive" / "T-901" / "style-loop" / ("v1.png" if step == "generate" else "v2.png")
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(png_bytes(sprite((10, 60, 120))))
                    answer.data["file"] = str(target) if step == "generate" else ""
                return answer
        fixture = {"generate": [{"file": "", "changed": "first"}], "refine": [{"file": "", "changed": "second"}],
                   "evaluate": [evaluation(5), evaluation(9)]}
        kept, rounds = loop.run(Agent(fixture), self.spec("art", out=self.root / "o.png"))
        self.assertEqual([r.version for r in rounds],
                         ["art-archive/T-901/style-loop/v1.png", "art-archive/T-901/style-loop/v2.png"])
        self.assertEqual(sorted(p.name for p in (root / "art-archive" / "T-901" / "style-loop").iterdir()),
                         ["v1.png", "v2.png"])

    def test_the_script_checks_find_a_red(self):
        path = self.made("red.png", (219, 26, 41))
        fixture = {"generate": [{"file": str(path), "changed": "first"}], "evaluate": [evaluation(9)]}
        _, rounds = loop.run(FakeClaude(fixture), self.spec("art", out=self.root / "o.png", size=(4, 4)))
        failed = [c for c in rounds[0].checks if not c["ok"]]
        self.assertEqual([c["rule"] for c in failed], [6])
        self.assertIn("failed: rule 6, no Redgull red", self.section())

    def test_no_png_stops_the_loop(self):
        with self.assertRaises(Pause):
            loop.run(FakeClaude({"generate": [{"file": "nowhere.png", "changed": ""}]}), self.spec("art"))


class CommandLine(Base):
    def cli(self, *argv):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = run.main(list(argv))
        return code, out.getvalue() + err.getvalue()

    @staticmethod
    def copy_of_ticket(out):
        """The ticket in the fake run's own sandbox, whose folder the run prints first."""
        base = Path(out.split(": ", 1)[1].splitlines()[0])
        return next((base / ts.TASKS_FOLDER).iterdir())

    def test_a_fake_text_run_goes_end_to_end_on_a_copy_of_the_task(self):
        ticket = self.ticket()
        code, out = self.cli("text", "--task", "T-901", "--brief", str(FIXTURES / "sample-brief.md"),
                             "--kind", "popup", "--fake", str(FIXTURES / "text-4-6-9.json"))
        self.assertEqual(code, 0, out)
        self.assertIn("Round 3: score 9/10", out)
        self.assertIn('Kept version 3, score 9/10: "SAMPLE COMBO!"', out)
        self.assertEqual(self.text(), TASK, "a fake run never changes the real task")
        self.assertIn("### Round 3", self.copy_of_ticket(out).read_text(encoding="utf-8"))
        self.assertEqual(self.ticket(), ticket, "the fake run's sandbox puts the status script's paths back")

    def test_a_fake_run_below_8_flags_only_the_copy(self):
        code, out = self.cli("text", "--task", "T-901", "--brief", str(FIXTURES / "sample-brief.md"),
                             "--kind", "popup", "--fake", str(FIXTURES / "text-never-8.json"))
        self.assertEqual(code, 1, out)
        self.assertIn("flagged for the board's review", out)
        self.assertEqual(ts.header(self.copy_of_ticket(out)).get("status"), "flagged-for-review")
        self.assertEqual(self.status(), "in-progress")

    def test_a_fake_art_run_archives_in_the_copy(self):
        made = self.root / "made.png"
        made.write_bytes(png_bytes(sprite((10, 60, 120))))
        fixture = self.root / "art.json"
        fixture.write_text(json.dumps({"generate": [{"file": str(made), "changed": "first"}],
                                       "evaluate": [evaluation(8)]}), encoding="utf-8")
        code, out = self.cli("art", "--task", "T-901", "--brief", str(FIXTURES / "sample-brief.md"),
                             "--out", "game/art/thing.png", "--size", "4x4", "--fake", str(fixture))
        self.assertEqual(code, 0, out)
        base = Path(out.split(": ", 1)[1].splitlines()[0])
        self.assertTrue((base / "art-archive" / "T-901" / "style-loop" / "v1.png").is_file())
        self.assertEqual((base / "out" / "thing.png").read_bytes(), made.read_bytes())
        self.assertFalse((self.root / "art-archive").exists())

    def test_usage_errors(self):
        code, out = self.cli("text", "--task", "T-999", "--brief", str(FIXTURES / "sample-brief.md"), "--kind", "popup")
        self.assertEqual(code, 2)
        self.assertIn("No task file for T-999", out)
        with self.assertRaises(SystemExit):
            with contextlib.redirect_stderr(io.StringIO()):
                run.main(["art", "--task", "T-901", "--brief", "b.md"])   # art needs --out


if __name__ == "__main__":
    unittest.main()
