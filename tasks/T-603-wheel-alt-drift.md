---
id: T-603
title: The Polarized Steering Wheel bursts after an alternate drift
status: in-progress
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
files_to_read_first: [tasks/README.md, docs/drifting.md, game/docs/driving/drift.md, game/data/power_ups.json, tasks/T-502-polarized-steering-wheel.md, tasks/T-527-steering-wheel-cooldown.md]
files_expected_to_change: [game/scripts/driving/, game/data/, game/tests/, game/docs/driving/, game/tools/]
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

Build Drifting, Decisions, "The Polarized Steering Wheel bursts after an alternate drift". The wheel's burst comes from each alternate drift the trick system pays (ALT DRIFT!), on the ground, outside the cooldown; the old trigger (lift W, steer, press W) is removed. The burst is half as strong (tier 1 x1.1, tier 2 x1.225 in power_ups.json), held 0.5 s, then fades quickly to the speed the car would have had (propose how quickly, with a reason). Settle the burst's direction when the alternate drift pays on a switch into a backward drift (the car moving backwards): the burst pushes along the car's travel, whichever way the nose points; say how. The tier 2 shock and the cooldown (T-527) stay as they are, as does the cooldown fill on the HUD icon. When the burst triggers, draw in code a small animation on the ground around the car: 2 arrows, one on each side of the car, pointing along the direction of travel at the moment the alternate drift paid (the way the burst pushes), drawn under the car and fading out (propose size, colour from the wheel's cyan and magenta, and length, about the burst's 0.5 s). Swap in T-602's descriptions. Check the tutorial (the missions slide, recorded demos) for anything showing the old trigger and say what you found. Rerun the speed bot (bash game/tools/speed_bot.sh) with the new trigger and put its peak and average speeds in the result notes, so a runaway speed would show. Numbers in data with reasons.

The board's review: play it from C:\solid-carbide-worktrees\T-603\game\project.godot: take the Polarized Steering Wheel, alt drift, feel the burst and see the arrows; lift-steer-gas gives nothing.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A completed alternate drift with the wheel owned gives the burst at x1.1 (tier 1) and x1.225 (tier 2) for 0.5 s, then fades in the proposed time (tests with the numbers). (QA: pass - test_an_alt_drift_gives_the_tiers_burst_held_half_a_second_then_faded_in_a_quarter; 0.25 s linear fade proposed with reason)
- [ ] Lift, steer and W again gives no burst; the cooldown still blocks a burst and the tier 2 shock still fires (tests). (QA: pass - test_lift_steer_and_w_again_gives_no_burst, cooldown and tier 2 shock tests present and green)
- [ ] The arrows show on the ground on each side of the car, under it, pointing along the travel at the payout, and fade out (a test of their direction and life). (QA: pass - test_the_arrows_show_at_both_sides_along_the_travel_and_fade_out, plus under-the-car test; screenshots)
- [ ] T-602's descriptions show on the cards (a test or screenshot). (QA: pass - test_the_cards_show_t602s_texts_with_10_and_23_percent and test_power_up_screen)
- [ ] The speed bot's peak and average speeds are in the result notes. (QA: pass - peak and average speeds listed per tier in the result notes)
- [ ] docs/drifting.md Content (The Polarized Steering Wheel section) and game/docs/driving/ describe the new trigger, numbers and arrows. (QA: pass - docs/drifting.md and game/docs/driving/drift.md changed in the diff)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass - full run 3265 tests, 3264 passing, 0 failing, 1 risky/pending, in the result notes)
- [ ] Screenshots or a GIF in art-archive/T-603/screenshots/ show the arrows around the car after an alternate drift, taken with bash game/tools/screenshot.sh. (QA: pass - 3 screenshots in art-archive/T-603/screenshots/)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started on T-602's branch (its texts show in this build): the burst after an alt drift, half as strong, fading after 0.5 s, with the ground arrows.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### Driving & Drift Agent, 2026-11-09: built

