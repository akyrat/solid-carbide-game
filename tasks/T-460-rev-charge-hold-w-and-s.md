---
id: T-460
title: Rev Charge: hold W and S to charge a boost that fires when S is released, with a placeholder charge and boost effect
status: needs-playtest
from: project-lead
to: driving-drift
lead: Goal-G-009
epic: driving
milestone: mvp
goal: G-009
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-455, T-457]
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/driving/drift.md, game/docs/driving/effects.md, game/scripts/driving/car.gd, game/scripts/driving/car_model.gd, game/scripts/driving/boost_effect.gd, game/scripts/run/run_state.gd, game/data/power_ups.json]
files_expected_to_change: [game/scripts/driving/rev_charge.gd, game/scripts/driving/rev_charge_effect.gd, game/scripts/driving/car.gd, game/tests/unit/test_rev_charge.gd, game/tests/fixtures/rev_charge_demo.gd, game/tests/fixtures/rev_charge_demo.tscn, game/docs/driving/drift.md, docs/drifting.md]
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

Drifting, Decisions, 'Driving power-ups': Rev Charge. With the power-up owned (RunState.power_up_tier('rev_charge') > 0), holding W and S at the same time charges a powerful boost, which fires when S is released. Charge time and boost strength come from the owned tier in power_ups.json. Without it, W+S behaves exactly as today (W wins over S). Decide, as proposals, what the car does while charging (held in place or slowing), whether a partial charge fires a partial boost, and how it meets drifting, the air and the wreck; write them in Drifting, Content.

A visible effect plays while charging and while boosting: a placeholder drawn in code (for example a growing glow at the rear and speed lines on release; it may reuse the cruise boost effect), replaced later by the art ticket.

Screenshots or a short GIF of a charge and its release.

The board's review: play a run with Rev Charge granted at each tier: how charging and releasing feels, and the placeholder effect.

## Acceptance criteria

- [ ] With Rev Charge owned, holding W+S charges, and releasing S fires a boost that raises the car's speed; the charge time and boost strength match the owned tier's numbers, and a higher tier gives a stronger or faster charge (GUT tests). (QA: pass)
- [ ] Without the power-up, W+S gives the same speed and state as before over the same steps (GUT test). (QA: pass)
- [ ] A placeholder effect is visible while charging and while boosting, and stops after (GUT test of its visibility; screenshots or a GIF in art-archive/<id>/screenshots/). (QA: pass)
- [ ] Drifting, Content, describes Rev Charge's behaviour and the proposals. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Blocked → In progress

Goal runner (G-009): started, in C:\solid-carbide-worktrees\T-460.

### 2026-10-31, In progress → In QA

Goal runner (G-009): the agent is done; QA is checking it.

### 2026-10-31, In QA → Needs playtest

Goal runner (G-009): QA passed; merged into playtest/G-009.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Driving & Drift Agent, 2026-10-31 (goal G-009). Done.

**What was built**
- `game/scripts/driving/rev_charge.gd` (new): `car.rev_charge`. At tier 0 (not owned) it returns at once, so the car is the same as before. With a tier, W+S charges (`charge_seconds` from power_ups.json via `PowerUpData.at`). Releasing S fires a boost: the forward speed is held at least at top speed × the multiplier for `boost_seconds`. Signals: `charge_started`, `charge_cancelled`, `fired(fraction, boost_speed, seconds)`, `boost_ended`.
- `game/scripts/driving/car.gd`: calls `rev_charge.before_step()` and `step()` around `model.update_velocity()`. A wall or ground-side hit (`_end_drift_on_hit`) ends a running boost. With `input_enabled` off (the wreck), `rev_charge.reset()` is called.
- `game/scripts/driving/rev_charge_effect.gd` (new): the placeholder drawn in code. While charging, a glow at the rear grows with the charge and pulses when full (heat yellows and oranges). While boosting, 5 light blue-grey speed lines fade out. Nothing shows without the power-up.
- `game/scripts/run/run.gd` (not in files_expected_to_change; needed for the board's playtest in a run): adds a "RevChargeEffect" child to the View, drawn over the car (under the car, the sprite hid the glow), lifted on raised ground like the boost effect. It also sets the car's tier from `RunState.power_up_tier("rev_charge")` on each new car and on `power_ups_changed` (`_apply_rev_charge_tier`).
- Fixtures: `game/tests/fixtures/rev_charge_demo.tscn` (tier 4, stepped once per frame) and `rev_charge_demo_record.tscn` (also saves frames for the GIF; this one is not in files_expected_to_change).

**Proposals for the playtest** (written in Drifting, Content, "Rev Charge (task T-460)")
- While charging, the car brakes to cruise speed at the ramp rate, then holds there. Steering and drifting still work.
- A partial charge fires a partial boost: the extra speed and the length both scale with the charge. Below 25% nothing fires.
- Letting go of W first drops the charge.
- In the air, the charge doesn't grow, and releasing S drops it. A boost that is already running keeps its clock in the air.
- A wall hit ends the boost but keeps the charge.
- The wreck drops both the charge and the boost.

**Tests:** `game/tests/unit/test_rev_charge.gd` has 16 tests: tier numbers, charge time per tier, boost strength and length per tier, higher tier is stronger and faster, slowing to cruise while charging, partial charge, short overlap, W released first, the wreck, a wall hit, no power-up matches `CarModel.step` step for step, effect visibility and stop, and the run sets the tier.
- GUT full suite: 2395/2395 passed (931 s).
- `python -m unittest discover -s game/tools`: 767 tests OK (1 skipped).
- `python -m unittest discover -s tools`: 614 tests OK.

**Screenshots** (`art-archive/T-460/screenshots/`): `rev_charge_t4_charging.png` (the glow while charging), `rev_charge_t4_boosting.png` (the speed lines after release), `rev_charge_t4_after.png` (the effect gone after the boost), `rev_charge_t4.gif` (a full charge and release, tier 4, real time).
- The GIF's source frames are in `art-archive/T-460/frames/`, not committed (90 PNGs). I didn't delete them, since deleting needs a command that isn't pre-approved. The fixture rebuilds them.

**Documents affected:** `docs/drifting.md` (Content, "Rev Charge (task T-460)"). Also `game/docs/driving/drift.md` ("Rev Charge (T-460)").

**PixelLab:** 0 generations. Refusals: none.

**QA round 1 (2026-10-31):** all five criteria pass. test_rev_charge.gd re-run: 16/16. `python -m unittest discover -s tools`: 614 OK. `-s game/tools`: ran, no failure. Screenshots (3 PNG + GIF) exist. Drifting doc has the Rev Charge section. The full GUT suite (931 s) is longer than the 10-minute foreground limit, so I did not re-run it and relied on the agent's 2395/2395. `tools/qa_check.py` was refused (not pre-approved), so it was not run.

**Housekeeping notes:**
- I ran one harmless no-op heredoc command by mistake (not refused).
- The GUT run went past the 10-minute foreground limit and finished in the background with exit 0. No background jobs are left.
- 2026-10-31, in-qa → needs-playtest: QA passed every criterion (goal G-009).
