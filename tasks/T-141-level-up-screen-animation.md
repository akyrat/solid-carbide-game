---
id: T-141
title: The level-up screen animates in, with its red and gold art
status: blocked
from: project-lead
to: ui
lead: Enemies
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-052, T-140]
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

**Blocked until T-052 (the level-up screen) and T-140 (its red and gold art) are done.** The board (2026-10-15) wants the screen's animation to use the new art, so it waits for it.

The board: "animate the level up screen showing up". Swap T-140's approved art into T-052's level-up screen, and animate the screen appearing: for example the dim fading in, the cards popping or sliding in one after the other in pixel-art frames, the header dropping in. Propose the animation and its length in the result notes; the board judges it in its playtest. Keep it short (well under a second), in the game's comic look, with hard pixel edges. It runs while the run is paused. The player's input must work as T-052 set it (no card can be taken by accident while the screen animates in; say how). If T-139's likes bar animation plays at the same moment, make the two follow each other cleanly. No new player-facing text; T-051's text stays as it is.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test levels the player up and shows the screen animates in within its proposed length and ends in T-052's layout with T-140's art (QA: pass / fail)
- [ ] A test shows input during the animation cannot take a card by accident, and the keyboard and mouse work as T-052 set them once it ends (QA: pass / fail)
- [ ] A screenshot sequence of a run shows the animation's key frames and the finished screen (QA: pass / fail)
- [ ] T-052's tests still pass, and `docs/hud-and-menus.md` describes the animation in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

Written by the agent when it finishes.
