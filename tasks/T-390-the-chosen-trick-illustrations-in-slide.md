---
id: T-390
title: The chosen trick illustrations in slide 2 and the pause trick list, placeholders retired
status: blocked
from: project-lead
to: ui
lead: Goal-G-007
epic: hud-menus
milestone: mvp
goal: G-007
user_facing_text: no
changes_visuals: yes
depends_on: [T-385, T-386]
documents_affected: [game/docs/hud-and-menus/tutorial-slides.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/tutorial-slides.md, game/scripts/menu/trick_list.gd, game/tests/unit/test_trick_list.gd, game/docs/setup/screenshots.md]
files_expected_to_change: [game/scripts/menu/trick_list.gd, game/tests/unit/test_trick_list.gd, game/docs/hud-and-menus/tutorial-slides.md]
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

Goal step 4 of the last MVP round (board, 2026-10-29): slide 2 and the pause screen's trick list show the seven illustrations the comparison ticket copied into game/art/tutorial/tricks/, with no placeholder left. Check each trick's texture loads from its file, draw them with nearest filtering at a whole-number scale (hard pixel edges), and remove the placeholder drawing code or leave it unused, documenting the files it drew for in game/docs/hud-and-menus/tutorial-slides.md. Screenshots of slide 2 and the open pause panel.

The board's review: Check the trick illustrations on slide 2 and in the pause screen's trick list.

## Acceptance criteria

- [ ] Slide 2 and the pause trick list panel both show the seven PNGs from game/art/tutorial/tricks/ with no placeholder drawn; a test checks each trick's texture is loaded from its file. (QA: pass / fail)
- [ ] The illustrations use nearest filtering and a whole-number scale; a test checks the filter and scale. (QA: pass / fail)
- [ ] The placeholder drawing code is removed or no longer reached, and game/docs/hud-and-menus/tutorial-slides.md documents the illustration files. (QA: pass / fail)
- [ ] Screenshots of slide 2 and the open pause trick list panel are saved in art-archive/<task id>/screenshots/. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
