---
id: T-604
title: Quick tuning: a new practice playground and alt drift take, with the board
status: open
from: project-lead
to: ui
lead: Rails
epic: hud
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md, docs/level-design.md]
files_to_read_first: [tasks/README.md, tasks/T-574-drift-slides-quick-tuning.md, docs/hud-and-menus.md, docs/level-design.md, game/docs/hud-and-menus/tutorial-slides.md, game/scripts/run/practice_session.gd, game/tools/build_practice_playground.py]
files_expected_to_change: [game/data/level/practice_playground.json, game/data/tutorial_takes/, game/tools/, game/tests/, game/docs/, docs/hud-and-menus.md, docs/level-design.md]
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

Quick tuning with the board (docs/working-with-the-board.md, "Quick tuning"). The board wants to change the tutorial's practice playground (game/data/level/practice_playground.json, Level design, "The practice playground") in the level creator and then re-record the alt drift take (game/data/tutorial_takes/alt_drift.json). In this folder only: (1) make the playground editable in the level creator and saved back to game/data/level/practice_playground.json (say how the board opens and saves it; if build_practice_playground.py would overwrite it, say so and stop it doing that); (2) bring back the take recording controls T-574 removed (F5 to F9 and their buttons, HUD and menus, Decisions, "The tutorial's recorded demos") so the board can re-record the alt drift take. Then tell the Project Lead it is ready, with the exact launch commands for the creator and the game. The board's tweaks come word for word through the Project Lead; write each in the result notes. When the board is happy: remove the recording controls again, keep the new playground and take, check every other tutorial take still does its trick on the new playground (say which ones it changed for, and that a take may need re-recording), update Level design Content and HUD and menus Content, and run the tests.

The board's review: play it from C:\solid-carbide-worktrees\T-604\game\project.godot: the tutorial's alt drift slide plays the new take on the new playground.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (reading is allowed). Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The new playground and alt drift take are committed; the alt drift demo pays ALT DRIFT! on the new playground (a test or the recorder's EXPECT check). (QA: pass / fail)
- [ ] The recording controls are gone again (the T-574 tests that check they are gone pass). (QA: pass / fail)
- [ ] The other tutorial takes are checked on the new playground, with the result in the result notes. (QA: pass / fail)
- [ ] docs/level-design.md and docs/hud-and-menus.md Content describe the change. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A screenshot or GIF in art-archive/T-604/screenshots/ shows the alt drift slide with the new take, taken with bash game/tools/screenshot.sh. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
