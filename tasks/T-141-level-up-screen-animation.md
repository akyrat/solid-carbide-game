---
id: T-141
title: The level-up screen animates in, with its red and gold art
status: in-progress
from: project-lead
to: ui
lead: Level-up
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-052]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, tasks/T-052-level-up-screen.md, tasks/T-140-level-up-screen-art.md, tasks/T-139-likes-bar-level-up-animation.md, game/README.md]
files_expected_to_change: [the level-up screen scene and scripts, tests, docs/hud-and-menus.md, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Builds on T-140's branch (board, 2026-10-16):** the board wants the screen's animation to use T-140's art (2026-10-15) and plays the whole new level-up in one build, so this task starts once T-140's full set is approved, from T-140's branch (`task/T-140-level-up-screen-art`), instead of waiting for T-140 to be done.

The board: "animate the level up screen showing up". Swap T-140's approved art into T-052's level-up screen, and animate the screen appearing: for example the dim fading in, the cards popping or sliding in one after the other in pixel-art frames, the header dropping in. Propose the animation and its length in the result notes; the board judges it in its playtest. Keep it short (well under a second), in the game's comic look, with hard pixel edges. It runs while the run is paused. The player's input must work as T-052 set it (no card can be taken by accident while the screen animates in; say how). If T-139's likes bar animation plays at the same moment, make the two follow each other cleanly. No new player-facing text; T-051's text stays as it is.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test levels the player up and shows the screen animates in within its proposed length and ends in T-052's layout with T-140's art (QA: pass / fail)
- [ ] A test shows input during the animation cannot take a card by accident, and the keyboard and mouse work as T-052 set them once it ends (QA: pass / fail)
- [ ] A screenshot sequence of a run shows the animation's key frames and the finished screen (QA: pass / fail)
- [ ] T-052's tests still pass, and `docs/hud-and-menus.md` describes the animation in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Updates

### 2026-10-16, Open → In progress

Started from T-140's art branch with T-144 merged in; part of the one level-up build.

## Result notes

**Animation (proposal):** 0.54 s with two cards (0.64 with three), 0.04 s pixel frames: dim fades in (4 steps), sunburst grows with a small overshoot, ribbon then emblem drop in with a bounce, cards slide up one after the other (left first, 0.1 s apart). Sunburst at alpha 0.75, spinning 1.5 degrees every 0.1 s. Runs on the screen's own clock while the run is paused.
**Input guard:** `is_animating()`: take, highlight move and the take/move keys do nothing, buttons ignore the mouse until the end; a key pressed during it and still held takes nothing until released.
**Text wrap:** word-smart wrap, 300 px text width; a test checks no word is wider than a line.
**Likes bar (T-139):** no dependency; the screen has its own nodes and clock, above the HUD.
**Screenshots:** `art-archive/T-141/screenshots/t_0.04.png`, `t_0.12.png`, `t_0.22.png`, `t_0.34.png`, `t_0.44.png`, `t_99.png` (finished). Fixture `tests/fixtures/level_up_anim_demo.tscn`. (A first batch with the same names was identical frames from a mistaken run; overwritten.)
**Tests:** full GUT suite 820/820 pass; Python tool tests: game/tools 270 OK (1 skipped), tools/ 182 OK.
**Docs:** docs/hud-and-menus.md (Content only), game/README.md.
