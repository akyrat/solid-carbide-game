---
id: T-480
title: Frame drops: trick popups build their textures while drawing
status: in-progress
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: [T-468]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, tasks/T-468-run-performance-recorder.md, game/docs/game-loop/perf-recorder.md, game/scripts/hud/trick_popups.gd]
files_expected_to_change: [game/scripts/hud/trick_popups.gd, game/tests/unit/, docs/hud-and-menus.md]
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

The board's recorded run (T-468, recording `game/perf/2026-11-01_13-13-18` in T-468's folder, 286 s, 150 frames over 25 ms): the top cause is `draw.popup` in `game/scripts/hud/trick_popups.gd` `_draw()`: 13.3 ms a call in spike frames against 0.24 ms usually, the largest part of 117 of the 150 spikes (up to 49 ms in one frame), mostly with two popups showing and often after `combo_broken`. `texture()` and `broken_textures()` appear to build the popup's textures (and the broken popup's two halves) the first time they are drawn; check it.

Make drawing a popup cheap every frame: build its textures before it is first drawn, or cache them by text and style so the same popup text never builds twice in a run (keep the cache bounded), with the popups looking exactly as they do today. Measure before and after with the recorder (`--record-perf`, `python game/tools/analyse_perf.py`, or a scripted run that shows many popups, broken ones included). Never write, move or commit anything in game/data/levels/.

The board's review: play a run with many tricks and broken combos and feel no hitch when a popup appears.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes say what made draw.popup expensive, with the evidence. (QA: pass / fail)
- [ ] A measured before/after (the recorder or a scripted benchmark) shows `draw.popup` under 1 ms a call at its worst, including a broken popup's first frame; numbers in the result notes. (QA: pass / fail)
- [ ] A test shows a popup (normal and broken) looks the same as before: same texture size and pixels as today's build for a sample of texts. (QA: pass / fail)
- [ ] A test shows the texture cache stays bounded over many different popup texts. (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content, Trick popups) notes the textures are built ahead of drawing. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: trick popups build their pictures ahead of drawing.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Cause.** `PopupText._draw()` called `texture()` / `broken_textures()`, and any picture not yet made was baked there in GDScript, pixel by pixel. The cache by text never helped for trick popups because the amount ("+12.0K") is new almost every trick, and a popup needs up to 12 pictures (6 flame frames, each with and without the amount). Measured first bake (headless, before): `THREAD THE NEEDLE! +12.0K` 17 ms, `FULL 360! +226K` at heat 3 24 ms, `TRENDING! +120 SUBS!` heat 3 26 ms, `COMBO BROKEN!` 10 ms, cached repeat 0.009 ms. This matches the recording (13.3 ms mean, 49 ms worst in `draw.popup`, mostly two popups, often after `combo_broken`).

**Fix** (`trick_popup_art.gd`, `combo_broken_art.gd`, `trick_popups.gd`):
- Pictures are made before drawing: `TrickPopups.prewarm()` (once, from `_ready`) bakes on worker threads each trick name at every heat step and flame frame (pinned for the run) and the broken card; `show_popup()` makes the popup's born picture on the spot and requests its other frames / no-amount look from workers; `_process` polls finished images into textures on the main thread. `_draw()` only looks pictures up.
- Bounded caches: trick cache FIFO `CACHE_MAX` 96 (plus the fixed pinned set of 63), broken cache 24, plain-size cache 96.
- `size()` uses `plain_size()` (no baking) instead of baking a heat-0 picture.
- `bake()` about 2x faster with identical pixels: bubble in row spans on an L8 image (`round_rect_span`), packed-int palette conversion, outline scanned over the lettering box only, flames scan from the ends and compute each tongue once per row/column.
- Pixels unchanged: hashes of 8 trick and 3 broken samples (incl. heat 3 flame frames, viewers, hidden amount) taken from the old code before the change match.

**Before/after** (`game/tools/bench_popup_frames.gd`, headless, 60 fps pacing, 80 popups over 40 s: 4 of 5 tricks with distinct amounts at heats 0 to 3, 1 of 5 broken; "draw lookups" = what `_draw()` does each frame, every popup every frame):
- Before: draw lookups 4093 calls, median 0.020 ms, p99 14.9 ms, max 37.0 ms, 48 calls over 1 ms. show_popup median 11.1 ms, max 18.2 ms.
- After: draw lookups 4679 calls, median 0.019 ms, p99 0.05 ms, max 0.31 ms, 0 calls over 1 ms (broken popup's first frame included). show_popup median 4.4 ms, max 10.4 ms (the heat 3 popups, flames; the cost is now when the trick is shown, not in `_draw`).
- Not measured with the real recorder in the game (no playable window run here); the board's playtest should confirm. Honest limit: a novel hot popup still costs about 8 to 12 ms once in the frame it is shown (GDScript pixel work); well under the 25 ms spike line but not free.

**Tests**: new `game/tests/unit/test_trick_popup_prebuild.gd` (10 tests: pixel hashes as before for normal and broken, requested textures same pixels, plain size equals texture size, row spans equal the pixel test, trick and broken caches bounded over 400 / 60 texts, a shown popup has all frames cached and drawing builds nothing, broken halves ready, prewarm covers every name and heat). Results: `python -m unittest discover -s game/tools` 858 tests OK (1 skipped); `python -m unittest discover -s tools` 633 tests OK; GUT (GUT_TIME_LIMIT=1800) 2522 of 2522 pass, 212 scripts, 1046 s.

**Also added**: `game/tools/bench_popup_frames.gd` (the benchmark), `game/tools/dump_popup_hashes.gd` (golden hashes). Nothing under game/data/levels/ or game/perf/ touched.

**Documents affected**: docs/hud-and-menus.md (Trick popups), game/docs/hud-and-menus/popups.md.
