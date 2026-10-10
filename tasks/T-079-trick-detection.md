---
id: T-079
title: Tricks: detect extended drifts, 360s and alternate drifts
status: needs-playtest
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-029]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/drifting/unity-prototype-report.md, tasks/T-029-drift-defaults-after-playtest.md, game/README.md]
files_expected_to_change: [the car's code, the tuning panel, tests, docs/drifting.md, game/README.md]
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

**Blocked until T-029 (the car's new defaults) is done.**

Drifting, Decisions defines the MVP's three tricks. Detect them from the car's own driving, without changing how it drives:
1. **Extended drift:** every full second of drifting is one trick. "Drifting" is the Unity definition the game already uses: W or S held together with A or D.
2. **360:** the car's heading turns a full 360 degrees in one direction during one unbroken drift. 720 degrees is two. A break in the drift, or turning back the other way, starts the count again.
3. **Alternate drift:** each switch between a forward drift and a backward drift while keeping the same steering direction is one trick. The board's description: drift forwards, release W while still steering, switch to S and drift backwards, then back to W, so the car draws semicircles. Propose the timing limits (for example how long the switch may take), and make them tuning panel sliders so the board can tune them.

Send one signal per trick, with the trick's id, so the combo (T-081) and the popups (T-083) can use it. Show the last trick in the drift prototype's readout, so the board can try them there.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test holds a drift for 3.5 seconds and shows exactly 3 extended-drift signals (QA: pass)
- [x] A test drifts the car through a full circle in one direction and shows one 360 signal; two circles give two; a drift that turns 300 degrees and then breaks gives none (QA: pass)
- [x] A test drives the forward-drift, release, backward-drift sequence with the same steering and shows one alternate-drift signal per switch; switching steering direction gives none (QA: pass)
- [x] The tuning panel has sliders for the alternate drift's timing limits, and its reset restores the proposed values (QA: pass)
- [x] A test shows the car's movement is exactly the same with trick detection on as before (T-012 and T-029's tests still pass) (QA: pass)
- [x] `game/README.md` documents the trick signal and the trick ids, and `docs/drifting.md` describes the detection in Content, without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: try the three tricks in the drift prototype (the readout shows the last trick) and tune the alternate drift's timing.

## Result notes

Done on branch task/T-079-trick-detection by the Driving & Drift Agent.

**What was built**

- `game/scripts/driving/trick_detector.gd` (new, `TrickDetector`): finds the three tricks from the driving model after each physics step. It only reads the model (its `is_drifting`, its rotation before and after the step, and the keys used); it never writes to it.
- `game/scripts/driving/car.gd`: every car has `tricks` (a `TrickDetector`) and emits `signal trick(trick_id: String)` once per trick. Ids: `extended_drift`, `three_sixty`, `alternate_drift` (the same keys as `trick_add` in `data/combo.json`). `detect_tricks = false` turns it off. The run's car gets it too.
- `game/scripts/driving/car_tuning.gd`: the alternate drift's limits as tuning values (`TRICK_SETTINGS`), included in the defaults, so the panel's reset restores them.
- `game/scripts/driving/tuning_panel.gd`: a "Tricks" group at the bottom of the panel (two sliders and a toggle, with tooltips), and the readout now shows the last trick, how long ago, and a count of each trick.
- Detection rules: "drifting" is the model's own `is_drifting` (W, or S without W, with A or D); any non-drifting step is a break. Extended drift: each full second of unbroken drift. 360: each full turn of the heading in one direction during an unbroken drift; turning back or a break restarts the count. Alternate drift: details in `game/README.md`, "Tricks".

**Proposed limits for the alternate drift** (all sliders or a toggle in the panel's "Tricks" group, read live):

- **Switch time 0.5 s** (slider 0 to 2): the longest gap from the end of one drift (W released) to the start of the opposite one (S held). Releasing W and pressing S takes a person about 0.1 to 0.25 s, so 0.5 leaves room without letting a slow, separate manoeuvre count. Holding S before releasing W counts as a gap of 0.
- **Shortest drift 0.3 s** (slider 0 to 2): both drifts must last at least this long, and the trick fires when the new drift reaches it (so the popup comes 0.3 s after the switch). It stops quick W / S taps from farming the high-value trick. A semicircle at the default turn speed takes about 0.94 s, so a real semicircle passes easily. A drift shorter than this breaks the chain.
- **Keep steering on** (toggle): A or D must stay held on the same side between the two drifts, as in the board's description ("release W while still steering"). If the board finds it too strict, turn it off: then only the two drifts need the same steering side.

Things the board may want to look at while tuning: the definition of a "break" is strict (one step without W/S + A/D breaks the extended drift and the 360). During an alternate drift with a gap (W released before S), the 360 count and the extended-drift second therefore restart at the switch; with S pressed before W is released they carry on. If the board wants a short grace time for breaks, that is a new decision for Drifting, Decisions, and an easy change.

**Tests** (`game/tests/unit/test_tricks.gd`, 25 tests): 3.5 s of drift gives exactly 3 extended drifts; one circle gives one 360, two give two, 300 degrees then a break gives none, turning back restarts the count; forward, release, backward, release, forward with the same steering gives one alternate drift per switch, switching steering gives none, plus the switch time, shortest drift, keep-steering and live-tuning cases; the car's `trick` signal; the panel's trick sliders and toggle, their proposed values and the reset; the readout; and a drive of every key combination (drifts both ways, switches, coasting) with two cars, detection on and off, and the bare driving model, checking position, velocity, rotation and drift amount are exactly equal on every step.

**Results:** GUT 202/202 pass (21 scripts; the T-012, T-029 and T-033 tests unchanged and passing). Python tool tests: `game/tools` 62 OK, `tools` 75 OK. A screenshot of the prototype with the panel open (`drift_prototype_demo_iso_panel.tscn`, 300 frames) shows the readout's "Last trick: extended drift" line.

**Documents affected:** `docs/drifting.md` (Content, "Godot drift prototype": a new "Tricks" bullet and the readout; Summary, Decisions and Open questions untouched), `game/README.md` (new "Tricks" section with the signal, the ids, the rules and the limits; drift prototype panel, file list and tests updated).

### QA round 1

QA/Integration Agent, 2026-10-10. Checked in the T-079 worktree, branch `task/T-079-trick-detection`. Result: **all 7 criteria pass.**

1. **3.5 s of drift gives exactly 3 extended drifts: pass.** `test_drift_held_3_5_seconds_gives_exactly_3_extended_drifts` passes, as do the tests for firing on each full second, a break restarting the second, and backward drifts counting. QA's own checks: 3.5 s of backward drift with D gives 3; 0.98 s of drift then a one-step break, five times over, gives none; a 0.04 s gap between a W drift and an S drift restarts the second; 32 s of unbroken drift wiggling between A and D gives 32.
2. **360s: pass.** `test_full_circle_gives_one_360` (93 steps none, 94 steps one), `test_two_circles_give_two_360s`, `test_300_degrees_then_a_break_gives_none` and `test_turning_back_the_other_way_restarts_the_count` pass. QA's own checks: 720 degrees in one drift gives 2; three backward circles give 3; 300 degrees then a break (letting go of A or D for one step, or of every key) then more turning gives none; 357 degrees, a break, then 357 degrees gives none; turning back the other way restarts the count, and turning back again restarts it once more; wiggling A and D for 32 s gives no 360. The model's rotation is never wrapped, so the angle sum has no jump at +-180 degrees.
3. **Alternate drift: pass.** `test_forward_release_backward_forward_gives_one_per_switch` (W, release, S, release, W, release, S with A held: 3) and `test_switching_steering_direction_gives_none` pass, with the switch-time, shortest-drift, keep-steering and live-tuning tests. QA's own checks: W with A straight to S with D (no gap) gives none; a 0.04 s tap of D during the switch, back to A, gives none while "keep steering" is on; W then W again with a gap gives none; W with A, then W with D, then S with D gives one (the switch with the same steering counts); ten forward/backward semicircles in a row give 19; 40 quick W/S taps of 0.1 s give none; W+S held then W released gives one; with both limits at 0, a no-gap switch counts and a one-step gap does not.
4. **Tuning panel sliders and reset: pass.** `test_panel_has_trick_sliders_and_reset_restores_the_proposed_values` passes: a "Tricks" group with sliders for switch time (0 to 2 s, starts at 0.5) and shortest drift (0 to 2 s, starts at 0.3), a keep-steering toggle (on), all with tooltips, applied live; the panel's reset restores 0.5, 0.3 and on, and the controls follow. `CarTuning.default_values()` includes all three. A screenshot of the prototype with the panel open (`drift_prototype_demo_iso_panel.tscn`, 300 frames, saved to the git-ignored `screenshots/qa_t079/panel_readout.png`) shows the readout's "Last trick: extended drift (0.1 s ago)" and "Tricks: extended 1 360 0 alternate 0" lines.
5. **Movement unchanged: pass.** `git diff master...HEAD -- game/scripts/driving/car_model.gd` is empty. In `car.gd` the detector is called after the model's update and only reads it (QA read `trick_detector.gd`: it writes nothing to the model). `test_movement_is_the_same_with_and_without_trick_detection` drives every key combination with two cars (detection on and off) and the bare model, and position, velocity, rotation and drift amount are exactly equal on every step. QA also checked that a car with detection off emits no trick signal. `test_drift_model.gd`, `test_drift_prototype.gd` and `test_car_collisions.gd` (T-012, T-029, T-033) are unchanged on this branch and pass.
6. **Documents: pass.** `game/README.md` has a new "Tricks" section with the `trick(trick_id: String)` signal, the ids and how each trick is found, and the limits table. The ids `extended_drift`, `three_sixty`, `alternate_drift` match `trick_add` in `game/data/combo.json` on master. In `git diff master...HEAD -- docs/drifting.md`, the only changes are in Content ("Godot drift prototype": a new "Tricks" bullet, and "the last trick" added to the readout); Summary, Decisions and Open questions are unchanged. The detection matches Drifting, Decisions for all three tricks.
7. **Full test suites: pass.** Full GUT suite (`bash game/tools/run_tests.sh`): 202/202, TESTS PASSED, exit 0 (the one GUT warning, inner class `TestRoom` skipped, is already on master). Python: `game/tools` 62 tests OK, `tools` 75 tests OK.

QA's 21 edge-case tests above ran in a temporary GUT script, all passed, and were deleted (not committed).

Notes for the Project Lead, not failures:
- **Merging master:** master has moved on (T-055, the screen flow). `git merge-tree` shows master merges into this branch with no conflicts. `game/README.md` changed on both sides, but in different places. The merge was not made, and the tests were not run on the merged result.
- **For the board's tuning:** a W to S switch with no gap (S pressed before W is released) is not a break, so the extended-drift second and the 360 count carry on through it. With a gap (W released first), both restart at the switch. The agent's result notes say the same. A grace time for breaks would be a new decision for Drifting, Decisions.
- The Tricks group is at the bottom of the tuning panel, so the board has to scroll down to reach it.
- `docs/drifting.md`'s tuning panel bullet still says the reset goes back "to the Unity values". This wording was already there before this task, and it hasn't been true since T-029 and T-033 (the trick limits now reset to their proposed values too). The Project Lead may want to fix it in the doc.
- The worktree has uncommitted changes to `.import` files under `game/addons/gut/`, `game/art/` and `game/audio/` (left by Godot's import, not part of this task). QA left them uncommitted.
