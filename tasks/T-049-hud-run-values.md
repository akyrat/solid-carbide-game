---
id: T-049
title: HUD: likes bar and level, health, coins
status: blocked
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-037, T-048, T-090]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-036-run-scene-and-state.md, tasks/T-037-likes-and-levels.md, tasks/T-048-text-hud.md, game/README.md]
files_expected_to_change: [the HUD scene and script, tests, docs/hud-and-menus.md, game/README.md]
model: sonnet
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

**Blocked until T-037 (likes and levels) and T-090 (the HUD with the timer) are done.** T-048's text is done.

Add the rest of the HUD to T-090's (which already shows the timer), as HUD and menus, Decisions describes it, kept plain for the MVP. It only displays values; the run (T-036, T-037) owns them.
- The car's health as a bar.
- The likes bar (XP shown as likes) and the current level.
- The coins collected this run.

Use exactly T-048's text. If T-048 chose a heart icon for likes, use a placeholder shape until its art task delivers it. Propose a first layout; the board adjusts it in playtests (HUD and menus, Decisions). The arrow to the nearest challenge and the kaiju's health bar are T-050.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test changes each run value (health, XP and level, coins) and shows the HUD shows the new value (QA: pass / fail)
- [ ] A test shows every label on the HUD is exactly T-048's text (QA: pass / fail)
- [ ] A screenshot of a run shows the HUD with all its parts (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes the layout in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
