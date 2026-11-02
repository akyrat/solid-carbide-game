---
id: T-498
title: Bricks tier 8: the widest wave with two extra crash rings
status: in-qa
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/scripts/weapons/bricks.gd, game/data/weapons.json]
files_expected_to_change: [game/data/weapons.json, game/scripts/weapons/bricks.gd, game/scripts/data/weapon_data.gd, game/art/weapons/, game/tools/, game/tests/unit/, docs/weapons.md, game/docs/weapons/]
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

The board, 2026-11-02 (docs/weapons.md, Decisions, "The board's own upgrade trees"): Bricks tier 8 (Widest Wave) multiplies the wave's radius by 3 on top of the earlier tiers (4 x1.4 x1.5 x3, about 25 units) and is a new wave: 2 extra outer crash rings around the usual one, and the wave travels from the inner ring out to the outer ones, for a sense of huge impact. Each ring hits enemies (damage and minion knockback, never pushing the kaiju) as the wave reaches it, once per enemy per landing. The board's note: "Effectively, this will be a new animation, where we add 2 extra outer layer crash circles around the existing one, massively increasing the width (probably gonna be 3 times bigger). I want the animation to look like a wave coming from the inner to the outer circles to give sense of huge impact." Add the tier to weapons.json (a new effect for this tier, your choice of name, with value 3) and draw the art the same way as T-325's wave sheets (script-drawn, no PixelLab); the radii the new tiers 2 and 5 reach get their sheets too, so no radius falls back to the placeholder ring. Mind T-481's frame-time work on bricks: the big wave must not bring back frame drops (measure the landing frame time headless and write it in the result notes). Ring timing is a proposal for the playtest. Describe it in docs/weapons.md Content (Bricks) and game/docs/weapons/. Never write, move or commit anything in game/data/levels/. SFX stay off.

The board's review: play the new weapon trees in one build with T-495 to T-499 together (levelling each weapon to tier 8 with the playtest switches), from this ticket's folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] weapons.json bricks has tier 8 with the new effect and value 3, and bricks reaches tier 8 in the level-up offers; the tier 8 card is T-495's text. (QA: pass / fail)
- [ ] A unit test: at tier 8 the wave's radius is 3 times the tier 7 radius. (QA: pass / fail)
- [ ] A unit test: an enemy near the outer edge is hit later than one near the car (when the wave reaches its ring), every enemy in reach is hit exactly once per landing, and the kaiju is damaged but never pushed. (QA: pass / fail)
- [ ] Every radius the bricks tiers reach (tiers 1 to 8) has a wave sheet in game/art/weapons/ (no placeholder ring), and the tier 8 sheet shows 3 rings drawn inner to outer. (QA: pass / fail)
- [ ] The landing frame time at tier 8, measured headless, is in the result notes. (QA: pass / fail)
- [ ] docs/weapons.md (Bricks) describes tier 8. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] Screenshots or a frame strip of the tier 8 wave, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started on top of T-495 and T-496 (built on their branch).

### 2026-11-02, In progress → In QA

Bricks tier 8 built: radius 25.2 in three crash rings travelling out (hits at 0, 0.5, 0.65 s, each enemy once), script-drawn sheet, tests pass; ready for QA.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

**Weapon Behavior Agent, 2026-11-02: done, ready for QA.**

