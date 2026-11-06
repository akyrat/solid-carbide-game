---
id: T-541
title: Rail grinding prototype: rails on the map, grind along them, jump between them
status: in-qa
from: project-lead
to: driving-drift
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: [T-533]
documents_affected: [docs/drifting.md, docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/driving/tricks.md]
files_expected_to_change: [game/scripts/driving/, game/scripts/level/, game/scenes/, game/data/combo.json, game/data/level/kaiju_city_map.json, game/tests/, game/docs/driving/, docs/drifting.md, docs/level-design.md]
model: opus
qa_rounds: 2
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

Build Drifting, Decisions, "Rail grinding, a prototype", and Level design, Decisions, "Rails" (the map side; the level creator's piece is T-542). A rail is a map piece: a straight segment (propose whether curves or corners are needed for the prototype) at a height, stored in the level file so the creator can place it later; define the format and write it in docs/level-design.md Content. Placeholder art drawn in code (a metal bar with a shadow, at the right depth in the isometric view). Grinding: a car that lands on or drops onto a rail (within a proposed distance, moving roughly along it) locks on and slides along it, sparks, its speed along the rail kept and slowly lost (propose), steering doesn't leave the rail; it leaves at the rail's end, or with Jump (Left Shift, the Jump power-up) which hops off and can land on another rail. Grinding counts as a trick: T-533's popup text, paid when the grind ends by its length or time (propose), adds to the combo and pays subs. Start from the old wall grind's rules (Drifting, Content, "Trick prototype (reference)"; code on the branch hold/trick-prototype). For the playtest, put a handful of rails on the run's map where they connect parts of the map, including two close enough to jump between with the first Jump tier, and make the playtest build start runs with the Jump power-up (a playtest switch in data, off on master).

The board's review: play the grind prototype build from C:\solid-carbide-worktrees\playtest-grind-rails\game\project.godot before merging.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Rails load from the level file in the documented format and draw at the right depth (test plus screenshot). (QA: pass)
- [ ] A car landing on a rail moving along it locks on, slides along it and leaves at its end; one landing across it doesn't lock on (tests). (QA: pass)
- [ ] Jump while grinding hops off; landing on a second rail starts a new grind (test). (QA: pass)
- [ ] Ending a grind pays the grind trick with T-533's text, adds to the combo and pays subs, with its numbers in game/data/combo.json (test). (QA: pass)
- [ ] The playtest switch starts runs with the Jump power-up and is off in the committed default data on master (test). (QA: pass)
- [ ] docs/drifting.md and docs/level-design.md Content describe the grind and the rail format, with each proposed number. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] GIFs in art-archive/T-541/screenshots/ show a car landing on a rail, grinding, and jumping to a second rail in a run. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-05, Open → In progress

Started: the agent is working in C:\solid-carbide-worktrees\T-541.

### 2026-11-06, In progress → In QA

Built: rails on the map, GRIND! trick, Jump hops rail to rail. QA is checking it.

### 2026-11-06, In QA → Needs playtest

QA passed. In the grind playtest build: C:\solid-carbide-worktrees\playtest-grind-rails\game\project.godot

### 2026-11-06, Needs playtest → In progress

The board's tweak: easier to snap onto rails, steer on the rail like in midair, Jump hops off diagonally toward the side the car points to. Back with the agent.

### 2026-11-06, In progress → In QA

Tweak in: snap within 2 units and 60 degrees, A/D turn the car on the rail like in midair, Jump hops off 15 degrees toward the nose's side. Ready to play in the grind build.

### 2026-11-06, In QA → Needs playtest

Back in the board's playtest.

### 2026-11-06, Needs playtest → In progress

The board's tweak 2: a jump off a rail ignores the Jump cooldown, so you can hop again quickly after landing on a rail. Back with the agent.

### 2026-11-06, In progress → In QA

Tweak 2 in: a jump off a rail ignores the Jump cooldown. Ready to play in the grind build.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### Driving & Drift Agent, 2026-11-06: rail grinding prototype built

