---
id: T-209
title: "Music: the board's two tracks loop through the game, alternating"
status: open
from: project-lead
to: sfx
lead: Coursework
epic: sound
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, game/README.md, game/scripts/run/run_sounds.gd, game/scripts/ui/game_settings.gd, game/project.godot]
files_expected_to_change: [game/audio/music/, game/scripts/, game/project.godot, game/default_bus_layout.tres, game/tests/unit/, game/README.md]
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

The board made two tracks for the game (Game loop architecture, Decisions, "Music", 2026-10-20). Copy them unchanged from the board's Downloads folder into `game/audio/music/`, renamed to plain file names (for example `demo_beat_1.mp3` and `demo_beat_2.mp3`):

- `C:\Users\andre\Downloads\DEMO BEAT 1 (ANDY GAME).mp3`
- `C:\Users\andre\Downloads\DEMO BEAT 2 (ANDY GAME).mp3`

Record their source where the sounds' sources are recorded: made by the board, for this game, with the original file names.

Make them play through the whole game, from the main menu on, without stopping or restarting when the screen changes (menu, run, garage, pause): track 1, then track 2, then track 1 again, and so on. Pausing the game doesn't stop the music.

Give the music its own volume, separate from the sound effects (for example its own audio bus). Add a setting in `game_settings.gd` from 0 to 100, which T-210's slider will set, saved and loaded like the SFX volume. Until then the music plays at a starting value you propose for the playtest; write it in the result notes and say why. Don't change any sound effect.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] Both tracks are in `game/audio/music/`, byte-identical to the board's files, and their source is recorded (QA: pass / fail)
- [ ] A test shows the music player plays track 1, then track 2, then track 1 again, and that one player is kept across screen changes (QA: pass / fail)
- [ ] The music keeps playing without restarting from the main menu into a run, through the pause screen and back to the menu (checked in a scripted run that reads the playback position before and after each change) (QA: pass / fail)
- [ ] The music's volume is separate from the sound effects': a `game_settings.gd` setting from 0 to 100 changes the music only, and is saved and loaded like the SFX volume; tests cover it (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: listen to the music from the main menu into a run and back.
Board review files: the main menu.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
