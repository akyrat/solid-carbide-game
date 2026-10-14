---
id: T-045
title: The kaiju: arrives at the boss time, can be damaged at any time, its death wins the run
status: open
from: project-lead
to: enemy-behavior
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-036, T-039, T-044, T-119]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-036-run-scene-and-state.md, tasks/T-039-enemy-data.md, tasks/T-044-minions.md, game/README.md]
files_expected_to_change: [the enemy code and scenes, tests, docs/enemies.md, game/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-036 (the run), T-039 (the numbers) and T-044 (the enemies' damage function) are done.**

Build the kaiju as Enemies, Decisions describes it, with T-039's numbers:
1. **Arrival:** on the run's "boss time" signal (T-036) the kaiju appears just off-screen and walks slowly towards the car.
2. **Contact damage and knockback**, like the minions.
3. **Damage:** weapons can damage the kaiju at any time, through the same damage function as the minions (T-044). It has no shield and no vulnerability windows (Enemies, Decisions, 2026-10-11).
4. **Health:** the kaiju's health is readable for the HUD, with a signal when it changes.
5. **Death:** at 0 health it dies and calls the run's kaiju-killed function (T-036), which ends the run as a win.

Its meteor attack is T-046. The kaiju itself is a placeholder for now: a large shape several times the car's size. The final kaiju art comes from a separate art task.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

**Kaiju coins (board, 2026-10-13):** when the kaiju is defeated it always drops a few coins (Enemies, Decisions; the number from T-119 in `enemies.json`). Its death ends the run straight away, so add its coins to the run's coins before the "run ended" signal, so they count in the coins saved.

## Acceptance criteria

- [ ] A test fires the "boss time" signal and shows the kaiju appears and moves towards the car (QA: pass / fail)
- [ ] A test shows weapon damage lowers the kaiju's health as soon as it has appeared, and the health signal fires (QA: pass / fail)
- [ ] A test damages the kaiju to 0 and shows the run's kaiju-killed function is called once (QA: pass / fail)
- [ ] A test shows contact with the car damages it and knocks it back (QA: pass / fail)
- [ ] A screenshot shows the placeholder kaiju (QA: pass / fail)
- [ ] `docs/enemies.md` describes the built kaiju in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

Written by the agent when it finishes.
