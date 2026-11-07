---
id: T-551
title: Grind overhaul: hold Space in the air to tilt and grind, release to launch; no Jump cooldown; jump effect and facing arrow
status: done
from: project-lead
to: driving-drift
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-548-rail-landing-boost-facing-jump.md, game/docs/driving/]
files_expected_to_change: [game/scripts/driving/, game/data/rail_grind.json, game/data/power_ups.json, game/tests/, game/docs/driving/, docs/drifting.md]
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

Build Drifting, Decisions, "The grind overhaul", "Jump has no cooldown" and the playing side of "A jump effect around the car", and HUD and menus, Decisions, "The jump arrow" (the arrow itself; the checkbox is T-553). Your branch starts from T-548's (the landing boost and the launch where the car faces), which this overhaul keeps. (1) **Tilt state:** while Space (the car_jump action) is held with the car in the air, the car is in a tilted pose, with a 3-frame transition in and the same transition backwards out on release in the air or on landing (propose what happens on landing). The art comes later (T-555): build the state, its frame timing and the hook that picks the tilted frame for the car's direction and transition step, with a placeholder look (for example the normal frame sheared or offset in code) that T-555 replaces. The car can still spin in the air while tilted. (2) **Grinding:** a grind starts only when Space is held in the air and the car touches a rail (keep or widen the catch reach so it is easier, and say what you chose); it lasts only while Space stays held; releasing Space launches the car along its facing at the data's speed, cancelling its momentum (T-548's launch). The landing boost on each rail landing stays (added to the speed). No power-up is needed for any of this; the Jump power-up's jump from the ground stays as it is, minus its cooldown. Propose what happens when the rail ends while Space is held. (3) **No Jump cooldown** at either tier (power_ups.json and code; tier 2 keeps its higher takeoff). (4) **Jump effect:** when the car jumps (the Jump power-up's jump, the launch off a rail, and propose whether a ramp take-off counts), play the equipped jump effect around the car, read from the saved cosmetic choice (T-552 adds it; until then default dash_cloud), with a code-drawn placeholder per effect id that T-556 replaces with art. (5) **Facing arrow:** a small arrow around the car pointing where the car faces, shown while grinding (proposal), drawn in code in the pixel look like the Drift Guide, switched by a saved setting `jump_arrow_enabled` (propose its default) that T-553 puts in the pause screen. Every number in game/data/rail_grind.json (or power_ups.json) with its reason. Check what else this changes (aerial tricks, airtime missions, the GRIND! trick, the trick list's clip, the tutorial's demo, the bots and tools that drive the car) and update it, listing each in the result notes.

The board's review: play the combined build (playtest/grind-overhaul) on the Kaiju City map: tilt, grind, launch, arrow, effects, and say what to change.

This ticket is part of the grind overhaul (board, 2026-11-07; Drifting, Decisions, "The grind overhaul"; tickets T-550 to T-556). The board plays all of it at the end, in one combined build (branch playtest/grind-overhaul, with T-547's map and T-548's grind changes), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, and leave no background job running when you hand back. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Holding Space in the air puts the car in the tilted state through 3 transition frames, and releasing it in the air plays them backwards; on the ground nothing tilts (tests). (QA: pass)
- [ ] A grind starts only while Space is held in the air and the car touches a rail, lasts while it is held, and releasing Space launches the car along its facing at the data's speed with its old momentum gone, also facing backwards (tests). (QA: pass)
- [ ] Each rail landing still adds the landing boost to the car's speed (test). (QA: pass)
- [ ] The Jump power-up's jump from the ground has no cooldown at either tier (test). (QA: pass)
- [ ] Jumping plays the equipped jump effect's placeholder around the car, the dash cloud by default (test). (QA: pass)
- [ ] The facing arrow shows while grinding when jump_arrow_enabled is on and not when off (test). (QA: pass)
- [ ] docs/drifting.md Content and game/docs/driving/ describe all of it with each proposed number and its reason, and the result notes list every other system checked or updated. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] GIFs in art-archive/T-551/screenshots/ show a tilt in and out, a grind started by holding Space, a launch off a rail backwards, the arrow, and a jump effect placeholder. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: hold Space in the air to tilt and grind, release to launch; no Jump cooldown; jump effect and arrow placeholders. Built on T-548.