**What it does (Drifting, Content, "Rail grinding (task T-541)"; Level design, Content, "Rails (task T-541)"; how it is built: game/docs/driving/rail-grind.md).** Rails are a map piece in the level file's new `"rails"` list. A car in the air (a jump, a ramp, the Jump hop, a drop off a rooftop edge) that catches a rail moving roughly along it locks on and slides along the bar with sparks. Only its speed along the rail is kept, and it slowly loses that speed. A and D swing the nose to that side but never take the car off the rail. It leaves at the rail's end (flying on and falling from the bar), drops off beside the rail when too slow, or hops off with Jump (the `car_jump` action, so whichever key that build binds: Space on master, Left Shift on the handbrake build). The hop adds a sideways push toward the nose's side and can land on a second rail. A grind pays GRIND! (T-533's text, word for word) when it ends, by its seconds on the rail: it adds to the combo and pays subs. The trick detector is unchanged: a landing on a rail is a landing, so a hop onto a rail also pays its HANG TIME! and air spins.

**Rail format (for T-542, written in Level design, Content, "Rails (task T-541)"):** `{"id": "rail-1", "x1", "y1", "z1", "x2", "y2", "z2"}`, in map units. The ends can be in any direction. z1 and z2 are the bar's height at each end and must be above 0. If z2 is left out it equals z1. The height changes in a straight line between the ends. Bad entries (a missing or non-number end, a height at or under the street, shorter than 1 unit) are skipped with a warning. The checks are `Rails.problem()` in game/scripts/level/rails.gd. The prototype has straight rails only; a corner is two rails that meet.

