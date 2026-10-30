---
id: T-429
title: The HUD's code follows the HUD style sheet (fonts, colours, outlines)
status: in-progress
from: project-lead
to: ui
lead: Goal-G-008
epic: hud-menus
milestone: mvp
goal: G-008
user_facing_text: no
changes_visuals: yes
depends_on: [T-430]
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/hud.md, game/scripts/hud/hud_style.gd]
files_expected_to_change: [game/scripts/hud/hud_style.gd, game/scripts/hud/*.gd, game/scripts/ui/pause_screen.gd, game/scripts/ui/level_up_screen.gd, game/tests/unit/hud/test_hud_style.gd, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md]
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

Goal G-008, 'A consistent HUD': the Asset Generation ticket D4 wrote the HUD style sheet in Visual style and, in its result notes, listed piece by piece the code changes the HUD needs (fonts, colours, outline widths). Make every one of them, in the shared HUD style place D3 made (and only where a piece needs it, in its own script). Don't move or resize anything. Add any font the sheet names under game/fonts/ with its licence. Describe the style each piece now uses in HUD and menus, Content and game/docs/hud-and-menus/hud.md.

The board's review: Play a run and check every HUD piece (clock, coins, hearts, weapon icons, sub goal, live viewers counter, reactions, popups, kaiju bar, pause strip, level-up screen) now looks like one family.

## Acceptance criteria

- [ ] Every code change listed in D4's result notes is made, ticked off one by one in a checklist in the result notes. (QA: pass / fail)
- [ ] The HUD's style values (fonts, colours, outline widths) are defined in the one shared place D3 made, named in the result notes, and the test for it checks the new values. (QA: pass / fail)
- [ ] Positions, sizes and behaviour are unchanged: the existing HUD layout and behaviour tests still pass. (QA: pass / fail)
- [ ] A screenshot of a run with the whole HUD is in art-archive/<id>/screenshots/, next to a copy of D4's before shot of the same moment. (QA: pass / fail)
- [ ] docs/hud-and-menus.md, Content and game/docs/hud-and-menus/hud.md describe the style each HUD piece now uses. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Goal runner (G-008): started, in C:\solid-carbide-worktrees\T-429.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
