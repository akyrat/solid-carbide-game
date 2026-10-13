---
id: T-115
title: The likes bar drains when the combo has drained
status: open
from: project-lead
to: game-loop
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-114]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, tasks/T-037-likes-and-levels.md, tasks/T-081-combo.md, tasks/T-114-likes-drain-data.md, game/README.md]
files_expected_to_change: [the run's scripts, their tests, game/README.md, docs/game-loop-architecture.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decision for the MVP (Game loop architecture, Decisions, "Likes drain", 2026-10-13): when the player stops doing tricks, the likes bar slowly empties, but never below the start of the current level, so the player never loses a level.

1. **When:** the drain runs while the combo is fully drained (the run's combo multiplier is at "no combo", after its own 2-second wait and drain, T-081), plus any extra wait T-114 provides. Any trick raises the combo and stops it; it starts again once the combo has drained again.
2. **How much:** at T-114's speed, read from `run_data.gd`. XP in the current level goes down toward 0 and stops there: the level never goes down. At the top level (bar full and stopped), decide whether the drain applies and write it in the result notes; the simplest is that it does not.
3. **HUD:** the HUD already follows the run's XP signal; make sure the drain sends it, so the likes bar visibly empties. No HUD layout changes (T-113 owns the layout).
4. No drain while the run is paused (the level-up screen, the pause screen) or after the run has ended.
5. Update Game loop architecture, Content, "Likes and levels", and game/README.md.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] GUT tests show: with the combo above "no combo", XP does not drain; once the combo is back to "no combo", XP goes down at T-114's speed; a trick stops the drain (QA: pass / fail)
- [ ] GUT tests show XP never goes below 0 within the current level and the level never goes down, including when the drain runs for a long time (QA: pass / fail)
- [ ] GUT tests show no drain while the run is paused or after it has ended, and that the HUD's XP signal fires as XP drains (QA: pass / fail)
- [ ] Two screenshots a few seconds apart in a run show the likes bar emptying with no tricks, and stopping at empty with the level unchanged (QA: pass / fail)
- [ ] Game loop architecture and game/README.md describe the drain (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest a run and judge how the drain feels (speed, when it starts).

## Result notes

- 2026-10-13, open → blocked: waits for T-114
