---
id: T-079
title: Tricks: detect extended drifts, 360s and alternate drifts
status: in-qa
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
qa_rounds: 0
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

- [ ] A test holds a drift for 3.5 seconds and shows exactly 3 extended-drift signals (QA: pass / fail)
- [ ] A test drifts the car through a full circle in one direction and shows one 360 signal; two circles give two; a drift that turns 300 degrees and then breaks gives none (QA: pass / fail)
- [ ] A test drives the forward-drift, release, backward-drift sequence with the same steering and shows one alternate-drift signal per switch; switching steering direction gives none (QA: pass / fail)
- [ ] The tuning panel has sliders for the alternate drift's timing limits, and its reset restores the proposed values (QA: pass / fail)
- [ ] A test shows the car's movement is exactly the same with trick detection on as before (T-012 and T-029's tests still pass) (QA: pass / fail)
- [ ] `game/README.md` documents the trick signal and the trick ids, and `docs/drifting.md` describes the detection in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

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
