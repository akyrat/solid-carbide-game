---
id: T-113
title: HUD: health and likes bars stand upright at the top left
status: in-progress
from: project-lead
to: ui
epic: ui
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, tasks/T-049-hud-run-values.md, tasks/T-083-hud-combo-and-trick-popups.md, game/README.md]
files_expected_to_change: [game/scenes/hud/hud.tscn, game/scripts/hud/hud.gd, the HUD's tests, game/README.md, docs/hud-and-menus.md]
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

The board wants the car's health bar and the likes bar to stand upright (vertical), side by side at the top left of the screen (HUD and menus, Decisions, 2026-10-13). Today both are horizontal bars stacked at the top left (T-049). Change only their layout; what they show and the signals they follow stay the same.

1. **Bars:** both bars are vertical and fill from the bottom up. The health bar is on the far left, the likes bar just to its right, with a small gap. Same height for both, tall enough to read at a glance, narrow enough to keep the map visible; propose the sizes in the result notes. Keep the current fill colours (green health, purple likes) and their behaviour: the likes bar starts again after a level-up and stays full at the top level.
2. **Labels:** reuse the approved texts only (T-048), no new text: "Car Health" under the health bar; the heart, "Likes" and "Hype Lv {level}" under the likes bar. Place them so they don't overlap each other (for example stacked lines centred under each bar, or a short row); write the layout in the result notes. The heart stays the placeholder until T-086 swaps its art in.
3. **Combo counter** (T-083): keep it next to the likes bar, now to the right of the likes bar near its top, still clear of the bars and their labels.
4. **Keep clear** of the timer (top centre), the coins (top right), the pause strip (below the timer) and the trick popups (near the car), and keep working at the game's window sizes the HUD already supports.
5. The look stays a placeholder (HUD and menus, Open questions); no new art.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A GUT test shows the health bar and the likes bar are vertical (fill from the bottom up), both in the top-left area of the screen, the health bar to the left of the likes bar, and none of the HUD elements' rectangles overlap (bars, labels, heart, combo counter, timer, coins) (QA: pass / fail)
- [ ] The existing HUD tests still pass: the bars follow the run's health, likes and level, the likes bar starts again after a level-up and stays full at the top level, and the combo counter follows the multiplier (QA: pass / fail)
- [ ] A screenshot of a run started from the main menu shows the two upright bars at the top left with their labels, the combo counter, the timer and the coins (QA: pass / fail)
- [ ] HUD and menus, Content, "The HUD", and game/README.md describe the new layout (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest the run and judge the new layout.

## Result notes

Written by the agent when it finishes.
