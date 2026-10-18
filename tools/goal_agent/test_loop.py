"""Tests for layer 4, the iteration loop (loop.py), with layer 3 under it: a whole fake goal, every pause rule,
the art cap, and resume. Each test runs in a temporary git repo with worktrees (temp_repo.py); the fake team
(fake_team.py) plays Claude, the agents and QA, so nothing calls Claude, PixelLab or the network."""

import contextlib
import io
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import taskboard_sync as tb  # noqa: E402
from goal_agent import build, goal_file, loop, run, temp_repo  # noqa: E402
from goal_agent.build import Places, Shell  # noqa: E402
from goal_agent.fake_team import FakeTeam  # noqa: E402
from goal_agent.test_tickets import VISUAL_READS, draft  # noqa: E402

FIXTURES = Path(__file__).resolve().parent / "fixtures"


# --- fixture builders: sample data for the runner, not game content ---

def sub(sid, needs=(), value=3):
    return {"id": sid, "title": f"Sub-goal {sid}", "why": "sample", "value": value,
            "criteria": [f"{sid} works"], "needs": list(needs)}


def plan(*subs, criteria=("The goal works",)):
    return {"goal_criteria": list(criteria), "open_questions": [], "sub_goals": list(subs)}


def missing(sid, *drafts):
    return {"sub_goal": sid, "verdict": "missing", "tickets": [], "code": [], "drafts": list(drafts)}


def named(sid, verdict, *titles):
    return {"sub_goal": sid, "verdict": verdict, "tickets": [f"title:{t}" for t in titles], "code": [], "drafts": []}


def gaps(*verdicts):
    return {"verdicts": list(verdicts)}


def art(key, title, deps):
    return draft(key, title=title, to="asset-generation", epic="art", changes_visuals="yes", review="look at the art",
                 files_to_read_first=VISUAL_READS, depends_on=list(deps))


def agent(summary="Did the work.", art=0, refusals=(), denials=None, files=None, blocked=False):
    a = {"summary": summary, "art_generations_used": art, "refusals": list(refusals), "blocked": blocked, "_art": art,
         "_files": files or {"game/data/work.txt": summary + "\n"}}
    if denials:
        a["_permission_denials"] = denials
    return a


def qa(mark="pass", refusals=(), blocked=False):
    return {"summary": f"QA says {mark}.", "refusals": list(refusals), "blocked": blocked, "_marks": mark}


def check(*results):
    return {"criteria": [{"criterion": f"criterion {i}", "result": r, "notes": "fake"} for i, r in enumerate(results, 1)],
            "refusals": []}


def quiet(fn, *args, **kw):
    with contextlib.redirect_stdout(io.StringIO()) as out:
        value = fn(*args, **kw)
    return value, out.getvalue()


