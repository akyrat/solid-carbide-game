---
id: T-340
title: "Art: bolder enemy outlines, so the player sees and avoids them"
status: open
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/enemies.md, game/README.md]
files_expected_to_change: [game/art/, game/tools/, art-archive/T-340/, docs/visual-style.md, game/README.md]
model: sonnet
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

The board's decision (Enemies, Decisions, "Damage in hearts, fewer health drops, bolder outlines", 2026-10-28): with hearts, each hit matters more, so the player must see where the enemies are and steer round them. Make every enemy's outline **a little bolder**: the minions (every kind, every frame and direction) and the kaiju. A free **script** pass is expected: thicken the dark outline by one pixel outward (or darken it), keeping the sprites' sizes or growing the canvas evenly, at most 30 colours, alpha 0 or 255. Keep the originals in `art-archive/T-340/`; never delete art. If an outline reads poorly over the street or a rooftop, say so and propose a fix (for example a slightly lighter rim). Every changed sprite set goes through the style loop. No PixelLab expected; if one is needed, ask the Project Lead first.

The board's review: play a run and see whether the enemies stand out more against the street and rooftops.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every enemy sprite (all minion kinds, frames and directions, and the kaiju) has the bolder outline, made by a script in game/tools/ that is rerunnable, with the originals in art-archive/T-340/. (QA: pass / fail)
- [ ] The sprites still pass the pixel rules (`style_rules.py art`: colours, alpha, size), and the game loads them (the existing enemy and art tests pass). (QA: pass / fail)
- [ ] Each sprite set scored at least 8 in the style loop, with every round in the Style review. (QA: pass / fail)
- [ ] Visual style and game/README.md record it. (QA: pass / fail)
- [ ] Before and after screenshots of enemies on the street and a rooftop are in `art-archive/T-340/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
