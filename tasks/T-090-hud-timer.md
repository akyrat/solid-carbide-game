---
id: T-090
title: HUD: the run timer
status: in-progress
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-036, T-048]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-036-run-scene-and-state.md, tasks/T-048-text-hud.md, game/README.md]
files_expected_to_change: [the HUD scene and script, the run scene, tests, docs/hud-and-menus.md, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: in-progress | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The first piece of the HUD (HUD and menus, Decisions), for the board's first playable build (2026-10-10): the run timer, counting down from 8:00 in minutes and seconds, shown during the run. The run (T-036) owns the time; the HUD only shows it (`time_left_changed`, `time_left_text()`). Kept plain for the MVP.

Build it as the HUD scene the rest of the HUD (T-049) will be added to, placed in the run scene. The timer is digits only and needs no text (T-048).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test changes the run's time left and shows the HUD shows it as M:SS, from 8:00 down to 0:00 (QA: pass / fail)
- [ ] A screenshot of the run shows the timer (QA: pass / fail)
- [ ] A test shows the timer stops while the game is paused (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes the HUD in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
