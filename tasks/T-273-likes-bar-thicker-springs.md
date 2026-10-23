---
id: T-273
title: A likes bar 4 times thicker that springs up when it fills
status: needs-playtest
from: project-lead
to: ui
lead: Coursework
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/README.md, game/scripts/hud/, game/scenes/hud/, tasks/T-113-hud-vertical-health-and-likes-bars.md, tasks/T-131-combo-heat-levels.md, tasks/T-139-likes-bar-level-up-animation.md]
files_expected_to_change: [game/scripts/hud/, game/scenes/hud/, game/tests/unit/, docs/hud-and-menus.md, game/README.md, art-archive/T-273/screenshots/]
model: sonnet
qa_rounds: 1
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

The board's decision (HUD and menus, Decisions, "A thicker likes bar that springs", 2026-10-22):

1. **4 times thicker:** the likes bar at the bottom centre goes from 16 to **64 pixels** tall, still half the screen wide and the same distance above the bottom edge. The row above it (heart, "Likes", level) and the combo counter above that move up to sit on it as before; the burning bar at x4 (T-131: flames along its top) and the level-up animation (T-139) fit the new size; nothing overlaps the combo popups, airtime and drift counters or the screen edge at the default window and zoom.
2. **Springs when it fills:** when likes come in, the fill shoots quickly to its new level, overshoots a little and settles (for example about 0.25 s with an ease-out-back, your proposal; keep the timing in one place to tune), instead of jumping there at once. When the bar fills completely it still triggers the level-up at the moment it fills, as today (T-139), and starts again from empty. Hard pixel edges; colours unchanged; it stops while the game is paused.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a screenshot of the new HUD at the bottom (plain, and burning at x4) and a short GIF of the bar springing as tricks land, including a level-up.

## Acceptance criteria

- [ ] The likes bar is 64 pixels tall and half the screen wide; the texts and counter above it sit on it without overlapping anything (screenshot, and a layout test) (QA: pass; 64 px, half width, layout test at four sizes passes, screenshot shows no overlap)
- [ ] Tests show the fill eases to its new value over the proposed time with a small overshoot, never shows below the old value or past full in a way that hides the level-up, triggers the level-up when it fills as before, and pauses with the game (QA: pass; test_likes_spring.gd covers ease and overshoot, never below old or past full, level-up then restart, pause, no spring on drain)
- [ ] The burning bar and the level-up animation fit the new size (screenshot) (QA: pass; burning x4 screenshot shows flames on the 64 px bar; level-up sized from bar rect and shown in the GIF)
- [ ] The screenshots and GIF are in `art-archive/T-273/screenshots/`; HUD and menus, Content, and `game/README.md` give the new size and animation; the full GUT suite and all Python tool tests pass (QA: pass; files and docs present, GUT 1372/1372, tools 451 OK, game/tools OK; layout ratio check loosened 10 to 5 because 576/64=9, and settle_likes() calls added, both keep intent)

The board's review: earn likes with tricks and watch the bar.
Board review files: the screenshots and GIF in `art-archive/T-273/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's request: the likes bar 4 times thicker, springing when it fills.

### 2026-10-23, In progress → In QA

Likes bar 64 px tall; fill springs up in 0.25 s with a small overshoot; level-up fills, then the new bar springs from empty. Sent to QA.

## Result notes

Written by the agent when it finishes.

UI Agent, T-273. Built:
- The likes bar is 64 px tall (`Hud.LIKES_BAR_HEIGHT`), still half the screen wide and 16 px above the bottom edge; the row, "Hype Lv" and the combo counter moved up 48 px with it. The x4 flames (along the bar's top) and the level-up animation (sized from the bar's rectangle) fit without changes.
- New `scripts/hud/likes_spring.gd` (`LikesSpring`, `hud.likes_spring`, pausable). Timing chosen, in one place: `DURATION` 0.25 s, ease-out-back with `OVERSHOOT` 1.2 (about 5 percent of the step). Likes going up spring; a level-up springs the old bar to full while the level-up flash and "Hype Lv" change at that moment, then the new bar starts from empty and springs to the leftover; draining likes and a new run snap with no animation. The bar never draws past full or below the old value.
- `likes_bar.value` is now the shown fill; tests call `hud.settle_likes()` before reading the real one (updated test_hud_values, combo_heat, level_up_flash, likes_drain; the T-086 position test and the layout ratio check updated for the 64 px size).
- Tests: `tests/unit/hud/test_likes_spring.gd` (curve, ease over the time with overshoot, never below old or past full, level-up at once then restart, paused, no spring when draining, 64 px and clear of the other parts at four window sizes), `tools/test_likes_spring_gif.py`. Full GUT suite: 1372 of 1372 passed. Python tool tests: `tools` 451 passed, `game/tools` 408 passed, 1 skipped.
- Screenshots and GIF in `art-archive/T-273/screenshots/`: `likes_bar_plain.png`, `likes_bar_burning.png` (x4), `likes_bar_spring.gif` (30 fps, five gains with a level-up). Made with `bash game/tools/record_likes_spring.sh`. I looked at them: the bar, flames and level-up flash fit; the GIF shows the fill rising, the white-hot level-up cover, and the bar starting again.
- Docs updated: `docs/hud-and-menus.md` (The HUD, bottom centre) and `game/README.md` (HUD layout value, new "Likes bar spring" paragraph).
- Refusals: none.
