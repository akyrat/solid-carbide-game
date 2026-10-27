---
id: T-324
title: "The Bricks weapon: an impact wave each time the car lands"
status: done
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-322, T-323]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/drifting.md, game/README.md, game/scripts/weapons/weapons.gd, game/scripts/weapons/weapon.gd, game/scripts/weapons/level_up_offers.gd, game/scripts/weapons/windshield_wiper.gd]
files_expected_to_change: [game/scripts/weapons/, game/scenes/, game/tests/unit/, game/README.md, docs/weapons.md]
model: opus
qa_rounds: 1
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

The board's decision (Weapons, Decisions, "Bricks", 2026-10-28). Build Bricks as a weapon like the other five: offered on level-up cards (with T-322's texts and a placeholder card image until T-325's art), with T-323's numbers and tiers. Each time the car lands on the ground after being in the air (off a ramp, a rooftop's edge or any drop, the car's existing landing signal; a time in the air below T-323's minimum doesn't count), a powerful impact wave goes out around the car: it damages every enemy within its radius (the kaiju too) and knocks minions back if T-323 gives a knockback. The same wave whatever the height. A placeholder wave drawn in code (an expanding ring on the ground with a dust burst, in the City's colours, none of Greenbull's colours), with a placeholder sound if the SFX bus makes it easy (or none). The car's handling doesn't change ("making the car heavier" is only the joke).

