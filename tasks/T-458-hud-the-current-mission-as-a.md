---
id: T-458
title: HUD: the current mission as a notebook page on the left, with checkboxes, live counts and crossing off (placeholder art)
status: done
from: project-lead
to: ui
lead: Goal-G-009
epic: hud-menus
milestone: mvp
goal: G-009
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: [T-456, T-457]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, docs/game-loop-architecture.md, game/docs/hud-and-menus/hud.md, game/scripts/hud/hud.gd, game/scripts/hud/hud_style.gd, game/scenes/hud/hud.tscn, game/scripts/run/missions.gd, game/data/screen_texts.json]
files_expected_to_change: [game/scripts/hud/mission_page.gd, game/scripts/hud/hud.gd, game/scenes/hud/hud.tscn, game/tests/unit/hud/test_hud_mission_page.gd, game/tests/fixtures/mission_page_demo.gd, game/tests/fixtures/mission_page_demo.tscn, game/docs/hud-and-menus/hud.md, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 1
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

Game loop architecture, Decisions, 'Mission packs': the current mission shows on the left side of the HUD as a pixel-art notebook page. Use a placeholder page drawn in code (a pale page with ruled lines) until the art ticket replaces it; use the HUD style (`hud_style.gd`) for fonts and colours.

- The page shows the header and the current mission's goals with the exact texts from the text ticket (D1), no wording of your own.
- Each goal has a checkbox. A quantity goal shows `{done}/{total}` and updates live on the tracker's goal_progress; a duration or other goal shows no count. A completed goal shows a ticked box and its line crossed off. On mission_completed the next mission appears.
- If the movable HUD (T-453) is on master when you build this, the page is one of the pieces the player can move; if not, say so in the result notes and leave it fixed.
- Mind the existing left-side pieces (hearts at the top left, coins and the clock at the bottom left): the page sits between them without overlapping at the HUD's sizes (T-431).

Screenshots with the screenshot tool: a mission with a goal half done, a goal ticked and crossed off, and the next mission shown.

The board's review: play a run and check the notebook page on the left: its place, readability, the live counts, the ticks and crossing off, and the next mission appearing.

## Acceptance criteria

- [ ] In a run the HUD shows the current mission on the left as a notebook page (placeholder), with the D1 header and goal texts exactly. (QA: pass)
- [ ] Each goal has a checkbox; a quantity goal shows '{done}/{total}' and its count updates after simulated progress; a duration goal shows no count; a completed goal is ticked and crossed off; after mission_completed the next mission is shown (GUT test checking the label text and the tick/cross state). (QA: pass)
- [ ] The page does not overlap the hearts, coins or clock at 1152x648 and 1920x1080 (screenshots). (QA: pass)
- [ ] If T-453's movable HUD is on master, the page is one of its movable pieces; otherwise the result notes say it wasn't there. (QA: pass)
- [ ] Screenshots in art-archive/<id>/screenshots/ show a half-done goal, a ticked and crossed-off goal, and the next mission. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Blocked → In progress

Goal runner (G-009): started, in C:\solid-carbide-worktrees\T-458.

### 2026-10-31, In progress → In QA

Goal runner (G-009): the agent is done; QA is checking it.

### 2026-10-31, In QA → Needs playtest

Goal runner (G-009): QA passed; merged into playtest/G-009.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

UI Agent, 2026-10-31.

**Built.** `game/scripts/hud/mission_page.gd` (`MissionPage`): the current mission as a placeholder notebook page (pale paper, ruled lines, red margin, dark Bangers ink, drawn in code) on the HUD's left, 176 x 180 at (12, 304) in the 1152 x 648 layout, between the weapon icons and the coins. `Hud` builds it (`hud.mission_page`) and `bind(state)` binds it to `state.missions` (T-457). Texts are `screen_texts.json`'s `missions.header` and `missions.goals.<trick>`, word for word, `{done}/{total}`/`{seconds}` filled in. Each goal has a checkbox; quantity goals update live on `goal_progress`; duration goals show no count; `goal_completed` ticks the box and crosses the line off; `mission_started` shows the next mission; after the last one the page hides. HudStyle got roles `mission_header`/`mission_goal` and the `MISSION_*` colours.

**Movable HUD (T-453): not on this branch**, so the page is fixed. It is noted in `game/docs/hud-and-menus/hud.md` as a piece to register when it lands.

**Placement:** the test checks the page's rect against the coins (`COINS_POS`), the clock and a full 30-heart block in layout pixels at 1152x648 and 1920x1080 (both give the same 1152 x 648 layout area, since the HUD scales as one piece); no overlap. The screenshot tool renders 1152 x 648 only.

**Tests:** `tests/unit/hud/test_hud_mission_page.gd`, 10 tests. Full Godot GUT run: 196 scripts, 2379 tests, all pass. `python -m unittest discover tools`: 614 tests OK. The third set (docs/staleness checks) is run by the runner, not here.

**Screenshots** (`art-archive/T-458/screenshots/`, from `game/tests/fixtures/mission_page_demo*.tscn`): `mission_half.png` (Alt drifts 5/10), `mission_ticked.png` (a goal ticked and crossed, the other open), `mission_next.png` (the next mission after two completed). The fixtures hide the power-up overlay (T-459) that opens on each completed mission.

**Notes for the playtest:** the rules on the page do not line up with the text lines (placeholder); a long line wraps (the stroke runs along each wrapped line); the page's place and size are proposals. Two fixtures extra to the expected list: `mission_page_demo_ticked.tscn` and `mission_page_demo_next.tscn`. Documents updated: `docs/hud-and-menus.md`, `game/docs/hud-and-menus/hud.md`. No PixelLab generations, no style loop (placeholder drawn in code; text is T-456's). No refusals.

**QA round 1 (2026-10-31):** all six criteria pass. Godot GUT: 196 scripts, 2379 tests, 2379 passing (10/10 in test_hud_mission_page.gd). `python -m unittest discover tools`: 614 OK. Screenshots viewed: half-done (Alt drifts 5/10), ticked and crossed-off, next mission; page clear of hearts, coins and clock. The third set (docs staleness) is run by the runner. Refused: `python tools/qa_check.py` (not on the pre-approved list), so its paperwork lines and final mark check were not run; I checked the same things by hand.
- 2026-10-31, in-qa → needs-playtest: QA passed every criterion (goal G-009).
- 2026-11-01, needs-playtest → done: The board played G-009: LGTM (2026-11-01).
