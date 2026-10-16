---
id: T-076
title: Find the MVP's sound effects
status: done
from: project-lead
to: sfx
lead: Playtest
epic: sound
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-004]
documents_affected: [docs/unfiled-game-details.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/unfiled-game-details.md, tasks/T-002-freesound-test-download.md, tasks/T-004-freesound-license-filter.md, game/README.md]
files_expected_to_change: [sound files under game/audio/ with their metadata, game/README.md]
model: sonnet
qa_rounds: 1
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

**Blocked until T-004 (the licence filter) is done,** so only CC0 and CC BY sounds come in.

The MVP has basic sound effects (Unfiled game details, Sound effects in the MVP). Find them on Freesound with the existing downloader: the engine, drifting, the gun firing, the flames, hits on enemies, picking up a coin, the kaiju's meteor warning and impact. Pick one or a few candidates per sound, with source and licence metadata next to each, and say which you recommend. Hooking them into the game is T-077.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] Every sound listed has at least one file under `game/audio/` with complete metadata (source page, author, licence) (QA: pass)
- [x] A script shows every downloaded sound's licence is CC0 or CC BY (QA: pass)
- [x] The result notes list the recommended file for each sound, and the credits CC BY needs (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: listen to the recommended sounds.

## Updates

### 2026-10-15, Needs playtest

Sound candidates are in: 2-3 per MVP sound (engine, drift, gun, flames, enemy hit, coin, meteor warning, meteor impact), 24 files, all CC0 or CC BY (checked by a script). Recommended set is in the result notes; only the meteor warning (Falling.wav by Augdog, CC BY 4.0) needs a credit. Nobody has listened yet: the agent picked by name, length and licence. QA round 1: all 4 pass. Waiting for the board to listen in the unified build; hooking them into the game is T-077.

### 2026-10-15, Needs playtest

The board will listen to the candidates and pick which to keep. Nothing plays in the game until T-077.

### 2026-10-16, Needs playtest → Done

You approved the sounds. Merging them; T-077 now puts them in the game for your playtest.

## Result notes

Written by the SFX Agent. Candidates only: I cannot listen, so recommendations rest on duration, name and licence (CC0 preferred); the board's listening decides.

**Live check of the T-004 filter:** the first live search (`"car engine loop"`, filter `license:("Creative Commons 0" OR "Attribution")`) returned results, so the quoted multi-word filter works. Every search returned results except "incoming missile whistle warning" (0 new), replaced by "falling whistle". One run hit Freesound's 30 requests/minute throttle (HTTP 429); waiting a minute fixed it. The worktree needed the git-ignored login copied from the main checkout's `.secrets/`.

Downloaded 24 files (2-3 per sound) to `game/audio/sfx/<sound>/` with JSON beside each; all load in Godot (`check_audio.sh`: 28 of 28 incl. the older test files). Licence check: `python game/tools/check_sfx_licenses.py game/audio --credits` -> 28 sounds, 0 problems (new script plus `test_check_sfx_licenses.py`).

**Recommended file per sound** (all paths under `game/audio/sfx/`):

| Sound | Recommended | Length | Licence | Alternatives |
|---|---|---|---|---|
| Engine | `engine/748027_sedan-engine-loop.ogg` | 17 s loop | CC0 | 369054 car-idle-ext-loop (4.3 s, CC0), 843123 |
| Drift | `drift/271337_car-peels-off.wav` | 3.2 s | CC0 | 538213 tires (CC BY 3.0), 426021 (has a crash in it) |
| Gun | `gun/854345_machine-gun-5-shot-burst.wav` | 0.6 s | CC0 | 342184 biggun, 165394 heavy-machine-gun (3.1 s) |
| Flames | `flames/831929_flamethrower.wav` | 1.0 s | CC0 | 472688 fire-burst (CC BY), 447941 |
| Hit on enemy | `hit/789388_bullet-impact-ground-subsonic-sfx.wav` | 0.9 s | CC0 | 719198, 812178 (CC BY, 6-7 s, need trimming) |
| Coin | `coin/347174_coin-pickup-sound-v-0.wav` | 0.5 s | CC0 | 341979, 538146 |
| Meteor warning | `meteor-warning/210205_falling.wav` | 5.4 s | CC BY 4.0 | 89538 and 89537 cartoon whistles (CC BY, mp3); no CC0 found |
| Meteor impact | `meteor-impact/869460_experimental-explosion-19.wav` | 2.3 s | CC0 | 869468 (6.2 s), 750822 (CC BY) |

Notes for T-077: whether the engine/drift/flames files loop cleanly and the hit/impact trims need listening; the bullet-impact "hit" is named "ground", so a body-hit alternative is 719198/812178.

**Credits needed if the recommended set ships:** only "Falling.wav" by Augdog (https://freesound.org/people/Augdog/sounds/210205/), CC BY 4.0. Other CC BY candidates (credit only if used): "Tires.wav" by oldestmillennial (538213, CC BY 3.0); "Fire Burst.wav" by SilverIllusionist (472688); "SFX_Impact_Bullet_Hit_Body_1" by PoundSoundUK (719198); "Sub Sonic Bullet Body Hit" by PotaterSalad (812178); "custom_short_explosion_impact_sound" by Artninja (750822); "Cartoon falling whistle" and "vers.2" by CGEffex (89538, 89537), all CC BY 4.0 unless noted.

Tests: GUT 671 passed; all Python tool tests pass (game/tools test_freesound 29, test_check_sfx_licenses 4, tools/test_*.py). Documents updated: docs/unfiled-game-details.md, game/README.md.
- 2026-10-15, in-qa → needs-playtest: QA round 1 pass. 24 new sounds with JSON metadata; check_sfx_licenses.py 28 sounds 0 problems; recommendations and CC BY credit (Falling.wav, Augdog) present; GUT 671/671, Python tests OK. No secrets: .secrets/ git-ignored, only .env.example tracked, no key strings in diff.
- 2026-10-16, needs-playtest → done: Board (2026-10-16): sfx looks good; the recommended file per sound goes into the game in T-077.
