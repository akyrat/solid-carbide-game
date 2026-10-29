---
id: T-382
title: The tutorial slides screen, with a reusable trick list scene (placeholder illustrations)
status: open
from: project-lead
to: ui
lead: Goal-G-007
epic: hud-menus
milestone: mvp
goal: G-007
user_facing_text: yes
changes_visuals: yes
depends_on: [T-381]
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/tutorial-slides.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/main-menu.md, game/docs/hud-and-menus/recap-screen.md, game/docs/driving/tricks.md, game/scripts/ui/game_settings.gd, game/scripts/ui/recap_screen.gd, game/data/tutorial_text.json, game/docs/setup/screenshots.md]
files_expected_to_change: [game/scenes/menu/tutorial_slides.tscn, game/scripts/menu/tutorial_slides.gd, game/scenes/menu/trick_list.tscn, game/scripts/menu/trick_list.gd, game/scripts/ui/game_settings.gd, game/tests/unit/test_tutorial_slides.gd, game/tests/unit/test_trick_list.gd, game/tests/unit/test_tutorial_setting.gd, game/tests/fixtures/tutorial_slides_demo.gd, game/tests/fixtures/tutorial_slides_demo.tscn, docs/hud-and-menus.md, game/docs/hud-and-menus/tutorial-slides.md, game/README.md]
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

HUD and menus, Decisions, 'Tutorial slides before the first run' (board, 2026-10-29). Build the slides screen as its own scene, game/scenes/menu/tutorial_slides.tscn: three slides with left and right arrows between them; slide 1 has no left arrow and slide 3 no right arrow (or they do nothing); slide 3 has the Start button and a 'Don't show again' checkbox. The screen emits a signal (for example start_pressed(dont_show_again: bool)) when Start is pressed; it does not start the run itself (the Game Loop ticket wires it to the main menu's Start). Slide 2's trick list is a separate scene, game/scenes/menu/trick_list.tscn, so the pause screen can reuse it: the seven tricks (ids from game/docs/driving/tricks.md), each with its name from game/data/tutorial_text.json and an illustration loaded from one fixed path per trick, game/art/tutorial/tricks/<trick id>.png. Give the trick list an exported illustration folder property defaulting to that folder, so the art tickets can screenshot their own sets. While a file is missing, draw a code-made placeholder (not in Greenbull's light green or yellow). Decide the illustration size in pixels (a still image for each trick, drawn at a whole-number scale with nearest filtering) and write it in game/docs/hud-and-menus/tutorial-slides.md: the two art tickets draw at that size. Every visible text comes from game/data/tutorial_text.json; no player-facing string is hard-coded. The arrows and Start work with the mouse and the keyboard; propose the keyboard controls and focus order and write them in the result notes and the doc. Add a tutorial_hidden setting to game_settings.gd (load and save, false by default), saved with the other settings. Screenshots of all three slides at 1152 x 648.

The board's review: Look at the three slides and the trick list with its placeholder illustrations, from the screenshots or by opening the scene in the task's folder.

## Acceptance criteria

- [ ] game/scenes/menu/tutorial_slides.tscn shows three slides; slide 1 has no left arrow and slide 3 no right arrow (or pressing them does nothing); slide 3 has the Start button and the 'Don't show again' checkbox; pressing Start emits a signal carrying the checkbox state. Scene tests cover arrow navigation in both directions and the Start signal with the checkbox on and off. (QA: pass / fail)
- [ ] game/scenes/menu/trick_list.tscn is a separate scene used by slide 2, showing the seven tricks, each with its name from game/data/tutorial_text.json and an illustration loaded from game/art/tutorial/tricks/<trick id>.png; with the file missing a code-drawn placeholder shows, not in Greenbull's colours. A test checks the placeholder shows when the files are missing, and that a PNG at the fixed path is loaded when present. (QA: pass / fail)
- [ ] The illustration size in pixels and the trick list's illustration folder property are written in game/docs/hud-and-menus/tutorial-slides.md. (QA: pass / fail)
- [ ] No player-facing string is hard-coded in tutorial_slides.gd or trick_list.gd: a search finds no literal text shown on screen, and a test checks each visible label's text matches its key in game/data/tutorial_text.json. (QA: pass / fail)
- [ ] The arrows and Start work with the mouse and with the keyboard; the keyboard controls and focus order are written in the result notes and the doc, and a test drives them with keyboard input events. (QA: pass / fail)
- [ ] game_settings.gd has tutorial_hidden, false by default, saved and loaded with the other settings; a unit test covers the save and load round trip and the default. (QA: pass / fail)
- [ ] Screenshots of all three slides at 1152 x 648 are saved in art-archive/<task id>/screenshots/. (QA: pass / fail)
- [ ] docs/hud-and-menus.md, Content describes the slides screen, and game/docs/hud-and-menus/tutorial-slides.md says how it is built, linked from game/README.md. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
