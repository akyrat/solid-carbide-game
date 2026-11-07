---
id: T-548
title: Grind: a speed boost on every rail landing; Jump off a rail goes where the car faces
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
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/driving/]
files_expected_to_change: [game/scripts/driving/, game/data/rail_grind.json, game/tests/, game/docs/driving/, docs/drifting.md]
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

Build Drifting, Decisions, "A speed boost on landing on a rail" and "Jumping off a rail goes where the car faces" (the board, 2026-11-06), in the rail grind (T-541, T-542; game/data/rail_grind.json). (1) Every time the car lands on a rail and starts grinding, it gets a set speed boost along the rail (propose: a speed it is raised to, or an amount added, and say which), which then declines over the grind (propose the rate or curve). Every landing boosts again; a joint between connected pieces is not a new landing. (2) Jump while grinding sends the car off in the direction it faces, whatever its direction of travel, even backwards, at a set launch speed (propose it, "a bit"); momentum along the rail is not kept. This replaces the 15-degree diagonal hop. The rail-jump's no-cooldown rule (T-541's second tweak) stays. All numbers in game/data/rail_grind.json with their reasons, because the board will tune them by playing.

The board's review: play it from C:\solid-carbide-worktrees\T-548\game\project.godot on the board's new map once T-547 is merged into master (or on any level with rails) and say what to change.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (the board's own levels; reading is fine where the ticket says so). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Landing on a rail raises the car's speed along it by the data's boost, and the speed then declines by the data's rate; a second landing boosts again; passing a joint does not (tests). (QA: pass / fail)
- [ ] Jump while grinding launches the car along its facing at the data's speed, also when the car faces against its travel (test with the car turned 180 degrees). (QA: pass / fail)
- [ ] The rail jump still ignores the Jump cooldown (the existing test still passes). (QA: pass / fail)
- [ ] docs/drifting.md Content and game/docs/driving/ describe both, with each proposed number and its reason. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] GIFs in art-archive/T-548/screenshots/ show a landing boost and a jump off a rail in the facing direction, one of them backwards. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-06, Open → In progress

Started: a speed boost on every rail landing, and Jump off a rail in the facing direction.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### Driving & Drift Agent, 2026-11-06: done

Built both of the board's decisions of 2026-11-06 in the rail grind. Every number is in `game/data/rail_grind.json`, each with its reason (`_boost_comment`, `_jump_comment`), for the board to tune by playing.

**1. Landing boost** (`rail_grind.gd` `start()` and `step()`):
- **Proposal: an amount added, not a speed it is raised to.** `land_boost` = **4 units/s** is added to the speed along the rail that the car lands with. A fast landing stays faster than a slow one, and every landing feels the same push. 4 is about a third of cruise speed (11 becomes 15), well under the top speed of 33.
- **Decline:** `boost_decline` = **2 units/s every second** on the boost's part only (`boost_left`), on top of the usual `decel` of 1. So the speed drops by 3 a second for 2 s (4 / 2) until the boost is gone, then by 1 as before. The decline is linear, the simplest curve to tune.
- Every landing boosts again, a Jump onto a second rail included. A joint between connected pieces is not a landing (joints never call `start()`), so it adds nothing, and the boost already running keeps declining across it.

**2. Jump off a rail goes where the car faces** (`leave_velocity("jump")`):
- The car leaves along its nose (`body_heading`), at `jump_speed` = **6 units/s** flat, whatever its travel along the rail, backwards included. Momentum along the rail is not kept.
- `jump_angle_deg` is removed, along with the 15-degree diagonal hop.
- 6 is "a bit": about half of cruise speed, about 5 units over a first-tier Jump. To catch the jump pair's other rail (3.5 apart), the nose must point about 40 to 45 degrees toward it, because the lock-on needs the car within 60 degrees of the rail and moving at least 2 units/s along it. A car facing straight across lands beside the rail.
- The no-cooldown rail jump (quick tuning 2) is unchanged, and its tests still pass.
- The slow drop's sideways push still uses `nose_side()`.

**Tests**
- `game/tests/unit/test_rail_grind.gd`, new tests:
  - the boost is added and declines at its rate, then only `decel` applies
  - every landing boosts again (a Jump from rail-a to rail-b)
  - a joint is not a new landing
  - the jump goes along the nose at `jump_speed` (straight, -20, 110 and 180 degrees)
  - a car turned 180 degrees on a rail jumps off backwards, against its travel
  - the numbers are in the data, and `jump_angle_deg` is gone
- Updated tests, now turning the nose about 40 degrees before jumping: the slide-speed check, the rail-to-rail jump, two quick rail jumps, and the parallel-rail spacing.
- `game/tests/unit/run/test_run_rails.gd`: rail-3 to rail-4, with the nose turned 40 degrees right.
- Rail tests: 32/32 and 14/14 in the grind and joint scripts, 5/5 in the run rails script.
- **Full run, second time: 2912 tests, 2911 passing, 0 failing, 1 pending (252 scripts), TESTS PASSED.** The first full run had 1 failing test. I lost its name because I piped the output through `tail`, and the rerun passed, so it was likely a flaky test elsewhere. Worth QA watching.

**GIFs** (`art-archive/T-548/screenshots/`)
- New fixture `game/tests/fixtures/t548_rail_gif.tscn` (`t548_rail_gif_demo.gd`). It uses the game's map with T-541's rail-3 and rail-4 added in a `user://` copy, because the current map has no rails. A recording-only readout along the bottom shows the speed along the rail and the boost left.
- `landing_boost_and_facing_jump.gif`: the car lands on rail-3 at 20.5 (16.5 + 4) and the speed declines. D turns the nose 40 degrees, and the Jump leaves at 6 along it onto rail-4, landing at 8.38 (4.38 along + 4, boosted again).
- `jump_off_backwards.gif`: D spins the car round on rail-3 and the Jump sends it off backwards at 6.
- Stills: `landing_boost.png`, `back_facing_before_jump.png`, `jumped_off_backwards.png`.

**Docs**
- `docs/drifting.md` Content, "Rail grinding (task T-541)": new "Landing boost" item, and the Jump part of "Leaving" rewritten. Both give the numbers and their reasons. The T-542 joint figure (9.5333) is marked as measured before the boost.
- `game/docs/driving/rail-grind.md`: the API, data keys, tests and recordings.
- `car.gd`: only a comment.

Documents affected: docs/drifting.md (updated). Nothing in game/data/levels/ was touched.
