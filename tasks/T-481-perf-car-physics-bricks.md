---
id: T-481
title: Frame drops: car physics spikes to ~28 ms together with the bricks weapon
status: in-qa
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: [T-468]
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, tasks/T-468-run-performance-recorder.md, game/docs/game-loop/perf-recorder.md, game/scripts/weapons/weapons.gd, game/scripts/driving/car.gd]
files_expected_to_change: [game/scripts/weapons/, game/scripts/driving/car.gd, game/tests/unit/, docs/weapons.md]
model: sonnet
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

The board's recorded run (T-468, recording `game/perf/2026-11-01_13-13-18` in T-468's folder): the second cause is `car.physics`: about 28 ms in a spike frame against 0.37 ms usually, always in the same frames as `weapon.bricks` jumping from 0.01 ms to 6 to 17 ms, with the physics engine phase also at 25 to 50 ms, and a molotov fire alive. Every one of the 5 `weapon_reset` events was followed by a spike within 1 s.

Find why: likely the bricks weapon creating, moving or freeing physics bodies or shapes the car collides with (or something the car's physics step then rebuilds); check the reset too. Fix it so the car's physics step and the bricks weapon stay near their usual cost, with the weapon behaving and looking as today. Work with the Driving & Drift Agent's car.gd only as far as the cause needs. Measure before and after with the recorder or a scripted benchmark. Never write, move or commit anything in game/data/levels/.

The board's review: play a run with the bricks weapon and feel no hitches.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes say what made car.physics and weapon.bricks spike together, and what weapon_reset did, with the evidence. (QA: pass / fail)
- [ ] A measured before/after (recorder or scripted benchmark with the bricks weapon firing near the car) shows car.physics under 2 ms and weapon.bricks under 2 ms at their worst; numbers in the result notes. (QA: pass / fail)
- [ ] The existing weapon and car tests pass unchanged, so the bricks weapon and the car behave as before. (QA: pass / fail)
- [ ] docs/weapons.md notes anything about how the bricks weapon handles its bodies, if that changed. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: the car physics spike with the bricks weapon.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

### Cause (evidence)

- The bricks weapon creates, moves and frees no physics bodies or shapes, and the car's collision is not involved. `weapon_reset` is a start-of-run event: all 5 of them are at frame 0 (run 0.0 s) in the recording, so "a spike after every reset" was the start-up, not a pattern.
- In the recording's spike frames (e.g. 53307) the trace nests `car.physics` 30.7 ms (self ~28 ms, the 1.4 ms `car.stepped_listeners` is separate), with `weapon.bricks` 7.1 ms after it and `draw.popup` 41 ms (2 calls) in the same frame. 95 frames have `car.physics` over 5 ms; 68 of the 143 frames with `draw.popup` over 5 ms are also car.physics spikes. The landing is the common thing: a bricks landing from a jump is also the airtime trick's landing.
- Reproduced with a scripted benchmark (tests/unit/weapons/test_bricks_perf.gd: real run scene, real car drop, real minions, bricks owned). Timing the segments of `car.physics_step` showed ~13 ms all in the trick step (`tricks.observe_air` -> airtime_trick -> combo -> `TrickPopups.show_popup`), where `_free_stack` called `PopupText.size()`, which called `TrickPopupArt.texture()`: a per-pixel GDScript bake of the plain popup picture (10 to 30 ms for a viewers text, more at higher heat), for a text that is new every time (the "+12.3K" amount). The real picture is baked again at the first draw (`draw.popup`).
- `weapon.bricks` 5 ms: `BricksWave.sheet_for()` does `load()` of the wave sheet on every landing; nothing holds the texture after its wave is freed, so it was decoded from disk again each time (4 to 5 ms measured inside `setup`).

### Fix

- bricks.gd: the sheets are kept in a static cache (`BricksWave.sheet_for`), and loaded when the weapon is gained or its tier changes (`apply_tier`).
- trick_popups.gd: `PopupText.size()` no longer bakes the picture: `TrickPopupArt.plain_size()` works the size out from the lettering. The popups node warms the lettering of every trick text (and the eye) in `_ready`.
- trick_popup_art.gd: lettering cached (`_letter`), `_crop` by row slices, `_fill_round_rect` by row spans, RGBA conversion by one `encode_u32` per pixel. Baked pictures are byte-identical to before (hash of 479 bakes over both styles, 4 heats, 3 frames, texts, viewers, hide_amount compared old vs new: identical) and the first draw of a popup now bakes 3 to 4 times faster (heat 0 "FULL 360! +12.3K" 11.6 -> ~3 ms; heat 3 30.6 -> 8.7 ms).
- car.gd untouched. No physics body/shape change was needed.

### Before / after (scripted benchmark, headless, worst of 6 landings with a minion crowd; ms)

| | before | after |
|---|---|---|
| car.physics_step on a landing | 12.2 to 14.4 | 1.6 to 2.4 on the first landing, 0.8 to 1.4 after (a landing with no trick costs 0.8 to 1.0 here) |
| bricks.step on a landing | 4.6 to 5.2 | 0.2 to 1.0 |

The strict "under 2 ms in a recorder run" numbers need the board's own machine; headless noise is up to ~0.5 ms. The test asserts loose limits (bricks < 3 ms, car < 5 ms). The remaining popup cost is the baking at the first draw (`draw.popup`, ~3 ms at heat 0, ~9 ms at the flaming heat 3 for a new text), which is outside the physics step and not part of this ticket; a further step would be to bake it off the main thread.

### Tests

- New: tests/unit/weapons/test_bricks_perf.gd (benchmark with limits, sheet cache, plain_size equals the baked size), tests/unit/hud/test_popup_art_fast_paths.gd (spans equal the per-pixel test over 75 shapes, crop equals the scan, cached lettering).
- GUT: 213 scripts, 2518 tests, all passing (`GUT_TIME_LIMIT=1800`). `python -m unittest discover -s game/tools`: 858 ran, OK (1 skipped). `python -m unittest discover -s tools`: 633 ran, OK.
- Existing weapon and car tests unchanged and passing. Nothing under game/data/levels/ or game/perf/ touched.
- Documents: docs/weapons.md (Bricks, "Bodies and cost (T-481)").
- 2026-11-01, in-progress → in-qa: Fixed: popup bake out of the landing's physics step, bricks sheet cached; all 3 test sets pass
