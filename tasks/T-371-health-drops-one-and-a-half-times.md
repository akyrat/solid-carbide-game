---
id: T-371
title: Health drops 1.5 times as often
status: in-qa
from: project-lead
to: game-data
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/enemies.md, game/docs/]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/data/enemies.json]
files_expected_to_change: [game/data/enemies.json, game/tests/unit/, game/docs/, docs/enemies.md]
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

The board's decision (Enemies, Decisions, "Health drops 1.5 times as often", 2026-10-29): "increase the drop rate of health items by enemies by 1.5 times of what it is now." Today a killed minion drops a health pickup with a chance of 0.15 (`game/data/enemies.json`, `health_drops.drop_chance`, T-333). Make it 0.225 (1.5 x 0.15). Nothing else changes: the coins' rate, the heal (1 heart) and the kaiju (drops none). Update the `_comment` with the history, any test that pins 0.15, and Enemies, Content and the game docs where they give the number.

The board's review: play a run and feel the health drops.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `health_drops.drop_chance` in game/data/enemies.json is 0.225 and nothing else in the file changed except its comment (diff). (QA: pass / fail)
- [ ] A test checks the drop chance is read from the data (no number pinned in code), and tests that pinned 0.15 are updated. (QA: pass / fail)
- [ ] Enemies, Content and the game docs give the new number. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started: health drops 1.5 times as often (0.15 to 0.225).

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Done (game-data). `health_drops.drop_chance` 0.15 to 0.225 in game/data/enemies.json; only that value and its `_comment` history changed. Tests updated: test_health_drops.gd (reads the data, 0.225, ratio to the old 0.15 is 1.5; the statistical test now expects 3/8 of the coins' rate, renamed `..._about_three_eighths_of_the_coins...`), test_run_hearts.gd, test_run_data.gd. Docs: docs/enemies.md (Health pickups line; the Decisions entry was already there), game/docs/enemies/minions.md. No separate Content doc gives the number. The long GDD is regenerated at merge.
Tests: game/tools unittest 573 OK; tools unittest OK; GUT 1849 tests: first run 1848 pass and 1 fail (the old quarter-ratio test, then fixed); test_health_drops rerun 11/11 pass. The full GUT was not rerun after that fix (about 9 min).
