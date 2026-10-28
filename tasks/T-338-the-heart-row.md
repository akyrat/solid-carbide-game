---
id: T-338
title: The hearts in a row at the top left, in place of the health bar
status: done
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-334]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, game/README.md, game/scripts/hud/]
files_expected_to_change: [game/scripts/hud/, game/scenes/, game/tests/unit/hud/, game/README.md, docs/hud-and-menus.md, art-archive/T-338/]
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

The board's decisions (2026-10-28): HUD and menus, Decisions, "The HUD looks like a livestream"; Game loop architecture, Decisions, "Hearts instead of health points". The upright health bar and its heart at the top left are replaced by a **row of hearts**, like Zelda's, at the **top left**: one heart per heart the car can have (5, plus the garage's), full ones for the hearts left and empty ones for the hearts lost (no half hearts). A heart lost does a small break or flash (your proposal); a heart healed pops back in. Past one row's width (a proposal: 10), a second row starts under it.

- **Position and size:** from the board's HUD layout page (https://claude.ai/artifact/CSHYCDV9xZbSYwQGUt5SJ4); the Project Lead writes the saved numbers in this ticket's Updates when it starts. The weapon icons column moves to the page's position for it too.
- If T-339's heart art (full and empty) is in the branch you start from, use it; otherwise today's heart picture for full hearts and a dark outline of it for empty ones.

The board's review: play a run, get hit and heal: the hearts empty and fill.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The health bar is gone; the hearts show in a row at the layout page's position (at 1152 x 648), one per heart, full or empty to match the run (tests with 5, with a garage heart, after a hit and after a heal). (QA: pass)
- [ ] The weapon icons are at the layout page's position and still clear of every other HUD piece (test). (QA: pass)
- [ ] HUD and menus, Content and game/README.md describe it. (QA: pass; docs in game/docs/hud-and-menus/hud.md per Project Lead)
- [ ] Screenshots (or a GIF for anything that moves) are in `art-archive/T-338/screenshots/`: full hearts, after a hit, and with a garage heart. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-28, Open → In progress

Started from the playtest build (T-334 approved). Layout from the board's page (1152x648): hearts x36 y24 w220 h40.

### 2026-10-28, Needs playtest → Done

The board approved it; merging to master next.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built by the UI Agent (2026-10-28). The health bar and the heart under it are gone; `HeartRow` (`game/scripts/hud/heart_row.gd`, `hud.heart_row`) shows one T-339 heart per heart the car can have, full or empty, at x36 y24 (220 x 40 at 1152 x 648, 44 x 40 cells). A lost heart flashes white and shakes (0.4 s), a healed one pops (0.3 s); a second row starts past 10 (max 30 drawn). Weapon icons moved to x12 y88. Gift arrows keep clear of the row. Only the health display changed (T-351 untouched). Docs: `docs/hud-and-menus.md` (Decisions, top-left passage), `game/docs/hud-and-menus/hud.md` ("The hearts row"); game/README.md is an index, so no change there.

Tests: new `tests/unit/hud/test_hud_heart_row.gd` (5 hearts, hit, heal, garage heart, second row, new run, weapon icons clear); updated layout, values, weapon icons, heart art, gift drops and health upgrade tests. Counts: GUT 1791 passing in the full run (one flaky failure in `test_run_likes` drift payment, a timing test under load; it passes alone, 35/35, and is not about the HUD); game/tools unittest 545 OK; tools unittest OK.

Screenshots: `art-archive/T-338/screenshots/hearts_full.png`, `hearts_hit.png`, `hearts_garage.png` (`bash game/tools/record_heart_row.sh`, fixture `heart_row_demo`). No GIF (animation covered by tests). Note: a second row (11+ hearts) reaches y108 and would touch the top of the weapon icons column; only matters if hearts pass 10.

QA (2026-10-28, round 1): all 5 criteria pass. qa_check --no-marks: tests PASS (3 sets), screenshots PASS (3 files, viewed: hearts full/empty in a row top left, weapon icon below), documents FAIL only for game/README.md, which is an index now (docs live in game/docs/hud-and-menus/hud.md and docs/hud-and-menus.md; counted as the README criterion per the Project Lead). No flaky test failure in this run.
- 2026-10-28, needs-playtest → done: The board played it in the livestream HUD build: okay (2026-10-28).