class GoalRepo(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        base = Path(self.tmp.name)
        self.root = temp_repo.make(base / "repo")
        self.places = Places(self.root, base / "worktrees")

    def tearDown(self):
        self.tmp.cleanup()

    def planned(self, fixture, shell=None, **kw):
        """A goal planned by run.start (layers 1 and 2) on the fake team; returns its Build."""
        team = FakeTeam(fixture)
        goal, _ = quiet(run.start, "Sample goal", self.root, team, **kw)
        self.assertEqual(goal.get("status"), "planned", goal.section("Pauses"))
        return build.Build(self.places, team, goal, shell)

    def run_loop(self, b):
        goal, self.printed = quiet(loop.run, b)
        return goal

    def now(self):
        return build.tickets_now(self.root)

    def status(self, tid):
        return self.now()[tid]["status"]

    def steps(self, b):
        return [c[0] for c in b.claude.calls]

    def merged(self, b, tid):
        return build.merged(b, self.now()[tid])

    def assertPaused(self, goal, kind, *words):
        self.assertEqual(goal.get("status"), "paused")
        pauses = goal.section("Pauses")
        self.assertIn(f"[{kind}]", pauses)
        for w in words:
            self.assertIn(w, pauses)
        self.assertEqual(goal.last_pause_kind(), kind)
        on_disk = goal_file.find(self.root / "goals", goal.id)
        self.assertEqual(on_disk.get("status"), "paused", "saved")
        self.assertIn(f"paused, {kind}", temp_repo.git(self.root, "log", "-1", "--format=%s"), "committed on master")

    def entries(self, goal):
        """The iteration log's per-ticket entries."""
        return [l for l in goal.section("Iteration log").splitlines() if re.search(r"iteration \d+: T-\d+ ", l)]


class WholeGoal(GoalRepo):
    def test_a_whole_fake_goal(self):
        b = self.planned(FIXTURES / "whole-goal.json")
        goal = self.run_loop(b)
        # planning: two sub-goals ranked (S2 first: S1 needs it), two tickets written in that order
        self.assertEqual([s["id"] for s in goal_file.read_sub_goals(goal)], ["S2", "S1"])
        self.assertEqual(loop.goal_tickets(goal), [("T-001", "S2", "written"), ("T-002", "S1", "written")])
        # built in rank order; T-002 failed QA once and passed on its retry, on opus
        self.assertEqual(self.steps(b), ["plan", "gaps", "agent", "qa", "gaps", "agent", "qa", "agent", "qa",
                                         "gaps", "goal-check"])
        agents = [c for c in b.claude.calls if c[0] == "agent"]
        self.assertEqual([c[2]["acts"]["ticket"] for c in agents], ["T-001", "T-002", "T-002"])
        self.assertEqual([c[2]["model"] for c in agents], ["sonnet", "sonnet", "opus"])
        self.assertEqual([c[2]["agent"] for c in agents], ["game-data", "ui", "ui"])
        self.assertTrue(all(c[2]["model"] == "sonnet" and c[2]["agent"] == "qa-integration"
                            for c in b.claude.calls if c[0] in ("qa", "goal-check")))
        now = self.now()
        self.assertEqual((now["T-002"]["model"], now["T-002"]["qa_rounds"]), ("opus", 2))
        self.assertIn("QA failed", now["T-002"]["result_notes"])
        self.assertEqual((now["T-001"]["status"], now["T-002"]["status"]), ("needs-playtest", "needs-playtest"))
        # both merged into playtest/G-001, whose folder has their work; master has only the goal's files
        self.assertTrue(self.merged(b, "T-001") and self.merged(b, "T-002"))
        folder = self.places.goal_folder("G-001")
        self.assertIn("Control", (folder / "game" / "scenes" / "sample_screen.tscn").read_text(encoding="utf-8"))
        self.assertTrue((folder / "game" / "data" / "sample.json").exists())
        self.assertFalse((self.root / "game" / "data" / "sample.json").exists(), "nothing on master")
        first = temp_repo.git(self.root, "rev-list", "--max-parents=0", "master").strip()
        names = temp_repo.git(self.root, "diff", "--name-only", first, "master").split()
        self.assertEqual(sorted(names), ["goals/G-001-sample-goal.md", "tasks/T-001-sample-data-file.md",
                                         "tasks/T-002-sample-screen.md"])
        self.assertEqual(temp_repo.git(self.root, "status", "--porcelain"), "")
        # the goal check passed: ready-to-play, criteria marked, how to play printed
        self.assertEqual(goal.get("status"), "ready-to-play")
        self.assertEqual(goal_file.find(self.root / "goals", "G-001").get("status"), "ready-to-play")
        self.assertIn("- [x] The sample screen's scene runs (QA: pass)", goal.section("Goal acceptance criteria"))
        self.assertIn(str(folder / "game" / "project.godot"), self.printed)
        self.assertIn("Builds tab", self.printed)
        # one iteration log entry per step, and the iteration count
        entries = self.entries(goal)
        self.assertEqual(len(entries), 2, entries)
        self.assertIn("iteration 1: T-001", entries[0])
        self.assertIn("iteration 2: T-002", entries[1])
        self.assertIn("QA rounds 2", entries[1])
        self.assertEqual(goal.get("iteration"), "2")
        self.assertEqual(goal.section("Pauses"), goal_file.EMPTY)

    def test_each_headless_session_takes_the_goals_name(self):
        b = self.planned(FIXTURES / "whole-goal.json")
        self.run_loop(b)
        sids = [c[2]["session_id"] for c in b.claude.calls if c[0] in ("agent", "qa", "goal-check")]
        self.assertEqual(len(set(sids)), len(sids), "a new session id for every headless session")
        last = json.loads((self.root / ".board" / "sessions" / f"{sids[-1]}.json").read_text(encoding="utf-8"))
        self.assertEqual(last["name"], "Goal-G-001")


class Pauses(GoalRepo):
    """One test per stop rule (layer 4). Each leaves the goal paused with its reason, and starts nothing more."""

    def two_tickets(self, **extra):
        f = {"plan": [plan(sub("S1", value=5), sub("S2"))],
             "gaps": [gaps(missing("S1", draft("D1", title="Ticket one")), missing("S2", draft("D2", title="Ticket two"))),
                      gaps(named("S1", "covered", "Ticket one"), named("S2", "in-flight", "Ticket two"))],
             "agent": [agent()], "qa": [qa()]}
        f.update(extra)
        return f

    def test_the_iteration_cap(self):
        b = self.planned(self.two_tickets(), max_iterations=1)
        goal = self.run_loop(b)
        self.assertPaused(goal, "max-iterations", "iteration cap (1)", "T-002 is next")
        self.assertEqual(self.steps(b), ["plan", "gaps", "agent", "qa", "gaps"])
        self.assertEqual(self.status("T-002"), "open")
        self.assertFalse(self.places.ticket_folder("T-002").exists(), "not started")

    def test_a_refusal_in_a_headless_session(self):
        b = self.planned(self.two_tickets(agent=[agent(denials=[{"tool_name": "Bash", "tool_input": {"command": "x"}}],
                                                       blocked=True)]))
        goal = self.run_loop(b)
        self.assertPaused(goal, "refusal", "never works around", "Bash")
        self.assertEqual(self.steps(b), ["plan", "gaps", "agent"])
        self.assertEqual((self.status("T-001"), self.status("T-002")), ("in-progress", "open"))

    def test_a_refusal_the_agent_reports(self):
        b = self.planned(self.two_tickets(agent=[agent(refusals=["the hook refused git push"], blocked=True)]))
        goal = self.run_loop(b)
        self.assertPaused(goal, "refusal", "the hook refused git push")
        self.assertEqual(self.steps(b), ["plan", "gaps", "agent"])

    def test_a_refusal_the_agent_got_past_is_logged_and_the_ticket_goes_on(self):
        denial = {"tool_name": "Bash", "tool_input": {"command": "python -c x"}}
        b = self.planned(self.two_tickets(agent=[agent(refusals=["the hook refused git push"], denials=[denial])]),
                         max_iterations=1)
        goal = self.run_loop(b)
        self.assertEqual(goal.last_pause_kind(), "max-iterations", goal.section("Pauses"))
        self.assertEqual(self.steps(b)[:5], ["plan", "gaps", "agent", "qa", "gaps"], "on to QA, then the rescan")
        self.assertEqual(self.status("T-001"), "done")
        first = self.entries(goal)[0]
        self.assertIn("T-001", first)
        self.assertIn("passed", first)
        self.assertIn("not blocking", first)
        self.assertIn("the hook refused git push", first)
        self.assertIn("python -c x", first, "a permission denial is written too")

    def test_a_blocked_agent_pauses_with_the_refusal_in_the_pauses(self):
        b = self.planned(self.two_tickets(agent=[agent(refusals=["no write to the main checkout"], blocked=True)]))
        goal = self.run_loop(b)
        self.assertPaused(goal, "refusal", "no write to the main checkout")
        self.assertEqual(self.steps(b), ["plan", "gaps", "agent"])

    def test_a_refusal_qa_got_past_is_logged(self):
        b = self.planned(self.two_tickets(qa=[qa(refusals=["python -c refused"])]), max_iterations=1)
        goal = self.run_loop(b)
        self.assertEqual(goal.last_pause_kind(), "max-iterations", goal.section("Pauses"))
        self.assertEqual(self.status("T-001"), "done")
        self.assertIn("QA: python -c refused", self.entries(goal)[0])

    def test_a_blocked_qa_pauses(self):
        b = self.planned(self.two_tickets(qa=[qa(refusals=["python -c refused"], blocked=True)]))
        goal = self.run_loop(b)
        self.assertPaused(goal, "refusal", "QA on T-001", "python -c refused")
        self.assertEqual(self.steps(b), ["plan", "gaps", "agent", "qa"])
        self.assertEqual(self.status("T-001"), "in-qa")

    def test_a_refusal_without_a_blocked_answer_counts_as_blocked(self):
        a = agent(refusals=["refused"])
        del a["blocked"]
        goal = self.run_loop(self.planned(self.two_tickets(agent=[a])))
        self.assertPaused(goal, "refusal", "refused")

    def test_both_schemas_require_blocked_and_the_prompts_explain_it(self):
        self.assertEqual(build.AGENT_SCHEMA["properties"]["blocked"]["type"], "boolean")
        self.assertEqual(build.QA_SCHEMA["properties"]["blocked"]["type"], "boolean")
        self.assertIn("blocked", build.AGENT_SCHEMA["required"])
        self.assertIn("blocked", build.QA_SCHEMA["required"])
        b = self.planned(self.two_tickets())
        t = self.now()["T-001"]
        folder = self.places.ticket_folder("T-001")
        for prompt in (build.agent_prompt(b, t, folder), build.qa_prompt(b, t, folder, "## Acceptance criteria\n")):
            self.assertIn("never work around it", prompt)
            self.assertIn("Set blocked to true only when", prompt)
            self.assertIn("list it in refusals", prompt)

    def test_a_refused_command(self):
        class Refusing(Shell):
            def run(self, cmd, cwd, check=True):
                if any("board_inbox.py" in str(c) for c in cmd):    # a real failing command, through the real check
                    cmd = [sys.executable, "-c", "import sys; print('Refused. Not today.'); sys.exit(1)"]
                return super().run(cmd, cwd, check)
        b = self.planned(self.two_tickets(), shell=Refusing())
        goal = self.run_loop(b)
        self.assertPaused(goal, "command", "Refused. Not today.")
        self.assertEqual(self.steps(b), ["plan", "gaps"], "no headless session started")
        self.assertEqual((self.status("T-001"), self.status("T-002")), ("in-progress", "open"))

    def test_two_refused_sets_of_drafts_in_a_rescan(self):
        bad = gaps(named("S1", "covered", "Ticket one"), missing("S2", draft("D9", to="nobody")))
        f = self.two_tickets()
        f["gaps"][1:] = [bad, bad]
        b = self.planned(f)
        goal = self.run_loop(b)
        self.assertPaused(goal, "drafts-refused", "refused twice", "not an agent")
        self.assertEqual(self.steps(b), ["plan", "gaps", "agent", "qa", "gaps", "gaps"])
        self.assertEqual(len(self.entries(goal)), 1, "the ticket's step is still logged")
        self.assertEqual(self.status("T-002"), "open")
        self.assertEqual(sorted(p.name[:5] for p in (self.root / "tasks").glob("T-*.md")), ["T-001", "T-002"])

    def test_a_flagged_ticket_others_depend_on(self):
        f = {"plan": [plan(sub("S1"), sub("S2", needs=["S1"], value=5), sub("S3"))],
             "gaps": [gaps(missing("S1", draft("D1", title="Ticket one")),
                           missing("S2", draft("D2", title="Ticket two", depends_on=["D1"])),
                           missing("S3", draft("D3", title="Ticket three"))),
                      gaps(named("S1", "in-flight", "Ticket one"), named("S2", "in-flight", "Ticket two"),
                           named("S3", "in-flight", "Ticket three")),
                      gaps(named("S1", "in-flight", "Ticket one"), named("S2", "in-flight", "Ticket two"),
                           named("S3", "covered", "Ticket three"))],
             "agent": [agent(), agent(), agent()], "qa": [qa("fail"), qa("fail"), qa()]}
        b = self.planned(f)
        goal = self.run_loop(b)
        self.assertPaused(goal, "flagged", "T-001 failed QA twice", "T-002 wait on it")
        self.assertEqual(self.steps(b), ["plan", "gaps", "agent", "qa", "agent", "qa", "gaps", "agent", "qa", "gaps"])
        self.assertEqual([self.status(t) for t in ("T-001", "T-002", "T-003")], ["flagged-for-review", "blocked", "done"])
        self.assertTrue(self.merged(b, "T-003"), "independent work carried on first")
        self.assertFalse(self.merged(b, "T-001"), "a flagged ticket is not merged")
        self.assertFalse(self.places.ticket_folder("T-002").exists())

    def test_the_same_failing_goal_criterion_twice(self):
        f = {"plan": [plan(sub("S1"), criteria=["criterion 1"])],
             "gaps": [gaps(missing("S1", draft("D1", title="Ticket one"))),
                      gaps(named("S1", "covered", "Ticket one")),
                      gaps(named("C1", "in-flight", "Ticket one"))],
             "agent": [agent()], "qa": [qa()], "goal-check": [check("fail"), check("fail")]}
        b = self.planned(f)
        goal = self.run_loop(b)
        self.assertPaused(goal, "repeat", "criterion 1")
        self.assertEqual(self.steps(b), ["plan", "gaps", "agent", "qa", "gaps", "goal-check", "gaps", "goal-check"])
        subs = goal_file.read_sub_goals(goal)
        self.assertEqual([s["id"] for s in subs], ["S1", "C1"], "the failing criterion went back as a gap")
        self.assertEqual(subs[1]["criteria"], ["criterion 1"])
        self.assertIn("(QA: fail, fake)", goal.section("Goal acceptance criteria"))

    def test_the_same_gap_twice(self):
        f = {"plan": [plan(sub("S1"))],
             "gaps": [gaps(missing("S1", draft("D1", title="Ticket one"))),
                      gaps(missing("S1", draft("D2", title="Ticket two"))),
                      gaps(missing("S1", draft("D3", title="Ticket three")))],
             "agent": [agent()] * 4, "qa": [qa("fail")] * 4}
        b = self.planned(f)
        goal = self.run_loop(b)
        self.assertPaused(goal, "repeat", "sub-goal S1", "missing again")
        self.assertEqual(self.steps(b).count("agent"), 4)
        self.assertEqual([self.status(t) for t in ("T-001", "T-002", "T-003")],
                         ["flagged-for-review", "flagged-for-review", "open"])
        self.assertFalse(self.places.ticket_folder("T-003").exists(), "nothing more started")


class ReusedTickets(GoalRepo):
    def test_a_reused_ticket_is_waited_on_not_built(self):
        temp_repo.add_ticket(self.root, "T-001", status="open", title="Someone else's ticket")
        temp_repo.git(self.root, "add", "-A")
        temp_repo.git(self.root, "commit", "-q", "-m", "T-001")
        f = {"plan": [plan(sub("S1"), sub("S2"))],
             "gaps": [gaps(missing("S1", draft("D1", title="Ticket one")), named("S2", "in-flight", "Someone else's ticket")),
                      gaps(named("S1", "covered", "Ticket one"), named("S2", "in-flight", "Someone else's ticket"))],
             "agent": [agent()], "qa": [qa()]}
        b = self.planned(f)
        goal = self.run_loop(b)
        self.assertPaused(goal, "waiting", "T-001 (open, lead none, reused: this goal doesn't build it)")
        self.assertEqual(self.steps(b), ["plan", "gaps", "agent", "qa", "gaps"], "only the goal's own ticket was built")
        self.assertEqual(self.now()["T-001"]["lead"], "", "a reused ticket is not claimed")
        self.assertFalse(self.places.ticket_folder("T-001").exists())


class ArtCap(GoalRepo):
    def fixture(self):
        return {"plan": [plan(sub("S1"), sub("S2", needs=["S1"]))],
                "gaps": [gaps(missing("S1", draft("D1", title="Functional")),
                              missing("S2", art("D2", "Art one", ["D1"]), art("D3", "Art two", ["D1"]))),
                         gaps(named("S1", "covered", "Functional"), named("S2", "in-flight", "Art one", "Art two")),
                         gaps(named("S2", "in-flight", "Art one", "Art two"))],
                "agent": [agent(), agent("Generated the art.", art=2)], "qa": [qa(), qa()]}

    def test_art_used_counts_the_new_log_lines_and_the_cap_blocks_the_next_art_ticket(self):
        log = self.root / build.ART_LOG
        log.parent.mkdir(parents=True, exist_ok=True)
        log.write_text('{"old": 1}\n{"old": 2}\n{"old": 3}\n', encoding="utf-8")   # earlier generations
        temp_repo.git(self.root, "add", "-A")
        temp_repo.git(self.root, "commit", "-q", "-m", "earlier art")
        b = self.planned(self.fixture(), art_cap=2)
        goal = self.run_loop(b)
        self.assertEqual(goal.get("art_used"), "2", "only the two lines T-002's branch added")
        self.assertIn("art 2", self.entries(goal)[1])
        self.assertPaused(goal, "art-cap", "2 of 2", "T-003, an asset-generation ticket, is next")
        self.assertEqual(self.steps(b), ["plan", "gaps", "agent", "qa", "gaps", "agent", "qa", "gaps"])
        self.assertEqual(self.status("T-003"), "open")
        self.assertFalse(self.places.ticket_folder("T-003").exists(), "never started")
        self.assertIn("2 generations left", [c for c in b.claude.calls if c[0] == "agent"][1][1])

    def test_an_art_cap_of_zero_blocks_the_first_art_ticket(self):
        f = self.fixture()
        f["agent"], f["qa"] = [agent()], [qa()]
        b = self.planned(f)
        goal = self.run_loop(b)
        self.assertPaused(goal, "art-cap", "0 of 0", "T-002")
        self.assertEqual(self.status("T-002"), "open")


class Resume(GoalRepo):
    def three_tickets(self):
        return {"plan": [plan(sub("S1", value=5), sub("S2", value=4), sub("S3"))],
                "gaps": [gaps(missing("S1", draft("D1", title="Ticket one")), missing("S2", draft("D2", title="Ticket two")),
                              missing("S3", draft("D3", title="Ticket three"))),
                         gaps(named("S1", "covered", "Ticket one"), named("S2", "in-flight", "Ticket two"),
                              named("S3", "in-flight", "Ticket three")),
                         gaps(named("S2", "covered", "Ticket two"), named("S3", "in-flight", "Ticket three")),
                         gaps(named("S3", "covered", "Ticket three"))],
                "agent": [agent(), agent(), agent()], "qa": [qa(), qa(), qa()], "goal-check": [check("pass")]}

    def test_resume_picks_up_a_ticket_in_progress_and_one_in_qa_without_repeating_finished_ones(self):
        b = self.planned(self.three_tickets(), max_iterations=1)
        goal = self.run_loop(b)
        self.assertPaused(goal, "max-iterations")
        t1_head = temp_repo.git(self.root, "rev-parse", "task/T-001-ticket-one").strip()
        # a run stopped half-way: T-002 built by its agent and in QA, T-003 just started
        now = self.now()
        build.ensure_ticket_folder(b, now["T-002"])
        build.move(b, "T-002", "in-progress")
        build.run_agent(b, self.now()["T-002"], self.places.ticket_folder("T-002"))
        build.move(b, "T-002", "in-qa")
        build.ensure_ticket_folder(b, now["T-003"])
        build.move(b, "T-003", "in-progress")
        self.assertEqual([self.status(t) for t in ("T-001", "T-002", "T-003")], ["done", "in-qa", "in-progress"])
        # the board raises the cap in the goal file; a new runner rebuilds everything from the files
        goal.set("max_iterations", 20)
        goal.save()
        before = len(b.claude.calls)
        b2 = loop.load(self.places, b.claude, "G-001")
        (goal2, message), _ = quiet(loop.resume, b2)
        self.assertEqual(goal2.get("status"), "ready-to-play", goal2.section("Pauses"))
        calls = b.claude.calls[before:]
        self.assertEqual([c[0] for c in calls], ["qa", "gaps", "agent", "qa", "gaps", "goal-check"])
        self.assertEqual([c[2]["acts"]["ticket"] for c in calls if c[0] in ("agent", "qa")], ["T-002", "T-003", "T-003"])
        self.assertEqual(temp_repo.git(self.root, "rev-parse", "task/T-001-ticket-one").strip(), t1_head,
                         "T-001 is not built again")
        self.assertTrue(all(self.merged(b2, t) for t in ("T-001", "T-002", "T-003")))
        self.assertIn("resumed", goal2.section("Iteration log"))
        self.assertEqual([e.split(": T-")[1][:3] for e in self.entries(goal2)], ["001", "002", "003"])

    def test_a_paused_goal_stays_paused_until_its_reason_is_cleared_or_forced(self):
        f = self.three_tickets()
        f["agent"][0] = agent(denials=[{"tool_name": "Write"}], blocked=True)
        b = self.planned(f)
        self.assertPaused(self.run_loop(b), "refusal")
        calls = len(b.claude.calls)
        (goal, message), _ = quiet(loop.resume, loop.load(self.places, b.claude, "G-001"))
        self.assertEqual(goal.get("status"), "paused")
        self.assertIn("--force", message)
        self.assertEqual(len(b.claude.calls), calls, "nothing started")
        (goal, message), _ = quiet(loop.resume, loop.load(self.places, b.claude, "G-001"), force=True)
        self.assertIn("--force", goal.section("Iteration log"))
        self.assertEqual(b.claude.calls[calls][0], "agent", "T-001's agent runs again")

    def test_a_cleared_reason_is_checked_by_the_loops_own_rules(self):
        b = self.planned(self.three_tickets(), max_iterations=1)
        self.assertPaused(self.run_loop(b), "max-iterations")
        (goal, message), _ = quiet(loop.resume, loop.load(self.places, b.claude, "G-001"))
        self.assertEqual(goal.get("status"), "paused")
        self.assertIn("would pause again", message)


if __name__ == "__main__":
    unittest.main()
