---
id: T-428
title: The HUD reads its fonts, colours and outlines from one shared HUD style (looks unchanged)
status: open
from: project-lead
to: ui
lead: Goal-G-008
epic: hud-menus
milestone: mvp
goal: G-008
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/docs/hud-and-menus/hud.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/hud.md, game/scripts/hud/hud.gd, game/scenes/hud/hud.tscn, game/data/hud.json, game/tests/unit/hud/test_hud_layout.gd]
files_expected_to_change: [game/scripts/hud/hud_style.gd, game/scripts/hud/*.gd, game/scripts/ui/pause_screen.gd, game/scripts/ui/level_up_screen.gd, game/tests/unit/hud/test_hud_style.gd, game/docs/hud-and-menus/hud.md]
model: opus
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

Goal G-008, 'A consistent HUD' (HUD and menus, Decisions): the HUD's code follows one style sheet. This is the functional half: move every HUD style value now hard-coded in the HUD scripts (font files and sizes, font colours, outline colours and widths, panel colours) into one shared place that the HUD scripts read: a Godot Theme, a style script (for example game/scripts/hud/hud_style.gd) or a data file, your choice, named in the result notes. Cover the clock, coins, hearts, weapon icons, sub goal, live viewers counter and its fire, reactions, trick and combo broken popups, kaiju health bar, pause strip and level-up screen. Keep today's values exactly: nothing the player sees changes. The Asset Generation ticket that follows writes the HUD style sheet in Visual style, redraws the pieces that break it and lists the code changes; a later UI ticket sets the new values in this shared place.

## Acceptance criteria

- [ ] One shared HUD style place exists (Theme, style script or data file), named in the result notes, and every HUD script listed in the description reads its fonts, font colours, outline widths and colours from it; a grep of game/scripts/hud/ for add_theme_color_override and add_theme_font_size_override with literal values finds none outside that place, or the result notes justify each one left. (QA: pass / fail)
- [ ] A GUT test loads the shared style and checks the HUD's labels use its values. (QA: pass / fail)
- [ ] Positions, sizes and behaviour are unchanged: the existing HUD layout and behaviour tests still pass unchanged. (QA: pass / fail)
- [ ] A screenshot of a run with the whole HUD visible is in art-archive/<id>/screenshots/, matching the look before the change. (QA: pass / fail)
- [ ] game/docs/hud-and-menus/hud.md names the shared style place and how HUD scripts read it. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
