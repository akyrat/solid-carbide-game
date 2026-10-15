---
id: T-046
title: The kaiju's meteor attack: warning circles, impacts and new boulders
status: in-qa
from: project-lead
to: enemy-behavior
lead: Enemies
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-045, T-039, T-097]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, docs/level-design.md, tasks/T-045-kaiju.md, tasks/T-097-mvp-map-without-challenges.md, tasks/T-039-enemy-data.md, game/README.md]
files_expected_to_change: [the enemy code and scenes, tests, docs/enemies.md, game/README.md]
model: opus
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

**Blocked until T-045 (the kaiju), T-039 (the numbers) and T-097 (meteor boulders on the map) are done.**

Build the kaiju's one special move, as Enemies, Decisions describes it:
1. After a short animation (a placeholder pause or flash is enough), several meteors rain down at once, as often and as many as the data says.
2. **Warning:** before they land, a red warning circle shows on the ground where each will land, for 2 seconds. Meteors land near the car, only where T-097's placement check accepts a boulder.
3. **Impact:** a meteor landing on the car damages it and knocks it back (the run's damage function, T-033's knockback).
4. **New boulders:** each landed meteor leaves a plain boulder where it landed, through T-097's function. No challenge or arrow (challenges are left out of the MVP, Level design, Decisions).
5. Meteors and warnings stop when the run is paused.

The warning circle, meteors and dust burst are placeholders for now. Visual style describes the final look, and separate art tasks make it.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test triggers an attack and shows warning circles appear for 2 seconds before the meteors land where they showed (QA: pass / fail)
- [ ] A test shows a meteor landing on the car damages it and knocks it back, and one landing elsewhere doesn't (QA: pass / fail)
- [ ] A test shows each landed meteor leaves a boulder through T-097's function, only at spots its placement check accepts, and the car bounces off it (QA: pass / fail)
- [ ] A test shows meteors and warnings stop while the run is paused (QA: pass / fail)
- [ ] A screenshot shows warning circles and boulders left by meteors (QA: pass / fail)
- [ ] `docs/enemies.md` describes the built attack in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

**What was built** (Enemy Behavior Agent, 2026-10-15). The attack lives in its own script, `game/scripts/enemies/kaiju_meteors.gd` (`run.kaiju_boss.meteors`). The only change to existing enemy code is 7 lines in `kaiju_boss.gd`'s `bind()`, which create and bind it. `kaiju.gd` and `run.gd` are unchanged, so T-050's hook on the kaiju should not conflict.
- Schedule from `meteor_attack` (no numbers changed): first attack 5 s after the kaiju appears, then every 8 s. Each attack has a 1 s windup (placeholder: pale yellow rings pulsing above the kaiju's head), then 3 warning circles at once, within 10 units of the car, only at spots `map.can_place_meteor_boulder()` accepts. They also avoid other meteors still to land and the kaiju's body. Each meteor lands 2 s later where its circle showed.
- On landing, if the car's centre is within 1.5 units: `RunState.damage_car(15)` and `car.apply_knockback(away, 20)`. A placeholder grey dust burst shows, and a plain boulder is placed through `map.add_meteor_boulder()`, with no challenge or arrow.
- A rule added in the code, so nothing gets trapped inside a boulder: if the car or the kaiju is on the spot as the meteor lands, the boulder appears on the first step the spot is clear. On a hit, the car is knocked off within a fraction of a second.
- Pausing stops everything (physics and process steps). Nothing happens after the run ends, and a new run clears it all.
- **Warning colour:** hazard amber `Color(1.0, 0.62, 0.12)`, a translucent amber disc with a thick pulsing amber edge and an inner ring that closes in as the meteor nears. Far from Redgull red `Color(0.86, 0.1, 0.16)` (distance > 0.5, checked by a test). The meteor placeholder is a dark purple rock with a magenta glow (the boulders' alien palette), and the dust is warm grey.
- The warning circles are drawn on the ground in the map's `View` (right after the drift marks: under buildings, boulders, enemies and the car). The falling meteor, dust and windup are drawn over everything.

**Playtest switch:** `game/data/playtest.json` `kaiju_early_arrival.enabled` is **true** in this branch (kaiju at 30 s, so the first attack comes at 35 s). **It must go back to `false` right before merging.** The tests set the switch off and do not depend on it.

**Tests:** new `game/tests/unit/enemies/test_kaiju_meteors.gd` (17 tests, one per criterion and more). The full GUT suite passed (688/688, `bash game/tools/run_tests.sh`). Python tests: `game/tools` 251 OK (1 skipped), `tools` 171 OK.

**Screenshot:** `C:\solid-carbide-worktrees\T-046\screenshots\T-046_meteors.png` (git-ignored), with a committed copy at `art-archive/T-046/screenshots/T-046_meteors.png`. It shows the kaiju, three amber warning circles, one meteor falling and two boulders just left by meteors with their dust. Fixture: `game/tests/fixtures/kaiju_meteors_demo.tscn`.

**Documents updated:** `docs/enemies.md` (Content: a new "The kaiju's meteor attack (built in task T-046)", plus one pointer line in "The kaiju"; Summary, Decisions and Open questions unchanged) and `game/README.md` ("The kaiju", "The meteor attack (T-046)").

**For the board to look at in the playtest:** whether the attack rhythm and the 3 meteors feel right, whether a 15-damage hit with a 20 knockback feels fair, and how readable the amber circles are (the placeholder is amber rather than red, see above). Also whether the boulders the kaiju leaves clutter the roads too fast over a full minute (about 21 boulders in the 60 s fight, fewer if spots are refused). The numbers are T-039's and were not changed.

## QA result (round 1, QA/Integration Agent, 2026-10-15)

- Warning circles 2 s, meteors land where shown: PASS (test_warnings_show_for_two_seconds_then_meteors_land_where_they_showed)
- Hit damages and knocks back, elsewhere doesn't: PASS (tests at lines 133-153)
- Boulder via T-097 function, only where placement check accepts, car bounces: PASS
- Pause stops meteors and warnings: PASS
- Screenshot: PASS (amber circles, a falling meteor, two left boulders)
- docs/enemies.md Content only (Summary, Decisions, Open questions untouched): PASS
- Full GUT 688/688, game/tools 251 OK (1 skipped), tools 171 OK: PASS
- Risks: warning colour is amber (1.0, 0.62, 0.12), not Redgull red, and a test checks it: PASS. game/data/enemies.json has no diff against master: PASS.
- Note for merge: playtest.json kaiju_early_arrival.enabled is true in this branch; must be set to false before merging.
