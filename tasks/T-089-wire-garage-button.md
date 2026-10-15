---
id: T-089
title: Screen flow: wire the Garage button to the garage screen
status: needs-playtest
from: project-lead
to: game-loop
lead: Playtest
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-055]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, tasks/T-055-screen-flow.md, tasks/T-058-garage-screen.md, game/README.md]
files_expected_to_change: [the scene flow code, tests, game/README.md]
model: sonnet
qa_rounds: 1
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

**Built on T-058's branch (board, 2026-10-15).** T-058 (the garage screen) waits for the board's playtest, and the board can only reach it from the main menu once it is wired. So branch `task/T-089-wire-garage-button` from `task/T-058-garage-screen` (not from master), in your own folder `C:\solid-carbide-worktrees\T-089`, merge master into it, and the board playtests the garage and its button together there. T-058 merges first, then this.

T-055 left the main menu's Garage button unwired (board, 2026-10-10). Wire it: **Garage** opens the garage screen, and its back button returns to the main menu (Game loop architecture, Decisions).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test presses Garage and shows the garage screen opens (QA: pass)
- [x] A test presses the garage's back button and shows the main menu again (QA: pass)
- [x] `docs/game-loop-architecture.md` describes it in Content, without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest it, with T-058's garage screen, before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Updates

### 2026-10-15, Open → In progress

Started: the Game Loop Agent wires the Garage button on top of T-058's garage screen, so you can playtest both together.

## Result notes

Written by the agent when it finishes.

Wired the main menu's Garage button to the garage screen, and the garage's back button back to the main menu. `GameFlow.show_garage()` (game/scripts/game/game_flow.gd) replaces the menu with `scenes/menu/garage_screen.tscn`, gives it `GameFlow.progress`, and connects `back_pressed` to `show_menu`. `game.garage` is the new screen variable, cleared with the others. Tests: `tests/unit/game/test_screen_flow.gd` (Garage opens the screen with the game's progress; back returns to the menu and Start still works). Docs: Game loop architecture Content (Screen flow bullet only) and game/README.md. Full GUT: 728 tests, 725 pass; the 3 failures are the known test_kaiju_health_bar.gd ones (not touched). pytest tools 180 passed; game/tools 257 passed, 1 skipped. Launch with --quit-after 300: no script errors.

How the board plays it: open `C:\solid-carbide-worktrees\T-089\game\project.godot` (or Play on T-089 in the Builds tab). Press Garage on the main menu to see T-058's garage screen, buy upgrades, press Back to return to the menu, then Start a run.
- 2026-10-15, in-progress → in-qa: Garage button wired to the garage screen, back returns to menu; tests added and passing (3 known kaiju bar failures)

### QA round 1 (QA/Integration Agent, 2026-10-15)

- Garage press opens garage screen: PASS (test_garage_opens_the_garage_screen)
- Back returns to main menu: PASS (test_garage_back_returns_to_the_main_menu, Start still works)
- Docs: PASS (diff vs master is one bullet in Content; Summary, Decisions, Open questions untouched)
- Tests: PASS (GUT 745/745, pytest tools 180, game/tools 257 + 1 skipped). Launch with --quit-after 300: no script errors.
- 2026-10-15, in-qa → needs-playtest: QA round 1 passed: all 4 criteria, GUT 745/745
