---
id: T-147
title: Meteors never land on a boulder left by an earlier meteor that is still standing
status: in-qa
from: project-lead
to: enemy-behavior
lead: Coursework
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/README.md, tasks/T-046-kaiju-meteor-attack.md, tasks/T-142-meteor-boulders-fade.md, game/scripts/enemies/kaiju_meteors.gd, game/scripts/level/mvp_map.gd]
files_expected_to_change: [game/scripts/enemies/kaiju_meteors.gd, game/scripts/level/mvp_map.gd (only if the placement check itself must change), game/tests/unit/enemies/test_kaiju_meteors.gd, docs/enemies.md, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decision (Enemies, Decisions, 2026-10-16): **a meteor can't fall on a boulder left by an earlier meteor that is still there** (one that hasn't faded away yet, T-142). Once that boulder is gone, its spot is free again.

The code already tries to do this: `kaiju_meteors.gd`, `is_good_spot()`, calls the map's `can_place_meteor_boulder()`, which refuses a spot overlapping any boulder on the map, meteor boulders included. Yet in the board's playtest meteors still came down on standing meteor boulders. Find out why before changing anything, and write the cause in the result notes. Things worth checking (not a list of answers):

- The placement check allows a new boulder to **touch** an old one, and the boulder sprite in the isometric view is taller than its collision circle, so a meteor landing right behind a standing boulder may look as if it falls on it.
- The **warning circle** and the falling meteor may be drawn larger than the boulder's circle.
- A meteor whose boulder is still **waiting** for the car or the kaiju to move off the spot (`pending_boulders`), or a boulder that is fading, may not be counted.
- Spots are chosen when the warning circles appear, 2 seconds before landing; anything placed in those 2 seconds is not re-checked.

Fix it so that, as the player sees it, a meteor never lands on or overlapping a standing meteor boulder (fading ones included, since they are still drawn and solid). If a clearance distance is needed, it is a tuning number in `game/data/enemies.json`, `meteor_attack`, not in code. If no spot is free, fewer meteors fall, as now.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The result notes name the cause of meteors landing on standing meteor boulders in the board's playtest (QA: pass; cause named: touching allowed plus sprite overhang)
- [ ] A GUT test places a meteor boulder, then runs many meteor attacks around it (with a fixed random seed), and no warning circle or landing spot overlaps the standing boulder, the clearance included if one was added (QA: pass; 150 seeded attacks around standing boulder, none within diameter+clearance)
- [ ] A GUT test shows the same for a boulder that is fading and for one waiting for the car to move off its spot, and that once a boulder is removed its spot can be used again (QA: pass; fading and waiting boulders tested, freed spot reused)
- [ ] Any new tuning number is read from `game/data/enemies.json`, `meteor_attack` (a test checks it) (QA: pass; boulder_clearance_units read from enemies.json, test_enemy_data checks it)
- [ ] `docs/enemies.md` (the built meteor attack section) and `game/README.md` describe the rule as built (QA: pass; docs/enemies.md and game/README.md updated)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass; GUT 1147 pass, tools unittest OK, game/tools OK (355, 1 skipped))

The board's review: play to the kaiju and watch several meteor attacks; no meteor should land on a boulder from an earlier one that is still there.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started at the board's request, in C:\solid-carbide-worktrees$t.

### 2026-10-21, In progress → In QA

Fixed: meteors now keep 1.5 units of clear ground from any boulder (a tuning number). Sent to QA.

## Result notes

**Cause.** The code did refuse spots overlapping any boulder (standing, fading or waiting ones were all counted: meteor boulders are in `all_boulders()` until removed, and `pending_boulders` was checked). What let a meteor "land on" a boulder as the player sees it: (1) the check allowed touching, and (2) the boulder's isometric sprite is about 71 px tall but its circle only about 34 px high on screen, so it stands roughly 37 px above its circle and covers ground behind it; a warning circle or landing right behind a standing boulder lay under the sprite (circles are drawn on the ground, under boulders) and looked like it fell on it. The "spots chosen 2 s ahead" gap does not matter in practice: attacks are 8 s apart and each meteor's boulder is placed or pending before the next attack picks spots.

**Fix.** New tuning number `boulder_clearance_units` (1.5, proposed) in `game/data/enemies.json`, `meteor_attack`. `is_good_spot()` in `kaiju_meteors.gd` now keeps that much free ground between the circle and every boulder in `map.meteor_boulders` (standing or fading), and between it and other warnings and `pending_boulders` (those were "no overlap", now the same gap). The map's own boulders stay covered by the placement check. No free spot: fewer meteors fall, as before. A removed boulder leaves `meteor_boulders`, so its spot is free again.

**Functions changed:** only `is_good_spot()` (and the file's header comment) in `game/scripts/enemies/kaiju_meteors.gd`. `game/scripts/level/mvp_map.gd` is NOT changed, so it merges cleanly with T-206.

**Tests:** `game/tests/unit/enemies/test_kaiju_meteors.gd` (6 new: clearance read from data; 150 seeded attacks around a standing, a fading and a waiting boulder, none within diameter + clearance; a freed spot used again and the area gets meteors again; a spot just beyond the clearance accepted); `game/tests/unit/test_enemy_data.gd` (new key). Full GUT suite: 1147 passed. `python -m unittest discover -s game/tools`: OK (355, 1 skipped). `-s tools`: see below.

**Screenshot:** `art-archive/T-147/screenshots/T-147_avoid.png` (a standing boulder beside the car and 7 warning circles, none close to it), made with the new fixture `game/tests/fixtures/meteors_avoid_boulders_demo.tscn`.

**Documents updated:** `docs/enemies.md` (meteor attack, Warning), `game/README.md` (The meteor attack, enemies data keys).

**Proposals:** clearance 1.5 units is a first guess (the sprite's full overhang would be about 3 units; the board judges it in the playtest). No commands were refused.