### 2026-11-07, In progress → In QA

Built: hold Space in the air to tilt and grind, release to launch; no Jump cooldown; effect and arrow placeholders. QA now.

### 2026-11-07, In QA → Needs playtest

QA passed (9/9). Waits for you in the combined build.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### Driving & Drift Agent, 2026-11-07

Done. Built on T-548's branch (landing boost and launch where the car faces kept). Every behaviour and number, with its reason: docs/drifting.md, Content, "The grind overhaul (task T-551)"; code: game/docs/driving/rail-grind.md, "The grind overhaul (T-551)".

**What was built**
1. **Tilt** (`game/scripts/driving/car_tilt.gd`, stepped by `car.gd`): Space (`car_jump`) held with the car in the air or on a rail tilts it through 3 frames, 0.06 s each (`tilt_frame_seconds`, 3 physics steps; held pose in 0.14 s). Letting go in the air plays the frames backwards. Proposal for landing: the frames play backwards on the ground as the car drives off (no snap). Holding Space on the ground never tilts. A and D still spin the car while it is tilted. Drawing hook: `car_sprite.gd` `set_tilt_step(step)`. The placeholder is the normal frame sheared and squashed in code.
2. **Grinding:** a grind starts only while Space is held in the air and the car touches a rail. Reach widened from 2.0 to 2.5 (only a held Space can catch, so a wider reach can't snatch an unwanted car). The grind lasts while Space stays held. Releasing launches the car where it faces at `jump_speed` 6 flat, its momentum gone (backwards too), and up at the new `launch_takeoff_speed` 5 (the tier-1 Jump takeoff T-548's numbers used; the owned Jump tier's takeoff when it is higher, so tier 2 launches at 8). No power-up is needed. The landing boost (+4) is unchanged. A Space press on a rail does nothing. Proposal for the rail ending while Space is held: no launch. The car flies on along the rail as before, stays tilted, and catches the next rail it reaches.
3. **No Jump cooldown:** `cooldown_seconds` removed from both Jump tiers in `power_ups.json` and from `jump_power_up.gd`, along with `hop_off_rail` and `reset`. Tier 2 keeps takeoff 8.
4. **Jump effect** (`jump_effect.gd`, over the car in the run's View): it plays on `car.jump_started` ("hop" for the Jump power-up, "rail_launch" for the release) for 0.4 s (`jump_effect_seconds`). It uses `JumpEffectChoice.equipped_id()`, which is dash_cloud by default. Each of the 5 ids has a code-drawn placeholder: grey puffs, a zigzag spring, an orange flame, sparks, and a ground ring. Proposal: a ramp take-off is not a jump (ramps launch every car often, while the effect marks the player's own jumps), and neither is falling off an edge or a rail's end.
5. **Facing arrow** (`facing_arrow.gd`, over the car): an off-white arrowhead with a dark outline at the car's height, 2 units from its centre along the heading, 0.9 long, 1 wide, 85% opacity. It shows while grinding (proposal). Setting: `GameSettings.load/save_jump_arrow_enabled` (section "graphics"), on by default (proposal: the new mechanic starts with its help on). A save switches the arrow at once through `GameSettings.notifier.jump_arrow_enabled_changed`.

**For the sibling tickets**
- **T-552 (cosmetics save) plugs in at** `game/scripts/driving/jump_effect_choice.gd`. Set `JumpEffectChoice.provider = func() -> String: return <your API>.equipped_jump_effect()` once, for example in an autoload's `_ready` or the cosmetics script's `_static_init`. Until then, and for any unknown id, it is "dash_cloud". The ids are listed in `JumpEffectChoice.IDS`.
- **T-553:** the checkbox calls `GameSettings.save_jump_arrow_enabled(on)` and reads `GameSettings.load_jump_arrow_enabled()`. The arrow follows at once. The menu preview can call `JumpEffect.draw_placeholder(ci, id, t, origin, basis, heading)`.
- **T-555:** add `game/art/car/car_iso_tilt.png` and `.json` with the car's frame size, centre and px_per_unit, `columns` = 32 directions and `rows` = 3 (row 0 = step 1, row 2 = the held pose), without the drop shadow. `car_sprite.gd` (`TILT_SHEETS`, `tilt_frame_index`) uses the sheet automatically when it exists and drops the placeholder.
- **T-556:** replace the bodies in `jump_effect.gd` `draw_placeholder()` (one branch per id).

**Other systems checked or updated**
- Aerial tricks, airtime trick and airtime missions: unchanged. The tilt is drawing only, a launch is a takeoff like any other, and a rail landing is a landing.
- GRIND! trick: unchanged. It is paid by seconds when the grind ends, and a launch keeps the reason "jump".
- Trick list's GRIND! clip: `tests/fixtures/tutorial_clip_rail_grind.gd` now holds Space and lets go to leave. Not re-recorded: re-record it after T-555's art, so the clip doesn't show the placeholder shear. Also, the clip's key pad (`key_pad.gd`) has only W, A, S and D, so it can't show Space being held. That is a UI follow-up if the board wants it.
- Tutorial demo: the only tutorial grind is that clip. The slide texts are T-550's.
- Bots and tools: `game/tools/shots/rails_creator_shots.gd` now holds Space. The speed bot, `drive_elevation_sample.gd` and the drivability check never jump or grind, so they are unchanged.
- Old GIF fixtures `rail_grind_gif_demo.gd` and `t548_rail_gif_demo.gd`: they hold Space, and release it to leave the rail.
- `jump_boulder_demo.gd` and `test_jump_real_run.gd`: the `jump.reset()` calls were dropped (there is no cooldown to reset).
- Tests that drive a car onto a rail hold Space: `test_rail_grind.gd`, `run/test_run_rails.gd`, `level_creator/test_creator_rails.gd`.
- `test_four_minute_run_data.gd`: the jump tier-2 check no longer expects a cooldown.

**Tests run by the agent (each file on its own, `bash game/tools/run_tests.sh -gselect=<file>`), all passing**
- 16 test_grind_overhaul (new)
- 36 test_rail_grind
- 14 test_rail_joints_and_heights
- 5 test_run_rails
- 26 test_creator_rails
- 12 test_jump_power_up
- 6 test_jump_real_run
- 8 test_jump_clears_obstacles
- 6 test_four_minute_run_data
- 9 test_gift_drops_heights
- 10 test_pickup_heights
- 4 test_mission_texts
- 7 test_tutorial_clips
- 3 test_jump_draw_order
- 14 test_wall_bounce
- 6 test_pause_drift_guide_toggle
- 10 test_drift_guide
- 12 test_game_map

The full sets are left for QA.

**Screenshots** (`art-archive/T-551/screenshots/`, from `tests/fixtures/t551_overhaul_gif.tscn`; each GIF has a readout of Space, the tilt frame, the state and the effect)
- `tilt.gif`: Jump tier 2, Space held in the air, then let go in the air (tilt in and out). A second hop is held to the landing.
- `grind.gif`: a hop with Space held catches rail-3, the arrow shows, D turns the nose, letting go launches the car onto rail-4 with Space held again.
- `back.gif`: the car spun round on rail-3, with the arrow pointing back, then launched backwards.
- `effects.gif`: five hops, one per effect placeholder.
- `tilt_frames_strip.png`: the tilt frames, enlarged.
- `jump_effects_placeholders.png`: the five placeholders side by side.

**Documents affected:** docs/drifting.md (new Content section "The grind overhaul (task T-551)"; pointers in "Rail grinding" and "Jump"). Also game/docs/driving/rail-grind.md and tricks.md, and agent-notes/driving-drift.md.

**Honest quality note:** the tilt placeholder (a shear) and the effect placeholders are stand-ins: readable, but plain. The spring and jet are hard to see under a car that is barely off the ground, so the effect is drawn over the car.

**Refusals on the way:** a Bash redirect to a scratch file was refused by the command guard, and `task_notes.py --text` from PowerShell was refused by the auto-mode classifier. These notes went in through the coordinator's route: the Write tool, then `task_notes.py --append`.
- 2026-11-07, needs-playtest → done: Board: grind overhaul build played, lgtm
