---
id: T-330
title: The gift pack helicopter 30% bigger on screen
status: open
from: project-lead
to: game-loop
lead: Tokens
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/docs/game-loop/gift-pack-and-pickups.md, game/data/gift_pack.json, game/scripts/data/gift_pack_data.gd, game/scripts/run/gift_helicopter.gd, game/scripts/run/gift_drops.gd, game/scenes/run/gift_helicopter.tscn]
files_expected_to_change: [game/data/gift_pack.json, game/scripts/data/gift_pack_data.gd, game/scripts/run/gift_helicopter.gd, game/scenes/run/gift_helicopter.tscn, game/tests/unit/, game/README.md, docs/game-loop-architecture.md]
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

The board's decision (Game loop architecture, Decisions, "A bigger gift pack helicopter", 2026-10-28): the helicopter that flies in to drop each gift pack is drawn 30% larger on screen. Today its sheet (`game/art/gift_pack/helicopter_sheet.png`, 4 rotor frames of 192 x 160) is drawn at scale 0.5, so 96 x 80 drawn pixels; 30% larger is scale 0.65, about 125 x 104. Same art, no new generation, no PixelLab.

Put the scale in `game/data/gift_pack.json` (`helicopter`), read through `GiftPackData`, instead of a number in the scene, so the board can tune it later. Then check what depends on the helicopter's size and keep it working at the new size: the package hangs clear of the helicopter's belly (`hang_below_px`), the helicopter stays fully on screen at the top (`screen_margin_px`), and it enters and leaves out of sight (`offscreen_margin_px`). Change those numbers only as much as the bigger body needs, and say which ones changed and why. Keep the pixel art crisp (nearest filtering, as today); say in the result notes how 0.65 looks against the nearest clean scale, if there's a visible difference.

Screenshots (`tasks/README.md`, "Screenshots"): the helicopter carrying the package, before and after, at the same spot.

The board's review: play a run to a level-up and look at the helicopter's size.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `gift_pack.json` holds the helicopter's draw scale, set to 0.65, and the game reads it from there: a test checks the helicopter sprite is drawn at 1.3 times today's size (about 125 x 104 drawn pixels). (QA: pass / fail)
- [ ] A test checks the carried package's top sits below the helicopter's bottom edge at the new size, and the helicopter's top stays at least `screen_margin_px` from the screen's top edge. (QA: pass / fail)
- [ ] The helicopter starts and ends fully off screen at the new size (a test, or the existing test updated). (QA: pass / fail)
- [ ] Before and after screenshots of the helicopter carrying the package are in the result notes, with their paths. (QA: pass / fail)
- [ ] Game loop architecture, Content and `game/README.md` ("The gift pack drop") describe the new size and where it is set. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
