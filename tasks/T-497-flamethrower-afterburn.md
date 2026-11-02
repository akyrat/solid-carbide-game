---
id: T-497
title: Hot Take Exhaust afterburn: burning enemies keep taking damage
status: done
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
files_to_read_first: [tasks/README.md, docs/weapons.md, game/scripts/weapons/flamethrower/exhaust_flamethrower.gd, game/docs/weapons/flamethrower.md]
files_expected_to_change: [game/scripts/weapons/flamethrower/, game/tests/unit/, docs/weapons.md, game/docs/weapons/flamethrower.md]
model: opus
qa_rounds: 1
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

The board, 2026-11-02 (docs/weapons.md, Decisions, "The board's own upgrade trees"): the flamethrower's burn time becomes real afterburn. Today an enemy hit by the flame flashes orange for burn_flash_seconds and takes damage only while inside the flame. Now an enemy that leaves the flame keeps taking the flame's damage (its current damage, after upgrades) every tick_interval for its burn time, while the orange tint and the burn flames on it show. Re-entering the flame refreshes the burn time; an enemy never takes more than one flame hit per tick (inside the flame or burning, not both). Tiers 5 and 7 (+1 s each, T-496's data) lengthen it. This task starts in parallel with T-495 and T-496 (no depends_on): test with burn times set directly in the stats, not through the new tier list. The weapons-during-the-wreck rule holds: burns already on enemies keep going. Explain the behaviour in game/docs/weapons/flamethrower.md and docs/weapons.md Content (the exhaust flamethrower). Never write, move or commit anything in game/data/levels/. SFX stay off.

The board's review: play the new weapon trees in one build with T-495 to T-499 together (levelling each weapon to tier 8 with the playtest switches), from this ticket's folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: an enemy that leaves the flame at tier 1 takes the flame's damage every tick_interval for burn_flash_seconds, then stops. (QA: pass; test_afterburn_at_tier_1_hits_every_tick_for_the_burn_time_then_stops exists and the suite is green)
- [ ] A unit test: with burn +2 s (tier 7) the same enemy keeps taking damage for burn_flash_seconds + 2 s. (QA: pass; test_two_more_seconds_of_burn_keep_it_burning_two_seconds_longer exists and the suite is green)
- [ ] A unit test: an enemy inside the flame and burning takes one hit per tick, not two. (QA: pass; test_an_enemy_inside_and_burning_takes_one_hit_per_tick exists and the suite is green)
- [ ] A unit test: re-entering the flame refreshes the burn time. (QA: pass; test_re_entering_the_flame_refreshes_the_burn exists and the suite is green)
- [ ] The orange tint and burn flames stay on for exactly the burn time (unit test). (QA: pass; test_tint_and_burn_flames_stay_on_for_exactly_the_burn_time exists and the suite is green)
- [ ] docs/weapons.md (the exhaust flamethrower) and game/docs/weapons/flamethrower.md describe the afterburn. (QA: pass; both docs have the afterburn text)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass; both test sets pass in qa_check)
- [ ] Screenshots of burning minions outside the flame, under art-archive/T-NNN/screenshots/. (QA: pass; 3 screenshots in art-archive/T-497/screenshots/)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started in parallel: real afterburn for the flamethrower.

### 2026-11-02, In progress → In QA

Afterburn built: enemies keep burning and taking the flame's damage every tick for the burn time after leaving it; tests and screenshots in.

### 2026-11-02, In QA

Built: burning enemies keep taking flame damage after leaving the flame, one hit per tick. QA running.

### 2026-11-02, In QA → Needs playtest

QA passed: all 8 criteria and both test sets green; ready for the board's playtest with T-495 to T-499.

### 2026-11-02, Needs playtest

QA passed (8/8). Waits for the board's playtest with T-495 to T-499 together.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Weapon Behavior Agent, 2026-11-02.

