---
id: T-406
title: A wrecked car that slides into a health pickup's range picks it up and revives with 1 heart
status: in-qa
from: project-lead
to: game-loop
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/docs/game-loop/]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/docs/game-loop/the-run.md, game/scripts/run/wreck_effect.gd, game/scripts/run/]
files_expected_to_change: [game/scripts/run/, game/data/run.json, game/tests/unit/, game/docs/game-loop/, docs/game-loop-architecture.md, art-archive/]
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

The board's decision (Game loop architecture, Decisions, "A health pickup revives a wrecked car", 2026-10-30): "when the player dies and they keep moving, if they go over or near the magnet, the pickup range of a health potion, they actually pick it up and revive with one life." During the 3-second wreck (Wrecked: the stream keeps rolling), a health pickup still pulls and is picked up by the sliding car within its usual pickup range; then the car comes back with 1 heart: controls return, the smoke and flames stop, the recap timer is cancelled and the run goes on. Other pickups (gift packs, coins) during the wreck: your proposal (the board asked only about health). Proposals for the playtest, in the result notes: the usual 1-second invulnerability after the revive (likely yes, so the swarm round the wreck doesn't finish it at once), and what the combo and live viewers do. No new text.

Other agents are working at the same time: T-402 (pickups drawn and picked up at their height) and T-403 (the car's red flash on damage). Keep to the wreck and revive code; use the pickups' existing pickup signal rather than changing their code.

The board's review: lose the last heart while sliding towards a health pickup, and see the car revive.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A wrecked, sliding car within a health pickup's range picks it up and revives with 1 heart: controls return, the wreck effect stops and the recap does not show (tests). (QA: pass)
- [ ] Without a health pickup in range, the wreck ends with the recap after 3 seconds as before (existing tests). (QA: pass)
- [ ] The proposals (invulnerability, combo and viewers, other pickups) are in the result notes and behave as written (tests). (QA: pass)
- [ ] Game loop architecture (Content) and game/docs/game-loop/ describe it. (QA: pass)
- [ ] A GIF of a wreck revived by a health pickup is in `art-archive/<id>/screenshots/`. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass; GUT 1945/1945, game/tools 668 OK, tools 579 OK)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started in build F (Hits, enemies & weapons).

### 2026-10-30, In progress → In QA

Built: a wrecked, sliding car that touches a health pickup revives with 1 heart (controls back, smoke off, no recap, 1 s invulnerability); GIF in art-archive/T-406/screenshots; all three test sets pass.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Built (game-loop agent). During the wreck a health pickup is pulled by the magnet and picked up on touch; `RunState.heal_car()` while wrecked calls the new `RunState.revive()` (1 heart, `REVIVE_HEARTS`), which clears the wreck, the result and the recap summary, restarts the run (no `run_ended`, no recap) and sends `revived`; `run.gd` gives the controls back, stops the smoke and flames and refreshes the blink. Pickups' code is untouched (their existing `heal_car` path is used). `pickup_magnet.gd` runs while wrecked but pulls only health pickups. No data change (the invulnerability uses `car.invulnerability_seconds`).

Proposals for the playtest:
- Invulnerability: yes, the usual 1 second after the revive, with the blink, so the swarm cannot finish the car at once.
- Combo: stays cut as the fatal hit left it (no restore); live viewers follow the combo as always; the recap's peak viewers are kept.
- Other pickups: coins and gift packs stay still during the wreck (not pulled, not collected); only health pickups revive. A pickup restoring 2 hearts still gives 1 on a revive.
- Clock and counting: the clock runs on from where it stopped; coins, likes, tricks and kills count again.

Tests: `test_wreck.gd` 23 of 23 (6 new: revive with 1 heart and no recap, invulnerability, combo and viewers, no revive after the recap starts / without a pickup, a sliding wreck in the run scene picking up a pickup and driving again, the magnet pulling only health pickups; the old "heal_car during the wreck does nothing" line was removed). Three sets: GUT 1945 of 1945 passed; `game/tools` unittest 668 (OK, 1 skipped); `tools` unittest 579 OK.
GIF and screenshot: `art-archive/T-406/screenshots/revive.gif`, `revive.png` (`bash game/tools/record_revive.sh`, fixture `tests/fixtures/revive_demo.tscn`).
Docs: Game loop architecture (Content, "Wrecked", new bullet) and `game/docs/game-loop/the-run.md`.
