---
id: T-571
title: A Settings screen opened from the main menu
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
depends_on: [T-570]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/hud-and-menus/main-menu.md, game/docs/hud-and-menus/pause-screen.md, game/scripts/menu/main_menu.gd, game/scripts/ui/pause_screen.gd, game/scripts/ui/game_settings.gd, tasks/T-567-main-menu-music-toggle.md]
files_expected_to_change: [game/scripts/menu/, game/scripts/ui/, game/scenes/, game/tests/, game/docs/hud-and-menus/, docs/hud-and-menus.md]
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

Build HUD and menus, Decisions, "A Settings screen from the main menu". A Settings button on the main menu (text from T-570) opens a screen with the pause screen's settings that make sense outside a run: the music volume (and the SFX volume only when `GameSettings.sfx_enabled()`), the camera zoom, Camera smoothing, Dynamic camera, Rain, the drift guide and the jump arrow. Left out: HUD size, the HUD layout editor, the trick list, Restart and Exit, Set min/max zoom and god mode. The values are the same saved settings the pause screen uses (read at open, saved like the pause screen's, applied at the next run), and a music change is heard at once in the menu's music. Reuse the pause screen's rows, look and save rules instead of copying them where you can (propose the cleanest split, for example shared row builders). Back and Escape return to the main menu. T-567 (cancelled) built a music toggle on its branch task/T-567-main-menu-music-toggle; read it for how the menu music volume is applied, but don't merge it.

The board's review: play it from C:\solid-carbide-worktrees\T-571\game\project.godot: open Settings from the main menu, change the music and the checkboxes, start a run and open the pause screen, quit and reopen the game.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. No PixelLab calls. Never run a real itch.io push (butler push) and never print .env values. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The main menu shows the Settings button; it opens the screen with exactly the listed settings, and Back and Escape return to the main menu (tests). (QA: pass / fail)
- [ ] A change on the Settings screen is saved, shows on the pause screen in the next run and is kept after a restart; the music volume changes the menu's music at once (tests). (QA: pass / fail)
- [ ] The pause screen works as before (the existing tests pass). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content and game/docs/hud-and-menus/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-571/screenshots/ show the main menu with the button and the Settings screen. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
