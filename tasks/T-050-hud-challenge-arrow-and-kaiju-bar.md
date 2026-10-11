---
id: T-050
title: HUD: the kaiju's health bar
status: blocked
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-049, T-045]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-049-hud-run-values.md, tasks/T-045-kaiju.md, tasks/T-048-text-hud.md, game/README.md]
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

**Blocked until T-049 (the HUD) and T-045 (the kaiju) are done.**

Add the kaiju's health bar to the HUD (HUD and menus, Decisions): shown only once the kaiju appears (T-045's health value and signal), with T-048's label. It hides when the kaiju dies. The arrow to the nearest challenge moved to T-098, after the MVP (2026-10-11).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test shows the kaiju's health bar is hidden before the kaiju appears, shows its health after, and hides when it dies (QA: pass / fail)
- [ ] A screenshot shows the kaiju's bar during the kaiju's minute, clear of the other HUD parts (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes it in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
