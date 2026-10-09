---
id: T-055
title: Screen flow: main menu, run, garage, back to the menu
status: blocked
from: project-lead
to: game-loop
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-054, T-058, T-036]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, tasks/T-036-run-scene-and-state.md, tasks/T-054-main-menu.md, tasks/T-058-garage-screen.md, game/README.md]
files_expected_to_change: [the scene flow code, game/project.godot (main scene), tests, docs/game-loop-architecture.md, game/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-054 (the main menu), T-058 (the garage screen) and T-036 (the run) are done.**

Connect the screens as Game loop architecture, Decisions describes:
- The game opens on the main menu. Make it the project's main scene. The drift prototype stays available as a tool; say how to open it in `game/README.md`.
- **Start** begins a fresh run (T-036).
- When a run ends, win or loss, the game goes straight back to the main menu, with no message.
- **Garage** opens the garage screen (T-058). Its back button returns to the main menu.
- **Quit** closes the game.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test starts the game and shows the main menu is the first screen (QA: pass / fail)
- [ ] A test presses Start and shows a fresh run begins (QA: pass / fail)
- [ ] A test ends a run as a win and as a loss and shows both return to the main menu (QA: pass / fail)
- [ ] A test opens the garage and goes back, and shows the main menu again (QA: pass / fail)
- [ ] `game/project.godot`'s main scene is the main menu, and `game/README.md` says how to open the drift prototype (QA: pass / fail)
- [ ] `docs/game-loop-architecture.md` describes the flow in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
