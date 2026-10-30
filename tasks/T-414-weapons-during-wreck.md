---
id: T-414
title: Weapons during the wreck, and molotovs land where enemies can be
status: needs-playtest
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-413]
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/scripts/weapons/weapons.gd, game/scripts/weapons/molotovs.gd, game/scripts/weapons/bricks.gd, game/scripts/weapons/flamethrower/exhaust_flamethrower.gd]
files_expected_to_change: [game/scripts/weapons/weapons.gd, game/scripts/weapons/molotovs.gd]
model: sonnet
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

Weapons, Decisions: "Weapons during the wreck" and "Molotovs land where enemies can be". Today no weapon is stepped while the run isn't going, so fires, burns and flame tints freeze and bullets hang in the air during the wreck. During the wreck: molotov fires and burning enemies keep going, the underglow keeps ticking, the bricks go off if the wrecked car lands; the gun, molotov throws, the wiper and the exhaust flamethrower fire nothing new. Also: weapons.gd checks the run only once per step, so after the kaiju's death ends the run, later weapons in the same step still kill minions; stop at the end of the run. A molotov landing inside a building or off the map (molotovs.gd random_landing) picks another spot.

The board's review: get wrecked with molotov fires burning and the underglow on, and see them keep damaging; jump, get wrecked in the air, and see the bricks go off on landing.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [x] During the wreck, a molotov fire and a burning enemy keep dealing damage, and the underglow keeps ticking (enemy health drops). (QA: pass)
- [x] During the wreck, a wrecked car landing from the air sets the bricks off. (QA: pass)
- [x] During the wreck, the gun, molotov throws, the wiper and the exhaust flamethrower fire nothing (no new bullets, bottles, wipes or flames). (QA: pass)
- [x] After the run ends (win or time up), no weapon damages anything later in the same step. (QA: pass)
- [x] Over 1000 throws on the board's level, no molotov lands inside a non-platform building or off the map. (QA: pass)
- [x] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

T-413 approved; the weapon-behavior agent starts.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Built (T-414). The rack (weapons.gd) now has three modes, checked before every projectile and weapon (not once per step): running, wrecked, stopped. Wrecked: projectiles (fire areas, bullets, bottles in flight) keep stepping; each weapon's new `step_wrecked(dt)` runs: the underglow and Bricks run their normal step (ticks, and a wave on a landing), the flamethrower only ages its burn tints, the gun drops a queued volley, the molotovs and the wiper do nothing. Stopped (run over): nothing steps, even mid-step, so after a kaiju kill ends the run no later weapon or projectile damages anything. Molotovs: `random_landing()` retries up to 30 spots, rejecting off-map and inside a non-platform building (`is_valid_landing`), else lands at the car.

Proposals for the playtest (written in docs/weapons.md): bullets and bottles already in the air carry on; a queued gun volley is dropped; burn tints run out; short buildings count as ground for landings; 30 tries, then the car's spot.

Tests: new tests/unit/weapons/test_weapons_wreck.gd (12 tests: fire and burning keep damaging, underglow ticks, bricks on a wrecked landing, no gun/throw/wiper/flame, burn tint ends, bullets fly, run ends mid-step for weapons and for projectiles, 1000 landings none in a building or off the map, validity checks). Three older tests (bricks, molotovs, underglow "nothing after the run") ended the run by wrecking the car, which is now not over; they now end it with kaiju_killed(). Results: GUT 2151 tests, the 3 that failed were those and pass now (rerun by file); python game/tools 582 OK; tools set OK.

Screenshots: art-archive/T-414/screenshots/wreck_fires_20.png and wreck_fires_90.png (wrecked car, fires and underglow; made with tests/fixtures/weapons/wreck_shot.tscn). Documents: docs/weapons.md (built notes and proposals). docs/game-loop-architecture.md line 191 still says "T-414's"; left for the Project Lead.
- 2026-10-30, in-progress → in-qa: Weapons during the wreck and molotov landings built; tests pass
- 2026-10-30, in-qa → needs-playtest: QA passed 6/6, all 3 test sets green (12 new tests); 3 older tests changed only to end the run via kaiju_killed(); proposals labelled in docs/weapons.md
