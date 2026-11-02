---
id: T-507
title: Rain over the map
status: in-progress
from: project-lead
to: level-challenge
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md]
files_expected_to_change: [game/scripts/, game/scenes/, game/data/, game/tests/unit/, docs/level-design.md, game/docs/]
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

The board, 2026-11-02 (docs/level-design.md, Decisions, "Rain over the map"): it rains on the map during a run. Build the rain with a placeholder look drawn in code (T-509 makes the art with PixelLab and swaps it in): drops falling at a slant that suits the isometric view, over the whole visible map, drawn over the map and enemies and under the HUD, with small splashes where drops land on the ground and rooftops. Steady light rain for the whole run. It changes nothing in driving or enemies. It reads a saved setting `rain_enabled` (default true), stored with the other settings the same way they are saved, and shows or hides at once when it changes (T-508 adds the toggle). Keep it cheap: measure the frame time with and without rain headless and write both in the result notes (the board watches frame drops, T-481); it must also work in the web export (no features the web build lacks). Make the look's numbers (density, speed, angle, splash count) data in a JSON file so T-509 and the playtest can tune them. Describe it in docs/level-design.md (Content) and game/docs/. This task's branch is built on T-497's branch, which already holds the board's new weapon trees (T-495 to T-499) and the playtest tier switch (T-500), so the board can play everything in one build. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py <id> --append <file>`, never with Edit or Bash on the ticket. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build with the weapon trees (T-495 to T-499), the power-up changes and God mode (T-501 to T-505), from the Project Lead's combined folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A run shows rain over the visible map, falling at a slant, with splashes on the ground (screenshots on a street and on a rooftop). (QA: pass / fail)
- [ ] The rain is drawn over the map and enemies and under the HUD (screenshot and a test of the draw order or layers). (QA: pass / fail)
- [ ] A unit test: with rain_enabled false no rain draws; switching it on or off takes effect at once; the setting is saved and loaded like the other settings, default true. (QA: pass / fail)
- [ ] Its numbers (density, speed, angle, splashes) come from a JSON data file. (QA: pass / fail)
- [ ] The headless frame time with and without rain is in the result notes, and rain adds no more than about 1 ms per frame. (QA: pass / fail)
- [ ] Driving and enemies are unchanged (the existing driving and enemy tests pass). (QA: pass / fail)
- [ ] docs/level-design.md (Content) describes the rain. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started: rain over the map with a placeholder look and a saved on/off setting.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### Level/Challenge Design Agent, 2026-11-02

Done: rain over the map with a placeholder look drawn in code, its numbers in a JSON file, and the saved setting `rain_enabled` (default true) that shows or hides it at once.

**What was built**
- `game/scripts/level/rain.gd`: a CanvasLayer "Rain" at layer 5, added by `run.gd` (`run.rain`) just before the HUD: over the world (map, car, enemies on layer 0), under the HUD (10) and every screen above it. Drops fall at a slant (18 degrees, tops to the right) in a screen-sized field that wraps round and shifts with the camera, so the rain moves with the map. Drops that end leave small three-frame splashes where they are, on the street or a rooftop alike. One art pixel = round(zoom * 16 / 32) screen px (min 1), on the map art's grid. Placeholder: opaque pale blue-grey pixels (streak with a lighter tip; splash), no Greenbull colours, made once as textures, drawn with `draw_texture` (batched). No shaders or particles.
- `game/data/rain.json`: drops per 1080p screen 220, fall speed 900 art px/s, angle 18, streak length 10, drop life 0.25 to 0.9 s, splash chance 0.35, max splashes 60, splash life 0.24 s, colours, and `drop_texture` / `splash_texture` / `splash_frames` slots for T-509's art (empty = placeholder). Proposals for the playtest.
- `game/scripts/ui/game_settings.gd`: `load_rain_enabled()` / `save_rain_enabled(on)`, section `graphics`, key `rain_enabled`, default true, in the same settings file; `GameSettings.notifier.rain_enabled_changed` fires on each save, and the rain follows it in the same frame (hidden, processing off, no drops). T-508's toggle only needs to call `save_rain_enabled`.
- Driving and enemies untouched: the only run.gd change adds the rain node.

**Frame time (headless, `bash game/tools/bench_rain.sh`)**: the game's run on its map, car parked, weapons off, minions seeded, rain switched on and off through the saved setting in 6 alternating blocks of 300 frames, the rain given a 1920 x 1080 screen's load (220 drops), dummy renderer (CPU side only).
- Rain on: mean 6.898 ms, median 6.901 ms, p95 8.935 ms (840 frames).
- Rain off: mean 6.900 ms, median 6.901 ms, p95 9.068 ms (840 frames).
- Difference: mean -0.002 ms, median 0.000 ms (the headless frame is paced at about 6.9 ms, so the difference is within noise).
- The rain's own work per frame (its _process + _draw, measured inside rain.gd): mean 0.21 ms, median 0.20 ms, p95 0.28 ms. Two earlier runs: mean 0.37 and 0.28 ms. Well under the 1 ms aim.

**Web export**: exported the Web preset to a scratch folder and ran it in headless Chrome (Compatibility renderer, WebGL 2): `node game/tools/web_audio_check.mjs` PASS with no errors, and a scratch CDP script that pressed Start, skipped the tutorial and Go Live took `art-archive/T-507/screenshots/web_export_run.png`: it rains in the browser, no console errors. (That build had splash chance 0.5, tried briefly and set back to 0.35.)

**Screenshots** (`art-archive/T-507/screenshots/`): `street.png` (spawn point on Kaiju City, minions coming in, HUD on top), `rooftop.png` (roof-1, height 3), `street_crop_x4.png` and `rooftop_crop_x4.png` (enlarged, nearest-neighbour: streaks and a splash), `web_export_run.png`. Fixtures: `game/tests/fixtures/rain_demo_street.tscn` and `rain_demo_rooftop.tscn` (`bash game/tools/screenshot.sh res://tests/fixtures/rain_demo_street.tscn <out.png> 240`), on `game/data/level/kaiju_city_map.json`; nothing in `game/data/levels/` read or written.

