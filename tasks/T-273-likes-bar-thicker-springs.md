---
id: T-273
title: A likes bar 4 times thicker that springs up when it fills
status: open
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

The board's decision (HUD and menus, Decisions, "A thicker likes bar that springs", 2026-10-22):

1. **4 times thicker:** the likes bar at the bottom centre goes from 16 to **64 pixels** tall, still half the screen wide and the same distance above the bottom edge. The row above it (heart, "Likes", level) and the combo counter above that move up to sit on it as before; the burning bar at x4 (T-131: flames along its top) and the level-up animation (T-139) fit the new size; nothing overlaps the combo popups, airtime and drift counters or the screen edge at the default window and zoom.
2. **Springs when it fills:** when likes come in, the fill shoots quickly to its new level, overshoots a little and settles (for example about 0.25 s with an ease-out-back, your proposal; keep the timing in one place to tune), instead of jumping there at once. When the bar fills completely it still triggers the level-up at the moment it fills, as today (T-139), and starts again from empty. Hard pixel edges; colours unchanged; it stops while the game is paused.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a screenshot of the new HUD at the bottom (plain, and burning at x4) and a short GIF of the bar springing as tricks land, including a level-up.

## Acceptance criteria

- [ ] The likes bar is 64 pixels tall and half the screen wide; the texts and counter above it sit on it without overlapping anything (screenshot, and a layout test) (QA: pass / fail)
- [ ] Tests show the fill eases to its new value over the proposed time with a small overshoot, never shows below the old value or past full in a way that hides the level-up, triggers the level-up when it fills as before, and pauses with the game (QA: pass / fail)
- [ ] The burning bar and the level-up animation fit the new size (screenshot) (QA: pass / fail)
- [ ] The screenshots and GIF are in `art-archive/T-273/screenshots/`; HUD and menus, Content, and `game/README.md` give the new size and animation; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: earn likes with tricks and watch the bar.
Board review files: the screenshots and GIF in `art-archive/T-273/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
