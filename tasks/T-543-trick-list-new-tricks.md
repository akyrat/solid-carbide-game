---
id: T-543
title: The trick list shows REVERSE DRIFT!, AURA FARMING! and GRIND!
status: done
from: project-lead
to: ui
lead: Rails
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: [T-541]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, docs/drifting.md, game/data/trick_recipes.json, game/scripts/menu/trick_list.gd]
files_expected_to_change: [game/data/trick_recipes.json, game/data/tutorial_text.json, game/art/tutorial/clips/, game/tools/, game/tests/, game/docs/hud-and-menus/, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 1
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

Build HUD and menus, Decisions, "The trick list shows the new tricks". Add the three tricks of 2026-11-05 to the trick list (pause screen's Trick list and the tutorial's trick slide, wherever the same list is shown), in the same form as the seven there: each with its line and keycap recipe exactly as T-533 wrote them (docs/hud-and-menus.md Content, T-533; reverse drift: S + A/D held, aura: no keys, stand still, grind: Jump onto a rail), in game/data/trick_recipes.json and the texts in game/data/tutorial_text.json, and a recorded clip of each (game/art/tutorial/clips/<clip>_sheet.png), recorded from the real game the way the existing clips were (see how T-491's clips were made). The grind clip shows a car landing on a rail on master's map (T-541's rails). Propose the order of the list (for example the ground tricks, then the air tricks, then the grind) and keep the list fitting on screen at 1280x720.

The board's review: open the pause screen's Trick list and the tutorial's trick slide in the ticket's folder, C:\solid-carbide-worktrees\T-543\game\project.godot.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] trick_recipes.json has entries for reverse_drift, aura and rail_grind (or the ids the trick detector uses), each with a clip and steps, and the texts match T-533's exactly (test). (QA: pass: entries and T-533's texts present, tests green)
- [ ] The trick list shows ten tricks with their clips, and still fits inside the window at 1280x720 (test or screenshot). (QA: pass: ten rows in two columns, test checks the panel inside 1280x720; screenshot at 1152x648 shows nothing cut off)
- [ ] The three new clip sheets exist and were recorded from the game, with the recording method in the result notes. (QA: pass: three sheets exist, method in the result notes; frames show reverse drift, aura popup, rail grind)
- [ ] docs/hud-and-menus.md Content describes the new rows. (QA: pass: new section and rows in docs/hud-and-menus.md)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass: qa_check test sets pass)
- [ ] Screenshots in art-archive/T-543/screenshots/ show the trick list with the three new rows, in the pause screen and in the tutorial. (QA: pass: pause screenshots show the three rows; tutorial slide 2 verified to hold no trick list, so none needed)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-06, Open → In progress

Started: the agent is working in C:\solid-carbide-worktrees\T-543.

### 2026-11-06, In progress → In QA

Built: the trick list has 10 rows in two columns, with clips of the three new tricks recorded from the game. QA is checking it.

### 2026-11-06, In QA → Needs playtest

QA passed. Play it from C:\solid-carbide-worktrees\T-543\game\project.godot: pause, Trick list.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done (agent, sonnet). The trick list has ten rows with REVERSE DRIFT!, AURA FARMING! and GRIND!, each with its keycap recipe and a clip recorded from the real game.

