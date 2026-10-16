---
id: T-077
title: Play the MVP's sound effects in the game
status: done
from: project-lead
to: sfx
lead: Playtest
epic: sound
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-076, T-036, T-041, T-042, T-044, T-046]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/unfiled-game-details.md, tasks/T-076-mvp-sound-effects.md, tasks/T-036-run-scene-and-state.md, tasks/T-041-starting-gun.md, tasks/T-042-exhaust-flamethrower.md, tasks/T-044-minions.md, tasks/T-046-kaiju-meteor-attack.md, game/README.md]
files_expected_to_change: [audio code and scenes, tests, game/README.md]
model: sonnet
qa_rounds: 2
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Unblocked (2026-10-16):** T-076's sounds are approved by the board ("sfx looks good") and merged; the run, gun, flamethrower, minions and coins, and meteor attack are all in master. Use the recommended file per sound from T-076's result notes.

Play T-076's recommended sounds at their moments: the engine while driving (following the car's speed if that's simple), a drift sound while drifting, the gun firing, the flames while they're on, enemy hits, coin pickups, the meteor warning and impact. Keep volumes balanced, and add a CC BY credits list to `game/README.md`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test fires each moment (signal or function) and shows its sound plays (QA: pass)
- [ ] A test shows the drift and flame sounds stop when drifting stops (QA: pass)
- [ ] `game/README.md` lists where each sound plays and credits every CC BY sound (QA: pass)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest it before it is merged (board, 2026-10-16: "make a ticket to integrate it in the game, and I'll playtest it").

## Updates

### 2026-10-16, Open → In progress

Started: the SFX Agent puts the approved sounds into the game. You'll playtest it in C:\solid-carbide-worktrees\T-077.

### 2026-10-16, Needs playtest

QA passed (4 of 4). Ready for your playtest: open C:\solid-carbide-worktrees\T-077\game\project.godot. Volumes are in game\data\sfx.json.

### 2026-10-16, In progress

Adding an 'SFX volume' slider to the pause screen, 0 to 100, starting at 0 (silent), saved like the zoom. The SFX Agent is on it in this folder.

### 2026-10-16, In progress

SFX volume slider added (pause screen, beside the camera checkboxes, 0-100, starts at 0 = silent, saved). Play it again here; press Escape and turn the slider up to hear the sounds.

### 2026-10-16, In progress

The slider was squeezed into the checkbox row and can't be dragged. Sent back: its own row, exactly like the zoom slider. When it's in, this ticket moves to QA for your review.

### 2026-10-16, In progress → In QA

Fixed: the SFX volume slider has its own row under the zoom slider, same width, number at the end, and drags. Ready for you to play in C:\solid-carbide-worktrees\T-077\game\project.godot.

### 2026-10-16, Needs playtest → Done

You approved it; final QA passed. Merging.

## Result notes

Written by the SFX Agent. Built `game/scripts/run/run_sounds.gd` (child "Sounds" of the run scene, wired in `run.gd`) with all files, volumes and limits in `game/data/sfx.json`.

