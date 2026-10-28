---
id: T-325
title: "Art: the Bricks card image and the impact wave"
status: open
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-324]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/weapons.md, game/docs/weapons/bricks.md, game/docs/weapons/shared.md, game/docs/art/pixellab.md, docs/working-with-the-board.md]
files_expected_to_change: [game/art/weapons/, art-archive/T-325/, docs/visual-style.md, game/README.md]
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

The board's decision (Weapons, Decisions, "Bricks", 2026-10-28). Make Bricks' final art and swap it in for T-324's placeholders: the level-up card image (64 x 64, like the other weapons' card images, T-174: a stack of bricks, perhaps in a car's boot, a proposal) and the impact wave on landing (a ground ring with dust and brick chips, in the City's colours, never in Greenbull's colours), in the game's pixel rules (Visual style, Content, "Rules"). Every asset goes through the style loop.

**PixelLab needs the board's go for this ticket before any generation** (docs/working-with-the-board.md, "Art and money"). Try free script work first (the wave may be drawn by script well enough); if PixelLab is needed, write the planned calls and their cost in the result notes and wait for the go. Sample first: the card image alone for the board's review, then the wave.

The board's review: look at the Bricks card and a landing wave in a run.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The card image and the wave art are in game/art/weapons/ and replace T-324's placeholders in the game. (QA: pass / fail)
- [ ] Each asset scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass / fail)
- [ ] The PixelLab generations used are within the board's go and listed in the result notes (or none, if all script work). (QA: pass / fail)
- [ ] Visual style and game/README.md record the art. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-325/screenshots/`, as `tasks/README.md`, "Screenshots", asks. The card on the level-up screen and a GIF of the wave. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
