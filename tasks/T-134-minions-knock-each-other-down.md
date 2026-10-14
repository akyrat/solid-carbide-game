---
id: T-134
title: Minions that bump into each other fall down, get up and carry on
status: open
from: project-lead
to: enemy-behavior
lead: Enemies
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-044, T-068]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/visual-style.md, tasks/T-044-minions.md, tasks/T-068-minion-art.md, game/README.md]
files_expected_to_change: [the enemy code, tests, docs/enemies.md, game/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Polish, built once the MVP is playable end to end (board, 2026-10-14).** Enemies, Decisions: when two minions bump into each other, they fall down, get up again and carry on running at the car.

- Detect two minions bumping into each other. Both fall down for a short time (your proposal, in the result notes; the board judges it in playtests), then get up and go back to chasing the car.
- While down, a minion doesn't move and doesn't damage the car. It can still be hit by weapons through `take_damage`.
- Expose a "down" state and signals (fell, got up) so the art task T-135 can play its fall-down and get-up animations. Until then, show the fall with a placeholder (for example the walking sprite tilted or squashed), never Redgull red.
- Pausing freezes it; a new run clears it, as for the rest of the minion.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test puts two minions on a collision course and shows both fall down, stay still for the proposed time, then get up and move towards the car again (QA: pass / fail)
- [ ] A test shows a fallen minion doesn't damage the car while down, and still takes weapon damage (QA: pass / fail)
- [ ] A test shows the fell and got-up signals fire once per fall (QA: pass / fail)
- [ ] A screenshot of a run shows a fallen minion's placeholder next to standing ones (QA: pass / fail)
- [ ] `docs/enemies.md` describes it in Content and `game/README.md` documents the state and signals for T-135, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

Written by the agent when it finishes.
