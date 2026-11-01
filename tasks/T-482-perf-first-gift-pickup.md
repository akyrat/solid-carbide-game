---
id: T-482
title: Frame drops: a 97 ms hitch at the first gift pack pickup
status: open
from: project-lead
to: game-loop
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: [T-468]
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, tasks/T-468-run-performance-recorder.md, game/docs/game-loop/perf-recorder.md, game/scripts/run/gift_drops.gd]
files_expected_to_change: [game/scripts/run/gift_drops.gd, game/tests/unit/, docs/game-loop-architecture.md]
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

The board's recorded run (T-468, recording `game/perf/2026-11-01_13-13-18` in T-468's folder): the longest frame (104 ms, 0:13 into the run) is `gifts.drops` in `game/scripts/run/gift_drops.gd` taking 97 ms (usually 0.02 ms), right at the first gift pack pickup and the level-up screen opening; gifts.drops was also the largest part of 2 more spikes. Likely a first-time load or build (a scene, texture, sound or the level-up screen's content) done on pickup; find it.

Move that cost out of play (load it with the run, before the first pickup), so picking up any gift pack costs under 2 ms, with everything looking and behaving as today. Measure before and after. Never write, move or commit anything in game/data/levels/.

The board's review: pick up the first gift pack in a run and feel no hitch.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes say what took the 97 ms, with the evidence. (QA: pass / fail)
- [ ] A measured before/after shows the first gift pack pickup's gifts.drops under 2 ms; numbers in the result notes. (QA: pass / fail)
- [ ] A test shows the moved load is ready before the first pickup, and the existing gift pack tests still pass. (QA: pass / fail)
- [ ] docs/game-loop-architecture.md notes what is loaded with the run, if that changed. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
