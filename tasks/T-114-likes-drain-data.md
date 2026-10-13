---
id: T-114
title: Data: how fast the likes bar drains
status: in-progress
from: project-lead
to: game-data
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/data/run.json, game/data/combo.json, tasks/T-038-run-and-likes-data.md, tasks/T-080-combo-data.md, game/README.md]
files_expected_to_change: [game/data/run.json, game/scripts/data/run_data.gd, its tests, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board decided the likes drain for the MVP (Game loop architecture, Decisions, "Likes drain", 2026-10-13): once the combo has fully drained (the multiplier is back to "no combo"), the likes bar slowly empties, but never below the start of the current level. A trick stops it, since it raises the combo again. T-115 builds the behaviour; this task adds the numbers it reads.

1. Add the drain numbers to `game/data/run.json` and expose them through `game/scripts/data/run_data.gd`, the way the other run numbers are read. At least: whether the drain is on, and how fast it drains. Propose whether the speed is a flat XP per second or a share of the current level's bar per second, and a starting value that feels slow (the board said "slowly"); for comparison, a drift second gives 10 XP and level 1 needs 100. Write the reasoning in the result notes and in the file's `_comment`.
2. If you think a short extra wait after the combo has drained is needed, propose it as a separate number, defaulting to 0 (the board's rule is that it starts when the combo has drained).
3. Write tests for the new values and their defaults.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] `game/data/run.json` has the drain numbers, and `run_data.gd` returns them; a GUT test checks they load and have sensible values (on by default, speed above 0) (QA: pass / fail)
- [ ] The result notes and the JSON `_comment` give the proposed speed and why it is "slow" compared with the drift XP (QA: pass / fail)
- [ ] game/README.md lists the new numbers where the run numbers are described (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
