---
id: T-560
title: The practice playground level
status: open
from: project-lead
to: level-challenge
lead: Rails
epic: level-challenges
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/drifting.md, game/scripts/driving/ground_grid.gd, game/docs/level/game-map.md]
files_expected_to_change: [game/data/level/, game/scenes/, game/scripts/level/, game/tests/, game/docs/level/, docs/level-design.md]
model: sonnet
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

Build Level design, Decisions, "The practice playground": a small level the tutorial's practice windows load (T-561), on the drift prototype's dark purple grid ground (ground_grid.gd's colours, or close to them), with an open area for drifts and alt drifts, a ramp (a jump ramp or a ramp onto a rooftop) fast enough for an AIR 360!, and two or three rails reachable from the ramp. It is a level file in the same format the game loads (game/data/level/, with the same checks: check_level.py, check_height_data.py), so the board can open and edit it in the level creator later. Give a start point per trick slide (drift, alt drift, air spin, grind), chosen so the trick is easy to try at once. Check the contrast: the car, its drift smoke and effects, the rails, the ramp and the HUD (the notebook) must stand out clearly against the ground; adjust the ground's colours if needed and say what you chose. Keep it small so it loads fast.

The board's review: play the tutorial in the combined build (playtest/interactive-tutorial): press Start from the main menu.

Part of the interactive tutorial (board, 2026-11-07; HUD and menus, Decisions, "Interactive tutorial slides" and "A trick falls into the notebook"; Level design, Decisions, "The practice playground"; tickets T-559 to T-563). The board plays all of it at the end in one combined build (branch playtest/interactive-tutorial), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --append <file>` (write the file with the Write tool) or `--text`, and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The playground level file loads in the game and passes check_level.py and check_height_data.py (output in the result notes). (QA: pass / fail)
- [ ] It has an open drift area, a ramp from which the car reaches an AIR 360! at full speed, and rails reachable from the ramp (tests). (QA: pass / fail)
- [ ] It names a start point for each of the four trick slides (test). (QA: pass / fail)
- [ ] Screenshots show the car drifting, on the ramp and on a rail on it, and the result notes say how the contrast was checked. (QA: pass / fail)
- [ ] docs/level-design.md Content and game/docs/level/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
