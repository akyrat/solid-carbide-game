---
id: T-335
title: The timer at the bottom left as a digital clock that turns from green to red
status: done
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, game/README.md, game/scripts/hud/]
files_expected_to_change: [game/scripts/hud/, game/scenes/, game/tests/unit/hud/, game/README.md, docs/hud-and-menus.md, art-archive/T-335/]
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

The board's decision (HUD and menus, Decisions, "The HUD looks like a livestream", 2026-10-28). The run timer moves from the top centre to the **bottom left** and becomes a **digital pixel-art clock**: blocky segment-style digits ("7:56") in a dark panel. Its digits start **green** and turn **yellow, orange and red** as the time nears 0:00. Proposed switch points (the board's layout page uses these): green above 3:00, yellow to 1:30, orange to 0:30, red below; keep them in the HUD's data.

- **Position and size:** from the board's HUD layout page (https://claude.ai/artifact/CSHYCDV9xZbSYwQGUt5SJ4). The Project Lead writes the saved numbers (game pixels at 1152 x 648) in this ticket's Updates when it starts; anchor it to the bottom-left corner so it keeps its margins at other window sizes.
- **Look:** placeholder drawn in code for now (dark panel, glowing digits). If T-339's clock art is in the branch you start from, use it instead.
- **Also, for the board's layout page:** save one **screenshot of a run with the HUD hidden** (the world only, 1152 x 648) as `art-archive/T-335/screenshots/run_no_hud.png`, so the board can place pieces over the clean game.

The board's review: play a run and watch the clock turn yellow, orange and red.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The timer shows at the bottom left at the layout page's position and size (at 1152 x 648), anchored to that corner, and no longer at the top centre (test). (QA: pass)
- [ ] Its colour is green, yellow, orange and red at the data's switch points (tests at each boundary). (QA: pass)
- [ ] It counts down exactly as before and stops while paused (the existing timer tests pass). (QA: pass)
- [ ] `art-archive/T-335/screenshots/run_no_hud.png` is a 1152 x 648 run with no HUD. (QA: pass)
- [ ] HUD and menus, Content and game/README.md describe it. (QA: pass)
- [ ] Screenshots of the clock in green, yellow, orange and red are in `art-archive/T-335/screenshots/`. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started in the livestream HUD build.

### 2026-10-27, In progress

Layout from the board's page (1152x648): clock x16 y560 w200 h72. Also saved: viewers x896 y560 240x72, hearts x36 y24 220x40, weapons x12 y88 40x308, coins x16 y496 108x36, subgoal x988 y340 128x180.

### 2026-10-28, In progress → In QA

Built; QA running now (the board's go to finish without stopping).

### 2026-10-28, Needs playtest → Done

The board approved it in the playtest build; merging to master next.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

UI Agent. Layout page now at https://claude.ai/artifact/CSHYCDV9xZbSYwQGUt5SJ4 (same positions: clock x16 y560 w200 h72). The coins counter (T-341, x16 y496, 108x36) goes above the clock; the clock's top edge is y560, so there is room (496 + 36 = 532).

Built:
- `game/scripts/hud/timer_clock.gd` (`TimerClock`, a PanelContainer): dark panel, monospace digits drawn in code, anchored to the bottom-left corner (offsets 16 / 216 from the left, 560 and 632 at 648 tall, so it keeps a 16 px bottom margin at other sizes). Placeholder look; T-339's art was not in this branch.
- `game/data/hud.json` (`timer_clock`): layout and colour steps: green above 180 s, yellow above 90, orange above 30, red at 30 and below (a switch point belongs to the next colour).
- `hud.gd`: builds the clock; `timer_label` is now inside it (`hud.timer_clock`); the colour updates with every time change and on bind. The old top-centre label and TIMER_* constants are gone.
- Tests: `game/tests/unit/hud/test_hud_timer_clock.gd` (position, anchoring, margins at other sizes, not top centre, colour at each boundary, colour follows the run, fresh run green). `test_hud_values.gd` no longer lists the removed TIMER_COLOR. The existing `test_hud_timer.gd` passes unchanged.
- Docs: `docs/hud-and-menus.md` (HUD section, and a "Timer clock" bullet replacing "Top centre"), `game/README.md`.
- Not done: the pause strip still sits at STRIP_TOP 92 (placed under the old top-centre timer); left alone, as the pause screen is not in this ticket.
- Screenshots in `art-archive/T-335/screenshots/` (made with `game/tests/fixtures/timer_clock_shots.tscn` at 1152 x 648): `run_no_hud.png`, `clock_green.png` (5:00), `clock_yellow.png` (2:00), `clock_orange.png` (1:00), `clock_red.png` (0:20).
- Test counts: GUT (`bash game/tools/run_tests.sh`) 1694 of 1694 passing, 143 scripts. `game/tools` Python set 620 tests OK (1 skipped); `tools` Python set 501 tests OK.

### QA round 1 (2026-10-28)

All 6 criteria pass. qa_check: 3 test sets pass, documents changed, 5 screenshots present (all 1152x648; clock_red.png shows red 0:20 at bottom left; run_no_hud.png has no HUD). Docs describe the clock and switch points (180/90/30 s).
- 2026-10-28, needs-playtest → done: The board played the livestream HUD build and approved it (2026-10-28).
