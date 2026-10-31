---
id: T-457
title: Missions in the run: 30 per run (5 fixed, 25 generated), progress from trick events, signals, and the car's owned power-ups
status: in-qa
from: project-lead
to: game-loop
lead: Goal-G-009
epic: game-loop
milestone: mvp
goal: G-009
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: [T-455]
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/drifting.md, game/docs/game-loop/the-run.md, game/docs/driving/tricks.md, game/data/missions.json, game/data/power_ups.json, game/scripts/data/mission_data.gd, game/scripts/data/power_up_data.gd, game/scripts/run/run_state.gd, game/scripts/run/run.gd, game/scripts/driving/trick_detector.gd, game/scripts/level/thread_the_needle.gd]
files_expected_to_change: [game/scripts/run/missions.gd, game/scripts/run/run_state.gd, game/scripts/run/run.gd, game/tests/unit/run/test_missions.gd, game/docs/game-loop/the-run.md, docs/game-loop-architecture.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Game loop architecture, Decisions, 'Mission packs' (board, 2026-10-31). Build the run's mission tracker, invisible to the player (the HUD page and the overlay are separate tickets).

- A mission node (or part of RunState) holds the run's 30 missions: the 5 fixed ones from `missions.json`, then 25 generated from its rules with an RNG seeded per run (a new seed each run; a test can pass a seed). A new run (Start, or Restart from the pause screen) resets to mission 1 and a fresh set.
- Trick events advance the current mission's goals: drift duration, alt drift, airtime seconds, air 180, air 360, thread the needle, and the other types the data allows. Hook into the signals the trick detector and thread the needle already emit; don't change how tricks pay. A continuous-drift goal counts only one unbroken drift (a drift that ends, by release or a wall hit, starts over).
- Signals: `goal_progress(mission_index, goal_index, done, total)`, `goal_completed(mission_index, goal_index)`, `mission_completed(mission_index)`. After mission 30 nothing more is offered (proposal; note it).
- The car's owned driving power-ups live in RunState too, so the power-up tickets can read them: `power_up_tier(id)` (0 = not owned), `grant_power_up(id)` (new at tier 1, or the next tier), cleared on a new run. A signal `power_ups_changed`.

Document it in game/docs/game-loop/the-run.md and Game loop architecture, Content.

## Acceptance criteria

- [ ] A new run has 30 missions; its first 5 match missions.json's fixed list and are identical across at least 3 different seeds, and missions 6 to 30 differ between at least two seeds (GUT test). (QA: pass)
- [ ] GUT tests complete missions 1 to 5 in order from simulated trick events, each sending goal_progress, goal_completed and mission_completed, and the current mission advances after each. (QA: pass)
- [ ] A GUT test shows the continuous-drift goal counts only one unbroken drift: two 2 s drifts don't complete mission 1, one 4 s drift does. (QA: pass)
- [ ] Starting a new run (and Restart) resets the tracker to mission 1 and clears owned power-ups; grant_power_up gives tier 1 then tier 2 and power_up_tier reads them (GUT tests). (QA: pass)
- [ ] game/docs/game-loop/the-run.md and Game loop architecture, Content, describe the tracker, its signals and the power-up state; the result notes say there is nothing to picture. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Blocked → In progress

Goal runner (G-009): started, in C:\solid-carbide-worktrees\T-457.

### 2026-10-31, In progress → In QA

Goal runner (G-009): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Game Loop Agent, 2026-10-31: done.**

What was built:
- `game/scripts/run/missions.gd` (new, `RunMissions`, a RefCounted): the run's 30 missions. `start(seed)` builds the 5 fixed missions from `missions.json`, then missions 6 to 30 through `MissionData.mission(n, rng)` with one RNG seeded per run (a negative seed picks a new random one; the seed used is kept in `mission_seed`). It holds the current mission (0-based), each goal's progress and completed flag. Signals: `goal_progress(mission_index, goal_index, done, total)`, `goal_completed(mission_index, goal_index)`, `mission_completed(mission_index)`, plus `mission_started(mission_index)` for the HUD page. It also has these reads: `count()`, `current_index()`, `current_number()`, `current_goals()`, `mission(i)`, `is_all_done()`.
- `game/scripts/run/run_state.gd`:
  - `state.missions` is created once in `_init()`, so the signals are connected once.
  - `mission_seed` defaults to -1, a new seed each run; tests set it.
  - `start_run()` resets the tracker to mission 1 with a fresh set and clears the power-ups.
  - Feeds, only while the run is going, with no change to how tricks pay: `add_trick` → `on_trick`, `add_airtime_trick` → `on_airtime` (every landing counts, including a hop too short to raise the combo), `add_needle_trick` → `on_trick("thread_the_needle")`, `drift_step` → `on_drift_step`, and `collision()` and the wreck → `on_crash`.
  - Power-ups: `power_up_tier(id)` (0 = not owned), `grant_power_up(id)` (tier 1 when new, otherwise the next tier, held at the last tier in `power_ups.json`, 0 for an unknown id), `owned_power_ups()`, and the signal `power_ups_changed` (sent on a grant and on every new run).
- `run.gd` did not need a change: the car's `trick`, `airtime_trick` and the needle's `threaded` already reach RunState's `add_*` functions, and a GUT test checks that this path works in a real run. The pause screen's Restart builds a new run and RunState, which gives it a fresh tracker; a GUT test covers that too.

The continuous drift goal: its progress is the unbroken drift in progress, fed each step by `drift_step`, so the goal is ticked the moment the drift reaches 4 s. A step without drifting, a collision or the wreck sets it back to 0. A crash pays its drift (T-315) to `on_trick` first, so a 4.2 s drift ended by a crash still counts.

Proposals for the playtest (not the board's yet):
- After mission 30 nothing more is offered: `is_all_done()`, `current_index()` returns -1, and no more signals are sent.
- A trick that completes a mission does not also count for the next one.
- A new mission's drift goal counts only drifting done after the mission appeared.
- Indices in the signals are 0-based.

Tests: `game/tests/unit/run/test_missions.gd`, 16 tests, 242 asserts:
- AC1: 30 missions; the first 5 match the fixed list and are identical for seeds 1, 2 and 3; missions 6 to 30 differ between seeds 1 and 2; the same seed gives the same set; the generated missions follow the rules.
- AC2: missions 1 to 5 complete in order from simulated trick events, with goal_progress, goal_completed and mission_completed each time, sent in that order, and the current mission advances after each.
- AC3: two 2 s drifts don't complete mission 1, one 4 s drift does; also, 2.5 s + 2.5 s across a wall hit is not 4 s.
- AC4: `start_run()` and the pause screen's Restart reset to mission 1 and clear power-ups; tier 1 then tier 2; held at the last tier; an unknown id gives 0.

All three test sets pass, on this branch after the last code commit:
- GUT, the full suite: 192 scripts, **2335/2335 passed** (1070 s). The run and game folders on their own: 470/470; hud, enemies, weapons and level creator: 929/929.
- `python -m unittest discover -s game/tools -p "test_*.py"`: **767 tests OK** (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: **614 tests OK**.

Documents affected: `game/docs/game-loop/the-run.md` (new section "Missions and the car's power-ups (T-457)") and `docs/game-loop-architecture.md` (Content, new section "Missions in the run (task T-457)").

Screenshots: there is nothing to picture. The tracker is invisible state with no screen, layout or motion; the HUD page and the overlay are separate tickets.

PixelLab generations: 0. Refusals: none.

**QA round 1 (QA/Integration, 2026-10-31): all 6 criteria pass.** Reran here: test_missions.gd 16/16 (242 asserts); GUT run folder 393 passed; game/tools Python 767 OK (1 skipped); tools Python 614 OK. The full GUT suite (about 1070 s, past the foreground limit) was not rerun; its count 2335/2335 is the agent's. `python tools/qa_check.py` is not on the pre-approved list and was not run. Docs sections for T-457 found in both documents; no-screenshot note present.

Notes on how it ran:
- The full GUT suite goes past the 10-minute foreground limit, so the tool moved it to the background, where it finished (exit 0). The studio-tools Python set did the same. Both had finished before this hand-back, and no jobs are left running.
- The Godot import left line-ending `.import` noise and untracked `.uid` files in the working tree. I did not commit them, because reverting them needs a git command that is not on the pre-approved list.
