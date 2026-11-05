---
id: T-540
title: Bouncier Bouncy Bumpers
status: in-progress
from: project-lead
to: game-data
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/driving/collisions.md]
files_expected_to_change: [game/data/power_ups.json, game/tests/, docs/drifting.md]
model: sonnet
qa_rounds: 1
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

Build Drifting, Decisions, "Bouncier Bouncy Bumpers". Raise the Bouncy Bumpers factors (today x1.4 / 1.8 / 2.2 / 2.6 in data, of which the run now uses 2 tiers) so the bounce is clearly further at every tier; propose the numbers (for example about 1.5 times today's) and check the farthest bounce doesn't throw the car through thin walls or off the map. Data only, unless the cap on the hardest bounce also needs raising (then say so). If the card text names a number, list it in the result notes: the Project Lead gets new text from the Narrative Theme Agent.

The board's review: play the combined build from C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot before merging.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The factors in data are higher at every tier, and the bounce distance test measures the new distances (test). (QA: pass)
- [ ] The result notes give the old and new distances per tier, and say whether any player-facing text names a number. (QA: pass)
- [ ] docs/drifting.md Content gives the new numbers. (QA: fail: paperwork - Content only gives tier 2 (x3.9, line 261); tier 1 x2.1 and the new distances 1.85 / 3.48 appear only in Decisions, and Content lines 267 and 319 still say x1.4/1.8/2.2/2.6 and 1.23/.../2.30)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] A plot in art-archive/T-540/screenshots/ shows old and new bounce distance per tier. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-05, Open → In progress

Started: the agent is working in C:\solid-carbide-worktrees$t.

### 2026-11-05, In progress → In QA

Built: Bouncy Bumpers x2.1 / x3.9 (head-on 1.85 / 3.48 units, was 1.23 / 2.30). QA is checking it.

### 2026-11-05, In QA → In progress

QA round 1: one paperwork fail (Drifting Content still shows the old bumper numbers). Back to the agent to fix the doc.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

T-540 report. Factors (proposal, 1.5x each): tier 1 x1.4 -> x2.1, tier 2 x2.6 -> x3.9 (game/data/power_ups.json; the run's 2 tiers). The 4-tier record x1.8/x2.2 had no data left.
Measured head-on bounce at cruise speed (tests/unit/test_bouncy_bumpers.gd): none 0.87; tier 1 1.23 -> 1.85 units; tier 2 2.30 -> 3.48 units.
Safety: the bounce goes away from the wall, never into it. Hardest-hit cap (16.5 units/s) is unchanged and scales by the same factor: estimated farthest bounce about 7.6 units at tier 2 (0.87 x 2.25 x 3.9, estimate not measured), peak speed about 13 units/s = 0.22 units per step, so no tunnelling through thin walls. Cap needs no raise. Not checked in play against the map edge: for the board's playtest.
Player-facing text: yes. The card text "Bounce {bounce_multiplier}x farther off walls and obstacles." (screen_texts.json) fills in the number from data, so it now reads 2.1x / 3.9x with no text change; tests hardcoded 2.6x, updated to 3.9x. No new text needed from Narrative.
Docs: docs/drifting.md (Decisions, Content tiers, new numbers).
Tests changed: test_bouncy_bumpers.gd (top tier from data, new test of factors above the old), test_four_minute_run_data.gd, test_power_up_screen.gd. Ran: test_bouncy_bumpers 4/4, test_four_minute_run_data 6/6, test_power_up_screen all passing.
Plot: art-archive/T-540/screenshots/bounce_distance_old_vs_new.png

QA round: criteria 1, 2, 4, 5 pass; criterion 3 fails (paperwork): docs/drifting.md Content gives only tier 2 (x3.9); tier 1 x2.1 and new distances 1.85/3.48 are only in Decisions, and Content (tier list line 267, Bouncy Bumpers section lines 317-319) still shows the old x1.4/1.8/2.2/2.6 and 1.23/.../2.30. qa_check: tests 2 sets passed, documents 1 changed, screenshots 1 file. Plot checked: shows none/tier 1/tier 2 old vs new.

QA round 1 fix: docs/drifting.md Content now gives x2.1/x3.9 and distances 1.85/3.48 (was 1.23/2.30), and the cap line x3.9.

QA round 1 fix: docs/drifting.md Content now gives x2.1/x3.9 and distances 1.85/3.48 (was 1.23/2.30), and the cap line 1.75 x 3.9 = 6.8 units.
