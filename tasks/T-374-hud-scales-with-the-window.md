---
id: T-374
title: The HUD scales with the window, and a HUD size slider in the pause screen
status: cancelled
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-373]
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, game/project.godot, game/scripts/hud/, game/scripts/ui/pause_screen.gd, game/scripts/ui/game_settings.gd]
files_expected_to_change: [game/project.godot, game/scripts/hud/, game/scripts/ui/, game/scenes/, game/tests/unit/, game/docs/hud-and-menus/, docs/hud-and-menus.md, art-archive/]
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

The board's decision (HUD and menus, Decisions, "The HUD scales with the window, and a HUD size slider", 2026-10-29; an MVP nice-to-have, **start only after the last MVP round** is done). The board, on an ultrawide screen: the HUD is super small and doesn't seem to scale with the window. `game/project.godot` sets no window stretch mode, so the HUD keeps its pixel size whatever the window.

1. **Scaling:** the HUD keeps a predictable place and a sensible size at any window size and resolution: 1152 x 648 (the layout page's size), 1920 x 1080, 2560 x 1440, 3440 x 1440 ultrawide, and a small window. Your design (for example a HUD scale from the window's height relative to 648, with the anchors keeping each piece at its corner or edge; or Godot's stretch settings if they don't break the world view, the pixel art's hard edges or the camera zoom). The pixel art stays crisp (whole-number scales for art, or nearest filtering). The world's zoom is not this ticket's.
2. **Slider:** the pause screen gets a HUD size slider (label from T-373, word for word) that multiplies the HUD's scale, saved with the other settings (`GameSettings`), applied at once and at the next start. Range and default are your proposal (for example 75% to 150%, default 100%).

The board's review: open the game at a few window sizes (and on the ultrawide) and move the HUD size slider.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] At 1152 x 648, 1920 x 1080, 2560 x 1440 and 3440 x 1440 every HUD piece keeps its corner or edge and a size in proportion to the window, with no overlap and nothing off screen (tests and screenshots). (QA: pass / fail)
- [ ] The HUD size slider in the pause screen changes the HUD's scale at once, is saved and is applied at the next start (tests). (QA: pass / fail)
- [ ] The slider's label comes from T-373's data file; no text is written in the code. (QA: pass / fail)
- [ ] HUD and menus, Content and the game docs describe the scaling rule and the slider. (QA: pass / fail)
- [ ] Screenshots at the four window sizes, and with the slider at its ends, are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

- 2026-10-30, open → cancelled: Replaced by goal G-008 (HUD and main menu), which writes its own tickets from the same decisions (2026-10-30).