**Where each sound plays:** engine loops all run long (pitch 0.8 to 1.6 and volume -18 to -8 dB follow the car's speed); drift loops while the car drifts; gun once per volley (the file is a 5-shot burst); flames loop while the flamethrower is owned and its flames are on (drifting plus the linger); hit on every bullet hit and every flame hit (rate-limited); coin when the coin count goes up; meteor warning when the warning circles appear (starts part way into the 5.4 s file so the whistle ends as the meteor lands); meteor impact at each landing. Sounds pause with the tree (level-up, pause screen) and stop when the run ends or a new run starts. Looping wavs restart on `finished` (the ogg engine loops natively), so a faint gap at the wav loop point is possible.

**Tuning volumes:** `game/data/sfx.json`, `volume_db` per sound (engine uses `volume_db_min`/`volume_db_max` by speed). Starting values: engine -18..-8, drift -8, gun -10, flames -8, hit -8, coin -6, meteor warning -8, meteor impact -4. `min_interval` and `max_players` there stop bursts becoming noise. No code change needed to tune. To swap a candidate, change `file` (and add a CC BY credit in game/README.md if needed).

**How the board plays it:** open `C:\solid-carbide-worktrees\T-077\game\project.godot` (or Play on the ticket in the Builds tab). Drive (engine), drift (tyre sound; with the flamethrower, flames; set `flamethrower_at_start` in data/playtest.json or level up to get it), let the gun kill minions (gun and hit), pick up coins, and use `kaiju_early_arrival` in data/playtest.json to hear the meteors. The gun plays per volley, hits are one sound for bullets and flames: say if you want them different.

**Tests:** `game/tests/unit/run/test_run_sounds.gd`, 17 tests: each moment plays its sound, drift and flame sounds stop when their moment ends, engine follows speed and stops when the run ends, volumes come from the data file, every file in sfx.json has a CC0/CC BY record, new run silences. Full GUT suite passes (the earlier baseline was 671, plus these 17), `python -m pytest tools` 180 passed, `python -m pytest game/tools` 261 passed 1 skipped. Launched the game once with `--quit-after 300`: no script errors.

Documents updated: game/README.md (sound table and CC BY credit for "Falling.wav" by Augdog).
- 2026-10-16, in-progress → in-qa: Sounds hooked up in the run; volumes in game/data/sfx.json. Play from C:\solid-carbide-worktrees\T-077\game\project.godot

### QA round 1 (QA/Integration Agent, 2026-10-16)

- Criterion 1 (each moment plays its sound): pass. test_run_sounds.gd covers every moment.
- Criterion 2 (drift and flame sounds stop): pass. Tests cover both.
- Criterion 3 (README sound table and CC BY credit): pass. Credit for "Falling.wav" by Augdog at game/README.md line 147; volumes in game/data/sfx.json.
- Criterion 4 (full suites): pass. GUT 754/754 passing (68 scripts); pytest tools 180 passed; pytest game/tools 261 passed, 1 skipped. Game launched with --quit-after 300: no script errors.
- 2026-10-16, in-qa → needs-playtest: QA round 1 passed: all 4 criteria, GUT 754/754
- 2026-10-16, needs-playtest → in-progress: add a settings slider for the SFX volume. default it to 0.

### Board's tweak (2026-10-16)

- Board: "add a settings slider for the SFX volume. default it to 0." (0 means silent by default; decision in docs/hud-and-menus.md.) Added the pause screen's "SFX volume" slider (0 to 100, default 0, (first on the checkbox row, see the next line)), saved in user://settings.cfg (`audio`/`sfx_volume`, GameSettings) and applied at once to a new "SFX" audio bus that every sound plays on, on top of data/sfx.json's volumes (100 = those volumes). The sounds are silent until the slider is turned up (Escape, then the slider). Tests: tests/unit/test_sfx_volume.gd (8). Docs: docs/hud-and-menus.md (pause screen Content), game/README.md. Full GUT 770 passed, pytest tools 180, game/tools 261 (1 skipped); game launches with no errors.
- Board, after playing it: "it's horrible, it doesn't work... I was just expecting the slider in the same way that the zoom slider exists. And that's not what it is... I can't slide the slider, there's not enough room." Fixed: "SFX volume" now has its own row directly under the "Camera zoom level" row (above the checkboxes), laid out like it: label, a slider of the same width (both labels are `LABEL_WIDTH` 170 wide so the sliders line up) and the value as a number at the right end. The strip grows by that row, as the board decided (compact, only as tall as its content): the strip-height limits in `tests/unit/game/test_screen_flow.gd` went from 25% to 30% of the screen height and from 40% to 45% for the strip's bottom edge. New tests there: same width and own row, and a real mouse drag across the slider changes and saves the value. Screenshot of the pause screen with both sliders: C:\solid-carbide-worktrees\T-077\screenshots\T-077-pause-screen.png (looked at: both rows line up).
- 2026-10-16, in-progress → in-qa: Ready for the board's review (no QA agent; board, 2026-10-16): the SFX volume slider now has its own row like the zoom slider and can be dragged.

### Final QA (QA/Integration Agent, 2026-10-16)

- Criterion 1 (each moment plays its sound): pass. test_run_sounds.gd covers every moment (QA: pass).
- Criterion 2 (drift and flame sounds stop): pass (QA: pass).
- Criterion 3 (README sound table and CC BY credit): pass (QA: pass).
- Criterion 4 (full suites): pass with a caveat (QA: pass). GUT 771/772 (70 scripts): the one failure is `test_starting_gun.gd::test_new_run_from_the_main_menu_starts_with_the_base_gun` (base damage 2.1, expected 2.0); it fails the same way on master, because it reads the real saved `progress.json` (a garage upgrade), not because of this branch. pytest tools 180 passed; game/tools 261 passed, 1 skipped. Launch with `--quit-after 300`: no errors.
- Pause screen slider: "SFX volume" is on its own row (`SfxRow`) directly under the zoom row; both labels `LABEL_WIDTH` 170 so the sliders have the same width; range 0 to 100; default `DEFAULT_SFX_VOLUME` 0.0 when nothing is saved; value saved to `audio/sfx_volume` (pass).
- docs/hud-and-menus.md vs master: one added line, in the pause screen Content only (pass).
- Real settings file: no test writes it. `test_sfx_volume.gd` and `test_screen_flow.gd` set `GameSettings.path` to a `RunPaths.file(...)` test path; the real `settings.cfg` was byte-identical before and after the full suite (pass).
- 2026-10-16, in-qa → needs-playtest: Final QA passed; the board already approved it (LGTM).
- 2026-10-16, needs-playtest → done: Board's playtest (2026-10-16): LGTM. The 60 the board saw was a value saved in its settings file, not the default (0); the Project Lead cleared it.
