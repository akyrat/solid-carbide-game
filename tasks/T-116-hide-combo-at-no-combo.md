---
id: T-116
title: HUD: hide the combo counter when there is no combo
status: in-progress
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, tasks/T-083-hud-combo-and-trick-popups.md, tasks/T-113-hud-vertical-health-and-likes-bars.md, game/README.md]
files_expected_to_change: [game/scripts/hud/hud.gd, the HUD's tests, game/README.md, docs/hud-and-menus.md]
model: sonnet
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

The board's decision (HUD and menus, Decisions, 2026-10-13): when the combo multiplier is at "no combo" (x1.0), the combo counter is hidden. It shows again as soon as a trick raises the multiplier, and hides again once the combo has drained back to x1.0 (T-081's drain). It also starts hidden in a new run.

**Branch:** build this on top of T-113, which is waiting for the board's playtest and moved the combo counter to above the likes bar. Create your branch `task/T-116-hide-combo-at-no-combo` from `task/T-113-hud-vertical-bars` (not from master), in your own folder `C:\solid-carbide-worktrees\T-116`, so the board playtests both changes together from your folder. T-113 is merged first, then this task.

1. Hide the counter when the multiplier is at the "no combo" value (read it from the combo data, not a hard-coded 1.0); show it when it is above.
2. Hiding must not move anything else on the HUD (the likes row and bar stay where they are).
3. Update HUD and menus, Content, "The HUD", and game/README.md.

## Acceptance criteria

- [ ] GUT tests show the combo counter is hidden at the start of a run and whenever the multiplier is at "no combo", shown with the right text after a trick, and hidden again once the combo has drained back (QA: pass / fail)
- [ ] GUT tests show the other HUD elements keep their positions whether the counter is shown or hidden, and T-113's layout tests still pass (QA: pass / fail)
- [ ] Two screenshots of a run started from the main menu show the counter hidden with no combo and shown with a combo (QA: pass / fail)
- [ ] HUD and menus, Content, "The HUD", and game/README.md say the counter is hidden at no combo (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest a run (together with T-113's layout) and judge the counter appearing and disappearing.

## Result notes

Written by the agent when it finishes.
