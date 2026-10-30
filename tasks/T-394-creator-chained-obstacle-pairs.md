---
id: T-394
title: Level creator: an obstacle in several pairs, and a row paired as a chain, so a row can be threaded gap after gap
status: in-qa
from: project-lead
to: level-challenge
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/level-design.md, game/docs/level/]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/docs/level/level-creator-pieces.md, game/scripts/level_creator/, game/scripts/run/, tasks/T-272-thread-the-needle.md]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/run/, game/tests/unit/, game/docs/level/, docs/level-design.md, art-archive/]
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

The board's decision (Level design, Decisions, "A row of obstacles can be threaded gap after gap", 2026-10-29). The board: "I have several obstacles in a row, and I want to be able to thread the needle in between all of them consecutively, but ... the current implementation doesn't allow for me to click on an obstacle and then pair it with two at the same time. It gets deselected from the other. Can you please come up with an intuitive solution that I can work in both ways?" Today (T-272, `game/docs/level/level-creator-pieces.md`, pairs) an obstacle is in at most one pair, and pairing it again moves it to the new pair.

The Project Lead's design (build it; adjust details if something reads better, and say so):
1. **An obstacle can be in several pairs.** Pairing A with B, then B with C, keeps both pairs. The same two obstacles are still one pair at most.
2. **Pair a row in one go:** pick several obstacles in order (for example Shift+click to add to the pick, the picked ones numbered on screen), then Pair (the button or P) pairs each one with the next: A with B, B with C, C with D. Picking two works as today.
3. **Unpair** removes only the pair it's aimed at: with two obstacles picked, their pair; with one picked, all of its pairs (your proposal if one-picked should open a choice instead).
4. **In the editor** every pair's link shows (as today's pair marker), so a chain reads as a row of links.
5. **In the run** each pair is its own gap: driving through a gap pays thread the needle for that gap; threading a row gap after gap pays each one (each pair keeps its own cool-down); a crash still pays nothing and cuts the combo.
6. **Saved levels:** the level file keeps its pairs list (a pair per entry); a level saved before still opens with its pairs; `check_level.py` accepts an obstacle in several pairs.

The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): read copies only, never write or commit them. Another agent (T-393) is fixing object heights in the level creator at the same time: keep your changes to the pairing code and the run's thread-the-needle code.

The board's review: in the creator, pair a row of obstacles as a chain, press Play and thread every gap in a row.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] In the creator an obstacle can be in several pairs (pairing B with C keeps A with B), and picking several obstacles in order then Pair makes the chain of consecutive pairs (tests). (QA: pass)
- [ ] Unpair removes only the pair aimed at, as the result notes describe (tests). (QA: pass)
- [ ] In a run, threading a row of three gaps one after another pays thread the needle three times, each gap with its own cool-down, and a crash pays nothing (tests). (QA: pass)
- [ ] A level saved before opens with its pairs, the new pairs save and reopen, and check_level.py accepts them (tests). (QA: pass)
- [ ] Level design, Content and game/docs/level/ describe the controls and the rules. (QA: pass; qa_check flags game/docs/level/ as a folder, but level-creator.md and level-creator-pieces.md changed on the branch)
- [ ] Screenshots of a chained row in the editor and a GIF of threading it in a run are in `art-archive/<id>/screenshots/`. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass; GUT all passed, 3 sets passed via qa_check)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: an obstacle in several pairs, a row paired as a chain in one go, and each gap paying its own thread the needle.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Level/Challenge Design Agent, 2026-10-30.** Built as designed. Commit `fbec6878` on `task/T-394-creator-chained-obstacle-pairs`.

**The controls as built (pair tool: Pair obstacles or P)**
- **One pair at a time, as before.** Click A, then B, and the pair is made. Then click B, then C. Each new pair now keeps the earlier ones, so the row ends up A-B, B-C, C-D.
- **A whole row in one go.**
  - With the tool on, **Shift+click** the obstacles in order. Each one gets a thicker ring and a number above it (1, 2, 3...).
  - Shift+click a numbered obstacle again to take it out of the row.
  - Then press **P** or **Pair obstacles**. Each obstacle is paired with the next one, and the tool stays on.
  - A **plain click** after a Shift+click row adds that obstacle as the last one and pairs the row straight away.
  - Picking two works as today.
