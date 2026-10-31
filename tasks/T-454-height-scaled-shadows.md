---
id: T-454
title: Shadows shrink as objects rise and grow as they come down
status: in-qa
from: project-lead
to: game-loop
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/visual-style.md, docs/game-loop-architecture.md, docs/drifting.md, game/docs/game-loop/gift-pack-and-pickups.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/drifting.md, tasks/T-407-gift-pack-falling-shadow.md, tasks/T-204-art-car-frames-without-shadow.md]
files_expected_to_change: [game/scripts/, game/tests/unit/, docs/visual-style.md]
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

The board, 2026-10-31 (docs/visual-style.md, Decisions, "Shadows shrink with height"): every object in the air casts a shadow on the ground (or platform) under it whose size depends on its height: small when high, growing as it comes down, up to the object's own sprite size at the surface. Covers the car in the air (jumps, falling off a platform), the falling gift pack (T-407's landing shadow), falling enemies (T-227's falls), and anything else drawn above the ground; find them all and list them in the result notes. One shared helper for the size curve, so every object behaves the same; the curve and the smallest size are your proposals for the playtest. The shadow sits on whatever surface is under the object (ground or platform top). Code only, no new art. Never write, move or commit anything in game/data/levels/.

The board's review: jump off ramps and platforms, watch a gift pack fall and an enemy drop off a rooftop.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test shows the shared helper's shadow size is the sprite's size at height 0, smaller as height grows, and never larger than the sprite. (QA: pass / fail)
- [ ] Tests show the car in the air, a falling gift pack and a falling enemy each use the helper (shadow size changes with their height). (QA: pass / fail)
- [ ] A test shows a shadow sits on the platform top when the object is above a platform. (QA: pass / fail)
- [ ] The result notes list every in-air object found and which use the helper. (QA: pass / fail)
- [ ] Screenshots of the car high and low in a jump, and a falling gift pack, are saved and listed in the result notes. (QA: pass / fail)
- [ ] docs/visual-style.md (Content) describes the shadow rule. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Built (code only, no new art, nothing in game/data/levels/).

**The shared helper**: `game/scripts/driving/shadow_size.gd`. At the surface the scale is 1, the sprite's own size. Higher up it is `1 / (1 + h / 4)` (half size at 4 units), never below `MIN_SCALE` 0.35 (reached at about 7.4 units), and never above 1. Heights at or below the surface, and NAN, count as on it. `h` is the height above the surface under the object (`height_above()`), so over a rooftop it is measured from the rooftop's top. Proposals for the playtest: the curve (it shrinks fastest just off the ground, so small hops show) and the smallest size, 35 %. Both are constants in that file.

**Every in-air object found, and which use the helper:**
- The car in the air: uses it. `car_shadow.gd` gained `full_diameter_units`, `height_above`, `diameter_units()` and `set_height_above()`, and `place(units, ground_h, object_h)` takes the car's height. Wired in `run.gd`, `elevation_test.gd` and `elevation_sample_map.gd`. Full size stays the car's width (1 unit, the old size), so the shadow on the ground under a parked car looks the same as before.
- A falling gift pack (T-407's landing shadow): uses it. `gift_drops.gd` `update_shadow()` runs on every fall step. Full size is the package's width on screen (`PACKAGE_WIDTH_PX` 40, the used width of package.png, checked by a test).
- A falling minion (T-226/T-227): uses it. `minion_sprite.gd` draws a ground circle the size of its body (`radius_units()`), in the car shadow's colour, `air_height` units below its feet; `minion_spawner.gd` sets `air_height` and `shadow_radius_units`. It shows only while the minion falls, because on the ground minions keep having no shadow (board, 2026-10-15), so it disappears on landing instead of reaching full size.
- A falling kaiju: uses it. `kaiju_sprite.gd`'s own ground shadow now stays on the ground under it while it falls (before, it had none in the air) and is scaled by the helper (`shadow_outline()`, `air_height` set in `kaiju_boss.gd`).
- Thrown Molotov bottles: use it. Each bottle in `molotovs.gd` draws a shadow 0.5 units across at full size (a proposal), height_units() down the screen, and the shadow does not spin with the bottle.
- Not changed: the kaiju's meteors. Each falling meteor already has its warning circle on the ground at its landing spot (its own design), and a second mark would clash. The board's call.
- Not changed: the gift helicopter. It is a screen-space flyer about 200 pixels above the landing spot, has no real height above the ground, and has never had a shadow. The board's call.
- Not changed: bullets. They fly flat at a fixed low height (`DRAW_HEIGHT_UNITS`) and never come down, and a shadow under every bullet would be clutter. The board's call.
- Not changed: coins and health pickups. They lie on the ground. The coin's bob is an idle animation over its own fixed ground shadow.
- Not changed: effects (smoke, sparks, wreck flames, the level-up burst and the meteor tail). They are effects, not objects.

**Depth**: the car's and gift pack's shadows keep their existing depth rules. An enemy's or a bottle's shadow is drawn in the object's own node, so it has the object's depth order at its height in the air. Where a falling enemy's shadow overlaps the rooftop it just left, the shadow can draw over the rooftop's edge. In the screenshots this did not show; to check in the playtest.

**Tests:**
- New `game/tests/unit/test_shadow_size.gd` (5 tests): full size at 0, smaller as the height grows, never larger than the sprite and never below the smallest size, the height above the surface, and the screen-width conversion.
- New `game/tests/unit/run/test_height_scaled_shadows.gd` (8 tests): the car shrinks and grows with its height; over roof-nw-6 the car's shadow lies on the rooftop's top and is sized by the height above it; a gift pack's shadow grows as it falls; the package-width check; a gift pack falling onto a rooftop; a falling minion; a falling kaiju; a Molotov bottle.
- Existing shadow tests (T-192, T-258, T-407) pass unchanged.
- Counts: COUNTS_HERE

**Screenshots** (`art-archive/T-454/screenshots/`; fixtures `game/tests/fixtures/height_shadow_*.tscn`, script `height_shadow_demo.gd`):
- The car: `car_ground.png`, `car_low.png` (2 units up), `car_high.png` (5 units up) and `car_roof.png` (2 units over roof-nw-6), side by side in `car_heights_strip.png`.
- A falling gift pack: `gift_high.png`, `gift_mid.png` and `gift_low.png` (0 %, 50 % and 92 % through its fall), side by side in `gift_fall_strip.png`.
- Falling enemies: `minion.png` (4 units up) and `kaiju.png` (5 units up).

**For the playtest:**
- Is a 1-unit shadow right for the car? It is the car's width (the sprite is 3 by 1 units), and the size it had before. If the board meant the car's whole length, it is one constant.
- The curve and the smallest size, 35 %.
- Should meteors, the helicopter or bullets get shadows too?

Documents: docs/visual-style.md (Content, "Shadows that shrink with height"), docs/game-loop-architecture.md (the falling shadow line now points to it), docs/drifting.md (the T-192 entry notes the change), game/docs/game-loop/gift-pack-and-pickups.md.
- 2026-10-31, in-progress → in-qa: Built: one shared size curve (shadow_size.gd) used by the car in the air, falling gift packs, falling minions and the kaiju, and Molotov bottles. Counts: GUT 192 scripts / 2327 tests passing; game/tools 767 OK (1 skipped); tools 614 OK. Screenshots in art-archive/T-454/screenshots/. The 'Counts: COUNTS_HERE' line in the result notes is a leftover placeholder: these are the counts (an edit to fix it was refused).