**Refusal**: a hook refused retaking the screenshots after a data tweak (`timeout 120 bash game/tools/screenshot.sh ...` in a loop; the guard could not tell `timeout` would not write a ticket). I did not retry it another way; I set the tweak (splash chance 0.5) back to 0.35 so the screenshots taken earlier match the data.

**Weak points / for the playtest**: the rain is light and thin at the default zoom (1 screen px per art px at 1080p), so it reads less on the light rooftops than on the dark streets; density, length and colours are all in rain.json. Splashes are drawn on whatever is under them, not tested against the map's ground or rooftop shapes. Trick popups (world-space) are under the rain, as everything in the world is.

**Tests** (`game/tests/unit/test_rain.gd`, 18 tests): setting default true, round trip, saved with the other settings, bad value; rain starts off when saved off; no drawing while off; drawing while on; saving the setting switches it in the same frame both ways; numbers from rain.json and from another file; slant angle and speed; splashes from ending drops and their life; moving with the map; opaque placeholder pixels; no Greenbull colours; pixel size from zoom; in the run, Rain layer above the world and below the HUD and level-up screen, enemies and view on the world's canvas, rain drawn by default, hidden at once when saved off. Run: test_rain 18/18, and the related files test_tutorial_setting 3/3, test_pause_slider_saves 8/8, test_camera_options 20/20, test_sfx_off 7/7, test_popups_above_buildings 6/6, test_drift_smoke 19/19, test_elevation_sample_map 17/17. The full set is for QA.

**Documents affected**: `docs/level-design.md` (Content, "Rain"), `game/docs/level/rain.md` (new).

**Files**: `game/scripts/level/rain.gd`, `game/data/rain.json`, `game/scripts/ui/game_settings.gd`, `game/scripts/run/run.gd`, `game/tests/unit/test_rain.gd`, `game/tests/fixtures/rain_demo.gd`, `rain_demo_street.tscn`, `rain_demo_rooftop.tscn`, `game/tools/bench_rain.gd`, `bench_rain.sh`, `game/docs/level/rain.md`, `docs/level-design.md`, `art-archive/T-507/screenshots/`.
