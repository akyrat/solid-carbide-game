---
id: T-386
title: A trick list button in the pause screen, opening a panel with the trick list
status: in-qa
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

- [ ] The pause screen has a trick list button whose text is its key in game/data/tutorial_text.json; pressing it shows a panel holding an instance of game/scenes/menu/trick_list.tscn with the seven tricks, and none of slide 2's other text. (QA: pass)
- [ ] The back control, with its text from game/data/tutorial_text.json, returns to the pause screen with its sliders, checkboxes and buttons unchanged, and the tree stays paused while the panel is open and after going back; scene tests cover opening, going back and the paused state. (QA: pass)
- [ ] At 1152 x 648 the panel's rectangle lies inside the screen and does not overlap the HUD timer or clock (checked in a test or from the screenshot). (QA: pass)
- [ ] Mouse and keyboard both open and close the panel; what Escape does while the panel is open is written in the result notes and the doc, and a test covers it. (QA: pass)
- [ ] Screenshots of the pause screen with the new button and of the open panel are saved in art-archive/<task id>/screenshots/. (QA: pass)
- [ ] docs/hud-and-menus.md, Content, 'Pause screen' and game/docs/hud-and-menus/pause-screen.md list the new button and panel. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Blocked → In progress

Goal runner (G-007): started, in C:\solid-carbide-worktrees\T-386.

### 2026-10-30, In progress → In QA

Goal runner (G-007): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

UI Agent, done. Trick list button ("Trick list") in the pause screen's run buttons row; it opens `TrickListPanel` with the slide-2 trick list scene (seven tricks only) and a "Back" button (texts from `game/data/tutorial_text.json`). The tree stays paused; back leaves the sliders/checkboxes untouched.

- **Escape while the panel is open (proposal):** goes back to the pause screen, does not resume; a second Escape resumes. Written in both docs and covered by `test_escape_goes_back_instead_of_resuming`.
- **Layout:** panel centred, starts at y=92 (below the HUD timer), 864 x 421 at 1152 x 648, ends at y=513, clear of the clock (bottom-left) and viewers panel. The test measures with the headless window forced to 1152 x 648 (it is tiny by default; my first run failed on that, not on the layout).
- **Tests:** new `tests/unit/test_pause_trick_list.gd` (6 tests). Three sets: GUT 1957/1957 passed (160 scripts); `game/tools` unittest 675 OK (1 skipped); `tools` unittest 573 OK.
- **Screenshots** in `art-archive/T-386/screenshots/`: `pause_screen.png` (with the new button), `pause_trick_list_panel.png` (open panel). Fixture: `pause_trick_list_demo.tscn`.
- **Docs updated:** `docs/hud-and-menus.md` (Pause screen), `game/docs/hud-and-menus/pause-screen.md`.
- QA round 1: all seven criteria pass. I ran the three test sets myself: GUT 160 scripts, 1957/1957 passed (test_pause_trick_list 6/6); game/tools 675 OK (1 skipped); tools 573 OK. The panel screenshot shows the panel inside the screen and clear of the timer. Both screenshots exist. Both docs describe the button, the panel and Escape. `python tools/qa_check.py` was refused (not pre-approved), so its paperwork check was skipped and I checked the files by hand.
- No PixelLab generations; no refusals. Godot's `.import` line-ending noise in the folder was left uncommitted.
