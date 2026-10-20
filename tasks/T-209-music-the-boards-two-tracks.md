---
id: T-209
title: "Music: the board's two tracks loop through the game, alternating"
status: in-qa
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

- [ ] Both tracks are in `game/audio/music/`, byte-identical to the board's files, and their source is recorded (QA: pass, byte-identical to the board's files, source .json next to each)
- [ ] A test shows the music player plays track 1, then track 2, then track 1 again, and that one player is kept across screen changes (QA: pass, test_plays_track_1_then_2_then_1_again and test_one_player_kept_across_screen_changes)
- [ ] The music keeps playing without restarting from the main menu into a run, through the pause screen and back to the menu (checked in a scripted run that reads the playback position before and after each change) (QA: pass, test_keeps_playing_without_restarting_through_menu_run_pause_menu reads the position at each step)
- [ ] The music's volume is separate from the sound effects': a `game_settings.gd` setting from 0 to 100 changes the music only, and is saved and loaded like the SFX volume; tests cover it (QA: pass, separate Music bus; save/load/clamp and SFX-untouched tests)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass, GUT 1136/1136; Python tools 399 OK; game/tools 355 OK (1 skipped))

The board's review: listen to the music from the main menu into a run and back.
Board review files: the main menu.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-20, Open → In progress

Started: the agent is working in its own folder, C:\solid-carbide-worktrees$t, in parallel with the others.

### 2026-10-20, In progress → In QA

Built: both tracks play through the game, 1 then 2, never restarting between screens, on their own Music bus (starting volume 40, a proposal). Sent to QA.

## Result notes

Written by the agent when it finishes.

- Both tracks copied byte-identical (checked with cmp) to `game/audio/music/demo_beat_1.mp3` and `demo_beat_2.mp3`; source and original file names in the `.json` next to each ("made by the board, for this game").
- `game/scripts/game/music_player.gd` (`MusicPlayer`): one `AudioStreamPlayer`, process mode Always, a child of the game flow (`GameFlow.music`), so it outlives menu, run, garage and pause. When a track ends it starts the other (1, 2, 1, ...).
- Own bus "Music"; setting `GameSettings.load_music_volume()` / `save_music_volume()` / `apply_music_volume()`, key `music_volume` in section `audio`, 0 to 100, saved like the SFX volume. T-210's slider calls these.
- Starting value proposal: **40** (a gain of 0.4, about -8 dB). Why: the SFX default is silent and the board turns it up, but music should be heard on first launch; 40 leaves headroom under the engine and weapon sounds, and I could not judge the mp3s' loudness here, so the board tunes it by ear in the playtest.
- `check_sfx_licenses.py` skips the `music` folder (the board's own work has no Freesound license); test added.
- Tests: `game/tests/unit/game/test_music.gd` (order 1, 2, 1; one player kept; playback position through menu, run, pause, menu; setting range and save; separate bus). The `test_screen_flow.gd` helper now ignores the music node.
- Results: GUT 1136/1136 passed; tools unittest 399 OK; game/tools unittest 355 OK (1 skipped).
- Documents updated: `docs/game-loop-architecture.md`, `game/README.md`.
