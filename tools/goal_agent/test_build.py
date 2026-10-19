"""Tests for layer 3, code writing (build.py): the folders and branches, the headless runs' options, merging
with Godot's .import noise reverted, a conflict, a ticket written by a rescan, and the file docstrings.
Temporary git repos with worktrees, and the fake team: nothing calls Claude, PixelLab or the network."""

import ast
import json
import subprocess
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from goal_agent import build, goal_file, temp_repo  # noqa: E402
from goal_agent.claude_call import Pause  # noqa: E402
from goal_agent.test_loop import GoalRepo, agent, check, draft, gaps, missing, named, plan, qa, sub  # noqa: E402

HERE = Path(__file__).resolve().parent


def one_ticket(to="game-data", files=None, **extra):
    f = {"plan": [plan(sub("S1"))],
         "gaps": [gaps(missing("S1", draft("D1", title="Ticket one", to=to))), gaps(named("S1", "covered", "Ticket one"))],
         "agent": [agent(files=files)], "qa": [qa()], "goal-check": [check("pass")]}
    f.update(extra)
    return f


class Folders(GoalRepo):
    def test_the_default_places_are_the_studios(self):
        p = build.Places("C:/solid-carbide-game")
        self.assertEqual(p.worktrees, Path("C:/solid-carbide-worktrees"))
        self.assertEqual((p.goal_branch("G-001"), p.goal_folder("G-001")),
                         ("playtest/G-001", Path("C:/solid-carbide-worktrees/G-001")))
        self.assertEqual(p.ticket_branch({"file": "tasks/T-012-short-title.md"}), "task/T-012-short-title")

    def test_folders_branches_and_secrets(self):
        (self.root / ".env").write_text("PIXELLAB_TOKEN=fake\n", encoding="utf-8")   # git-ignored in the studio
        (self.root / ".secrets").mkdir()
        (self.root / ".secrets" / "key.txt").write_text("fake", encoding="utf-8")
        b = self.planned(one_ticket())
        self.assertEqual(self.run_loop(b).get("status"), "ready-to-play")
        goal_folder, ticket_folder = self.places.goal_folder("G-001"), self.places.ticket_folder("T-001")
        for folder in (goal_folder, ticket_folder):
            self.assertEqual((folder / ".env").read_text(encoding="utf-8"), "PIXELLAB_TOKEN=fake\n")
            self.assertTrue((folder / ".secrets" / "key.txt").exists())
        branch = lambda f: temp_repo.git(f, "rev-parse", "--abbrev-ref", "HEAD").strip()  # noqa: E731
        self.assertEqual((branch(goal_folder), branch(ticket_folder)), ("playtest/G-001", "task/T-001-ticket-one"))
        # the ticket's branch starts from the goal's build, which starts from master
        start = temp_repo.git(self.root, "merge-base", "task/T-001-ticket-one", "playtest/G-001^1").strip()
        self.assertEqual(start, temp_repo.git(self.root, "rev-parse", "playtest/G-001^1").strip())

    def test_a_later_ticket_builds_on_the_goals_earlier_work(self):
        f = {"plan": [plan(sub("S1"), sub("S2", needs=["S1"]))],
             "gaps": [gaps(missing("S1", draft("D1", title="Ticket one")),
                           missing("S2", draft("D2", title="Ticket two", depends_on=["D1"]))),
                      gaps(named("S1", "covered", "Ticket one"), named("S2", "in-flight", "Ticket two")),
                      gaps(named("S2", "covered", "Ticket two"))],
             "agent": [agent(files={"game/one.txt": "one\n"}), agent(files={"game/two.txt": "two\n"})],
             "qa": [qa(), qa()], "goal-check": [check("pass")]}
        b = self.planned(f)
        self.run_loop(b)
        self.assertTrue((self.places.ticket_folder("T-002") / "game" / "one.txt").exists(), "T-001's work is there")

    def test_a_ticket_a_rescan_writes_is_brought_into_the_build_and_built(self):
        f = one_ticket()
        f["gaps"][1:] = [gaps(missing("S1", draft("D2", title="Ticket two"))), gaps(named("S1", "covered", "Ticket two"))]
        f["agent"], f["qa"] = [agent(), agent()], [qa(), qa()]
        b = self.planned(f)
        goal = self.run_loop(b)
        self.assertEqual(goal.get("status"), "ready-to-play", goal.section("Pauses"))
        self.assertEqual(loop_tickets(goal), [("T-001", "S1", "written"), ("T-002", "S1", "written")])
        self.assertIn("bring T-002", temp_repo.git(self.root, "log", "playtest/G-001", "--format=%s"))
        self.assertTrue(self.merged(b, "T-002"))
        self.assertEqual(self.now()["T-002"]["lead"], "Goal-G-001", "claimed for the goal")