**What changed (game/scripts/weapons/flamethrower/exhaust_flamethrower.gd).** The burn is now the flame's damage. Each burning enemy has its own entry in `burning` with `left` (burn seconds left) and `tick` (seconds since its last hit). Every step `_age_burns()` runs first (in `step()` and `step_wrecked()`): each burn's clock runs and every `tick_interval` the enemy takes one hit of `stats.damage` (the flame's damage now, after tiers and the garage bonus), inside the flame or not; at the end of the burn (a hit due on that very step still lands) the tint and burn flames go. Then, while the flame is on, an enemy touching it that is not burning takes the entering hit and starts burning; one already burning only has its burn time set back to full (`_refresh_burn()`, no extra hit). So the burn counts from the last step an enemy touched the flame, and every hit comes from one clock per enemy: at most one flame hit per tick. The shared `tick_timer` is gone. The entering step counts on the enemy's clock, so an enemy that stays inside gets exactly the old rhythm (entering hit + one every 0.2 s); one entering mid-cycle now gets its next hit a full tick after entering instead of at the next shared tick. Burns keep hitting while the car is wrecked (Weapons, Decisions, "Weapons during the wreck": burning enemies keep going). weapons.json untouched; tests set `burn_flash_seconds` in the stats directly.

**Tests (all run, all pass):**
- `bash game/tools/run_tests.sh -gselect=test_exhaust_flamethrower.gd`: 36/36 passing (6 new: `test_afterburn_at_tier_1_hits_every_tick_for_the_burn_time_then_stops` (AC1, flame on and off), `test_afterburn_hits_are_the_flames_current_damage`, `test_two_more_seconds_of_burn_keep_it_burning_two_seconds_longer` (AC2), `test_an_enemy_inside_and_burning_takes_one_hit_per_tick` (AC3, also going in and out every 3 steps), `test_re_entering_the_flame_refreshes_the_burn` (AC4), `test_tint_and_burn_flames_stay_on_for_exactly_the_burn_time` (AC5, 0.38, 1.0 and 2.38 s)). `test_entering_hit_flashes_the_enemy_for_the_burn_time` changed: the enemy stays inside through the 0.2 s linger, so its burn now ends linger + burn time later.
- `-gselect=test_weapons_wreck.gd`: 13/13 (1 new: `test_a_burning_enemy_keeps_taking_damage_during_the_wreck`).
- `-gselect=test_burn_flames.gd`: 7/7 (unchanged).

**Screenshots (AC8):** `art-archive/T-497/screenshots/afterburn_frame_60.png` and `afterburn_frame_120.png`: three minions moved out of the flame, in front of the car, still burning (burn time 2.38 s set in the stats, tier 6 flame); three on the right never touched it. `afterburn_frame_220.png`: the same after the burn is over. Fixture `game/tests/fixtures/weapons/flame_afterburn_demo.gd` / `flame_afterburn_shot.tscn` (the run scene directly, mission overlay disconnected).

**Documents updated:** docs/weapons.md (Content, the exhaust flamethrower: "Damage and afterburn"), game/docs/weapons/flamethrower.md (each step, tests, "See the afterburn").

**For the Project Lead / playtest:**
- Weapons, Decisions, "Weapons during the wreck" still says (T-414 proposal) "the flamethrower's burn tints already on enemies run out"; with afterburn they also keep doing damage, as the same entry's "burning enemies keep going" says. That Decisions line is the Project Lead's to reword if wanted; Content is updated.
- The Content tiers line and the summary still say "burn flash" for tier 5; left for T-496, which changes those tiers, to avoid a conflict.
- Seen in the screenshots: the burn flames cover a minion entirely, and the orange tint also tints the flames (they are a child of the sprite). With afterburn they now show for the whole burn time outside the flame (up to 2.38 s at tier 7), so this look is more visible than before. Existing art behaviour, not changed here.
- The old fixture `tests/fixtures/weapons/flame_hit_area_shot.tscn` (T-267) no longer runs: `game.run` is null after pressing Start (the menu flow changed since). Not fixed here (outside this ticket).
- 2026-11-02, needs-playtest → done: The board played the combined build on 2026-11-02: LGTM.
