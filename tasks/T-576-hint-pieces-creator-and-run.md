---
id: T-576
title: Hint pieces in the level creator and in runs (placeholder art)
status: in-progress
from: project-lead
to: level-challenge
lead: Rails
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-575]
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/docs/level/practice-playground.md, game/scripts/level_creator/editor.gd, game/scripts/level_creator/level_document.gd, game/scripts/level/mvp_map.gd]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/data/level/, game/tools/check_level.py, game/tools/, game/tests/, game/docs/level/, docs/level-design.md]
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

Build Level design, Decisions, "Hint pieces in the level creator", with placeholder art drawn by script (T-577 swaps in the PixelLab art): (1) the creator's side panel gets a hints category (labels from T-575) with five pieces: gas (W keycap), brake (S keycap), straight arrow, curved arrow (left or right, by Mirror), circular arrow (either direction, by Mirror); each placed either painted on the ground or as a standing sign (a toggle, labels from T-575); R steps the direction through the 8 directions for both kinds. (2) Placing, moving and deleting them like other pieces; they are saved in the level file (a new key, kept by older files and by check_level.py, which checks them) and load again. (3) In a run (and the practice playground, which uses the same map code), ground hints are drawn flat on the ground in their direction, under the car, minions and buildings, with no collision; signs stand upright, sorted with props, and block the car like a prop. The icons are made top-down and laid flat on the isometric ground by the engine, so one image per icon serves all 8 directions; the sign is one piece with the icon put on its face by script. Define the art's file names, sizes and where the engine reads them, so T-577 can drop the PixelLab files in; the placeholders follow the same names. Give a test level in the result notes for the board to try (in a temporary folder, never game/data/levels/).

The board's review: play it from C:\solid-carbide-worktrees\T-576: open the level creator (`"C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" --path "C:\solid-carbide-worktrees\T-576\game" res://scenes/level_creator/level_creator.tscn`), place each hint both ways and in several directions, save, press Play.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (the board's own levels). Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The creator offers the five hints, each as a ground decal or a sign, with Mirror for the arrows and R through 8 directions (tests). (QA: pass / fail)
- [ ] Hints are saved, load again, and check_level.py accepts a level with them and refuses a bad one (tests). (QA: pass / fail)
- [ ] In a run, ground hints draw flat under the car with no collision, and signs stand and block the car (tests). (QA: pass / fail)
- [ ] Levels saved before load and play as before (tests). (QA: pass / fail)
- [ ] The art's file names and sizes are in game/docs/level/ for T-577, and docs/level-design.md Content describes the pieces. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-576/screenshots/ show the creator with hints of both kinds and a run with them. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: Level Design builds the hint pieces with placeholder art.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Level/Challenge Design Agent, 2026-11-08. Built Level design, Decisions, "Hint pieces in the level creator" with script-drawn placeholder art.

What was built:
- Data: game/data/level/hints.json (icons, the 8 headings, the ground and sign settings: footprints, sizes, the sign's face and anchor, collision). Catalogue: build_creator_assets.py writes hint-<icon>-ground / hint-<icon>-sign (kind hint) and one family per icon in a new group "hints" (label group_hints), the two modes on the family's height axis.
- Creator (editor.gd, asset_panel.gd, level_document.gd): the Driver hints group with the five buttons; top bar On the ground / Roadside sign (set_hint_mode; H does not change the mode); R steps the 8 headings clockwise on screen from 270; M mirrors only the curved and circular arrows; the strip shows hint_ground_hint or hint_sign_hint, plus hint_mirror_hint for the two arrows. Placed through the same path as every piece (place_asset -> LevelSnapping.placement -> LevelDocument.place), so T-581's free placement applies to them unchanged. snapping.gd: one token (cuts_object_problem also counts hints). Selected with a click, Del deletes, preview drawn exactly as the map draws it.
- Level file: new key "hints": {id, icon, mode, heading, mirror, x, y, w, h}. No key is written for a level without hints. check_level.py checks it (check_hints) and keeps a sign off the spawn.
- Run (scripts/level/level_hints.gd, called from mvp_map.gd _build, so the run, the creator and the practice playground share it): ground hints are drawn by one node, map.hint_decals, right over the ground (flat pixels; view_root's iso projection lays them on the ground), under buildings, rooftops, props, car and minions, no body. Signs are LevelProps.PropSprite in map.prop_sprites (depth-sorted with props), the icon a child sprite turned to the heading as seen on screen, plus a StaticBody2D circle (r 0.5) in map.prop_bodies on layer 1, 3 units tall: the car crashes into it like a prop, and enemies path round it (LevelProps.obstacles / blocks_spot). LevelSpawn.problem refuses the start on a sign.
- Art for T-577: game/docs/level/hint-pieces.md. Five icons game/art/hints/hint_{gas,brake,arrow_straight,arrow_curved,arrow_circular}.png, 64 x 64, top-down, pointing up the picture (curved turns right, circular clockwise). Sign game/art/hints/hint_sign.png, 64 x 96, post foot at (32, 95), icon face 8,8 48x48, drawn at 0.5. Placeholders: game/tools/build_hint_placeholders.py (--check checks sizes).

Proposals for the playtest: a ground hint is 4 x 4 units (a road's width) and only on the street (like a crater). A sign is 2 x 2 cell, 2 units wide and 3 tall, on the street or a rooftop. On a sign every icon, the keycaps too, is turned to the heading as seen on screen. The run's tyre marks are drawn under the painted hints (run.gd puts them right after the ground tiles; not changed).

Test level for the board: C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/t576_hint_test/hint_test_level.json (10 hints on a road, check_level OK). The creator only lists game/data/levels/, so to open it there the board copies it in itself; or just place hints in a new level as the review line says. Made by game/tools/hint_shots.gd.

Screenshots: art-archive/T-576/screenshots/creator_hints.png (Driver hints group, ground hints and signs, a Turn arrow sign's preview), creator_ground_preview.png, run_hints.png (car over the painted gas hint, signs standing).

Tests: new game/tests/unit/level_creator/test_creator_hints.gd (15 pass), TestCheckHints in game/tools/test_check_level.py and HintTest in game/tools/test_build_creator_assets.py. Updated counts and groups in test_creator_families.gd, test_editor_place_delete.gd, test_creator_assets.gd, test_build_creator_assets.py. Full Godot set: 3071 tests, 3070 passing, 0 failing, TESTS PASSED. Game tools set: 1054 tests, OK (4 skipped). (The Godot run was moved to the background by the harness after 180 s; I waited for it to finish and nothing is left running.)

Documents affected: docs/level-design.md (Content, "Level creator: hint pieces"), game/docs/level/hint-pieces.md (new).
