---
id: T-394
title: Level creator: an obstacle in several pairs, and a row paired as a chain, so a row can be threaded gap after gap
status: in-progress
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

- [ ] In the creator an obstacle can be in several pairs (pairing B with C keeps A with B), and picking several obstacles in order then Pair makes the chain of consecutive pairs (tests). (QA: pass / fail)
- [ ] Unpair removes only the pair aimed at, as the result notes describe (tests). (QA: pass / fail)
- [ ] In a run, threading a row of three gaps one after another pays thread the needle three times, each gap with its own cool-down, and a crash pays nothing (tests). (QA: pass / fail)
- [ ] A level saved before opens with its pairs, the new pairs save and reopen, and check_level.py accepts them (tests). (QA: pass / fail)
- [ ] Level design, Content and game/docs/level/ describe the controls and the rules. (QA: pass / fail)
- [ ] Screenshots of a chained row in the editor and a GIF of threading it in a run are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: an obstacle in several pairs, a row paired as a chain in one go, and each gap paying its own thread the needle.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
