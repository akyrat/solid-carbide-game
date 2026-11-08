---
id: T-603
title: The Polarized Steering Wheel bursts after an alternate drift
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
depends_on: [T-602]
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/docs/driving/drift.md, game/data/power_ups.json, tasks/T-502-polarized-steering-wheel.md, tasks/T-527-steering-wheel-cooldown.md]
files_expected_to_change: [game/scripts/driving/, game/data/, game/tests/, game/docs/driving/, game/tools/]
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

Build Drifting, Decisions, "The Polarized Steering Wheel bursts after an alternate drift". The wheel's burst comes from each alternate drift the trick system pays (ALT DRIFT!), on the ground, outside the cooldown; the old trigger (lift W, steer, press W) is removed. The burst is half as strong (tier 1 x1.1, tier 2 x1.225 in power_ups.json), held 0.5 s, then fades quickly to the speed the car would have had (propose how quickly, with a reason). Settle the burst's direction when the alternate drift pays on a switch into a backward drift (the car moving backwards): the burst pushes along the car's travel, whichever way the nose points; say how. The tier 2 shock and the cooldown (T-527) stay as they are, as does the cooldown fill on the HUD icon. When the burst triggers, draw in code a small animation on the ground around the car: 2 arrows, one on each side of the car, pointing along the direction of travel at the moment the alternate drift paid (the way the burst pushes), drawn under the car and fading out (propose size, colour from the wheel's cyan and magenta, and length, about the burst's 0.5 s). Swap in T-602's descriptions. Check the tutorial (the missions slide, recorded demos) for anything showing the old trigger and say what you found. Rerun the speed bot (bash game/tools/speed_bot.sh) with the new trigger and put its peak and average speeds in the result notes, so a runaway speed would show. Numbers in data with reasons.

The board's review: play it from C:\solid-carbide-worktrees\T-603\game\project.godot: take the Polarized Steering Wheel, alt drift, feel the burst and see the arrows; lift-steer-gas gives nothing.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A completed alternate drift with the wheel owned gives the burst at x1.1 (tier 1) and x1.225 (tier 2) for 0.5 s, then fades in the proposed time (tests with the numbers). (QA: pass / fail)
- [ ] Lift, steer and W again gives no burst; the cooldown still blocks a burst and the tier 2 shock still fires (tests). (QA: pass / fail)
- [ ] The arrows show on the ground on each side of the car, under it, pointing along the travel at the payout, and fade out (a test of their direction and life). (QA: pass / fail)
- [ ] T-602's descriptions show on the cards (a test or screenshot). (QA: pass / fail)
- [ ] The speed bot's peak and average speeds are in the result notes. (QA: pass / fail)
- [ ] docs/drifting.md Content (The Polarized Steering Wheel section) and game/docs/driving/ describe the new trigger, numbers and arrows. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots or a GIF in art-archive/T-603/screenshots/ show the arrows around the car after an alternate drift, taken with bash game/tools/screenshot.sh. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
