---
id: T-611
title: Timer at the top centre, notebook movable in the HUD editor
status: in-qa
from: project-lead
to: ui
lead: Polish
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, game/scripts/hud/hud_layout.gd, game/scripts/hud/timer_clock.gd, game/scripts/hud/mission_page.gd, game/tests/unit/hud/test_hud_layout_editor.gd]
files_expected_to_change: [game/scripts/hud/, game/scripts/ui/, game/data/, game/tests/, game/docs/, docs/hud-and-menus.md]
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

Build two decisions of HUD and menus, Decisions (board, 2026-11-09).

1. "The timer sits at the top centre": the timer clock's default place moves from the bottom left (T-335) to the top centre of the screen, centred, anchored to the top centre so it stays centred at any window size and HUD size. It stays a movable piece in the HUD layout editor, and Reset layout puts it at the top centre. A saved layout that already holds a place for the timer keeps that place. Propose its margin from the top edge. Check what was laid out around the old place (the coins counter sits above the timer, T-341) and what is shown at or near the top centre (popups, the pause strip, the trick list panel, the gift pack screen, the tutorial's practice windows, the kaiju's arrival, anything else): nothing placed by default may overlap the timer, and say in the result notes what you moved, if anything, as proposals. Update the doc's Content ("Timer clock", and the lines that still say the top centre is empty or that the timer is at the bottom left).

2. "The notebook can be moved in the HUD layout editor": the mission notebook page becomes one of the editor's movable pieces, like the hearts row, the weapon icons, the coins counter, the timer and the sub goal: framed in the editor, dragged, snapped, kept on screen, saved in `user://settings.cfg` section `hud_layout`, put back by Reset layout. Its default place and size do not change. The editor must show it even when the run has no mission on the page at that moment (propose how, for example the page's outline). The trick box that falls into the notebook (T-563) and the pulse (T-606) must play at the page's moved place. The notebook inside the tutorial's practice windows keeps its place there and ignores the saved layout. Update the doc's Content ("The HUD layout editor", "Which pieces move"; "The mission notebook page", which says the page is fixed).

No new player-facing text: the editor's texts are unchanged.

The board's review: play it from C:\solid-carbide-worktrees\T-611\game\project.godot: start a run, see the timer at the top centre; pause, Edit HUD layout, drag the notebook somewhere else, Done, do a trick that counts for the mission and watch the box fall into the moved notebook; Reset layout puts everything back.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] With no saved layout, at 1152 x 648 the timer clock's centre is on the screen's vertical centre line (within 2 pixels) at the top margin written in the result notes; a test checks it there and at one other window size and one other HUD size, fully on screen each time. (QA: pass)
- [ ] A test checks that at 1152 x 648 no HUD piece at its default place overlaps the timer at its new place, and the result notes list what else was checked near the top centre and what was moved. (QA: pass)
- [ ] A test checks that a saved layout holding a place for the timer still puts the timer at that place, and that Reset layout puts it at the top centre. (QA: pass)
- [ ] A test checks that the notebook page is a movable piece in the editor: it is framed, a drag moves it with the same snapping and on-screen rule as the other pieces, Done writes its entry in the `hud_layout` section, a new run reads it back, and Reset layout returns it to its default place (x 12, y 304 at the 1152 x 648 layout). (QA: pass)
- [ ] A test checks that with the notebook moved, the pulse (T-606) scales the page about its centre at the moved place and the falling trick box (T-563) lands in the page at the moved place. (QA: pass)
- [ ] A test checks that the notebook in a tutorial practice window is at the same place with and without a saved layout that moves the notebook. (QA: pass)
- [ ] Screenshots in art-archive/T-611/screenshots/: the HUD at the start of a run with the timer at the top centre; the layout editor with the notebook framed; the HUD with the notebook moved to another place. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] Every document in documents_affected is updated, and the proposals made for the playtest are listed in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-09, Open → In progress

Started: the UI Agent is moving the timer to the top centre and making the notebook a movable piece in Edit HUD layout.

### 2026-11-09, In progress → In QA

The UI Agent finished: the timer is at the top centre (16 px margin) and the notebook is a movable piece in Edit HUD layout. QA is checking it now.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. Timer: TimerClock now anchored top centre (offsets -100..100, top margin 16, hud.json timer_clock.layout.top), centred within 2 px at 1152x648, 1920x1080, 960x540, 2560x1080 and HUD sizes min/100/max. Saved layout entry for the clock is kept; Reset puts it at top centre. Checked near the top centre: all HUD pieces, airtime/drift counters, trick popups (top limit y162, clock ends y88), pause strip and trick list panel (start y92), gift pack/Time's up screens and practice windows (full screens / own layers), kaiju health bar (world). Nothing moved; coins stay at x16 y496 (the spot under them is now empty). Notebook: new piece id notebook in HudLayout.PIECES (Hud.piece maps it to mission_page); default x12 y304 and size unchanged; saved/reset like the others. Hidden page (no mission): editor frames it and fills the frame (HudLayoutEditor.is_ghost, GHOST_FILL). Pulse and falling box travel with the page (tests). Practice-window notebook is its own MissionPage, ignores layout (test). Proposals for playtest: top margin 16; ghost fill alpha 0.16; coins left where they were. New tests: tests/unit/hud/test_hud_timer_top_centre.gd (6), test_hud_notebook_layout.gd (8). Updated test_hud_timer_clock, test_hud_coins_position, test_hud_mission_page, test_hud_scaling. Ran test_hud_ (224 pass), test_pause (61), test_mission_page (26), test_practice (47), test_screen_flow (28), test_tutorial_flow (9), test_four_minute (24), test_gift_drops (56), all green. Docs updated: docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md. Screenshots in art-archive/T-611/screenshots/: start.png, editor_notebook.png, notebook_moved.png (fixtures game/tests/fixtures/t611_*.tscn).