What changed
- `game/data/trick_recipes.json`: `reverse_drift` (keys S + A, /D tag on A), `aura` (one step, badge), `rail_grind` (one step, badge); ids are the detector's. `game/data/tutorial_text.json`: `trick.*`, `trick_rule.*` and `trick_recipe.*` with T-533's texts word for word (test checks them against the strings).
- Order (a proposal): LONG DRIFT!, FULL 360!, ALT DRIFT!, REVERSE DRIFT!, AURA FARMING! (ground), AIR 180!, AIR 360!, HANG TIME! (air), GRIND!, THREAD THE NEEDLE!.
- Fit: ten rows in one column would not fit under the pause strip's top line, so `trick_list.gd` stands them in two columns of five (`LIST_COLUMNS`, `ROW_WIDTH` 262, `DETAIL_WIDTH` 564). The panel is inside the window at 1152 x 648 and 1280 x 720 (tests).
- Pictures: the rows need 64 x 48 pictures; script-drawn with `game/tools/build_trick_illustrations.py` (3 new drawers, no PixelLab, 0 generations) into `game/art/tutorial/tricks/`; originals in `art-archive/T-543/script/`. They are placeholders-in-style for the playtest, for the board's eye.
- The tutorial's slide 2 does not show the trick list (it shows three clips), so there was nothing to change there; the list is only in the pause screen. A screenshot of slide 2 is included for the record.
- Docs: `docs/hud-and-menus.md` (the list's description, new section "The trick list's new rows (T-543)", trick names row), `game/docs/hud-and-menus/pause-screen.md`, `game/docs/driving/tricks.md` (a line for `rail_grind`, which its own test needs).

Recording method (the clips are from the real game, the way T-483/T-490 were made)
`python game/tools/record_tutorial_clips.py --only reverse_drift aura rail_grind` (Godot movie maker, 50 physics steps per second, every 3rd/5th/4th kept, 480 x 320 crop, shared palette, sheets via gif_to_sheet). It checks the detector fired the trick and not unwanted ones (`EXPECT`). Fixtures: `tutorial_clip_reverse_drift.tscn` and `tutorial_clip_aura.tscn` (the demo script with new exports `show_popups` and `quit_at_step`: the real car from a standstill, S + A held; the reverse clip ends before the drift ends so LONG DRIFT! does not pay in it; the aura clip stands still about 7 s with popups left on, AURA FARMING! paid at 6 s and 7 s) and `tutorial_clip_rail_grind.tscn` (new script: a run on master's map from the main menu, T-541's rails, HUD and popups hidden, no minions or kaiju, Jump tier 1, W held, one Jump onto rail-3, a grind of 1.6 s, Jump off; GRIND! paid). Records: reverse_drift 28 frames 368 KB, aura 74 frames 33 KB, rail_grind 34 frames 925 KB (all under 1.5 MB). Takes copied to `art-archive/T-543/takes/` (not committed).
Note: a fresh worktree needs `godot --headless --import` once before the recorder (class cache), else the movie run hangs.

Tests run (foreground)
- Godot, with `bash game/tools/run_tests.sh -gselect=<file>`: test_trick_list_recipes 12/12, test_trick_list 18/18 (with the file's own), test_pause_trick_list 9/9, test_tutorial_clips 7/7, test_tutorial_slides 26/26. New tests: the three tricks' texts, recipes, clips and pictures; the order; ten rows; the panel inside 1280 x 720 for every trick.
- Python: `unittest` on test_record_tutorial_clips, test_build_trick_illustrations, test_check_sprite_rules, test_text_inventory: 35 OK (the illustration tests' style rules pass for the new pictures).

Screenshots (art-archive/T-543/screenshots/): pause_trick_list_reverse_drift.png, pause_trick_list_aura.png, pause_trick_list_rail_grind.png (pause screen, 1152 x 648, ten rows, the three new rows selected), tutorial_slide2.png (the tutorial, unchanged), clip_frames.png (four frames of each new clip), illustrations_x6.png (the three pictures enlarged).

For the playtest: the order and two-column layout; the aura clip shows the popup (the others show none); the rail clip's car is seen from its rail run on the map; Open the pause screen's Trick list in C:\solid-carbide-worktrees\T-543\game\project.godot.
Not committed: Godot's .uid and .import noise.

QA round 1: all six criteria pass; qa_check all pass (2 test sets, tools skipped). Screenshots seen: pause list shows ten rows in two columns of five, GRIND! selected with its clip, nothing cut off at 1152x648 (the 1280x720 fit is test-checked); clip_frames shows reverse-drift skid, AURA FARMING! popup on a still car, rail grind sparks with GRIND! popup. Slide 2 claim verified: tutorial_slides.gd shows one trick picture, no list. Minor: rail clip frames show HANG TIME!/GRIND! popups although the notes say popups are hidden there.
- 2026-11-06, needs-playtest → done: The board: trick list lgtm, merge it.
