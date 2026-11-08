---
id: T-574
title: Quick tuning: the drift tutorial slides, with the board
status: in-progress
from: project-lead
to: ui
lead: Rails
epic: ui
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/working-with-the-board.md, game/docs/hud-and-menus/tutorial-slides.md, game/scripts/menu/tutorial_slides.gd, tasks/T-561-practice-session.md, tasks/T-562-interactive-tutorial-slides.md, tasks/T-565-drift-seconds-running-totals.md]
files_expected_to_change: [game/scripts/menu/, game/scripts/run/, game/scripts/hud/, game/scenes/, game/data/, game/tests/, game/docs/, docs/hud-and-menus.md]
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

Quick tuning with the board (docs/working-with-the-board.md, "How the board builds the game", quick tuning): the board works at a game designer's level on the tutorial's drift slides (the drift and the alt drift practice), changing both the slides' layout and how the practice plays. The Project Lead passes on the board's tweaks word for word; each tweak goes in straight away in this folder so the board plays it at once, and each is written in the result notes. The board decided there is no QA round for this ticket (board, 2026-11-08): when the board says it is done, it goes to the board's review and then merges. Keep the existing tests passing and add or update tests for what you change; the merge runs the full test sets. New player-facing text follows the board's own wording when it gives one; otherwise propose it and say so. Record each settled tweak as a decision in docs/hud-and-menus.md (or the doc it belongs to) when the board says it is done.

The board's review: play it from C:\solid-carbide-worktrees\T-574\game\project.godot after each tweak.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."`, one entry per tweak, and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. No PixelLab calls. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each of the board's tweaks is in and written in the result notes. (QA: pass / fail)
- [ ] The test sets pass at the merge. (QA: pass / fail)
- [ ] The docs describe the settled result. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Quick tuning folder ready; waiting for the board's first tweak.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Tweak 1 (board: "make the practice window span from side to side keeping the same height, and put the totiral text in the game"): on all four trick slides (they share one layout: drift, alt drift, air spins, grind) the practice window now spans the content width, 1050 x 400 at (115, 214), between the arrows (tutorial_slides.gd WINDOW_POS, WINDOW_SIZE). The tutorial text, meaning the instruction (and the grind's Jump hint), is no longer beside the window: it sits in the game, centred on a dark band (60% opacity, CAPTION_BAND_ALPHA) along the window's bottom edge, size 30 with a dark outline. The band ignores the mouse and stays clear of the notebook (top left) and the success message (centre). The headline stays above the window. A wider window shows more of the playground, because the camera zoom follows the height. Tests: test_tutorial_slides.gd now checks the side-to-side span at the same height and the text inside the window (the 'only a bit bigger' test was replaced); test_tutorial* 69/69 pass. Screenshots: art-archive/T-574/screenshots/tweak1_slide2.png and tweak1_slide3.png. Commit 10705308.

Tweak 2 (the board's practice playground): the tutorial now loads the board's layout. Its content was copied from game/data/levels/practice_playground.json (read only) into game/data/level/practice_playground.json, keeping ground_style (the purple grid) and the four start points; task is T-574 and the spawn is the board's (-7, -1). Start points: drift (-45, -19), alt_drift (-45, 19) and grind (-29, 1) are unchanged. air_spin moved from (-55, 1) to (-44, 22), facing east, because driving east from the old point met no ramp and ran into a parked car at x 18; from the new point the car goes straight into the jump ramp ramp-7 at full speed, with about 1.6 s of air, and AIR 360! with A held (the old ramp gave 1.8 s). Grind: a Jump hop from the grind start catches rail-40 from anywhere up to x -24. Drift and alt drift both still reach their goal in the scripted drives, but the long arc bumps cones and barriers (prop-11, prop-14, prop-16, prop-17), so the open space is smaller than before. tools/build_practice_playground.py is retired: it writes nothing and exits 1 with a message (one accidental run before the guard was in place rewrote the old file; it was re-copied from the board's file straight away). check_level.py and check_height_data.py print OK. Tests updated: test_practice_playground.gd (drives to the new ramp and rails, the builder retired), test_practice_session.gd (_drive_east hops for the grind), and the practice_session_demo.gd fixture. test_practice* 35/35, test_tutorial* 69/69, check-tool pytest 74/74 pass. game/docs/level/practice-playground.md updated. Screenshots: art-archive/T-574/screenshots/tweak2_*.png. Commit bd33dc50.