**Proposed numbers, each with its reason (also in the docs; constants at the top of rail_grind.gd, trick numbers in combo.json):**
- Catch reach: 1 unit from the rail's line (the car's side within half a unit of the bar). The wall grind used 2, but a rail is thin.
- Past an end: 0.5 units still catches (the grind starts at the end), so a landing right at the end isn't lost.
- Height window: from 0.5 under to 0.25 over the bar, falling or level only. One step of a fall moves up to about 0.3 units, so the car never steps through the bar, and a car still rising doesn't snap on.
- Angle: within 45 degrees of the rail, either way. This is what makes a landing across a rail fall past it.
- Least speed along the rail: 2 units/s. Slower than that isn't a grind.
- Speed loss: 1 unit/s every second. The wall grind lost 4, but rails are for travelling: at cruise speed a ride crosses the map's 35 to 54 unit rails.
- Drops off below 2 units/s, with a 2 units/s sideways push.
- Angle across the rail: 70 degrees (the wall grind's look). Sparks are the wall grind's: 5 a second per unit/s, 0.3 s each.
- Jump's sideways push: 4 units/s. With Jump tier 1 (about 0.83 s in the air) that carries the car about 3.3 units, enough for rails up to about 3.5 units apart at the same height.
- The rail just left can't be caught again until the car touches the ground or another rail, so a hop never drops it straight back on.
- Pay (combo.json `rail_grind`): nothing under 0.3 s; 0.25 x seconds added to the combo, at most 1.0 (a 2 s grind adds 0.5, like AIR 360!); 5 subs a second, at most 20 (2 s pays 10, like the big tricks), times the combo from before the grind.
- Playtest switch: `jump_at_start` in game/data/playtest.json, the Jump tier each run starts with. It is **0 (off) in the committed data**. **For the playtest build at C:\solid-carbide-worktrees\playtest-grind-rails, set it to 1.**

**Rails on the game's map** (kaiju_city_map.json; the only change to the file is the new `"rails"` list):
- rail-1: from roof-12 up to roof-13, which had no way up.
- rail-2: from roof-13 to roof-10.
- rail-3 and rail-4, the jump pair: on the road just north-east of the spawn, 3.5 units apart at height 1. A tier 1 hop from the street lands on them, and Jump with D held while driving north goes from rail-3 to rail-4.
- rail-5: from roof-2 down to the street east of it.

**Placeholder art (drawn in code):** a 3-pixel grey metal bar on thin posts every 6 units and at both ends, with a dark shadow line on the street. Each 2-unit piece sits in the map's depth order like the car at that place and height (the screenshots show the bar going behind a skyscraper and over rooftops). The car on the rail draws over it. The pieces just in front of a car driving under a rail draw over the car.

**Not in the prototype (for the board):** curved rails, and carrying a grind on into the next rail at a corner; speed changing with a rail's slope; enemies knocking the car off; rails as obstacles on the street (a car drives under them); the trick list entry and keycap recipe for GRIND!. The level creator may drop the `rails` list if the board saves the game map from it; T-542 handles that.

**Files:** new: game/scripts/level/rails.gd, game/scripts/level/rail_drawing.gd, game/scripts/driving/rail_grind.gd, game/scripts/driving/rail_sparks.gd, game/docs/driving/rail-grind.md, game/tests/unit/test_rail_grind.gd, game/tests/unit/run/test_run_rails.gd, game/tests/fixtures/rail_grind_gif.tscn and rail_grind_gif_demo.gd. Changed: car.gd (`car.grind`, the grind step; the normal step is unchanged when there are no rails), car_height.gd (set_on_rail, leave_rail), run.gd (_build_rails, sparks), run_state.gd (add_grind_trick, jump_at_start), combo_data.gd, trick_popups.gd (one TEXTS and one SIZES line), combo.json, playtest.json, kaiju_city_map.json, game/README.md. The trick detector is untouched, which should keep this clear of T-536. The likely merge overlaps with T-536 are trick_popups.gd's TEXTS and SIZES and combo.json, each a one-line add.

**Documents affected:** docs/drifting.md (Content, "Rail grinding (task T-541)"), docs/level-design.md (Content, "Rails (task T-541)"; "The game's map" notes the added rails).

**Tests run (foreground, the changed code's sets):** test_rail_grind 21/21, test_run_rails 5/5, test_jump_power_up 12/12, test_game_map 12/12, test_run_combo 20/20, test_run_scene 5/5, test_run_state 10/10, test_car_collisions 19/19, test_car_footprint_height 11/11, test_car_height 21/21, test_combo_data 6/6, test_tricks 27/27, test_trick_popups* 35/35. `python game/tools/check_level.py game/data/level/kaiju_city_map.json`: OK.

**Screenshots and GIFs (art-archive/T-541/screenshots/):**
- rail_jump_between_rails.gif: a run, hop from the street onto rail-3, grind, Jump with D onto rail-4, grind to the end.
- rail_climb_to_roof_13.gif: off roof-12 onto rail-1, up to roof-13.
- rail_grind_popup.png: the GRIND! popup.
- Depth stills: rails_jump_pair_by_spawn.png, rail_1_depth_roof_12_to_roof_13.png, rail_2_depth_roof_13_to_roof_10.png.

**For the Project Lead:** an earlier recording run of mine was left orphaned: a Godot window (PID 36536, `--write-movie ...scratchpad/mjump/f.png`) paused on its pause screen and still writing frames into my scratchpad. My `Stop-Process` on it was refused by the auto-mode classifier, so I did not try another way. Please close that Godot window (or end PID 36536). The fixture now unpauses itself and quits, so this won't happen again.

### QA, 2026-11-06: PASS. qa_check: 2 test sets passed (tools set skipped), documents and screenshots pass; all 8 criteria marked pass (rail tests, jump_at_start 0 in committed data, combo.json rail_grind, docs sections present, GIFs present). Orphaned Godot PID 36536 from the agent still needs closing by the board.

Playtest build (2026-11-06): playtest/grind-rails commit 0b7fa1fb sets game/data/playtest.json jump_at_start to 1 there only (this branch and master keep 0). Headless check in that folder: RunState.start_run() gives Jump tier 1. On that build only, test_rail_grind's test_the_playtest_switch_is_off_in_the_committed_data fails, as intended, since the switch is on there.
- 2026-11-06, needs-playtest → in-progress: The board, after playing: make it easier to snap onto the rail; steer on the rail like in midair; with the rail line as the threshold, Jump hops off slightly diagonally toward the side the car points to.

### Quick tuning 1 (board, 2026-11-06), Driving & Drift Agent

**The board's words, verbatim:** "Okay, for the grinding prototype, I want you to make it easier to snap on the rail because it's kind of hard now to get on it. And I want to be able to turn the car, so steer just like I would steer when I'm in midair while I'm on the rail, and basically have kind of a threshold which is, you know, on parallel with the rail, on the rail line. And whenever you, depending on whether you're more to the left or to the right, and you press jump, you have like a slight diagonal direction towards that side."

**What changed.** The grind's numbers moved from constants into the new file game/data/rail_grind.json; rail_grind.gd reads it, and its DEFAULTS are used for any missing key.
1. **Easier to snap on:** reach goes from 1 to **2 units** (the old wall grind's loosened reach). Past an end: 0.5 to **1 unit**. Height window: from 0.5 under / 0.25 over to **0.75 under / 0.5 over**. Angle: 45 to **60 degrees**; 60 still lets a landing straight across (or 65 degrees off the rail) fall past. Least speed along the rail stays **2 units/s**.
2. **Steering on the rail as in midair:** the car no longer snaps across the rail at 70 degrees. It keeps the heading it landed with, and A/D spin the body at the **air turn rate** (`tuning.turn_rate_for(true)`, so the garage's air turn upgrade applies). It keeps sliding along the rail whichever way it faces, sideways or backwards included. It leaves a rail still facing the way it faced. A spin on a rail pays no air-spin trick; the trick detector is unchanged.
3. **The threshold is the rail line:** on Jump, if the nose points left of the rail line the hop's flat velocity is turned **15 degrees** to the left of the rail at the same speed; right of it, 15 degrees right; exactly along it, straight on. This works facing forwards or backwards. Reason for 15 degrees ("slight"): at cruise (11 units/s) it is about 2.8 units/s sideways, about 2.4 units over a tier-1 Jump's 0.83 s, and with the 2-unit reach that reaches a second rail up to about 4.4 units away (the jump pair is 3.5 apart). Key: `jump_angle_deg`. A slow drop pushes 2 units/s toward the same nose side, and not at all when the nose is exactly along the line. This replaces the first prototype's flat 4 units/s sideways push toward the side A/D last chose.
- The rest is unchanged: decel 1, end speed 2, the combo/subs pay, and the rails on the map.

**Files:** game/data/rail_grind.json (new), game/scripts/driving/rail_grind.gd, game/scripts/driving/car.gd (the grind step's turning, the leaving heading), game/tests/unit/test_rail_grind.gd (updated, plus 3 new tests), game/tests/fixtures/rail_grind_gif_demo.gd (D now turns the nose about 25 degrees right of the rail before the jump), docs/drifting.md Content, docs/level-design.md Content (the jump pair's line), game/docs/driving/rail-grind.md.

**Tests (foreground):** test_rail_grind 24/24, test_run_rails 5/5, test_jump_power_up 12/12.

**GIFs retaken:** art-archive/T-541/screenshots/rail_jump_between_rails.gif (hop onto rail-3, D turns the nose right, a slightly diagonal Jump onto rail-4) and rail_climb_to_roof_13.gif (the car now faces the way it landed). The other stills are unchanged.
- 2026-11-06, in-progress → in-qa: Ready for the board to play (quick tuning 1), no QA agent yet.
- 2026-11-06, needs-playtest → in-progress: The board: jumping off a rail is not subject to the regular jump's cooldown; after landing on a rail the player can jump again quickly.

### Quick tuning 2 (board, 2026-11-06), Driving & Drift Agent

**The board's words, verbatim:** "for the grinding: jumping out from a rail should not be subjected to the cooldown for the regular jump. jumping on a rail, i should be able to jump again quickly if i want to."

**What changed:**
- A Jump pressed while grinding now always fires if the Jump power-up is owned, whatever the regular cooldown says. It goes through the new `JumpPowerUp.hop_off_rail()`, which hops at the tier's takeoff speed and leaves the cooldown as it was: it neither starts nor extends it. So after landing on a rail the player can jump off again right away.
- Off the rails the regular Jump keeps its cooldown as before. A cooldown that was already running keeps ticking during a grind.
- No minimum gap was added (so nothing new in rail_grind.json): one key press is one Jump, because the press is used once and then forgotten.

**Files:** game/scripts/driving/jump_power_up.gd (hop_off_rail), game/scripts/driving/car.gd (the grind step and _leave_grind), game/tests/unit/test_rail_grind.gd (3 new tests: the cooldown is ignored and left alone, two rail jumps in quick succession, the regular cooldown still applies on the ground), docs/drifting.md Content ("Leaving"), game/docs/driving/rail-grind.md.

**Tests (foreground):** test_rail_grind 27/27, test_run_rails 5/5, test_jump_power_up 12/12.

**GIFs:** not retaken. The recorded drive jumps after 1.6 s on the rail either way, so it looks the same.
- 2026-11-06, in-progress → in-qa: Ready for the board to play (quick tuning 2), no QA agent yet.
