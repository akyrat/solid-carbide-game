---
id: T-454
title: Shadows shrink as objects rise and grow as they come down
status: open
from: project-lead
to: game-loop
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/drifting.md, tasks/T-407-gift-pack-falling-shadow.md, tasks/T-204-art-car-frames-without-shadow.md]
files_expected_to_change: [game/scripts/, game/tests/unit/, docs/visual-style.md]
model: opus
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

The board, 2026-10-31 (docs/visual-style.md, Decisions, "Shadows shrink with height"): every object in the air casts a shadow on the ground (or platform) under it whose size depends on its height: small when high, growing as it comes down, up to the object's own sprite size at the surface. Covers the car in the air (jumps, falling off a platform), the falling gift pack (T-407's landing shadow), falling enemies (T-227's falls), and anything else drawn above the ground; find them all and list them in the result notes. One shared helper for the size curve, so every object behaves the same; the curve and the smallest size are your proposals for the playtest. The shadow sits on whatever surface is under the object (ground or platform top). Code only, no new art. Never write, move or commit anything in game/data/levels/.

The board's review: jump off ramps and platforms, watch a gift pack fall and an enemy drop off a rooftop.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test shows the shared helper's shadow size is the sprite's size at height 0, smaller as height grows, and never larger than the sprite. (QA: pass / fail)
- [ ] Tests show the car in the air, a falling gift pack and a falling enemy each use the helper (shadow size changes with their height). (QA: pass / fail)
- [ ] A test shows a shadow sits on the platform top when the object is above a platform. (QA: pass / fail)
- [ ] The result notes list every in-air object found and which use the helper. (QA: pass / fail)
- [ ] Screenshots of the car high and low in a jump, and a falling gift pack, are saved and listed in the result notes. (QA: pass / fail)
- [ ] docs/visual-style.md (Content) describes the shadow rule. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
