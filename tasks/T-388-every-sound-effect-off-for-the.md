---
id: T-388
title: Every sound effect off for the MVP, with one switch; the music stays
status: in-qa
from: project-lead
to: sfx
lead: Goal-G-007
epic: sound
milestone: mvp
goal: G-007
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/docs/sound/sound-effects.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/sound/sound-effects.md, game/data/sfx.json, game/scripts/run/run_sounds.gd, game/scripts/ui/game_settings.gd, game/scripts/game/music_player.gd, game/tests/unit/run/test_run_sounds.gd, game/tests/unit/test_sfx_volume.gd, game/tests/unit/game/test_music.gd]
files_expected_to_change: [game/data/sfx.json, game/scripts/run/run_sounds.gd, game/scripts/ui/game_settings.gd, game/tests/unit/run/test_sfx_off.gd, game/docs/sound/sound-effects.md]
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

HUD and menus, Decisions, 'No sound effects in the MVP' (board, 2026-10-29): every sound effect is off for the MVP; the music stays; the sound code is kept. Add one switch in data or code (for example sfx_enabled: false in game/data/sfx.json, read where the SFX bus volume is applied) that turns every sound effect off whatever the saved SFX volume, for example by muting the SFX bus or not starting the players. Delete nothing: the sound-effect scripts, game/data/sfx.json and the saved SFX volume setting stay. The music keeps playing in the menu and during runs. Hiding the pause screen's SFX slider is a separate UI ticket.

The board's review: Play a run and check there are no sound effects and the music still plays.

## Acceptance criteria

- [ ] One switch (named in the result notes and the doc) turns every sound effect off; a test plays each sound effect id in game/data/sfx.json with the saved SFX volume at 100 and checks nothing is audible (the SFX bus is muted, or no player starts). (QA: pass / fail)
- [ ] The music player runs in the main menu and during a run, at the saved music volume; a test checks it. (QA: pass / fail)
- [ ] The sound-effect scripts, game/data/sfx.json and the saved SFX volume setting are all still present (git diff shows no deleted files), and the existing sound tests still pass or are updated to the switch. (QA: pass / fail)
- [ ] game/docs/sound/sound-effects.md records that the SFX are off for the MVP and how to turn them back on. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Goal runner (G-007): started, in C:\solid-carbide-worktrees\T-388.

### 2026-10-30, In progress → In QA

Goal runner (G-007): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

**The switch:** `"sfx_enabled": false` in `game/data/sfx.json`, read by `GameSettings.sfx_enabled()` (`game_settings.gd`). Off: `apply_sfx_volume` always mutes the SFX bus, and `RunSounds.play()` and loop starts (`_set_loop`) start no player. Missing key = on. Music untouched. Nothing deleted.

**Changes:** `sfx.json`, `game_settings.gd`, `run_sounds.gd`; new `tests/unit/run/test_sfx_off.gd` (7 tests: data switch off, bus muted at saved volume 100, every id in sfx.json does not start/play with volume 100, no loops in a run, switch on brings sounds back, music plays in menu and in a run at saved volume 65, nothing deleted). Older tests (`test_run_sounds`, `test_sfx_volume`, `test_music_volume_slider`, `test_music`) set the test hook `GameSettings.sfx_enabled_override = 1`. Doc: `game/docs/sound/sound-effects.md`.

**Tests:** GUT 1972/1972 passed (162 scripts); `python -m unittest discover -s game/tools` 675 tests OK (1 skipped); `python -m unittest discover -s tools` 573 tests OK.

**Screenshots:** none; audio-only change, nothing on screen.

**Refusals:** none.
