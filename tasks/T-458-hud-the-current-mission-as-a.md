---
id: T-458
title: HUD: the current mission as a notebook page on the left, with checkboxes, live counts and crossing off (placeholder art)
status: blocked
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

Game loop architecture, Decisions, 'Mission packs': the current mission shows on the left side of the HUD as a pixel-art notebook page. Use a placeholder page drawn in code (a pale page with ruled lines) until the art ticket replaces it; use the HUD style (`hud_style.gd`) for fonts and colours.

- The page shows the header and the current mission's goals with the exact texts from the text ticket (D1), no wording of your own.
- Each goal has a checkbox. A quantity goal shows `{done}/{total}` and updates live on the tracker's goal_progress; a duration or other goal shows no count. A completed goal shows a ticked box and its line crossed off. On mission_completed the next mission appears.
- If the movable HUD (T-453) is on master when you build this, the page is one of the pieces the player can move; if not, say so in the result notes and leave it fixed.
- Mind the existing left-side pieces (hearts at the top left, coins and the clock at the bottom left): the page sits between them without overlapping at the HUD's sizes (T-431).

Screenshots with the screenshot tool: a mission with a goal half done, a goal ticked and crossed off, and the next mission shown.

The board's review: play a run and check the notebook page on the left: its place, readability, the live counts, the ticks and crossing off, and the next mission appearing.

## Acceptance criteria

- [ ] In a run the HUD shows the current mission on the left as a notebook page (placeholder), with the D1 header and goal texts exactly. (QA: pass / fail)
- [ ] Each goal has a checkbox; a quantity goal shows '{done}/{total}' and its count updates after simulated progress; a duration goal shows no count; a completed goal is ticked and crossed off; after mission_completed the next mission is shown (GUT test checking the label text and the tick/cross state). (QA: pass / fail)
- [ ] The page does not overlap the hearts, coins or clock at 1152x648 and 1920x1080 (screenshots). (QA: pass / fail)
- [ ] If T-453's movable HUD is on master, the page is one of its movable pieces; otherwise the result notes say it wasn't there. (QA: pass / fail)
- [ ] Screenshots in art-archive/<id>/screenshots/ show a half-done goal, a ticked and crossed-off goal, and the next mission. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
