# The performance recorder (T-468)

The board, 2026-10-31: there are frame drops at certain points in a run. The board plays a run with the recorder on; the Project Lead then reads the recording's analysis to find what causes the spikes. No gameplay changes: with the recorder off (the default) nothing is recorded and nothing is written.

Code: `game/scripts/perf/perf.gd` (`Perf`, the timed zones) and `game/scripts/perf/perf_recorder.gd` (`PerfRecorder`, one per run). Analysis: `game/tools/analyse_perf.py`. Tests: `game/tests/unit/run/test_perf_zones.gd`, `game/tests/unit/run/test_perf_recorder.gd`, `game/tools/test_analyse_perf.py`.

## Recording a run

Switch it on for a game session, either way:

- the command-line option `--record-perf` after `--`: from the repo root, `powershell -ExecutionPolicy Bypass -File game/tools/play_with_perf.ps1`, which runs `"C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" --path game -- --record-perf`;
- or the environment variable `SC_RECORD_PERF=1` (also `true`, `yes`, `on`) before starting Godot or the editor.

Options (after `--`, or as environment variables): `--record-perf-spike-ms=N` / `SC_PERF_SPIKE_MS` (the spike threshold, 25 ms by default), `--record-perf-dir=PATH` / `SC_PERF_DIR` (where recordings go).

