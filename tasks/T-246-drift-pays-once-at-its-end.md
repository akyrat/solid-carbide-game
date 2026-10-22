---
id: T-246
title: A drift pays once at its end, scaled by how long it lasted
status: in-qa
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, game/README.md, game/scripts/driving/trick_detector.gd, game/data/combo.json, game/scripts/hud/trick_popups.gd, tasks/T-242-airtime-trick.md]
files_expected_to_change: [game/scripts/driving/trick_detector.gd, game/data/combo.json, game/scripts/hud/, game/tests/unit/, game/README.md, docs/drifting.md, art-archive/T-246/screenshots/]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decision (Drifting, Decisions, "Drift pays once, at its end", 2026-10-22): the extended drift trick no longer pays a small LONG DRIFT! every second. A whole drift pays once, when it ends, with a combo amount scaled by its length in seconds and hundredths, shown in the existing LONG DRIFT! popup with its amount (no new text). It mirrors the airtime trick (T-242, being built in parallel on its own branch; keep your change to the drift's payout so the two merge cleanly). The XP from drifting seconds stays as it is. Propose reasonable defaults as tuning numbers in `game/data/combo.json` (an amount per second, a minimum length below which nothing pays, a cap), keeping a long drift worth about what it pays today in total. The drift's 360 and alternate drift tricks are unchanged. A drift broken by the air (Drifting, "No drifting in the air") ends there and pays. The live drift counter is T-247's.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a screenshot of the popup and a short GIF of a long drift paying out.

## Acceptance criteria

- [ ] Tests show a drift pays nothing while it lasts and once when it ends, with the amount the data's scaling gives for its length (two different lengths give the expected amounts), and a drift below the minimum pays nothing (QA: pass; test_tricks.gd covers nothing while it lasts, one payment at end, 1.5 s and 3.5 s amounts, 0.98 s pays nothing; GUT green)
- [ ] The popup is the existing LONG DRIFT! text with its amount; FULL 360!, ALT DRIFT! and the drift-second XP behave as before (tests) (QA: pass; popup is the existing LONG DRIFT! +0.12 in the screenshot and GIF; 360, ALT and XP tests unchanged and green)
- [ ] The scaling numbers live in `game/data/combo.json` and are listed with their reasons in the result notes and Drifting, Content (QA: pass; drift_pay in combo.json, reasons in the result notes and docs/drifting.md Content)
- [ ] A GIF of a long drift paying out is in `art-archive/T-246/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass; GIF and PNG present, popup appears as the drift ends; GUT 1291/1291, tools 439 OK, game/tools 393 OK)

The board's review: drift for a while and watch it pay out at the end.
Board review files: the GIF in `art-archive/T-246/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started.

### 2026-10-22, In progress → In QA

Built: a drift pays once when it ends, 0.05 a second from 1 s, capped at 0.5, in the LONG DRIFT! popup. Sent to QA.

## Result notes

Written by the agent when it finishes (Driving & Drift Agent).

**Built.** A whole drift now pays once, when it ends (keys let go, a break, or a takeoff), and nothing while it lasts.
- `game/scripts/driving/trick_detector.gd`: the per-second emit is gone. On the first step that is not drifting it emits one `extended_drift` if the drift lasted at least `drift_min_seconds`, with its length in `last_trick_seconds` (set just before the signal; 0 for other tricks). `reset()` forgets a drift in progress without paying. 360 and alternate drift untouched.
- `game/data/combo.json`: `trick_add.extended_drift` removed, new `drift_pay` block. `ComboData` gets `drift_min_seconds()`, `drift_amount(seconds)`, `trick_amount(trick, seconds)`; `after_trick(multiplier, trick, seconds := 0.0)`.
- `RunState.add_trick(trick_id, seconds := 0.0)`; `run.gd` connects the car's `trick` signal through a lambda that passes `car.tricks.last_trick_seconds`. The `trick(trick_id)` signal itself is unchanged, so the popups (existing LONG DRIFT! text, small size, "+amount") needed no change. The XP from drifting seconds (`run_state.gd`) is untouched.
- Merge note for T-242: it will touch `trick_detector.gd` (observe_air/_land and the ids) and `combo.json` `trick_add`; my edits there are the extended-drift block in `observe()`, the header comment, the removed `EXTENDED_DRIFT_SECONDS`, the new `last_trick_seconds`/`drift_min_seconds` vars and `_emit`, and the `drift_pay` block plus removal of one `trick_add` line. If T-242 also forwards a per-trick amount through `add_trick`, the two should share one parameter.

**Scaling proposal (all in `combo.json`, `drift_pay`, for the playtest):**
- `per_second` 0.05: the old build paid 0.05 per full second, so a drift pays about what it did in total (4 s: 0.20), now counting hundredths (2.38 s pays +0.12).
- `min_seconds` 1.0: the old build paid nothing before the first full second.
- `max` 0.5: equal to an ALT DRIFT!, reached at 10 s; the old build had no cap.
Listed in Drifting, Content, "Drift pays once, at its end (task T-246)".

**Tests.** `test_tricks.gd` (pays nothing while it lasts and once at its end; 1.5 s and 3.5 s give amounts 1.5x and 3.5x one second's; 0.98 s pays nothing, 1.0 s pays; steering side change does not end it; a break ends it; reset), `test_run_likes.gd` (a run scene: no combo while drifting, one payment scaled by the length and the popup "LONG DRIFT! +0.0x", drift-second XP unchanged), plus updated `test_hud_combo.gd`, `test_hud_combo_hidden.gd`, `test_run_combo.gd`, `test_run_likes_drain.gd`, `test_combo_data.gd`, `test_air_tricks.gd` for the new amount. Results: GUT 1291 of 1291 pass; `python -m unittest discover -s tools` 439 OK; `python -m unittest discover -s game/tools` 393 OK (1 skipped). FULL 360! and ALT DRIFT! are covered by the existing tests, unchanged.

**Proposals / notes.** (1) The likes drain is no longer reset every drift second by the old trick, so it can start a little earlier during a long drift; a drift that ends pays then. Fixtures `combo_demo.gd` and `popups_follow_demo.gd` still emit `extended_drift` directly with length 0, so their popups show no amount. (2) A drift in progress when a run ends or `reset()` is called pays nothing.

**Screenshots** (in `art-archive/T-246/screenshots/`): `long_drift_popup.png` (LONG DRIFT! +0.12 after a 2.38 s drift, with FULL 360! +0.25 from the same drift) and `long_drift_pays_at_end.gif` (a 3.5 s drift, the popup appears as it ends). Fixture `game/tests/fixtures/drift_pay_gif.tscn`. In the recording the car drives over a ramp at the start and an AIR 180! pays first (the staged start spot); it is not part of the drift.

Documents affected: `docs/drifting.md` (Content: new "Drift pays once, at its end" section; the tricks and takeoff lines), `game/README.md` ("Tricks").
