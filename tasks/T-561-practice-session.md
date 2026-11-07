---
id: T-561
title: The practice session: a small live run in a window, counting one trick
status: open
from: project-lead
to: game-loop
lead: Rails
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/drifting.md, game/docs/game-loop/the-run.md]
files_expected_to_change: [game/scripts/run/, game/scripts/game/, game/scenes/, game/tests/, game/docs/game-loop/, docs/game-loop-architecture.md]
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

Build the engine of the practice windows (HUD and menus, Decisions, "Interactive tutorial slides"): a self-contained practice scene the tutorial slide (T-562) embeds in a SubViewport. It loads the practice playground (T-560's level; until it is in, a stand-in on ground_grid.gd), puts the real car at the slide's start point, with the real driving, combo and trick signals, and no enemies, kaiju, clock, damage or gift packs. It is set up per slide with the trick to count: drift (a drift that pays LONG DRIFT!, so 1 s or more; propose), alt drift, air spin (AIR 180! or AIR 360!), grind (GRIND!). It counts successes, shows the goal in the real mission notebook inside the window ("x/3"), and signals the third success (the slide shows the success message over the window). For the grind slide, it starts by offering the Jump power-up gift (the real power-up gift overlay, in the window, one choice) and gives Jump when taken. The car resets to the start point if it leaves the area or on a key (propose). It reads input only while its window has focus, so the slide's other keys don't drive it. Text comes from T-559's keys. Make it testable headless.

The board's review: play the tutorial in the combined build (playtest/interactive-tutorial): press Start from the main menu.

Part of the interactive tutorial (board, 2026-11-07; HUD and menus, Decisions, "Interactive tutorial slides" and "A trick falls into the notebook"; Level design, Decisions, "The practice playground"; tickets T-559 to T-563). The board plays all of it at the end in one combined build (branch playtest/interactive-tutorial), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --append <file>` (write the file with the Write tool) or `--text`, and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The practice scene loads the playground (or the stand-in) with the real car and no enemies, clock or damage (test). (QA: pass / fail)
- [ ] Set to each of the four tricks, it counts that trick and no other, and signals on the third (tests for each). (QA: pass / fail)
- [ ] The notebook in the window shows the goal and its count (test). (QA: pass / fail)
- [ ] The grind practice opens with the Jump gift and gives Jump when taken (test). (QA: pass / fail)
- [ ] docs/game-loop-architecture.md Content and game/docs/game-loop/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-561/screenshots/ show the scene with each trick's notebook goal. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
