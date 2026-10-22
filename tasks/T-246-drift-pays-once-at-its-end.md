---
id: T-246
title: A drift pays once at its end, scaled by how long it lasted
status: open
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

- [ ] Tests show a drift pays nothing while it lasts and once when it ends, with the amount the data's scaling gives for its length (two different lengths give the expected amounts), and a drift below the minimum pays nothing (QA: pass / fail)
- [ ] The popup is the existing LONG DRIFT! text with its amount; FULL 360!, ALT DRIFT! and the drift-second XP behave as before (tests) (QA: pass / fail)
- [ ] The scaling numbers live in `game/data/combo.json` and are listed with their reasons in the result notes and Drifting, Content (QA: pass / fail)
- [ ] A GIF of a long drift paying out is in `art-archive/T-246/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: drift for a while and watch it pay out at the end.
Board review files: the GIF in `art-archive/T-246/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
