---
id: T-008
title: Short "boost" effect when W snaps the car to cruise speed
status: needs-playtest
from: project-lead
to: driving-drift
lead: Weapons
epic: driving
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: [T-012]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/drifting/unity-prototype-report.md, docs/extended-narrative.md, docs/visual-style.md]
files_expected_to_change: [the car's code and scene, and their tests]
qa_rounds: 2
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Unblocked: T-012 is done** (2026-10-08). The Godot car exposes the signal for the jump to cruise speed.

When the player presses W and the car jumps instantly to cruise speed (Drifting, Decisions; the jump is described in the Unity prototype report, section 4, step 5), a short "boost" effect plays to emphasise that jump.

- **When it plays:** when W is newly pressed and that press makes the car jump up to cruise speed. Not on the jumps back to cruise that happen every physics step during a held drift, and not while W stays held.
- **What it looks like:** a placeholder for now (for example a brief flash or streak behind the car). The final animation is made by the **Asset Generation Agent** in the linked task T-009, from the board's description. This task does not wait for it: when the art arrives, it replaces the placeholder, hooked to the same signal.
- Make the trigger a clear signal the art, the SFX Agent and the UI can hook into later.
- Changes no driving behaviour.

## Acceptance criteria

- [ ] A test shows the boost signal fires once when W is pressed from standstill, and once when W is pressed while moving slower than cruise speed (QA: pass)
- [ ] A test shows it does not fire while W stays held, including during a held drift where the car drops below cruise and jumps back every step (QA: pass)
- [ ] A test shows it does not fire when W is pressed while already at or above cruise speed (QA: pass)
- [ ] The car's speed values are identical with and without the effect, shown by a test (QA: pass)
- [ ] A screenshot taken just after pressing W shows the placeholder effect (QA: pass)
- [ ] The full test suite passes (QA: pass)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Updates

### 2026-10-15, Needs playtest

A placeholder boost effect is in: when a fresh W press snaps the car up to cruise speed, five light blue-grey streaks flash behind the car for 0.35 s (not during a held drift, not while W stays held; driving unchanged). The look is rough on purpose; the T-009 art replaces it. QA round 1: all 6 pass. It waits for the board's playtest in the unified build (C:\solid-carbide-worktrees\playtest).

## Result notes

Done on `task/T-008-cruise-boost-effect`.

- New signal `Car.boost(from_speed)`: `cruise_jump` filtered to `w_just_pressed` (`car.gd`). The driving model is untouched.
- Placeholder effect `game/scripts/driving/boost_effect.gd`: five opaque light blue-grey streaks behind the car, 0.35 s, shrinking, no red. Added to the run (`run.boost_effect`, under the car) and bound to the car on each new run. Not added to the drift prototype scene.
- Tests `game/tests/unit/test_boost.gd` (8): fires once from standstill; once when pressed below cruise; not while held in a drift (cruise_jump fires >3 times, boost 0); not at or above cruise; again on a new press; speeds and rotation identical with and without the effect; effect plays and ends; the run binds it.
- Full GUT suite: 679 pass. Python tests in `tools/` (171) and `game/tools/` (251) pass.
- Screenshot (git-ignored): `C:\solid-carbide-worktrees\T-008\screenshots\T-008-boost-6.png`, from `bash game/tools/screenshot.sh res://tests/fixtures/boost_effect_demo.tscn screenshots/T-008-boost-6.png 6`. Streaks are visible behind the car; quality is rough (placeholder), look and size are for the board to judge.

**Documents updated:** `game/README.md` (new "Boost effect" section, file list).

**QA round 1 (2026-10-15):** all 6 criteria pass. test_boost.gd covers once-from-standstill, once-below-cruise, none while held in drift (cruise_jump fires >3, boost 0), none at/above cruise, identical velocity and rotation with and without the effect. Screenshot shows light streaks behind the car. Full GUT: 679/679 pass. Signal is `cruise_jump` filtered by `w_just_pressed`; car.gd change is signal-only.
- 2026-10-15, in-qa → needs-playtest: QA passed