The board's review: take Bricks, jump off a ramp into a crowd of minions, and judge the wave.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Bricks can be offered on a level-up card and taken, and its upgrades raise what T-323 says (tests). (QA: PASS, test_bricks.gd and test_level_up_offers.gd cover get, tiers 2 to 8 against bricks_at())
- [ ] A landing after enough time in the air sends one wave that damages each enemy within the radius once, and none outside it (tests); a shorter hop sends none (test). (QA: PASS, test_bricks.gd: in-radius once, outside none, 0.3 s minimum, short hop none)
- [ ] The wave is the same after a short and a tall drop (test). (QA: PASS, test_bricks.gd short and tall real drop send the same wave)
- [ ] The card shows T-322's texts word for word. (QA: PASS, test_the_bricks_cards_show_t322s_texts_word_for_word; texts match the Weapons doc)
- [ ] Weapons, Content, "Bricks" and game/README.md describe how it works. (QA: PASS, docs/weapons.md "Bricks" and game/README.md "Bricks" describe it)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-324/screenshots/`, as `tasks/README.md`, "Screenshots", asks. A GIF of a jump that lands among enemies. (QA: PASS, GIF of a ramp jump landing in a crowd plus 6 stills; the strip shows ring and dust)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: PASS, game/tools 620 OK (1 skipped), tools 501 OK, GUT 1735/1735)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started: the Weapon Behavior Agent is building Bricks (an impact wave on each landing), on top of the shared build.

### 2026-10-27, In progress → In QA

Built: Bricks sends an impact wave on each landing after 0.3 s in the air, offered on level-up cards with the approved texts. QA is checking it.

### 2026-10-27, In QA → Needs playtest

QA passed all 7 criteria. In the shared build (playtest/batch-1028) for your playtest.

### 2026-10-27, Needs playtest → Done

Approved after the board's playtest of batch-1028; merging to master.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Weapon Behavior Agent, 2026-10-27.

**What was built**

- `game/scripts/weapons/bricks.gd` (new): Bricks, one of the rack's weapons (`weapons.gd` `WEAPON_SCRIPTS`, `run.weapons.bricks`). Each step it reads the car's `airborne` and counts the seconds in the air; the step the car is back on the ground is the landing. A landing after at least `min_air_seconds` (0.3), and at least `cooldown` (0.5 s) after the last wave, sends one wave at the landing spot: every enemy whose body is within the radius takes the damage once (the kaiju too), minions that survive are pushed away from the spot (never the kaiju, a killed minion not pushed). The impact speed is never read, so the wave is the same whatever the height. Every number from T-323 (`WeaponData.bricks_at`), damage times the garage bonus. The car's handling is untouched (a test drives the same path with and without it).
- Placeholder wave drawn in code (`BricksWave`, a projectile of the rack, so it stops while paused): an isometric ring on the ground at the landing spot (lifted to the roof on a rooftop) growing in stepped frames to exactly the damage radius, an inner ring behind it, and a burst of dust puffs and brick chips that grow and then shrink. City colours (pale blue-white ring, blue-grey band, dark navy outline, concrete dust, pale brick chips), opaque, none of Greenbull's colours.
- Turned on at level-ups: `offered_in_level_ups` true in `game/data/weapons.json`, `bricks` in `WEAPON_ORDER`, `get_bricks` / `upgrade_bricks` in `ALL_IDS`; `available_offers()` now also honours the data flag. T-322's texts are used as they are (no text was changed).
- Placeholder card image: a 16 x 16 brick stack in `level_up_screen.gd`'s `PLACEHOLDER_GRIDS` (two new colours, kept clear of the "reads as red" test), also used for the HUD's weapon icon, until T-325.
- Playtest switch `bricks_at_start` (false) in `game/data/playtest.json`, like the other weapons'.
- No sound: the SFX bus has no fitting impact sound, and wiring one is the SFX Agent's file (`run_sounds.gd`); the weapon emits `wave_sent(centre, hit_count)` for it.

**Tests** (new: `game/tests/unit/weapons/test_bricks.gd`, 18 tests; plus a Bricks get-and-upgrade test and a tier-by-tier test against `bricks_at()` in `test_level_up_offers.gd`, and T-322's texts word for word on every Bricks card in `test_level_up_screen.gd`). Updated for six weapons: `test_level_up_offers.gd`, `test_all_weapons_run.gd`, `test_weapon_data.gd` (the not-offered test is now "offered"), `test_level_up_screen.gd` (the lists that max the other weapons, the choice count, and the final-art test skips Bricks while `art/level_up/weapon_bricks.png` is missing, `AWAITING_ART`; T-325 can drop it). `test_level_up_screen.gd`'s text count (expected 80) was already out of date after T-322's 16 texts; now 96.

- `python -m unittest discover -s game/tools -p "test_*.py"`: 620 tests, OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 501 tests, OK.
- `bash game/tools/run_tests.sh`: 1735 tests, 1735 passing, TESTS PASSED (run after the test changes; the only later code change was the dust puffs' size in the drawing).

**For the Project Lead (a layout question for the UI Agent):** with six weapons the HUD's icon column (6 x 48 + 5 x 8 = 328 px) is 8 px taller than the 320 px health bar; HUD and menus says five take 272 of 320. `test_hud_weapon_icons.gd` asserted "no taller than the bar" for five; I changed it to six weapons and "no lower than the heart under the bar, and clear of it", which holds. Whether the column should shrink (for example 6 px row gaps) is the UI Agent's call; I did not change the HUD.

**Screenshots** (`art-archive/T-324/screenshots/`): `bricks_ramp_jump_landing.gif` (a run from the main menu on the elevation map, Bricks at tier 1 and the gun off: the car drives up ramp-nw-0-3, jumps onto roof-nw-3 into a crowd of 12 minions, 6 with normal health that die, 6 tough ones pushed out; all 12 hit), stills `bricks_1_in_the_air.png`, `bricks_2_landing_minions_hit.png`, `bricks_3_wave_spreading.png`, `bricks_4_wave_at_its_radius.png`, the four in `bricks_landing_strip.png`, and `bricks_card.png` (the gift pack with the Bricks card and its placeholder image). In the recording the car clips a minion in the air and lands a little short, as it would in play. Fixtures: `game/tests/fixtures/weapons/bricks_landing_gif.tscn`, `game/tests/fixtures/level_up_screen_bricks_demo.tscn`; how to record: `game/README.md`, "Bricks".

**Proposals for the playtest** (the docs left them open): the reach counts the enemy's body (as the other weapons), the wave is flat (enemies on another level within the radius are hit, as the underglow's "damage areas are unchanged"), the push goes from the landing spot, and the ring's look and timing.

**Documents affected:** `docs/weapons.md` (the two Bricks headings merged into one Content section, "Bricks", with how it works, then T-323's numbers and T-322's texts; the level-up offers section now says six weapons; Summary and Decisions not touched), `game/README.md` ("Weapons", new "Bricks" section, and the level-up offers' ids, counts and tests).
- 2026-10-27, needs-playtest → done: The board played batch-1028 and approved it.
