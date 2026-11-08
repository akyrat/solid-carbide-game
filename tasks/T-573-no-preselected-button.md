---
id: T-573
title: No button looks selected when a menu opens
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
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/scripts/ui/key_nav.gd, game/scripts/menu/garage_screen.gd, game/scripts/menu/cosmetics_screen.gd, game/scripts/menu/main_menu.gd, game/scripts/menu/settings_screen.gd, game/scripts/menu/tutorial_slides.gd, game/scripts/ui/pause_screen.gd]
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

Build HUD and menus, Decisions, "No button looks selected when a menu opens". The board's bug: entering the garage and the Cosmetics screen shows the first available button as selected (they call grab_focus() on open: garage_screen.gd, cosmetics_screen.gd). Fix those, then check every other menu and screen that does the same (main menu, Settings screen, tutorial slides, pause screen, trick list, HUD layout editor, god mode page, level-up and other screens; grep for grab_focus) and fix them the same way. Keyboard play must keep working: no button looks selected until the player presses a key that moves between buttons (arrows, Tab), and that first press shows the selection where it starts. Mouse hover is unchanged. Prefer one shared way (for example in key_nav.gd) over a fix per screen. Propose what Enter or Space does on a screen where nothing looks selected yet (keep today's action where a screen relies on it, for example the level-up cards or the tutorial's Go live), and list each screen's behaviour in the result notes. Your branch starts from the board's menu fixes build (playtest/menu-fixes: T-568, T-569, T-571, T-572), so the Settings screen is there.

The board's review: play it in the menu fixes build (the Project Lead merges your branch into C:\solid-carbide-worktrees\playtest-menu-fixes once QA passes): open the garage, Cosmetics, Settings and the other menus with the mouse, then use the arrows.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. No PixelLab calls. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The garage and the Cosmetics screen open with no button shown as selected (tests). (QA: pass / fail)
- [ ] Every other menu or screen that selected a button on opening does the same, listed in the result notes (tests for each). (QA: pass / fail)
- [ ] Arrows or Tab still move the selection, and the first press shows it (tests); mouse hover works as before. (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content and game/docs/hud-and-menus/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-573/screenshots/ show the garage and Cosmetics screens just opened, and after one arrow press. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
