---
id: T-443
title: Minions spawn on a timer from the screen's edges, faster as the run goes on, and move 30% slower
status: open
from: project-lead
to: enemy-behavior
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/enemies.md, game/docs/enemies/minions.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, game/docs/enemies/minions.md, game/data/enemies.json, game/data/combo.json]
files_expected_to_change: [game/scripts/enemies/, game/data/enemies.json, game/tests/unit/, game/docs/enemies/minions.md, docs/enemies.md]
model: opus
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

The board, 2026-10-31 (docs/enemies.md, Decisions, "Minions spawn on a timer, and 30% slower"): today the spawner keeps a wanted number of minions around the car (12 growing to 20) and only spawns when fewer are around, one every 0.5 s. That rewards not killing them: the fewer the player kills, the fewer come, so runs end with few likes and weapons.

Change it to a constant timer: minions spawn one after another on a timer, however many are already around, from just beyond the edges of the visible screen, as today (street only, clear of buildings and boulders, 3 units out). The timer speeds up over the run, so more come later. The combo's spawn multiplier (combo.json, spawning) still raises spawning, now by shortening the timer instead of raising a count. Minions move 30% slower: move_speed 6 becomes 4.2. The kaiju is unchanged.

Propose for the playtest, with your reasons in the result notes: the spawn interval at the run's start and at the kaiju's arrival (7 minutes) and how it changes in between, and a safety ceiling on minions alive at once if you think the game needs one (the board wants a constant flow, so a ceiling should be high and only there to protect the frame rate; say what number and why). Use the T-444 measurement idea (a minion count and frame time) informally if it helps choose. Put the numbers in game/data/enemies.json with a clear comment. Remove the old wanted-count numbers or mark them unused.

Never write, move or commit anything in game/data/levels/.

The board's review: play a full run; minions should keep coming from the screen's edges whether you kill them or not, more of them as the run goes on, and noticeably slower than before.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test shows minions keep spawning on the timer while many minions are already alive (no top-up to a wanted count). (QA: pass / fail)
- [ ] A test shows the spawn interval at the run's start, at 7 minutes and in between follows the numbers in enemies.json, and that the combo's multiplier shortens it. (QA: pass / fail)
- [ ] A test shows a new minion appears beyond the visible screen's edge, on the street, clear of buildings and boulders. (QA: pass / fail)
- [ ] A test shows minions move at 4.2 units per second (30% slower than 6), and the kaiju's speed is unchanged. (QA: pass / fail)
- [ ] The proposed spawn numbers and any ceiling, with reasons, are in the result notes and in enemies.json's comment. (QA: pass / fail)
- [ ] docs/enemies.md (Content, "Spawning") and game/docs/enemies/minions.md describe the timer. (QA: pass / fail)
- [ ] Screenshots of a run late on, with many minions, are saved and listed in the result notes (tasks/README.md, "Screenshots"). (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
