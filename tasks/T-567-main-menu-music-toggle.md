---
id: T-567
title: A music toggle in the main menu's top right corner
status: open
from: project-lead
to: ui
lead: Rails
epic: ui
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/hud-and-menus/main-menu.md, game/docs/hud-and-menus/pause-screen.md, game/scripts/menu/main_menu.gd, game/scripts/ui/game_settings.gd, game/scripts/game/music_player.gd]
files_expected_to_change: [game/scripts/menu/, game/scripts/ui/, game/tests/, game/docs/hud-and-menus/, docs/hud-and-menus.md]
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

Build HUD and menus, Decisions, "A music toggle on the main menu": a small button with a music note in the main menu's top right corner. A click sets the music volume to 0 and shows the note crossed out; a second click puts back the volume it had before (the default if that was 0). It is the same saved setting as the pause screen's music volume slider, so both show each other's changes, and it is kept between sessions. Draw the note icon and its crossed version with a script in the menu's pixel look (no PixelLab), and keep it clear of the other main menu items at the usual window sizes. It shows no text.

The board's review: play it from C:\solid-carbide-worktrees\T-567\game\project.godot: click the note, start a run, open the pause screen's music slider, quit and reopen the game.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. No PixelLab calls. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The main menu shows a note button in its top right corner; a click sets the music volume to 0 and shows the crossed note, a second click restores the previous volume (tests). (QA: pass / fail)
- [ ] The pause screen's music slider and the toggle stay in step, and the setting is kept after a restart (tests). (QA: pass / fail)
- [ ] The icon is drawn by a script, with no PixelLab call (result notes). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content and game/docs/hud-and-menus/main-menu.md describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-567/screenshots/ show the main menu with the note on and crossed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
