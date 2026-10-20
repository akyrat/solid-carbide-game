---
id: T-210
title: "The pause screen's music volume slider"
status: blocked
from: project-lead
to: ui
lead: Coursework
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-208, T-209]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/README.md, game/scripts/ui/pause_screen.gd, game/scripts/ui/game_settings.gd, tasks/T-208-text-music-volume-label.md, tasks/T-209-music-the-boards-two-tracks.md]
files_expected_to_change: [game/scripts/ui/pause_screen.gd, game/scenes/, game/tests/unit/, game/README.md, docs/hud-and-menus.md, art-archive/T-210/screenshots/]
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

Add the music volume slider to the pause screen (HUD and menus, Decisions, 2026-10-20). Put it on its own row directly under the SFX volume slider, laid out exactly like it (label, slider of the same width, the value as a number at the right end), from 0 to 100. Its label is T-208's text, word for word, from HUD and menus, Content. It starts from T-209's saved music setting, changes the music's volume at once while the game is paused (the music keeps playing under the pause screen), and is saved between sessions. The pause strip stays as compact as the docs ask, below the HUD timer. Start from a branch that has both T-208 and T-209 merged.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the work (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] The pause screen shows the slider under "SFX volume", with T-208's label word for word, laid out like the SFX volume slider (screenshot) (QA: pass / fail)
- [ ] Moving it changes the music's volume at once and not the sound effects', and the value is saved and loaded between sessions (tests) (QA: pass / fail)
- [ ] The pause strip still sits below the HUD timer without overlapping it (screenshot) (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: pause during a run and move the music volume slider.
Board review files: the pause screen in a run.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
