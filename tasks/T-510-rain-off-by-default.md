---
id: T-510
title: Rain off by default
status: open
from: project-lead
to: level-challenge
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, tasks/T-507-rain-over-the-map.md]
files_expected_to_change: [game/scripts/, game/tests/unit/, game/docs/, docs/level-design.md]
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

The board, 2026-11-02, after playing the rain (docs/level-design.md, Decisions, "Rain over the map", "Off by default"): the saved setting rain_enabled defaults to false, so a new player (no saved settings, or saved settings without the rain key) has no rain until they tick the Rain checkbox in the pause settings. A player who already saved a choice keeps it. Change the default where T-507 defined it (and anywhere else it is assumed true: the pause screen's checkbox start state, tests that pin the default), update game/docs/ and docs/level-design.md Content if they say on by default. The board asked for this to be merged and pushed to itch.io straight after QA, without its own playtest. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-510 --text "..."`. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: with no saved setting (and with saved settings that lack the rain key), rain_enabled is false and no rain draws in a run. (QA: pass / fail)
- [ ] A unit test: a saved rain_enabled true still shows rain; ticking the checkbox still turns it on at once and saves it. (QA: pass / fail)
- [ ] The pause screen's Rain checkbox starts unticked for a new player (test). (QA: pass / fail)
- [ ] No doc in docs/ or game/docs/ still says the rain is on by default. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] A screenshot of a new player's run with no rain and the unticked checkbox, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
