---
id: T-482
title: Frame drops: a 97 ms hitch at the first gift pack pickup
status: in-progress
from: project-lead
to: game-loop
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: [T-468]
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, tasks/T-468-run-performance-recorder.md, game/docs/game-loop/perf-recorder.md, game/scripts/run/gift_drops.gd]
files_expected_to_change: [game/scripts/run/gift_drops.gd, game/tests/unit/, docs/game-loop-architecture.md]
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

The board's recorded run (T-468, recording `game/perf/2026-11-01_13-13-18` in T-468's folder): the longest frame (104 ms, 0:13 into the run) is `gifts.drops` in `game/scripts/run/gift_drops.gd` taking 97 ms (usually 0.02 ms), right at the first gift pack pickup and the level-up screen opening; gifts.drops was also the largest part of 2 more spikes. Likely a first-time load or build (a scene, texture, sound or the level-up screen's content) done on pickup; find it.

Move that cost out of play (load it with the run, before the first pickup), so picking up any gift pack costs under 2 ms, with everything looking and behaving as today. Measure before and after. Never write, move or commit anything in game/data/levels/.

The board's review: pick up the first gift pack in a run and feel no hitch.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes say what took the 97 ms, with the evidence. (QA: pass / fail)
- [ ] A measured before/after shows the first gift pack pickup's gifts.drops under 2 ms; numbers in the result notes. (QA: pass / fail)
- [ ] A test shows the moved load is ready before the first pickup, and the existing gift pack tests still pass. (QA: pass / fail)
- [ ] docs/game-loop-architecture.md notes what is loaded with the run, if that changed. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: the hitch at the first gift pack.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

**What took the 97 ms.** The recording's markers: `gift_pack_picked_up` at wall 15.3824 s, `level_up_screen_opened` at 15.4792 s, so the 97 ms (all counted as `gifts.drops` self time) lies between the pickup and the level-up screen opening: `GiftDrops.pick_up` -> `RunState.open_choice` -> pause -> `LevelUpOffers` draw -> `LevelUpScreen.show_offers` -> `_add_card`, which loaded on the spot `card_frame.png`, `highlight_frame.png` and each offered weapon's picture (`load()`), and shaped the cards' texts for the first time. The frame's monitors confirm first-time loads: `resources` 306 -> 312 and texture memory +0.43 MB in that one frame; `pipeline_*` unchanged (no shader compile). The later pickups cost 27 and 20 ms (new weapon pictures each time). The assets are tiny (64x64 to 192x162), so the 97 ms is cold-disk and first-use cost. I could not reproduce the cold-disk part here (warm OS cache).

**Fix.** `LevelUpScreen.prewarm()` (new, called at the end of `setup()`, i.e. with the run in `_ready`): loads the card frame, the highlight frame and every weapon picture (kept in `_warm_art` so the engine cache keeps them), builds every possible card once (all `LevelUpOffers.ALL_IDS`), asks each for its minimum size (shapes the texts), then clears them. Screen stays hidden and empty; `prewarmed` is true. Nothing the player sees changes. Costs about 15 ms once at run set-up.

**Before / after** (temporary probe scene, not committed: real `game.tscn`, GPU window 1670x907, car driving, 3 s in, `GiftDrops.pick_up` timed, 3 processes each, warm disk cache):
- before: first pickup 4.3, 4.5, 2.2 ms; later pickups 2.8 to 4.4 ms.
- after: first pickup 1.9, 2.2, 2.3 ms; later 2.0 to 2.4 ms (flat, no first-time cost).
What remains is the tree pause (0.8 ms) plus building the two cards (about 1.2 ms): about 2.0 to 2.3 ms, so just over the "under 2 ms" line in this warm-cache measure. The cold-disk 97 ms case could not be measured here, but a pickup now loads nothing. QA/board: re-record with `play_with_perf.ps1` and read gifts.drops at the first pickup. If a hitch remains, the next step is a pool of kept-built cards (touches the card code and about 78 test references; left out).

**Tests.** New `game/tests/unit/run/test_level_up_prewarm.gd` (3 tests: prewarmed and clean with the run; card art and weapon pictures cached before any pickup; the first pickup still opens the screen with 2 cards). Results: Python `game/tools` 858 tests OK (1 skipped); Python `tools` 633 tests OK; GUT 212 scripts, 2515 tests, all passing.

**Documents.** `docs/game-loop-architecture.md`, "The gift pack drop": one bullet on what is loaded with the run. Nothing in game/data/levels/ touched.
