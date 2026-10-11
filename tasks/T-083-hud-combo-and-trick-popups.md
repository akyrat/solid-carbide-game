---
id: T-083
title: HUD: the combo counter, and the combo amount on trick popups
status: open
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-081, T-091, T-049]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-081-combo.md, tasks/T-082-text-combo.md, tasks/T-049-hud-run-values.md, game/README.md]
files_expected_to_change: [the HUD scene and script, the popup scene, tests, docs/hud-and-menus.md, game/README.md]
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

**Blocked until T-081 (the combo), T-091 (the trick popups) and T-049 (the HUD) are done.** T-082's text is done.

As HUD and menus, Decisions describes:
1. **Combo counter** next to the likes bar, showing the current multiplier with T-082's label.
2. **What each trick added:** T-091's trick popups gain the amount the trick added to the multiplier, from T-081's signal, with T-082's `combo.added` text. Placeholder comic styling for now (a bold font and a simple shape behind it); the final comic look is T-084's art.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test changes the multiplier and shows the counter shows it, with T-082's label (QA: pass / fail)
- [ ] A test sends each of T-081's trick signals and shows the popup also shows the amount added, in T-082's `combo.added` text (QA: pass / fail)
- [ ] Screenshots show the counter and a popup for each trick (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes both in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
