---
id: T-389
title: The pause screen hides the SFX volume slider for the MVP
status: open
from: project-lead
to: ui
lead: Goal-G-007
epic: hud-menus
milestone: mvp
goal: G-007
user_facing_text: no
changes_visuals: yes
depends_on: [T-388, T-386]
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/pause-screen.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/pause-screen.md, game/docs/sound/sound-effects.md, game/scripts/ui/pause_screen.gd, game/tests/unit/test_pause_screen.gd, game/tests/unit/test_music_volume_slider.gd, game/docs/setup/screenshots.md]
files_expected_to_change: [game/scripts/ui/pause_screen.gd, game/tests/unit/test_pause_screen.gd, docs/hud-and-menus.md, game/docs/hud-and-menus/pause-screen.md]
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

HUD and menus, Decisions, 'No sound effects in the MVP' (board, 2026-10-29): with every sound effect off (the switch from the SFX ticket), the pause screen hides its SFX volume slider row, and the strip's layout closes the gap. The music volume slider still shows and still changes the music. Keep the slider's code (hidden, not deleted), so it can come back with the sound effects. Take a pause screen screenshot.

The board's review: Pause a run and check the SFX slider is gone and the music slider still works.

## Acceptance criteria

- [ ] The SFX volume slider row is not visible in the pause screen, and the rows below it move up so no gap is left; a test checks the row is hidden and the layout. (QA: pass / fail)
- [ ] The music volume slider still shows and moving it changes the music bus volume; a test covers it. (QA: pass / fail)
- [ ] The SFX slider's code is still in pause_screen.gd (hidden, not deleted). (QA: pass / fail)
- [ ] A pause screen screenshot is saved in art-archive/<task id>/screenshots/. (QA: pass / fail)
- [ ] docs/hud-and-menus.md, Content, 'Pause screen' and the 'No sound effects in the MVP' decision note, and game/docs/hud-and-menus/pause-screen.md, record that the SFX are off and the slider hidden for the MVP. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