**What changed**
- The wheel's burst now comes from each ALT DRIFT! the trick detector pays, on the ground, outside the cooldown (`car.gd` connects `tricks.trick` to `polarized.on_alternate_drift()`). The old lift-steer-W trigger and its numbers (min_angle_degrees, max_coast_seconds, min_speed) are removed.
- The burst is a factor on the car's whole velocity: x1.1 (tier 1) / x1.225 (tier 2), held 0.5 s, then a straight line back to x1 over 0.25 s. Each step the wheel takes the factor out before the model drives (`before_step`) and puts it back after (`step`), so the model always drives the speed the car would have had, and the car ends at exactly that speed. Tested against a twin car without the wheel, step by step.
- The tier 2 shock, the cooldown (3 s / 4 s, T-527) and the HUD cooldown fill are unchanged. A wall hit ends the burst as before; new: catching a rail ends it too (keeps the speed). Without that, leaving the rail would divide the rail's speed by the factor.
- Ground arrows: `game/scripts/driving/polarized_arrows.gd`, a child of the boost effect, so it is under the car's sprite and lifted with it in the run and in the practice.
- Card texts: T-602's are in place. `describe()` gives "Pull an ALT DRIFT: +10% speed burst." and "+23% burst after each ALT DRIFT!, and a shock shoves minions." (tested; roundi gives 23 for 22.5).
- Speed bot (`game/tools/speed_bot.gd`) now chains alternate drifts (W+A then S+A, straight W in between, Rev Charge or not) and also runs tier 0 as a baseline. Fixtures `t502_polarized_demo.gd` and `wheel_cooldown_demo.gd` use alternate drifts.

**Proposals (no questions, with reasons)**
- Fade 0.25 s, linear (`fade_seconds` in power_ups.json). That is half the hold: quick enough to read as a kick that ends rather than a slow coast-down, long enough that the drop (about 1.7 u/s at top speed at tier 1, 3.7 at tier 2) is not a jolt.
- Direction on a switch into a backward drift: the burst scales the velocity vector, so it always pushes along the travel, whichever way the nose points or if the car is moving backwards. No special rule needed. A standing car gains nothing.
- Arrows: 2 units long (about two thirds of the drawn car), 0.24 shaft, 0.6 x 0.7 head, centred 1.2 units out on each side. Left of the travel is cyan (42,213,239), right is magenta (220,70,200): the icon's hub colours, with the hub's dark shades as edges. They are full for 0.1 s and gone at 0.5 s (the hold), sliding 0.5 units along the travel so they read as the push. They follow the car's position and keep the payout direction. All are exports on polarized_arrows.gd.
- Rail catch ends the burst (see above).

**Tutorial check:** nothing shows the old trigger. The missions slide text has no wheel (and is unused since T-559); the recorded takes in game/data/tutorial_takes/ are drift, alt drift, air spin and grind with no wheel; the practice has no wheel either.

**Speed bot (60 s per tier, top speed 16.5 u/s), 2026-11-09:** no runaway, never above 10x top speed, and every 10 s window has the same peak.
- Best overall (with Rev Charge tier 2): peak 31.4 at tiers 0, 1 and 2 (Rev Charge's x1.9 sets it). Average 25.3 (no wheel), 25.8 (tier 1), 24.5 (tier 2). Bursts 17 (t1), 12 (t2).
- Without Rev Charge: peak 24.7 / 24.8 / 26.2, average 19.1 / 19.4 / 17.6 (tier 0 / 1 / 2).
- The old trigger peaked at 88 to 90 u/s. Not covered by the bot: an alt drift during a Rev Charge boost multiplies it for 0.75 s (at most about 38.4 u/s at tier 2), once per cooldown.
- CSV: art-archive/T-603/speed_bot.csv

**Tests:** test_polarized_steering_wheel.gd rewritten (20 tests, 261 asserts, all pass). test_four_minute_run_data.gd tier 2 is now 1.225. Full run: 3265 tests, 3264 passing, 0 failing, 1 risky/pending (285 scripts, 230 s).

**Screenshots:** art-archive/T-603/screenshots/
- t603_arrows_start.png: just after the payout
- t603_arrows_fading.png
- t603_arrows_tier2_shock.png: with the Bricks wave

They were taken with `bash game/tools/screenshot.sh res://tests/fixtures/t603_arrows_*.tscn <out> 480`. The old overlay card fixtures (t502_overlay_*) no longer open the card overlay, so the card texts are shown by the test, not a screenshot.

**Documents affected:** docs/drifting.md (Content, "The Polarized Steering Wheel (tasks T-502, T-603)", and the two tier lines), game/docs/driving/drift.md ("Polarized Steering Wheel (T-502, T-603)"). The long GDD is not regenerated (the Project Lead's merge step).

**Not merged:** master is not merged in, as the Project Lead asked (T-601's wall fix comes at merge time).
