---
id: T-476
title: The browser build on itch.io plays no sound and no music
status: in-progress
from: project-lead
to: sfx
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, docs/working-with-the-board.md, game/export_presets.cfg, game/scripts/run/run_sounds.gd, game/scripts/game/music_player.gd, tools/publish_itch.py]
files_expected_to_change: [game/scripts/run/run_sounds.gd, game/scripts/game/music_player.gd, game/export_presets.cfg, game/tests/unit/, docs/working-with-the-board.md]
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

The board, 2026-11-01: the game on itch.io (the "Web" export preset, thread support off, Godot 4.6.2) plays no sound and no music at all; the desktop game has both.

Find the cause in a real browser: export the Web preset to a folder outside game/ (as `python tools/publish_itch.py --dry-run` does, never pushing), serve it locally over http (e.g. `python -m http.server`), open it in a browser (headless Chrome or Edge is fine), click into the game and start a run, and read the browser console for audio errors. Likely suspects to check, not conclusions: the browser's autoplay rule (audio only after a user gesture; does the game resume audio on the first click or key press?), Godot's web "sample" playback mode with threads off (what run_sounds.gd and music_player.gd do that it may not support: duplicated streams, looping, pitch, bus effects, mp3), the saved volume settings on a fresh browser, and whether the audio files are in the exported .pck.

Fix the cause so the browser build plays the music in the menus and the run's sound effects once the player has clicked or pressed a key, with no change to the desktop game's sound. Never push to itch.io (the Project Lead does it when the board asks). Never write, move or commit anything in game/data/levels/.

The board's review: after the Project Lead pushes the build, play it on itch.io and hear the music and the car.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes name the cause, with the browser console lines (or other evidence) that show it. (QA: pass / fail)
- [ ] In a local browser run of the Web export, after one click, the menu music plays and a run's engine sound plays: shown by console or log lines the agent adds (or the Web Audio state), listed in the result notes. (QA: pass / fail)
- [ ] A test (or the agent's scripted browser check, saved in game/tools/) covers the fix so it can be rerun. (QA: pass / fail)
- [ ] The desktop game's sound is unchanged: the existing sound tests still pass. (QA: pass / fail)
- [ ] docs/working-with-the-board.md ("Publishing to itch.io") notes anything about sound in the browser the board should know (for example, that sound starts after the first click). (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing is pushed to itch.io, and nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: the SFX Agent finds why the browser build is silent, in a local browser run.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
