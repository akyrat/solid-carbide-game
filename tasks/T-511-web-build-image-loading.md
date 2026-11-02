---
id: T-511
title: Garage icons (and other images loaded from disk) missing in the web build
status: open
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, game/scripts/menu/garage_screen.gd, game/export_presets.cfg, game/tools/web_audio_check.mjs, docs/working-with-the-board.md]
files_expected_to_change: [game/scripts/menu/, game/scripts/level/building_towers.gd, game/tests/unit/, game/tools/]
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

The board, 2026-11-02, on the itch.io build: the garage shows no icons. Cause (the Project Lead's reading): game/scripts/menu/garage_screen.gd `icon_texture()` reads res://art/garage/<id>.png with ProjectSettings.globalize_path + FileAccess.file_exists + Image.load_from_file. In an exported build (the web build above all) the raw PNG is not in the pack, only its imported texture, so the file is never found and the grey placeholder shows. It works on the desktop from the project folder, which is why tests never caught it.

Fix the garage icons so they load in the exported build too (for example: load the imported texture with ResourceLoader.exists / load() and keep the raw-PNG and placeholder fallbacks for tests that point icon_dir elsewhere). Then check the other runtime image loads that use the same pattern and fix any that break in an export: game/scripts/menu/main_menu.gd (~line 119), game/scripts/menu/trick_list.gd (~line 430), game/scripts/level/building_towers.gd (~line 197). Leave save files, the level store, settings and the perf recorder alone (they read and write real files on purpose). Write a test that fails on today's code: for example a check that every image the game loads at runtime is loadable through ResourceLoader (as in an export), or a headless check against an exported pack. Verify in a real Web export: export the Web preset to a folder outside game/ and screenshot the garage in Chrome headless (game/tools/web_audio_check.mjs shows how to drive the web build), and the main menu and trick list if you changed them. The board asked for this in the next itch.io push, merged straight after QA. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-511 --text "..."`. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] In a Web export, the garage shows its real upgrade icons, not the grey placeholder (screenshot from the web build). (QA: pass / fail)
- [ ] A test fails on the old garage code and passes on the new: the garage's icons load the way an exported build loads them. (QA: pass / fail)
- [ ] main_menu.gd, trick_list.gd and building_towers.gd are each either fixed (with the same kind of test) or shown in the result notes to work in the web export (with how it was checked). (QA: pass / fail)
- [ ] The garage still works on the desktop and in the existing garage tests (the placeholder still shows for an id with no icon). (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] Screenshots of the garage from the web build (and of any other fixed screen), under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
