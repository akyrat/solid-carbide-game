---
id: T-513
title: Tricks pay subs
status: open
from: project-lead
to: game-loop
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [docs/game-loop-architecture.md, game/data/combo.json, game/data/run.json, tasks/README.md]
files_expected_to_change: [game/scripts/, game/data/combo.json, game/data/run.json, game/tests/unit/, docs/game-loop-architecture.md]
model: sonnet
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

Each trick (the ones in game/data/combo.json trick_add: FULL 360, ALT DRIFT, AIR 180, AIR 360, THREAD THE NEEDLE; and the drift's own pay and airtime if you judge they count as tricks, say so) now also pays subs straight away, into the sub goal (the same XP the run's levels use), on top of raising the multiplier as today. Propose the numbers for the playtest in game/data (for example a trick_subs table in combo.json or run.json, with a _comment), and whether the multiplier multiplies them (a proposal; say why). Keep everything else about the combo and the subs as it is (drain, cuts, drift pay). Expose a signal or value the HUD can use to show the subs a trick paid (the UI Agent's T-514 shows them going into the sub goal). Update docs/game-loop-architecture.md Content (the combo and subs sections) with what was built and the proposals.

The board, 2026-11-02: the live viewers are confusing; back to the combo multiplier number, shown beside the car; tricks also pay subs. Decisions: docs/game-loop-architecture.md, "Back to the combo multiplier; tricks pay subs", and docs/hud-and-menus.md, "The multiplier beside the car". The board plays T-512..T-514 together in one playtest build before anything merges. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: each trick in trick_add adds its proposed subs to the run's XP when it pays, on top of its multiplier add. (QA: pass / fail)
- [ ] A unit test: the multiplier's own behaviour (add, cut, drain, drift pay multiplied) is unchanged. (QA: pass / fail)
- [ ] The numbers live in game/data with a _comment, not in code; the result notes give them and the reasoning. (QA: pass / fail)
- [ ] docs/game-loop-architecture.md Content describes how tricks pay subs and points to the data. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] A screenshot of a run where a trick fills the sub goal, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