def loop_tickets(goal):
    from goal_agent import loop
    return loop.goal_tickets(goal)


class HeadlessRuns(GoalRepo):
    def test_a_project_lead_ticket_runs_without_agent_and_the_prompts_say_the_rules(self):
        b = self.planned(one_ticket(to="project-lead"))
        self.run_loop(b)
        step, prompt, options = next(c for c in b.claude.calls if c[0] == "agent")
        self.assertIsNone(options["agent"])
        self.assertEqual(options["cwd"], str(self.places.ticket_folder("T-001")))
        self.assertNotIn("add_dir", options, "no access to the main checkout")
        self.assertTrue(options["session_id"])
        self.assertEqual(options["permission_mode"], build.PERMISSION_MODE)
        self.assertTrue(prompt.startswith("Work on task T-001"))
        for words in ("goal G-001", "commit only in that folder", "result notes", "tests",
                      "never work around it", "generations left"):
            self.assertIn(words, prompt)
        step, prompt, options = next(c for c in b.claude.calls if c[0] == "qa")
        self.assertTrue(prompt.startswith("QA round 1 for task T-001"))
        self.assertIn("- [ ] It works (QA: pass / fail)", prompt)        # the ticket's criteria are listed
        self.assertIn("`(QA: pass)` or `(QA: fail: <reason>)`", prompt)
        self.assertEqual((options["agent"], options["model"]), ("qa-integration", "sonnet"))

    def prompts(self, b):
        self.run_loop(b)
        return [next(c for c in b.claude.calls if c[0] == step)[1] for step in ("agent", "qa")]

    def test_agent_prompt_asks_for_screenshots_and_qa_prompt_fails_a_ticket_without_them(self):
        agent, qa = self.prompts(self.planned(one_ticket()))
        for words in ("art-archive/<ticket id>/screenshots/", "listed in your result notes",
                      "a picture drawn from the data by a script when nothing is on screen yet",
                      "none only for tooling, docs or text-only work"):
            self.assertIn(words, agent)
        for words in ("screenshots rule", "could be pictured", "art-archive/<ticket id>/screenshots/",
                      "fails, whatever its criteria say"):
            self.assertIn(words, qa)

    def test_prompts_list_the_pre_approved_commands_from_the_settings(self):
        (self.root / ".claude").mkdir(exist_ok=True)
        allow = ["Bash(git add *)", "Bash(python -m unittest discover *)"]
        (self.root / ".claude" / "settings.json").write_text(json.dumps({"permissions": {"allow": allow}}),
                                                             encoding="utf-8")
        for prompt in self.prompts(self.planned(one_ticket())):
            for entry in allow:
                self.assertIn(entry, prompt)
            self.assertIn("plain, separate Bash commands", prompt)
            self.assertIn("no && chains", prompt)

    def test_a_missing_or_empty_list_leaves_the_prompts_as_they_were(self):
        self.assertEqual(build.pre_approved_note(self.root), "", "no settings file")
        (self.root / ".claude").mkdir(exist_ok=True)
        (self.root / ".claude" / "settings.json").write_text('{"permissions": {"allow": []}}', encoding="utf-8")
        self.assertEqual(build.pre_approved_note(self.root), "")
        (self.root / ".claude" / "settings.json").write_text("{}", encoding="utf-8")
        for prompt in self.prompts(self.planned(one_ticket())):
            self.assertNotIn("pre-approved", prompt)

    def test_the_sessions_keep_accept_edits(self):
        self.assertEqual(build.PERMISSION_MODE, "acceptEdits")