- **Shift+click with the tool off.** On an obstacle, with nothing picked, it turns the tool on and starts a row.
- **The same two obstacles make one pair at most.** Pairing them again, in either order, changes nothing.
- **Unpair** removes only the pair you aim at. It shows only when there is something to remove.
  - Two picked (Shift+click): only their pair goes.
  - A row picked: only the pairs between neighbours in the pick go. Their other pairs stay.
  - One picked, or one selected with the tool off: all of its pairs go. This is my proposal for the one-obstacle case, instead of opening a choice.
- **Deleting an obstacle** removes its pairs. The rest of the chain stays.
- **In the editor** every pair has its own dashed line, so a chain reads as a row of links.
- **No new text.** All labels and messages are T-271's.

**Changes to the design, and why**
- **Shift+click with the tool off** also starts a row. I added it so a row can be started without pressing P first.
- **A plain click after a Shift+click row pairs the row.** It is the same rule as "the second click makes the pair", so the two ways of pairing behave the same.
- **P and Pair obstacles** pair the row when two or more are picked, and keep the tool on. With fewer picked they switch the tool on and off, as before.
- **The run's code did not need to change.** `ThreadTheNeedle` already made one gate per pair, each with its own cool-down. A touch of an obstacle cancels the pass through every gap that obstacle is part of. I only added the doc comment and the tests.
- **`check_level.py`** now accepts an obstacle in several pairs. It refuses the same two obstacles paired twice.
- **A note for the playtest:** `pair_hint` still reads "Pair: click two obstacles". It does not mention Shift+click. If the board wants that hint changed, it needs a Narrative Theme text task.

**Tests**
- `tests/unit/level_creator/test_creator_pairs.gd`: 33 tests. T-272's "one pair per obstacle" test is replaced by "several pairs". New tests cover:
  - the same two obstacles twice
  - a Shift+click row paired with P, with the button, or ended with a plain click
  - pairing one at a time
  - Shift+click to take one out, and Shift+click with the tool off
  - a real mouse Shift+click
  - the numbered row being drawn
  - Unpair of one, two, a row, and two that are not a pair
  - deleting the middle of a chain
  - a chain saved, reopened and passing `check_level`
  - a T-272-style level opening with its pairs
- `tests/unit/run/test_thread_the_needle.gd`: 22 tests, 6 new. They use a zigzag row of four boulders paired A-B, B-C, C-D, and cover:
  - one gate per pair
  - three gaps paid in order
  - each gap's own cool-down
  - a touch on a shared obstacle cancelling only that obstacle's gaps
  - a run threading the row, paying thread the needle three times with no crash
  - a crash into the row, paying nothing and cutting the combo
- `tools/test_check_level.py`: a chain is accepted, the same two paired twice is refused.
- **Full sets:**
  - GUT `bash game/tools/run_tests.sh`: 1962/1962 passing, TESTS PASSED.
  - `python -m unittest discover -s game/tools -p "test_*.py"`: 670 OK (1 skipped).
  - `python -m unittest discover -s tools -p "test_*.py"`: 573 OK.

**Screenshots** (`art-archive/T-394/screenshots/`; I looked at each one):
- `chain_in_editor.png`: a row of five boulders zigzagging along a road, paired as a chain (four links). A second row of barrier, cones and crates is picked with Shift+click and numbered 1, 2, 3.
- `thread_the_chain.gif`: the creator-built chained row of four boulders in a run. The car drives straight north through the three gaps, and THREAD THE NEEDLE! pops three times (combo 1.0 → 1.5 → 2.0 → 2.5, no crash).
- `chain_popup.png`: the third popup.
- `chain_drive_end.png`: the last frame.
- Fixtures: `tests/fixtures/level_creator_chain_demo.tscn` and `level_creator_chain_drive.tscn`. The commands are in `game/docs/level/level-creator-pieces.md`.

**Documents affected**
- `docs/level-design.md` (Content: "Level creator: thread the needle" updated, and a new "Level creator: a row paired as a chain")
- `game/docs/level/level-creator-pieces.md` ("Thread the needle (T-272)": data, "Several pairs and chains (T-394)", tests)
- `game/docs/level/level-creator.md` (the validator line)

I kept to the pairing code, the pair overlay and the run's thread-the-needle code, to stay clear of T-393. No refusals.