Every run played in that session writes its own folder, `game/perf/<date>_<time>/` (in an exported build, `user://perf/`). The run scene (`run.gd`, `_ready`) adds the recorder (`PerfRecorder.attach_to_run`); it starts recording at once (so the run's own set-up is in it), starts a new folder when the same run scene starts another run, and closes the folder when the run is removed (the recap, Restart, Exit) or the game closes. `game/perf/` is git-ignored, and the recorder puts a `.gdignore` in it so Godot never imports the files.

Then: `python game/tools/analyse_perf.py` (the newest recording) or `python game/tools/analyse_perf.py game/perf/<folder>`; `--top N`, `--spike-ms N`, `--window SECONDS`, `--check-trace` (also checks the trace's nesting).

## What a recording holds

**`frames.csv`**: one line per frame, from the first frame of the run to its end:

- `frame`, `wall_s` (seconds since the recording began), `run_s` (the run's time elapsed, `RunState.time_elapsed()`; -1 when there is no run), `paused`, `frame_ms` (the whole frame, from the start of one engine frame to the start of the next), `zone_calls` (zone begins in the frame, for the overhead);
- Godot's monitors (`Performance`), as Godot reports them at that moment (its own times are the previous frame's): `fps`, `mon_process_ms`, `mon_physics_ms`, `mon_navigation_ms`, `static_mem_mb`, `static_mem_max_mb`, `message_buffer_max_kb`, `objects`, `resources`, `nodes`, `orphan_nodes`, `render_objects`, `render_primitives`, `draw_calls`, `video_mem_mb`, `texture_mem_mb`, `buffer_mem_mb`, `physics_active`, `physics_pairs`, `physics_islands`, `nav_maps`, and the `pipeline_*` compilation counts (running totals: a change is a shader compiled);
- the run's counts: `minions` (alive), `minions_spawned` and `minions_killed` (this frame), `paths_found` (this frame), `coins`, `health_pickups`, `projectiles` (with `bullets`, `molotov_fires`, `other_projectiles`), `burning_enemies`, `flame_on`, `kaiju`, `meteor_warnings`, `boulders_pending`, `boulders_standing`, `meteor_dust`, `map_meteor_boulders`, `gift_helicopters`, `gift_packages`, `popups`, `drift_smoke_puffs`, `drift_mark_pieces`, `wreck_puffs`, `hud_reactions`, `hud_viewer_flights` (-1 when that part is missing);
- `zones`: every zone used in the frame, `id:inclusive_usec:self_usec:calls` separated by `;`.

Lines starting `#` are records between frames: `#zone,<id>,<name>` (a zone's name, written when first used), `#marker,<frame>,<wall_s>,<run_s>,<name>,<json>` (an event), `#spike,<frame>,<ms>`. A line cut short when the game closed is skipped by the analysis.

**`trace.json`**: Chrome trace events; open it in https://ui.perfetto.dev or chrome://tracing. It has counters for every frame (`frame_ms`, `minions`, `projectiles`), the events as instant markers, a `SPIKE <ms>` marker on every spike, and, **in full detail as a flame graph**, the frames around every spike (30 before and 30 after; settings `frames_before`, `frames_after`), plus one ordinary frame in 300 for comparison. Detail is capped at 12,000 frames a recording (about 150 MB); past it, only the spike frames themselves. Every begin (`B`) has its end (`E`), nested; the writing is spread over the following frames (0.3 ms a frame) so it does not cause drops itself.

**`meta.json`**: the settings, the machine (CPU, GPU, renderer, window size, refresh rate, vsync, physics rate, debug build), and at the end the frame and spike counts, the zone names and the recorder's overhead.

### The frame's phases

The recorder follows the engine's own signals (`SceneTree.physics_frame`, `process_frame`, `RenderingServer.frame_pre_draw`, `frame_post_draw`) and runs its own `_physics_process` and `_process` after every other node, so every frame is cut into zones:

`frame` > `physics_step` (one per physics step; more than one means the game is catching up) > `physics.scripts` (every node's `_physics_process`) and `physics.engine` (the physics server's step, deferred calls and frees), then `process` (every node's `_process`), `after_process` (deferred calls: the custom `_draw()` of every node that redraws, `queue_free`), `render` (RenderingServer's draw), `wait` (input, vsync and frame pacing until the next frame). A phase's self time is the code in it that has no zone of its own. `perf.recorder` (at the start of each frame) is the recorder writing the last frame.

### The game's zones

Inside the phases, the game's systems are timed with `Perf.begin(&"name")` / `Perf.end(&"name")` (one-line calls, nothing else changed):

- **Car:** `car.physics` (the whole step: controls, drift model, `move_and_collide`, heights, tricks) > `car.stepped_listeners` (everything that runs on the car's step: `run.sync_view` (camera, drawn car, `level.car_depth_sort`, `level.see_through`), `run.drift_likes`, `run.needle`, `map.car_obstacles`, `effects.drift_marks_lay`, `effects.drift_smoke_emit`); `car.sprite`.
- **Minions:** `minions.step` > `minions.prune`, `minions.spawn`, `minions.move` (> `minions.separation`, then for each minion `minions.path` (path following, with `nav.find_path`, the A* search) and `minions.walk` (moving and sliding, `move_and_collide`); the self time of `minions.move` is the contact damage and the loop), `minions.despawn`, `minions.place_and_depth` (each sprite placed and given its depth among the buildings); `enemy.damage` (each hit taken, minion or kaiju, death included) > `minions.death_drops` (coins and health drops); `draw.minion`.
- **Kaiju and meteors:** `kaiju.step`, `kaiju.sprite_anim`, `draw.kaiju`, `meteors.step`, `meteors.fx_process`, `draw.meteors`, `hud.kaiju_bar`, `draw.kaiju_bar`.
- **Weapons:** `weapons.step` > `weapons.projectile` (each), `weapon.<id>` (`weapon.gun`, `weapon.flamethrower`, `weapon.underglow`, `weapon.molotov`, `weapon.wiper`, `weapon.bricks`; each weapon's update and its hits, with `enemy.damage` inside); `weapon.flamethrower_drawing`, `weapon.underglow_glow`; `draw.bullet`, `draw.flame`, `draw.underglow`, `draw.molotov_bottle`, `draw.molotov_fire`, `draw.wiper`, `draw.bricks`, `effects.burn_flames`, `draw.burn_flames`.
- **Pickups:** `pickups.magnet`, `draw.coin`, `draw.health_pickup`.
- **Gift packs:** `gifts.drops`, `gifts.arrows`, `gifts.helicopter`, `gifts.package`.
- **The run:** `run.start_run` (building the map and the car), `run.clock`, `sounds.sync`.
- **Effects:** `effects.drift_marks`, `effects.drift_smoke`, `effects.boost`, `effects.wreck`, `draw.drift_smoke`, `draw.drift_sparks`, `draw.boost`, `draw.car_shadow`, `draw.wreck`.
- **HUD and popups:** `hud.clock`, `hud.combo_heat`, `hud.hearts`, `hud.likes_fire`, `hud.likes_spring`, `hud.reactions`, `hud.sub_goal`, `hud.viewers`, `hud.viewers_drop`, `hud.viewers_flight`, `hud.popup`, `hud.popup_place`, `draw.hud_sub_goal`, `draw.hud_reactions`, `draw.hud_likes_fire`, `draw.hud_counter`, `draw.popup`; `ui.level_up_screen`, `ui.recap`, `ui.time_up`.
- **The level:** `map.update_car`, `map.see_through`, `draw.platform`, `draw.building`, `draw.see_through_building`, `draw.map_layer`, `draw.needle`.

Work done for every item many times a frame (each minion, each sprite's drawing, each projectile, each hit) uses the **each** form, guarded so it costs about 0.1 microseconds while the recorder is off:

```gdscript
if Perf.on: Perf.each_begin(&"minions.path")
...
if Perf.on: Perf.each_end(&"minions.path")
```

Each-zones are summed, not kept one by one: `frames.csv` has their total and number of calls, and the trace shows one block per each-zone under the zone that holds them, with the true `calls` and `us` in its arguments (blocks are as wide as their self time and laid after the zone's last real child). A zone begun inside an each-zone counts as one too (`nav.find_path` inside `minions.path`). A missed end is closed by the next end of an outer zone and counted in `meta.json`'s `unbalanced_zones` (0 in every test and sample).

**Adding a zone:** put `Perf.begin(&"area.what")` at the top and `Perf.end(&"area.what")` before every `return` and at the end (a `return` with a value: keep the value in a variable, end, return it). Use the each form inside loops over many items. Names are `area.what`, lower case; a new name shows up in the recording and the analysis by itself.

### Markers (events)

From the run's own signals: `recording_started`, `run_started`, `world_rebuilt`, `level_up`, `gift_helicopter_sent`, `gift_pack_dropped`, `gift_pack_landed`, `gift_pack_picked_up`, `level_up_screen_opened`, `level_up_choice_made`, `weapon_gained` / `weapon_tier` / `weapon_reset` (with the weapon and tier), `boss_time`, `kaiju_arrived`, `kaiju_defeated`, `meteor_attack`, `meteor_landed`, `boulder_placed`, `car_damaged`, `combo_broken`, `wreck`, `revive`, `time_up`, `paused` / `resumed`, `run_ended` (with the result), `recording_stopped`. Missions (G-009) have no code yet; when they do, `PerfRecorder.mark("mission_completed", {...})` from anywhere adds a marker.

## The analysis

`analyse_perf.py` prints, in order:

1. The recording: the machine, the frame times (mean, median, p95, p99, max), the spikes (at the threshold, over 50 and over 100 ms) and the recorder's own overhead (its zone, plus the zone calls times the measured cost of a call).
2. **Worst spikes**: for each, its time in the run (m:ss elapsed), the phases (how many physics steps, and each phase's ms), where the time went (the zones with the most self time, against what those calls usually cost), the run's counts and monitors (new shader compilations flagged), and the events within a second.
3. **Zones in spike frames against normal frames**: each zone's mean self time in spike frames and in normal frames, the calls, and in how many spikes it was the largest part.
4. **Growth with the minion count**: frame time by 25-minion bands, and the zones whose time grows with the minions (fitted on frames with one physics step, so catch-up steps do not pass for growth).
5. **Events followed by a spike**: for each kind of event, how many are followed by a spike within the window, against chance.
6. **Likely causes**, ranked: the zones that add the most to a spike frame, with why (more calls, dearer calls, growth with minions), then catch-up physics (several physics steps a frame, and whether a step costs more than its own 20 ms, a spiral), shader compilation, and events linked to spikes.

## Overhead (measured, T-468)

On the board's machine (Intel Core Ultra 9 275HX, RTX 5070 Laptop GPU, the editor's debug build, Kaiju City, run time 5:00 to 5:20, the car parked, weapons off so the minions come in the same way every time; `perf_sample_run.sh --seconds=20 --start-at=300 --no-vsync --park --no-weapons`, two runs each):

| | frames | mean ms | median ms | minions at the end |
|---|---|---|---|---|
| recorder off | 4089 / 3905 | 4.41 / 4.62 | 1.19 / 1.18 | 51 / 51 |
| recorder on | 2949 / 3170 | 6.11 / 5.71 | 1.74 / 1.56 | 51 / 51 |

So about +0.5 ms on a median frame and +1.4 ms on the mean (the mean holds the heavy frames with many minions, where the per-minion zones add up). The recorder's own estimate in the same recordings: 0.15 to 0.25 ms a frame writing, plus about 100 to 140 zone calls a frame at about 1.8 microseconds each (0.2 to 0.25 ms). With vsync on at 60 fps that is about 3% of a frame; at 300-minion loads the per-minion zones add about 1.7 microseconds per minion per zone per physics step. Off, the zones cost a static call each (about 0.3 microseconds a begin/end pair; 0.1 for the guarded each form).

## The scripted sample

`bash game/tools/perf_sample_run.sh [--record-perf] [--seconds=150] [--start-at=300] [--all-weapons] [--no-vsync] [--park] [--no-weapons]` (needs a window): the game's own run on Kaiju City, the run clock moved on `--start-at` seconds, the car driven by a fixed pattern of drifts (a short reverse when stuck), the first card taken at every level-up, the car kept alive; saves go to `user://perf_sample_*`, never the player's. It prints its own frame times (measured without the recorder), so a run with and one without `--record-perf` give the overhead. The sample recording's analysis is in T-468's result notes, to compare with the board's.
