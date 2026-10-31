---
id: T-451
title: Threading the needle flashes the pair and its dashed line
status: in-qa
from: project-lead
to: level-challenge
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, tasks/T-272-thread-the-needle.md, tasks/T-394-creator-chained-obstacle-pairs.md, tasks/T-420-needle-scrape-and-level-guards.md]
files_expected_to_change: [game/scripts/, game/tests/unit/, docs/level-design.md]
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

The board, 2026-10-31 (docs/level-design.md, Decisions, "Threading the needle flashes the pair"): when the car threads the needle in a run, the two paired obstacles and the dashed line connecting them flash, so the player sees which gap paid. With chained pairs (T-394), only the pair just threaded flashes. Code only, no new art: the flash's look (colour, length, how many pulses) is your proposal for the playtest, fitting Visual style. Never write, move or commit anything in game/data/levels/ (test with your own fixture levels).

The board's review: play a level with paired obstacles and thread them, including a chained row.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test threads a pair in a run and asserts both obstacles and their dashed line start flashing on that step and stop after the proposed time. (QA: pass / fail)
- [ ] A test with a chained row shows only the threaded pair flashes. (QA: pass / fail)
- [ ] A test shows a pass that doesn't thread (going round) makes no flash. (QA: pass / fail)
- [ ] Screenshots of the flash are saved and listed in the result notes (tasks/README.md, "Screenshots"). (QA: pass / fail)
- [ ] docs/level-design.md (Content) describes the flash. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built by the Level/Challenge Design Agent.

- `game/scripts/level/needle_flash.gd` (new, `NeedleFlash`): the run binds it to the ThreadTheNeedle (run.gd, `needle_flash`, only on levels with pairs); it starts on `threaded` (the step the trick pays) for that one pair, so a chained row flashes one gap at a time. `thread_the_needle.gd` keeps its markers by pair id and the marker draws brighter and thicker by a `flash` value.
- The look (a proposal for the playtest): two white pulses over 0.6 s (bright at 0, dark at 0.15, bright at 0.3, rest from 0.6). Obstacle pixels mix up to 75 percent towards white through a small canvas_item shader (modulate above 1 does not brighten in this renderer, tried first; the material is removed at rest, alpha kept). The dashed line goes opaque white and twice as thick. White only, none of Greenbull's colours. Constants at the top of the file: DURATION, PULSES, OBSTACLE_WHITEN.
- Tests `game/tests/unit/run/test_needle_flash.gd` (6): pulse curve; threading flashes both obstacles and the line from the paying step and stops after DURATION (all restored); a chained row flashes only the pair just threaded (pair-2 and pair-3, boulders 3 and 4 and their lines stay still); going round makes no flash; a touch (voided pass) makes no flash; a level without pairs has no flash.
- Test sets: `game/tools` unittest 767 tests OK (1 skipped); `tools` unittest 614 tests OK; GUT 2320/2320 passing in 191 scripts.
- Screenshots (`art-archive/T-451/screenshots/`, from `game/tests/fixtures/t451_needle_flash_demo.tscn`): 0_before.png (pair at rest, chalk line), flash_000.png (first frame; the capture lags the render by one frame so it still shows rest), flash_015.png (dark point), flash_030.png (second pulse peak: both boulders and the line white, popup up), flash_045.png, 9_after.png (rest again).
- Docs: docs/level-design.md, Content, "Level creator: thread the needle": new bullet on the flash plus a screenshot link. No `game/data/levels/` file touched.
- Note for the playtest: the car is metres past the gap when the trick pays (0.25 s after the crossing), so the flash is short (0.6 s); the camera follows, so a fast pass sees the flash near the screen's edge. Length and pulse count are the levers.
- 2026-10-31, in-progress → in-qa: Flash built (needle_flash.gd), 6 tests, all three test sets pass, screenshots saved
