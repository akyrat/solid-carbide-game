---
id: T-015
title: Escape pauses the game, with a simple "Paused" screen
status: blocked
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-012]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/README.md, tasks/T-012-godot-drift-prototype.md, docs/extended-narrative.md, docs/visual-style.md]
files_expected_to_change: [the pause screen scene and script, their tests, the input map in game/project.godot, game/README.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-012 is done:** the drift prototype is the first thing there is to pause.

Escape pauses the game (HUD and menus, Decisions). For the MVP the pause screen is as simple as possible: the word "Paused" and a hint that Escape resumes. Pressing Escape again resumes. A full pause menu with settings comes later (T-016, final release); do not build it here.

- While paused, everything in the game stops: the car's physics and any timers.
- Escape is a named action in the input map, so the final-release menu can reuse it.
- Plain text is enough for now; the look follows the Visual style document once it has content.
- The prototype's tuning panel (Tab, from T-012) does not need to work while paused.

## Acceptance criteria

- [ ] A test shows that pressing Escape pauses the game: the car's position and velocity do not change over several frames while paused (QA: pass / fail)
- [ ] A test shows that pressing Escape again resumes, and the car continues from exactly where it was (QA: pass / fail)
- [ ] A screenshot of the paused game shows the word "Paused" and a hint that Escape resumes (QA: pass / fail)
- [ ] Escape is an action in the input map in `game/project.godot` (QA: pass / fail)
- [ ] `game/README.md` lists Escape under the prototype's keys (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
