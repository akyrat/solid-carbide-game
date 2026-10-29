---
id: T-361
title: Art: pixel art smoke and flames for the wrecked car
status: open
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-360]
documents_affected: [docs/visual-style.md, game/docs/art/]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/working-with-the-board.md, game/docs/art/pixellab.md, docs/game-loop-architecture.md]
files_expected_to_change: [game/art/, game/scripts/, game/tools/, art-archive/, docs/visual-style.md, game/docs/art/]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decision (Game loop architecture, Decisions, "Wrecked: the stream keeps rolling", 2026-10-29): when the car loses its last heart it sits crashed for 3 seconds, **smoking and burning**. The board: "It'd be cool if it was like pixel art smoke. And I want to play test it directly with a pixel art smoke. I trust you to generate the animation with it ... Maybe it'd be really cool to add some flames as well."

Make two looping animations: **smoke** rising from the wrecked car (dark grey puffs that rise, grow and thin out) and **flames** licking up from it (small, flickering). They sit on the isometric car at the game's pixel scale, in the game's pixel rules (Visual style, Content, "Rules"; none of Greenbull's colours outside Greenbull's things, rule 6), and read against the grey street and the car's colours. Save them as frames or sheets in `game/art/` with a record, then swap them in for the behaviour ticket's placeholders.

**PixelLab: the board's go** (2026-10-29: "I trust you to generate the animation"), **up to 16 generations** for the two animations, no sample review (the board plays it directly with the behaviour ticket). Write the planned calls and their cost in the result notes before calling; 600 s timeout. A script-drawn animation is fine instead if it scores better. Every animation goes through the style loop (at most 3 refines).

The board's review: lose all your hearts and watch the car smoke and burn for 3 seconds.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/` holds a looping smoke animation and a looping flames animation with records, and they replace the behaviour ticket's placeholders on the wrecked car. (QA: pass / fail)
- [ ] Each animation scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass / fail)
- [ ] The PixelLab generations used are at most 16 and listed in the result notes, with the plan written before the first call. (QA: pass / fail)
- [ ] Visual style and the art docs under game/docs/art/ record the art. (QA: pass / fail)
- [ ] A contact sheet of the frames, enlarged, on a dark and a light background, and a GIF of the wreck in a run are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
