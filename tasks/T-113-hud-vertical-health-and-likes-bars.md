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

UI Agent, built on branch task/T-113-hud-vertical-bars (worktree C:\solid-carbide-worktrees\T-113).

- **Proposed bar sizes:** both bars 24 x 160 pixels (`Hud.BAR_SIZE`), 12 pixels apart (`BAR_GAP`), 16 pixels from the screen's top and left edges. Health on the far left, likes just right of it; both `ProgressBar.FILL_BOTTOM_TO_TOP`. Same fill colours (green, purple) and frame as before; same signals and behaviour (likes bar starts again after a level-up, stays full at the top level).
- **Proposed label layout:** three short lines under the bars, each starting at its bar's left edge (a staircase), so long texts never overlap: "Car Health" (under the health bar); the heart and "Likes" (under the likes bar); "Hype Lv {level}" (under that). Only T-048's approved texts, no new text. The whole top-left block is about 76 x 255 pixels (to y = 270 at 1152x648).
- **Combo counter:** right of the likes bar, 20 pixels from it, level with the bar's top (x 96, y 16 at 1152x648); "Combo x5.75" ends around x 270.
- **Keeping clear:** the block stays in the left quarter and the top half; it is clear of the timer, the coins, the middle of the screen (car and trick popups) and the pause strip's centred text and slider. While paused, the strip's dark band (full width from y 92, task T-095) still runs over the lower part of the bars, as it ran over the old bars on master; its text and slider are untouched. Flagging it in case the board wants the band itself narrowed.
- **Code:** `game/scripts/hud/hud.gd` (`_build_left()`, new `_layout_left()`, `_place_combo()` now follows the likes bar; `left_column` is now a plain Control). The `hud.tscn` scene needed no change (the HUD is built in code).
- **Tests:** new `game/tests/unit/hud/test_hud_layout.gd` (7 tests: upright and bottom-up, side by side at the top left with a small gap, labels under their bars, no overlaps among bars, labels, heart, combo, timer and coins at 1152x648, 1280x720, 1920x1080 and 1024x576, clear of the screen's middle, clear of the pause strip's content in a run from the main menu). Headless, Godot's root viewport is only 64x64, so these tests lay the HUD out in a window-sized SubViewport. `test_hud_combo.gd`: the placement test now checks "right of the likes bar, near its top" and clear of every label. Existing `test_hud_values.gd` unchanged and passing.
- **Results:** full GUT suite 330/330, TESTS PASSED. Python: `game/tools` 125 OK, `tools` 115 OK.
- **Screenshot:** `screenshots/T-113-hud.png` in the worktree (a run started from the main menu: 30% damage, Hype Lv 2, 37 coins, Combo x1.75), from `bash game/tools/screenshot.sh res://tests/fixtures/hud_from_menu_demo.tscn screenshots/T-113-hud.png 30`. The fixture now also adds a combo.
- **Docs:** `docs/hud-and-menus.md` (Content, "The HUD" only), `game/README.md` ("The HUD" paragraph under "The run").
