---
id: T-077
title: Play the MVP's sound effects in the game
status: in-qa
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
qa_rounds: 0
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

- [ ] A test fires each moment (signal or function) and shows its sound plays (QA: pass / fail)
- [ ] A test shows the drift and flame sounds stop when drifting stops (QA: pass / fail)
- [ ] `game/README.md` lists where each sound plays and credits every CC BY sound (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-16: "make a ticket to integrate it in the game, and I'll playtest it").

## Updates

### 2026-10-16, Open → In progress

Started: the SFX Agent puts the approved sounds into the game. You'll playtest it in C:\solid-carbide-worktrees\T-077.

## Result notes

Written by the SFX Agent. Built `game/scripts/run/run_sounds.gd` (child "Sounds" of the run scene, wired in `run.gd`) with all files, volumes and limits in `game/data/sfx.json`.

**Where each sound plays:** engine loops all run long (pitch 0.8 to 1.6 and volume -18 to -8 dB follow the car's speed); drift loops while the car drifts; gun once per volley (the file is a 5-shot burst); flames loop while the flamethrower is owned and its flames are on (drifting plus the linger); hit on every bullet hit and every flame hit (rate-limited); coin when the coin count goes up; meteor warning when the warning circles appear (starts part way into the 5.4 s file so the whistle ends as the meteor lands); meteor impact at each landing. Sounds pause with the tree (level-up, pause screen) and stop when the run ends or a new run starts. Looping wavs restart on `finished` (the ogg engine loops natively), so a faint gap at the wav loop point is possible.

**Tuning volumes:** `game/data/sfx.json`, `volume_db` per sound (engine uses `volume_db_min`/`volume_db_max` by speed). Starting values: engine -18..-8, drift -8, gun -10, flames -8, hit -8, coin -6, meteor warning -8, meteor impact -4. `min_interval` and `max_players` there stop bursts becoming noise. No code change needed to tune. To swap a candidate, change `file` (and add a CC BY credit in game/README.md if needed).

**How the board plays it:** open `C:\solid-carbide-worktrees\T-077\game\project.godot` (or Play on the ticket in the Builds tab). Drive (engine), drift (tyre sound; with the flamethrower, flames; set `flamethrower_at_start` in data/playtest.json or level up to get it), let the gun kill minions (gun and hit), pick up coins, and use `kaiju_early_arrival` in data/playtest.json to hear the meteors. The gun plays per volley, hits are one sound for bullets and flames: say if you want them different.

**Tests:** `game/tests/unit/run/test_run_sounds.gd`, 17 tests: each moment plays its sound, drift and flame sounds stop when their moment ends, engine follows speed and stops when the run ends, volumes come from the data file, every file in sfx.json has a CC0/CC BY record, new run silences. Full GUT suite passes (the earlier baseline was 671, plus these 17), `python -m pytest tools` 180 passed, `python -m pytest game/tools` 261 passed 1 skipped. Launched the game once with `--quit-after 300`: no script errors.

Documents updated: game/README.md (sound table and CC BY credit for "Falling.wav" by Augdog).
- 2026-10-16, in-progress → in-qa: Sounds hooked up in the run; volumes in game/data/sfx.json. Play from C:\solid-carbide-worktrees\T-077\game\project.godot