class Merging(GoalRepo):
    def test_import_noise_is_reverted_and_real_changes_are_merged(self):
        imp = self.root / "game" / "art" / "car.png.import"
        imp.write_bytes(b"[remap]\nimporter=\"texture\"\n")
        temp_repo.git(self.root, "add", "-A")
        temp_repo.git(self.root, "commit", "-q", "-m", "an import file")
        b = self.planned(one_ticket(files={"game/art/car.png.import": "[remap]\r\nimporter=\"texture\"\r\n",
                                           "game/scripts/new.gd": "extends Node\n"}))
        self.run_loop(b)
        folder = self.places.goal_folder("G-001")
        self.assertEqual((folder / "game" / "art" / "car.png.import").read_bytes(), b"[remap]\nimporter=\"texture\"\n")
        self.assertTrue((folder / "game" / "scripts" / "new.gd").exists())
        merge = temp_repo.git(self.root, "show", "--name-only", "--format=%s", "playtest/G-001")
        self.assertIn("Merge task/T-001-ticket-one into playtest/G-001", merge)
        self.assertNotIn("car.png.import", merge)

    def test_a_real_import_change_is_kept(self):
        imp = self.root / "game" / "art" / "car.png.import"
        imp.write_bytes(b"[remap]\nimporter=\"texture\"\n")
        temp_repo.git(self.root, "add", "-A")
        temp_repo.git(self.root, "commit", "-q", "-m", "an import file")
        b = self.planned(one_ticket(files={"game/art/car.png.import": "[remap]\nimporter=\"image\"\n"}))
        self.run_loop(b)
        self.assertIn(b"image", (self.places.goal_folder("G-001") / "game" / "art" / "car.png.import").read_bytes())

    def test_a_merge_conflict_is_aborted_and_pauses(self):
        class Meddling(build.Shell):
            """Someone else changes the same line on the goal's build just before the merge."""
            def run(self, cmd, cwd, check=True):
                if "merge" in cmd and "--no-ff" in cmd:
                    (Path(cwd) / "game" / "scripts" / "car.gd").write_text("extends Sprite2D\n", encoding="utf-8")
                    temp_repo.git(cwd, "commit", "-q", "-am", "someone else's change on the build")
                return super().run(cmd, cwd, check)
        b = self.planned(one_ticket(files={"game/scripts/car.gd": "extends Node2D\n"}), shell=Meddling())
        folder = self.places.goal_folder("G-001")
        goal = self.run_loop(b)
        self.assertPaused(goal, "merge", "conflicted")
        self.assertEqual(temp_repo.git(folder, "status", "--porcelain"), "", "the merge was aborted")
        self.assertEqual(self.steps(b), ["plan", "gaps", "agent", "qa"])


class RealCommand(unittest.TestCase):
    def test_the_headless_claude_command(self):
        import json
        from unittest import mock
        from goal_agent.claude_call import RealClaude
        out = {"is_error": False, "structured_output": {"summary": "s"}, "permission_denials": []}
        done = mock.Mock(stdout=json.dumps(out), stderr="", returncode=0)
        with mock.patch("subprocess.run", return_value=done) as run:
            answer = RealClaude().ask("agent", "Work on task T-001", build.AGENT_SCHEMA, model="opus", agent="ui",
                                      session_id="abc", cwd="C:/w/T-001", permission_mode="acceptEdits", timeout=5)
        cmd, kw = run.call_args[0][0], run.call_args[1]
        self.assertEqual(cmd[:2], ["claude", "-p"])
        self.assertNotIn("Work on task T-001", cmd)
        self.assertEqual(kw["input"], "Work on task T-001")
        for flag, value in (("--model", "opus"), ("--agent", "ui"), ("--session-id", "abc"),
                            ("--permission-mode", "acceptEdits"), ("--output-format", "json")):
            self.assertEqual(cmd[cmd.index(flag) + 1], value)
        self.assertNotIn("--add-dir", cmd)
        self.assertEqual((kw["cwd"], kw["timeout"]), ("C:/w/T-001", 5))
        self.assertEqual(answer.data, {"summary": "s"})


class Docstrings(unittest.TestCase):
    def test_every_new_file_names_its_layer(self):
        for name, words in (("build.py", "Layer 3"), ("loop.py", "Layer 4"), ("fake_team.py", "Test support"),
                            ("run.py", "command line")):
            tree = ast.parse((HERE / name).read_text(encoding="utf-8"), name, feature_version=(3, 9))
            self.assertTrue(ast.get_docstring(tree).startswith(words) or words in ast.get_docstring(tree).split("\n")[0],
                            name)

    def test_shell_pauses_on_a_failed_command(self):
        with self.assertRaises(Pause) as e:
            build.Shell().run([sys.executable, "-c", "import sys; print('Refused. no'); sys.exit(1)"], HERE)
        self.assertEqual(e.exception.kind, "command")
        self.assertIn("Refused. no", str(e.exception))
        self.assertEqual(build.Shell().run([sys.executable, "-c", "pass"], HERE).returncode, 0)


if __name__ == "__main__":
    unittest.main()
