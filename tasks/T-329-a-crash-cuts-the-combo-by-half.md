---
id: T-329
title: A crash cuts the combo by 50%, not 80%
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
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/docs/game-loop/the-run.md, game/data/combo.json, game/scripts/data/combo_data.gd, game/scripts/run/run_state.gd]
files_expected_to_change: [game/data/combo.json, game/scripts/run/run_state.gd, game/tests/unit/, game/README.md, docs/game-loop-architecture.md]
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

The board's decision (Game loop architecture, Decisions, "A crash cuts the combo by 50%", 2026-10-28): breaking the combo (a collision with a wall, a building, the map edge or a boulder, or any damage to the car) now cuts the part of the multiplier above "no combo" by 50% instead of 80%. So x4 becomes x2.5 (today x1.6), and the cap x6 becomes x3.5 (today x2).

Today the cut is `collision_cut: 0.8` in `game/data/combo.json`, applied by `ComboData.after_collision` (`new = start + (old - start) * (1 - collision_cut)`); only the number changes, not the formula. Also update the comments and docs that name the 80%: the comment on `RunState.collision()` in `game/scripts/run/run_state.gd`, `game/README.md` (the `collision()` row and any other mention), the header comment of `game/tests/unit/run/test_run_combo.gd`, and Game loop architecture, Content (the "Hitting a wall..." line). The "combo broken" popup still shows whenever the multiplier went down, as today.

The board's review: play a run, crash with a high combo and feel how much is left.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `combo.json`'s `collision_cut` is 0.5. (QA: pass)
- [ ] A test checks that a collision at x4.0 leaves x2.5 and at x6.0 leaves x3.5, and that a collision at x1.0 leaves x1.0 with no "combo broken" signal. (QA: pass (x4->2.5, x6->3.5 in test_run_combo.gd/test_combo_data.gd; x1.0 no combo_broken in test_combo_broken_popup.gd))
- [ ] Every test that assumed 0.8 is updated, and none is weakened beyond the number change (the result notes list them). (QA: pass)
- [ ] No comment or doc in `game/` or `docs/` still describes the collision cut as 80% (outside the timeline and dated Decisions entries); Game loop architecture, Content and `game/README.md` say 50%. (QA: pass (round 2: docs/drifting.md:195 now says 50% since T-329; no other live 80% mention outside Decisions history))
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass (all three sets passed in qa_check))

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Taken over from Tokens on the board's word. Started: a crash cuts the combo by 50% instead of 80%.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Done (Game Data). `collision_cut` 0.8 -> 0.5 in `game/data/combo.json`; the formula is unchanged, so T-356 (bad reactions burst) and T-319 (recap stats) are untouched and their tests pass.
- Updated tests: `test_combo_data.gd` (cut 0.5; after_collision(5.0) is 3.0, new x4 -> 2.5 and x6 -> 3.5 checks; x1.0 stays 1.0), `test_run_combo.gd` (header and two test names say 50%; new test for x4 -> x2.5 and x6 -> x3.5 through `collision()`), `test_crash_pays_trick.gd` (assert message). Every other test computes through `after_collision`, so only the number moved; none weakened.
- Comments and docs now say 50%: the `RunState.collision()` comment, `game/docs/game-loop/the-run.md` (the `collision()` row; game/README.md is an index and never named the percentage), Game loop architecture lines 21 (Combo) and 145 (Content). The dated Decisions entry (line 49) keeps the 80% as history.
- Tests: GUT 1931 of 1931 passing (156 scripts); Python unittest run printed "Ran 573 tests, OK" (my output was tailed, so the two Python sets' counts are not separated; no failure shown).
- Refused once: a hook refused an inline Python edit of this ticket file; I used the Edit tool instead.

QA round 1: criteria 1,2,3,5 pass; 4 fails (paperwork): docs/drifting.md:195 still says 80%. Three test sets passed per qa_check (counts not printed by its summary; builder reported GUT 1931/1931, Python 573 tests). README criterion met via game/docs/game-loop/the-run.md; screenshots waived (data-only).

QA round 2: all criteria pass. Criterion 4 fixed (drifting.md:195, commit d8f06460). Tests not rerun (only a doc changed since the green sets of round 1). qa_check documents (game/README.md) and screenshots lines are the same waived items as round 1 (README is an index; data-only ticket).
