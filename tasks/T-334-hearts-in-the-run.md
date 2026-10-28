---
id: T-334
title: "Hearts in the run: damage in hearts, 1 second of invulnerability with a blink, health drops"
status: needs-playtest
from: project-lead
to: game-loop
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-333]
documents_affected: [docs/game-loop-architecture.md, docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/enemies.md, docs/garage-design.md, game/docs/game-loop/the-run.md, game/docs/hud-and-menus/hud.md, game/scripts/run/run_state.gd, game/scripts/run/run.gd]
files_expected_to_change: [game/scripts/run/, game/scripts/enemies/, game/scripts/driving/, game/scripts/garage/, game/tests/unit/, game/README.md, docs/game-loop-architecture.md, docs/enemies.md]
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

The board's decision (Game loop architecture, Decisions, "Hearts instead of health points", 2026-10-28), with T-333's numbers. The run counts the car's health in whole **hearts** (5 to start, more with the garage upgrade):

- Every hit takes its hearts at once (minion 1, meteor 1, kaiju 2). The repeated contact hits every 0.5 s go: after **any** hit the car is **invulnerable for 1 second**, and **blinks** the whole time so the player sees it; hits during that second do nothing at all (no hearts, no knockback if that reads better (your proposal), and **no combo cut**: only the first hit cuts the combo).
- A health pickup heals 1 heart, never above the maximum, and drops at T-333's chance.
- The garage's car health upgrade adds 1 heart per level.
- The run ends at 0 hearts as it ended at 0 health.
- Everything that read the old health (the HUD's health bar, the recap if built, the crash pays the trick in progress of T-315, the time's up screen) keeps working; the HUD's health bar can show hearts as a fraction until T-338 replaces it with the heart row.

The board's review: play a run and get hit: you lose a heart, the car blinks for a second and you can drive out of a swarm.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A run starts with 5 hearts (plus 1 per garage level); a minion and a meteor take 1, the kaiju 2 (tests). (QA: pass)
- [ ] After a hit the car is invulnerable for 1 s (±0.05) and blinks; a second hit inside it takes nothing and doesn't cut the combo, and one after it does (tests). (QA: pass)
- [ ] A health pickup heals 1 heart and never goes above the maximum; it drops at T-333's chance (tests). (QA: pass)
- [ ] The run ends at 0 hearts with the same result as at 0 health before (test). (QA: pass)
- [ ] Game loop architecture, Enemies and game/README.md describe it. (QA: pass; README part met by game/docs/game-loop and game/docs/enemies, per the Project Lead)
- [ ] Screenshots (or a GIF for anything that moves) are in `art-archive/T-334/screenshots/`, as `tasks/README.md`, "Screenshots", asks: a GIF of a hit, the blink and the car driving out of a swarm. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-28, Open → In progress

Started from the playtest build (T-333 approved).

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Done (game-loop, 2026-10-28).** Built on the playtest build with T-333's numbers.