What was built (tier 8, Widest Wave):
- Data (`game/data/weapons.json`, bricks): `max_tier` 8, tier 8 `{ "effect": "widest_wave", "value": 3 }` (the radius x3 and the wave becomes 3 rings, at the tier 7 radius x1, x2, x3: 8.4, 16.8, 25.2), and `ring_interval` 0.15 (my proposal for the playtest). `WeaponData.bricks_at()` returns `rings` and `ring_interval` too.
- Hits (`game/scripts/weapons/bricks.gd`): the inner ring hits on the landing as every tier does; ring 2 hits 0.5 s after the landing and ring 3 0.65 s after (`BricksWave.RING_SECONDS` + (k - 1) x `ring_interval`), the moments the drawn wave reaches them. Each ring hits the enemies then within its radius that no ring of this landing has hit (one shared set per landing): every enemy once per landing, the tier's damage, minions pushed away, the kaiju damaged and never pushed. New signal `ring_hit(centre, ring, count)`. A new run drops rings still to come.
- Art: `game/art/weapons/bricks_wave_r25_2.png` + `.json`, drawn by the free script `game/tools/build_bricks_wave.py` (no PixelLab). Ring 1 is the tier 7 wave pixel for pixel; ring 2 sets off from 8.4 when ring 1 gets there and races to 16.8 in 3 frames, ring 3 from 16.8 to 25.2 likewise; each crumbles for 5 frames, each with its own dust and brick chips. 18 frames, 0.9 s. At 0.55 s all three show at once. A one-row sheet would be about 41 000 px wide and 130 MB in memory, so the sheet keeps only the 16 px strips that hold pixels in a 4096 x 928 atlas (about 15 MB in memory, less than the 8.4 sheet's 16.6 MB), and the record lists each frame's strips; the game draws them strip by strip (at most about 550 rects, one texture, only when the frame changes).
- The script's drawing loops now walk only the ring's band and the drawn pixels; the 4.0, 5.6 and 8.4 sheets rebuild byte for byte the same (checked), and building twice gives the same tier 8 files (checked). The radii tiers 2 and 5 reach (5.6 and 8.4) already had sheets from T-496, so every tier 1 to 8 radius has a sheet and none falls back to the placeholder.
- Docs: `docs/weapons.md` (Content, Bricks: a "Tier 8, Widest Wave" bullet, the Look and Tiers bullets, and the level-up line), `game/docs/weapons/bricks.md` (new section "Tier 8: the widest wave"). Stale "Bricks 7 until T-498" comments fixed in `weapon_data.gd`, `weapon.gd`, `level_up_offers.gd`.

**Landing frame time, headless** (`game/tests/unit/weapons/test_bricks_widest_perf.gd`, a real run, 4 landings each, Time.get_ticks_usec around the weapon's step; noisy, run on this PC):
- The wave alone (no enemies): tier 8 landing 2.0 ms the first time in the process (the first wave of any tier: tier 7 is 1.95 ms), then 0.15 to 0.3 ms; outer ring steps 0.08 to 0.11 ms. Frames while it is drawn: mean 6.76 ms, worst 9.2 ms, the same as tier 7 (mean 6.68, worst 9.2): the drawing adds nothing measurable headless.
- With 80 real minions spread over the 25-unit radius: tier 8 landing worst 7 to 9 ms, ring steps worst 8 to 13 ms (each ring kills about 27 minions); tier 7 on the same crowd: landing worst 6 to 10 ms (26 kills). The time is the minions' deaths (about 0.25 ms per kill, the same at both tiers), not the wave; tier 8 kills 3 times as many but spreads them over three steps. If the board's recorder shows spikes from mass kills, that is the minions' death cost (coins, popups), a separate task.
- Note for merging: T-481's bricks fix (sheet cache, loaded in `apply_tier()`) is not on master or on this branch's base, and without it every landing reloaded the sheet from disk (11 to 17 ms). I applied T-481's exact `bricks.gd` change here (same lines), and added one line after it that also warms the tier 8 strip record (`BricksWave.record_for(radius())`, 4 ms to parse otherwise). Merging T-481 and T-498 will touch the same `apply_tier()` lines: keep both lines.

Merge notes:
- T-499 (wiper tier 8) edits the same test lines: `test_weapon_data.gd` (the `["wiper"]` last-tier lists), `test_level_up_offers.gd` (level-up count 46, `test_bricks_and_wiper_are_never_offered_past_their_last_tier`), `test_level_up_screen.gd` (choice count `7 + 4 * 8 + 7`) and the comments in `weapon_data.gd`, `weapon.gd`, `level_up_offers.gd`. After both: every weapon 8, count 47 level-ups and `7 + 5 * 8` choices.
- For the Project Lead: docs/weapons.md lists the tier 8 card's description as "Your landing wave reaches its widest yet. Greenbull calls it a city-wide rollout." while `level_up_texts.gd` (and test_level_up_screen.gd) have "... Brace for impact!" (T-495's text, not touched here).

Proposals for the playtest: `ring_interval` 0.15 s (ring 2 at 0.5 s, ring 3 at 0.65 s), the inner ring hitting on the landing (as every tier), more dust and chips round the outer rings (2x and 3x).

Screenshots (`art-archive/T-498/screenshots/`): `tier8_widest_wave_frames.png` (all 18 frames at half the run's size, numbered with their time), `tier8_frame11_game_size_dark_light.png` (frame 11, all three rings, at the run's size on dark and light ground), `tier8_frame11_closeup_x2.png` (a close-up of the rings, dust and chips at 2x).

Tests run (only the files touched):
- `bash game/tools/run_tests.sh -gselect=test_bricks.gd`: 25/25 passed (4 new: tier 8 radius 3x tier 7 and 3 rings; outer enemy hit later than near one at the drawn wave's times, every enemy once, a pushed minion not hit again, kaiju damaged and never pushed; a new run drops pending rings; the sheet frame by frame and its record).
- `-gselect=test_bricks_widest_perf.gd`: 4/4 passed (benchmark above).
- `-gselect=test_weapon_data.gd`: 18/18; `-gselect=test_level_up_offers.gd`: 31/31; `-gselect=test_level_up_screen.gd`: 49/49; `-gselect=test_weapons_wreck.gd`: 12/12.
- `python -m unittest test_build_bricks_wave` (game/tools): 14/14 passed (new `WidestWave`: timing, three rings drawn inner to outer, the inner ring the tier 7 wave, pixel rules).

Documents affected: docs/weapons.md (Content, Bricks), game/docs/weapons/bricks.md.
