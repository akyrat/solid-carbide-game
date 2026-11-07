---
id: T-551
title: Grind overhaul: hold Space in the air to tilt and grind, release to launch; no Jump cooldown; jump effect and facing arrow
status: open
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
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-548-rail-landing-boost-facing-jump.md, game/docs/driving/]
files_expected_to_change: [game/scripts/driving/, game/data/rail_grind.json, game/data/power_ups.json, game/tests/, game/docs/driving/, docs/drifting.md]
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

Build Drifting, Decisions, "The grind overhaul", "Jump has no cooldown" and the playing side of "A jump effect around the car", and HUD and menus, Decisions, "The jump arrow" (the arrow itself; the checkbox is T-553). Your branch starts from T-548's (the landing boost and the launch where the car faces), which this overhaul keeps. (1) **Tilt state:** while Space (the car_jump action) is held with the car in the air, the car is in a tilted pose, with a 3-frame transition in and the same transition backwards out on release in the air or on landing (propose what happens on landing). The art comes later (T-555): build the state, its frame timing and the hook that picks the tilted frame for the car's direction and transition step, with a placeholder look (for example the normal frame sheared or offset in code) that T-555 replaces. The car can still spin in the air while tilted. (2) **Grinding:** a grind starts only when Space is held in the air and the car touches a rail (keep or widen the catch reach so it is easier, and say what you chose); it lasts only while Space stays held; releasing Space launches the car along its facing at the data's speed, cancelling its momentum (T-548's launch). The landing boost on each rail landing stays (added to the speed). No power-up is needed for any of this; the Jump power-up's jump from the ground stays as it is, minus its cooldown. Propose what happens when the rail ends while Space is held. (3) **No Jump cooldown** at either tier (power_ups.json and code; tier 2 keeps its higher takeoff). (4) **Jump effect:** when the car jumps (the Jump power-up's jump, the launch off a rail, and propose whether a ramp take-off counts), play the equipped jump effect around the car, read from the saved cosmetic choice (T-552 adds it; until then default dash_cloud), with a code-drawn placeholder per effect id that T-556 replaces with art. (5) **Facing arrow:** a small arrow around the car pointing where the car faces, shown while grinding (proposal), drawn in code in the pixel look like the Drift Guide, switched by a saved setting `jump_arrow_enabled` (propose its default) that T-553 puts in the pause screen. Every number in game/data/rail_grind.json (or power_ups.json) with its reason. Check what else this changes (aerial tricks, airtime missions, the GRIND! trick, the trick list's clip, the tutorial's demo, the bots and tools that drive the car) and update it, listing each in the result notes.

The board's review: play the combined build (playtest/grind-overhaul) on the Kaiju City map: tilt, grind, launch, arrow, effects, and say what to change.

This ticket is part of the grind overhaul (board, 2026-11-07; Drifting, Decisions, "The grind overhaul"; tickets T-550 to T-556). The board plays all of it at the end, in one combined build (branch playtest/grind-overhaul, with T-547's map and T-548's grind changes), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, and leave no background job running when you hand back. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Holding Space in the air puts the car in the tilted state through 3 transition frames, and releasing it in the air plays them backwards; on the ground nothing tilts (tests). (QA: pass / fail)
- [ ] A grind starts only while Space is held in the air and the car touches a rail, lasts while it is held, and releasing Space launches the car along its facing at the data's speed with its old momentum gone, also facing backwards (tests). (QA: pass / fail)
- [ ] Each rail landing still adds the landing boost to the car's speed (test). (QA: pass / fail)
- [ ] The Jump power-up's jump from the ground has no cooldown at either tier (test). (QA: pass / fail)
- [ ] Jumping plays the equipped jump effect's placeholder around the car, the dash cloud by default (test). (QA: pass / fail)
- [ ] The facing arrow shows while grinding when jump_arrow_enabled is on and not when off (test). (QA: pass / fail)
- [ ] docs/drifting.md Content and game/docs/driving/ describe all of it with each proposed number and its reason, and the result notes list every other system checked or updated. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] GIFs in art-archive/T-551/screenshots/ show a tilt in and out, a grind started by holding Space, a launch off a rail backwards, the arrow, and a jump effect placeholder. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
