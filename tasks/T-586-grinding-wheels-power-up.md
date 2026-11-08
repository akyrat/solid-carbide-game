---
id: T-586
title: Grinding Wheels: a power-up that heats the grind sparks and boosts the launch
status: in-qa
from: project-lead
to: driving-drift
lead: Rails
epic: power-ups
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-585]
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/game-loop-architecture.md, game/data/power_ups.json, game/data/rail_grind.json, game/scripts/driving/rail_grind.gd, game/scripts/driving/rail_sparks.gd, tasks/T-578-rail-launch-keeps-speed.md]
files_expected_to_change: [game/data/power_ups.json, game/data/, game/scripts/driving/, game/scripts/run/, game/art/power_ups/, game/tests/, game/docs/driving/, docs/drifting.md]
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

Build Drifting, Decisions, "Grinding Wheels, a driving power-up", on top of T-578 (the launch keeps the grind's speed, floor 6; on master). Add `grinding_wheels` to game/data/power_ups.json like the others (one tier; texts from T-585; icon path game/art/power_ups/grinding_wheels.png with a script-drawn placeholder until T-587's art), so it is offered in mission gifts and counts against the driving power-up cap like the others. While grinding with it owned: a stack builds each full second of the grind, up to 3; the grind sparks (rail_sparks.gd) are yellow, then orange after 1 s, then red after 2 s, fading between; letting go of Space launches at the grind speed times (1 + 0.33 per stack), so 2x at 3 stacks (numbers in data with reasons; proposals). Stacks reset at each new grind; without the power-up the sparks and the launch are as today. Check the launch floor (6) applies before the boost, and say how the boost and the floor combine.

The board's review: play it from C:\solid-carbide-worktrees\T-586\game\project.godot: god mode (N in a run) or the result notes' way to get the power-up, then grind 1, 2 and 3+ seconds and launch.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Grinding Wheels is in power_ups.json and can be offered and taken like the other driving power-ups (tests). (QA: pass / fail)
- [ ] With it, stacks build one per second up to 3, the sparks go yellow, orange, red, and the launch speed is the grind speed times 1, 1.33, 1.67, 2 by stacks (tests); stacks reset on a new grind. (QA: pass / fail)
- [ ] Without it, sparks and launch are unchanged (the existing tests pass). (QA: pass / fail)
- [ ] docs/drifting.md Content and game/docs/driving/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A GIF in art-archive/T-586/screenshots/ shows the sparks changing colour over a 3-second grind and the launch. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: Grinding Wheels behaviour (sparks heat over 3 s, launch up to 2x).

### 2026-11-08, In progress → In QA

Grinding Wheels built: sparks yellow, orange, red over 3 s; launch up to 2x. QA now.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built Grinding Wheels (Drifting, Decisions, "Grinding Wheels, a driving power-up"), on T-578's launch.

What: game/data/power_ups.json has grinding_wheels (one tier; icon res://art/power_ups/grinding_wheels.png, a script-drawn placeholder until T-587, drawn by game/tools/draw_power_up_icon_grinding_wheels_placeholder.py). PowerUpData.IDS lists it, so the mission gifts offer it, the god-mode page lists it (N in a run, Power-ups, Grinding Wheels +), and it fills one of the 3 driving power-up slots. Its card shows T-585's name and text. New game/scripts/driving/grinding_wheels.gd (car.grinding_wheels, bound to car.grind.wheels; run.gd gives it the owned tier). rail_grind.gd launch_speed() multiplies by it; rail_sparks.gd colours_for(car) takes its heat shades.

Numbers (power_ups.json, reasons there; all proposals): stack_seconds 1.0, max_stacks 3, max_launch_boost 1.0 (launch x 1, 1.333, 1.667, 2 for 0..3 stacks), colour_fade_seconds 0.25. Stacks count the grind's own seconds (rail_grind.gd seconds, 0 at every start(), joints included), so they reset on every new grind.

Floor and boost: the floor first, then the boost: launch = max(grind speed, 6) x (1 + stacks/3). A 3 units/s grind held 3 s launches at 12; 0 stacks is exactly the plain T-578 launch. Off a rail's end or a slow drop: no boost.

Proposals (the ticket left these open):
1. The colour fade: each colour holds while its stack holds and fades to the next over the first 0.25 s of the new stack (yellow until 1.0 s, to orange by 1.25 s, to red by 2.25 s), so the colour change lands with the stack. A fade over the whole second would read as orange-ish before the stack is earned.
2. Spark shades: four per colour (pale hot core to deep shade), like the plain sparks' four; none is Greenbull's yellow. They live in the power-up's own spark_colours, outside the tiers: inside a tier they broke the power-up card's number formatting (power_up_screen.gd format_number on an array), found by the test.
3. No cap on the boosted launch: a fast grind (say 15 for 3 s) can launch at 2x, past top speed 33 at the extreme, and slows back on the ground like any boost.
4. No HUD readout of the stacks: the spark colour is the cue. A stack counter would be a UI ticket if the board wants one.
5. A spark already in the air keeps the colour it was made with.

How the board gets it: god mode (N in a run), Power-ups, Grinding Wheels +; or take it from a mission gift. Then grind 1, 2 and 3+ seconds (Space held) and let go.

Tests: new game/tests/unit/test_grinding_wheels.gd 12/12 (213 asserts): data and icon, card text, offered/taken/cap, run gives the tier, stacks per second, launch x1/1.33/1.67/2 through the car, 4.5 s stays 2x, floor before boost, stacks reset on the next rail, yellow/orange/red with the fade, sparks made in each second take that heat, without it sparks and launch unchanged. Updated test_four_minute_run_data.gd (six power-ups, Grinding Wheels one tier) and test_power_up_offers.gd (the pool lists it). Targeted runs: test_rail_grind 38/38, test_grind_overhaul 16/16, test_rail_joints_and_heights 14/14, test_rail_snap_drawing 14/14, test_four_minute_run* 24/24, test_power_up_offers 16/16, test_power_up_screen 22/22, test_mission_data 5/5, test_missions 20/20, test_god_mode* 17/17, test_hud_slot_grids 6/6, test_polarized_steering_wheel 16/16, test_jump_power_up 12/12. Python: test_draw_power_up_icon_grinding_wheels_placeholder 2/2.
Full Godot set (bash game/tools/run_tests.sh, 12 processes): 276 scripts, 3149 tests, 3148 passing, 0 failing, 1 risky/pending, TESTS PASSED (239 s). No background job left running.

GIF: art-archive/T-586/screenshots/grinding_wheels_3s_grind_and_launch.gif (3.4 s grind: yellow, orange after 1 s, red after 2 s; launched after 3.40 s with 3 stacks, grind 13.1 -> 26.2, x2.00, landed 26.2 units away), still sheet sparks_yellow_orange_red_and_launch.png. Fixture: game/tests/fixtures/t586_grinding_wheels_gif.tscn (T586_SCENE=plain for no power-up).

Docs: docs/drifting.md, Content, new "Grinding Wheels (task T-586)"; game/docs/driving/rail-grind.md, new "Grinding Wheels (T-586)".

Documents affected: docs/drifting.md (updated).