What changed:
- `game/scripts/run/run_state.gd`: `health`/`max_health` now count hearts (kept under those names so the HUD, the recap, T-315's crash pay and the end screens keep working; read-only `hearts`/`max_hearts` give whole numbers). `start_run()` uses `RunData.starting_hearts()` (5) or the garage's `car_health` (+1 heart a level). `damage_car()` takes the hearts at once, cuts the combo, and starts `car.invulnerability_seconds` (1 s): `invulnerable_left` counts down in `advance()` (stops while paused). During it `damage_car()` does nothing at all: no hearts, no combo cut, no `car_damaged` (no shake), and the second is not restarted. New: `is_invulnerable()`, `car_blink_visible()` (off/on phases of `car.blink_interval_seconds`, 0.1 s, starting hidden), signal `invulnerability_started(seconds)`. 0 hearts ends the run as a loss with the coins, as before.
- `game/scripts/run/run.gd`: `apply_blink()` sets `car_sprite.visible` from `car_blink_visible()` after every physics step and on a new run (shadow unchanged).
- `game/scripts/enemies/minion.gd`, `kaiju.gd`: `contact_step()` returns early (no hit, no knockback) while the car is invulnerable; the per-enemy repeat default is now 0 (the invulnerability spaces the hits). `kaiju_meteors.gd` `land()`: no damage and no knockback while invulnerable (`hit` false).
- `game/scripts/data/run_data.gd`: comment only.
- HUD: no change. The health bar already shows `health / max_health`, so it shows hearts as a fraction until T-338.
- Health pickups: unchanged code (T-333 already set `restore_hearts` 1 and `drop_chance` 0.15). They go through `heal_car()`, capped.

Proposals for the playtest: no knockback during the invulnerability (so the car drives out of a swarm); an ignored hit doesn't restart the second; the blink starts hidden so the hit shows at once; it hides the whole car drawing (the shadow stays).

Tests: new `game/tests/unit/run/test_run_hearts.gd` (16 tests: 5 hearts and +1 per garage level; minion 1, meteor 1, kaiju 2 through their real hit code; 1 s (+-0.05) invulnerability; a hit inside it takes nothing and doesn't cut the combo; one after it does; no extra knockback from a second minion; no meteor hit while invulnerable; the blink's phases and the run scene hiding/showing the car; a pickup heals 1 heart, capped, at 0.15; 0 hearts is a loss with the coins). Updated for the invulnerability: `test_minions.gd` and `test_kaiju.gd` contact tests (one hit per second of invulnerability, `advance(DT)` in the loop), `test_enemies_on_heights.gd` (clears the invulnerability between its checks), `test_run_state.gd` (`test_damage_to_zero_is_a_loss_once` waits out the second).

Test counts (all in the foreground, in this worktree):
- `python -m unittest discover -s game/tools -p "test_*.py"`: 643 tests, OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 545 tests, OK.
- `bash game/tools/run_tests.sh`: 147 scripts, 1773/1773 passing, TESTS PASSED.

Screenshots in `art-archive/T-334/screenshots/`: `hearts_hit_blink_swarm.gif` (5 s: the car drives into a swarm of 9 minions, the first touch takes a heart (the HUD bar goes to 4/5), the car blinks, the others don't hit or push it, and it drives out). Stills: `1_before_the_swarm.png`, `2_hit_one_heart_off.png`, `3_blink_off_phase.png` (car hidden, only its shadow), `4_out_of_the_swarm.png`, and `contact_sheet.png`. Recorded with the new `game/tools/record_hearts_gif.sh` and fixture `game/tests/fixtures/hearts_gif_demo.tscn` (no spawning; the minions are stepped by hand; hearts topped up at 1 so the clip never ends the run).

Documents affected: `docs/game-loop-architecture.md` (Decisions, "Hearts instead of health points": built in T-334 plus the proposals; the run section in hearts), `docs/enemies.md` (minion contact: built, no knockback while invulnerable), and in place of `game/README.md` (now an index): `game/docs/game-loop/the-run.md` (new "Hearts and the invulnerability (T-334)" bullet and the API tables), `game/docs/enemies/minions.md`, `game/docs/enemies/kaiju.md` (also fixed the stale "20"/"1 s"), `game/docs/enemies/meteors.md`.

Nothing was refused. `game/tests/fixtures/crash_pays_gif_demo.gd.uid` was an untracked uid file Godot made in this worktree; I left it out of the commit.

**QA (2026-10-28, qa-integration).** qa_check: tests PASS (3 sets), screenshots PASS (6 files; the contact sheet shows the hit, the bar at 4/5, the hidden blink phase and the car driving out). Documents FAIL only for game/README.md, which is now an index; the hearts text is in game/docs/game-loop/the-run.md, game/docs/enemies/{minions,kaiju,meteors}.md, docs/game-loop-architecture.md and docs/enemies.md, counted as the README criterion per the Project Lead. All 7 criteria pass.
