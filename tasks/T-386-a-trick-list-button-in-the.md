---
id: T-386
title: A trick list button in the pause screen, opening a panel with the trick list
status: blocked
from: project-lead
to: ui
lead: Goal-G-007
epic: hud-menus
milestone: mvp
goal: G-007
user_facing_text: yes
changes_visuals: yes
depends_on: [T-381, T-382]
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/pause-screen.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/pause-screen.md, game/docs/hud-and-menus/tutorial-slides.md, game/scripts/ui/pause_screen.gd, game/scenes/menu/trick_list.tscn, game/data/tutorial_text.json, game/docs/setup/screenshots.md]
files_expected_to_change: [game/scripts/ui/pause_screen.gd, game/tests/unit/test_pause_trick_list.gd, game/tests/fixtures/pause_trick_list_demo.gd, game/tests/fixtures/pause_trick_list_demo.tscn, docs/hud-and-menus.md, game/docs/hud-and-menus/pause-screen.md]
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

HUD and menus, Decisions, 'A trick list in the pause screen' (board, 2026-10-29). Add a trick list button to the pause screen, with its text from game/data/tutorial_text.json. Pressing it shows a sub-panel holding the same trick list scene as slide 2 (game/scenes/menu/trick_list.tscn: the seven tricks with names and illustrations), with none of slide 2's other text. A back control, with its text from the same file, returns to the pause screen with its sliders, checkboxes and buttons unchanged. The run stays paused throughout. The panel fits at 1152 x 648 and keeps clear of the HUD timer and clock. Mouse and keyboard both work; propose what Escape does while the panel is open (for example, back to the pause screen rather than resuming) and write it in the result notes and the doc. Screenshots of the pause screen and the open panel.

The board's review: Pause a run, open the trick list and go back.

## Acceptance criteria

- [ ] The pause screen has a trick list button whose text is its key in game/data/tutorial_text.json; pressing it shows a panel holding an instance of game/scenes/menu/trick_list.tscn with the seven tricks, and none of slide 2's other text. (QA: pass / fail)
- [ ] The back control, with its text from game/data/tutorial_text.json, returns to the pause screen with its sliders, checkboxes and buttons unchanged, and the tree stays paused while the panel is open and after going back; scene tests cover opening, going back and the paused state. (QA: pass / fail)
- [ ] At 1152 x 648 the panel's rectangle lies inside the screen and does not overlap the HUD timer or clock (checked in a test or from the screenshot). (QA: pass / fail)
- [ ] Mouse and keyboard both open and close the panel; what Escape does while the panel is open is written in the result notes and the doc, and a test covers it. (QA: pass / fail)
- [ ] Screenshots of the pause screen with the new button and of the open panel are saved in art-archive/<task id>/screenshots/. (QA: pass / fail)
- [ ] docs/hud-and-menus.md, Content, 'Pause screen' and game/docs/hud-and-menus/pause-screen.md list the new button and panel. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
