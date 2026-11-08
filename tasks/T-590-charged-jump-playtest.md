---
id: T-590
title: A charged jump, for a playtest
status: in-progress
from: project-lead
to: driving-drift
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/data/power_ups.json, game/data/rail_grind.json, game/scripts/driving/, tasks/T-578-rail-launch-keeps-speed.md]
files_expected_to_change: [game/data/, game/scripts/driving/, game/tests/, game/docs/driving/, docs/drifting.md]
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

Build Drifting, Decisions, "A charged jump, for a playtest": with the Jump power-up owned and the car on the ground, holding Space charges the jump, linearly up to +50% takeoff (the jump's speed/height, as the grind launch's boost is applied) over 3 seconds, and the car jumps on release with the charge it reached. Space in the air is unchanged (tilt and grind). A tap jumps as today (no charge). Without Jump, Space on the ground does what it does today. A small script-drawn cue near the car shows the charge filling (a proposal; no text). Numbers in data with reasons. This is its own playtest: it stays on its own branch and nothing else is merged into it.

The board's review: play it from C:\solid-carbide-worktrees\T-590\game\project.godot: god mode (N in a run) or the result notes' way to get Jump, then tap, half-charge and full-charge jumps, and a grind to compare with the launch.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] With Jump owned, holding Space on the ground for 0, 1.5 and 3+ s gives takeoff x1, x1.25 and x1.5, jumping on release (tests). (QA: pass / fail)
- [ ] Space in the air still tilts and grinds as before, and without Jump the ground Space is unchanged (the existing tests pass). (QA: pass / fail)
- [ ] The charge cue shows while charging and is gone after the jump (a test or screenshot). (QA: pass / fail)
- [ ] docs/drifting.md Content and game/docs/driving/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A GIF in art-archive/T-590/screenshots/ shows a tap and a full charge side by side or one after the other. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: the charged jump, its own playtest build.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built (Driving & Drift, 2026-11-08): with Jump owned, a press of Space on the ground starts a charge; while Space stays held there the takeoff (the hop's upward speed, as the rail launch's takeoff) grows linearly x1 -> x1.5 over 3 s, then holds at x1.5; the hop comes when Space is let go. A tap (pressed and let go at once) hops at x1, now on the release (a few hundredths of a second later than before, not felt). Space in the air (tilt, grind) and the rail launch unchanged; without Jump, ground Space does nothing. Numbers in game/data/power_ups.json jump.charge (charge_seconds 3, max_multiplier 1.5, the board's; with reason): tier 1 takeoff 5 -> 7.5 at full charge (0.83 s -> about 1.25 s in the air, peak 1.0 -> 2.27 units, measured in the GIF fixture), tier 2 8 -> 12.

Code: game/scripts/driving/jump_power_up.gd (charging, charge_time, multiplier_for(), charge_fraction(), reset(), step(..., held)), car.gd (passes held; the dead keys reset the charge), scripts/data/power_up_data.gd (jump_charge()), new game/scripts/driving/jump_charge_cue.gd, wired in run.gd and practice_session.gd.

The cue (proposal, no text): a 20 x 4 view-px bar 26 px above the car's drawn centre, off-white filling left to right over the jump arrow's dark outline, warm yellow (255,196,64) when full; gone on the jump or a dropped charge. Numbers in power_ups.json jump.charge cue_*.

Proposals (listed in docs/drifting.md, Content, 'The charged jump (task T-590)'): (1) only a press on the ground starts a charge: Space held through a landing starts none, and letting go then is no hop; (2) the car leaving the ground while charging (ramp, roof edge) drops the charge with no hop; (3) the dead keys (wreck, pause) drop the charge; (4) consequence for the board: catching a rail from a hop now takes a tap, then Space pressed again and held in the air (before, one held press did both). The tutorial text already reads 'jump, then hold Space over a rail', but the recorded tutorial clip art/tutorial/clips/rail_grind.json still shows the one-press version; left as is for the playtest (its fixture tutorial_clip_rail_grind.gd now taps then holds, so a re-recording would match).

How to get Jump: god mode (N in a run) or the playtest switch, as before. Tests changed: test_run_rails.gd (two hop-and-hold tests now tap, step, then hold). New tests: game/tests/unit/test_jump_charge.gd (12 tests, 1424 asserts: x1/x1.25/x1.5 at 0/1.5/3/4.5 s for both tiers, no hop while held, air Space unchanged, held landing, without Jump, dead keys, cue shows and goes, run binds the cue). Targeted sets pass: test_jump_power_up 12/12, test_run_rails 5/5, test_grind_overhaul 16/16, test_rail_grind 38/38, test_jump_clears_obstacles 8/8, test_jump_real_run, test_rail_joints_and_heights, test_practice_session 28/28, test_power_up_offers 16/16, test_tutorial_practice_real 6/6. Full run (bash game/tools/run_tests.sh, 272 s): 275 scripts, 3146 tests, 3145 passing, 0 failing, 1 risky/pending.

Docs: docs/drifting.md (Content: new 'The charged jump (task T-590)', a pointer in 'Jump (task T-461)'), game/docs/driving/tricks.md (Jump (T-461): the charge and the cue).

Screenshots/GIF: art-archive/T-590/screenshots/tap_then_full_charge.gif (the car standing still: a tap hop, then a 3 s charge with the cue filling and the x1.5 hop), charge_half.png, charge_full.png. Fixture: game/tests/fixtures/t590_charged_jump_gif.tscn.
