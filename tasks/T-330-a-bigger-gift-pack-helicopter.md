---
id: T-330
title: The gift pack helicopter 30% bigger on screen
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

- [ ] `gift_pack.json` holds the helicopter's draw scale, set to 0.65, and the game reads it from there: a test checks the helicopter sprite is drawn at 1.3 times today's size (about 125 x 104 drawn pixels). (QA: pass)
- [ ] A test checks the carried package's top sits below the helicopter's bottom edge at the new size, and the helicopter's top stays at least `screen_margin_px` from the screen's top edge. (QA: pass)
- [ ] The helicopter starts and ends fully off screen at the new size (a test, or the existing test updated). (QA: pass)
- [ ] Before and after screenshots of the helicopter carrying the package are in the result notes, with their paths. (QA: fail: paperwork - screenshots are in C:\solid-carbide-worktrees\T-330\screenshots\ (git-ignored), not art-archive/T-330/screenshots/; the images themselves show the change correctly)
- [ ] Game loop architecture, Content and `game/README.md` ("The gift pack drop") describe the new size and where it is set. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Taken over from Tokens on the board's word. Started: the gift pack helicopter 30% bigger.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done (Game Loop Agent, commit d1fb86af). 0 PixelLab calls.
- `gift_pack.json` `helicopter.draw_scale` 0.65 (was a 0.5 in the scene), read via `GiftPackData.helicopter_scale()`; `GiftHelicopter._ready` applies it (or `send_helicopter` sets `draw_scale` from the drops' data first); the scene default is also 0.65. Drawn size 124.8 x 104.
- Numbers changed: `package.hang_below_px` 80 -> 88 (the existing "box hangs clearly below the belly" test failed at 80: the opaque belly now reaches 37 px below the centre and the box top was at 37). Unchanged: `screen_margin_px` 12 and `offscreen_margin_px` 80, because the top margin and the off-screen start/end are measured from the drawn size (`helicopter_top`, `fly_y`); new tests confirm it starts and ends fully off screen at the new size.
- 0.65 against the nearest clean scale: nearest filtering keeps edges hard; 0.65 gives slightly uneven pixel sizes next to a clean 0.5 or 1.0, not visibly rough at game zoom in the screenshots.
- Tests: two new `test_t330_*` in `game/tests/unit/run/test_gift_drops.gd` (scale 1.3 times today, 125 x 104, read from the data file; off-screen start/end, top margin, package below the belly); the data-file tests now include `draw_scale`.
- Test counts: `game/tools` unittest 668 OK (1 skipped); `tools` unittest 573 OK; `run_tests.sh` GUT 1932 of 1932 passing.
- Screenshots (same fixture, same frame): before `C:\solid-carbide-worktrees\T-330\art-archive\T-330\screenshots\T-330_before_250.png` and `T-330_before_300.png`; after `T-330_after_250.png` and `T-330_after_300.png` (same folder, committed).
- Docs: `docs/game-loop-architecture.md` (Content, "The gift pack drop" bullet; the Decisions entry was already there), `game/docs/game-loop/gift-pack-and-pickups.md` (numbers and art), `game/README.md` index line.
- The board's review: play to a level-up and look at the helicopter.

QA round 1: criteria 1-3, 5, 6 pass (qa_check tests PASS, 2 docs changed). Criterion 4 fails on paperwork only: the before/after screenshots exist and show the bigger helicopter clearly, but sit in the git-ignored screenshots/ folder; move them to art-archive/T-330/screenshots/ and list those paths.
