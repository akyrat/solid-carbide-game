---
id: T-113
title: HUD: health bar upright at the top left, likes bar along the bottom
status: done
from: project-lead
to: ui
lead:
epic: ui
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, tasks/T-049-hud-run-values.md, tasks/T-083-hud-combo-and-trick-popups.md, game/README.md]
files_expected_to_change: [game/scenes/hud/hud.tscn, game/scripts/hud/hud.gd, the HUD's tests, game/README.md, docs/hud-and-menus.md]
model: opus
qa_rounds: 2
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: opus or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Reworked after the board's playtest (2026-10-13).** The first version stood both bars upright at the top left, with the labels in staggered lines under them; the board found the text placing horrible and wants to try the likes bar horizontal at the bottom of the screen instead (HUD and menus, Decisions, 2026-10-13). Change only the layout; what the bars show and the signals they follow stay the same.

1. **Health bar:** stays upright at the top left, filling from the bottom up. "Car Health" sits directly above it, left-aligned with the bar's left edge, on one line. Nothing else is stacked under the bar.
2. **Likes bar:** horizontal, centred at the bottom of the screen, about half the screen wide, a small margin above the bottom edge, filling left to right. Keep the purple fill and its behaviour (starts again after a level-up, stays full at the top level).
3. **Likes row:** one row directly above the likes bar, the same width: the heart and "Likes" at its left end, "Hype Lv {level}" at its right end, both on the same baseline. The heart stays the placeholder until T-086 swaps its art in.
4. **Combo counter** (T-083): centred just above the likes row, clear of the heart, "Likes" and "Hype Lv".
5. Text and labels line up cleanly: each label aligned with the edge of the bar it belongs to, same font size within a group, nothing staggered or floating. Reuse the approved texts only (T-048), no new text.
6. **Keep clear** of the timer (top centre), the coins (top right), the pause strip (below the timer) and the trick popups (near the car), and keep working at the window sizes the HUD already supports.
7. The look stays a placeholder (HUD and menus, Open questions); no new art.

Work on the same branch and folder. Propose sizes in the result notes. Take screenshots for the board at 1152x648 and 1920x1080.

## Acceptance criteria

- [x] A GUT test shows the health bar is upright at the top left with "Car Health" directly above it, left-aligned with the bar; and the likes bar is horizontal, centred at the bottom, filling left to right, with the likes row (heart and "Likes" at the left end, "Hype Lv" at the right end, same baseline) directly above it and the combo counter centred above that (QA: pass)
- [x] The same test shows none of the HUD elements' rectangles overlap (bars, labels, heart, combo counter, timer, coins) at the supported window sizes (QA: pass)
- [x] The existing HUD tests still pass: the bars follow the run's health, likes and level, the likes bar starts again after a level-up and stays full at the top level, and the combo counter follows the multiplier (QA: pass)
- [x] Screenshots of a run started from the main menu, at 1152x648 and 1920x1080, show the layout above (QA: pass)
- [x] HUD and menus, Content, "The HUD", and game/README.md describe the new layout (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest the run and judge the new layout, especially how the text sits.

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

QA/Integration, round 1 (2026-10-13), in the worktree on branch task/T-113-hud-vertical-bars:

- **GUT layout test: pass.** `game/tests/unit/hud/test_hud_layout.gd` (7/7) asserts `FILL_BOTTOM_TO_TOP` and height > 4x width for both bars, equal sizes; health bar's right edge left of the likes bar's left edge with a gap under 20 px, tops level, both in the left quarter and top half, health bar at the left margin; pairwise no-overlap (with a non-zero-size check) among both bars, "Car Health", heart, "Likes", "Hype Lv", combo, timer and coins at 1152x648, 1280x720, 1920x1080 and 1024x576 with long texts (Hype Lv 99, Combo x5.75, 99999 coins); also clear of the screen's middle and the pause strip's content. The SubViewport is a fair test: the HUD's CanvasLayer resolves its anchors (timer top centre, coins top right) against the SubViewport's size, the project sets no stretch mode, so this is the same layout the real window gets, and it lets several window sizes be checked.
- **Existing HUD tests: pass.** `test_hud_values.gd` is unchanged and passes 7/7 (health, likes and level follow the run, the likes bar's value and max follow the new level after a level-up, `test_max_level_keeps_the_bar_full`). `test_hud_combo.gd` passes 7/7; its only change is the placement test, which still checks right of the likes element and clear of the timer, coins and health bar, and now also checks near the bar's top and clear of the likes bar and all three labels: nothing it covered was dropped.
- **Screenshot: pass.** Retook it with the fixture (`hud_from_menu_demo.tscn`, a run started from the main menu, 1152x648); identical layout to `screenshots/T-113-hud.png`: two upright bars at the top left (green about 70%, purple partly filled), "Car Health", heart + "Likes", "Hype Lv 2" stacked under them, "Combo x1.75" right of the likes bar at its top, timer 8:00 top centre, "Coins 37" top right, no overlaps. QA copy deleted.
- **Docs: pass.** `docs/hud-and-menus.md`, Content, "The HUD", "Top left" bullet describes the upright bars (sizes, gap, bottom-up fill), the stacked labels and the combo position, plus the pause band note; `game/README.md` "The HUD" paragraph describes the T-113 layout and the new test.
- **Full suites: pass.** GUT 330/330, TESTS PASSED (one GUT warning about an inner class, existing). Python `game/tools` 125 OK, `tools` 115 OK. Godot's line-ending-only `.import` changes left uncommitted.

### The board's playtest, 2026-10-13 (round 1)

Not approved: "the text placing is horrible". The board wants to try the likes bar horizontal at the bottom of the screen; the health bar stays upright at the top left. Reworked description and criteria above.

### Round 2

UI Agent, same branch and worktree.

- **Health (top left):** "Car Health" at (16, 16), and the upright health bar directly under it, 6 pixels below the text, both at x = 16 (`Hud.HEALTH_BAR_SIZE` 24 x 160, bottom-up fill). At 1152x648 the bar runs from y = 50 to y = 210. Nothing else is under it.
- **Likes (bottom centre):** the bar is horizontal, half the window wide (`LIKES_BAR_WIDTH` 0.5), 16 pixels tall (`LIKES_BAR_HEIGHT`), centred, 16 pixels above the bottom edge, filling left to right. Same purple fill and frame, same signals: it starts again after a level-up and stays full at the top level. At 1152x648 it spans x 288 to 864, y 616 to 632; at 1920x1080, x 480 to 1440.
- **Likes row:** 6 pixels above the bar. The heart's left edge is on the bar's left edge, with "Likes" 6 pixels to its right; "Hype Lv {level}" ends exactly on the bar's right edge. Both labels get the same top and height, so they share a baseline; both use 20 px text, the same size as "Car Health". The heart is centred on the "Likes" line.
- **Combo counter:** centred on the bar, 4 pixels above the row (30 px pink text, as before).
- **Code:** `game/scripts/hud/hud.gd`: `_build_left()` and `_layout_left()` now hold only "Car Health" and the health bar. The new `_build_bottom()` and `_layout_bottom()` lay out a full-screen `bottom_area` Control (it ignores the mouse) holding the likes bar, the row and the combo counter. The layout re-runs when the window or any of those texts changes size. `_build_combo()` and `_place_combo()` are gone, and `_make_bar()` now takes the fill mode. `BAR_SIZE`, `BAR_GAP` and `LINE_GAP` are replaced by `HEALTH_BAR_SIZE`, `LIKES_BAR_WIDTH` and `LIKES_BAR_HEIGHT`; `COMBO_GAP` is now 4. `hud.tscn` is unchanged.
- **Tests:** `game/tests/unit/hud/test_hud_layout.gd` is rewritten (7 tests). They check the health bar is upright at the left edge in the top-left quarter and top half, with "Car Health" left-aligned with it and within 10 px above it. They check the likes bar fills left to right, is horizontal, half the width (within 1 px), centred (within 1 px) and 16 px from the bottom; the heart sits at the bar's left end, "Likes" right of the heart, and "Hype Lv" ends at the bar's right end. "Likes" and "Hype Lv" have the same top and height, the row is within 10 px above the bar, and the combo is centred and within 10 px above the row. The tests also check: the same font size within each group; no overlaps among the bars, labels, heart, combo, timer and coins at 1152x648, 1280x720, 1920x1080 and 1024x576 (with long texts: Hype Lv 99, Combo x5.75, 99999 coins), in a run with a level-up and a combo, and after the window is resized from 1152x648 to 1920x1080; clear of the screen's middle (car and popups) at every size; and clear of the pause strip's text and slider in a run started from the main menu. `test_hud_combo.gd`'s placement test now checks "centred above the likes row" in a 1152x648 SubViewport; it previously ran in the 64x64 headless root. `test_hud_values.gd` is unchanged.
- **Results:** full GUT suite 330/330, TESTS PASSED. Python: `game/tools` 125 OK, `tools` 115 OK.
- **Screenshots** (a run started from the main menu: 30% damage, Hype Lv 2, 37 coins, Combo x1.75, a FULL 360 popup over the car), both in the worktree's `screenshots/` folder:
  - `T-113-r2-1152x648.png`, taken with `bash game/tools/screenshot.sh res://tests/fixtures/hud_from_menu_demo.tscn screenshots/T-113-r2-1152x648.png 30`.
  - `T-113-r2-1920x1080.png`, taken with the same fixture by running Godot with `--resolution 1920x1080` before `-s res://tools/screenshot.gd`.
  - I checked enlarged crops: the heart's left edge and "Hype Lv"'s right edge line up with the bar's ends, and "Car Health" is flush with the health bar. The HUD keeps fixed pixel sizes, so at 1920x1080 the text is smaller relative to the screen (as before T-113).
- **Pause strip:** its dark band (full width from y 92) still runs over the lower part of the health bar while paused; its text and slider are clear. The likes area at the bottom is untouched by it.
- **Docs:** `docs/hud-and-menus.md`. In Content, "The HUD", the "Top left" bullet is rewritten, a new "Bottom centre" bullet is added, and the pause band note is updated. The Decisions line is brought in line with master's 2026-10-13 decision so the merge is clean. `game/README.md`: "The HUD" paragraph under "The run". The fixture's comment is updated too.
- 2026-10-13, needs-playtest → in-progress: board playtest: text placing horrible; likes bar to the bottom
- 2026-10-13, in-progress → in-qa: round 2: likes bar horizontal at the bottom centre, health bar under Car Health; GUT 330/330, Python 125 + 115 OK

QA/Integration, round 2 (2026-10-13), in the worktree on branch task/T-113-hud-vertical-bars, against the reworked criteria:

- **GUT layout test: pass.** `game/tests/unit/hud/test_hud_layout.gd` (7/7). Health: `FILL_BOTTOM_TO_TOP`, height > 4x width, at the left margin, in the top-left quarter and top half; "Car Health" left edge equal to the bar's (0.5 px), its bottom above the bar's top and within 10 px, at the top margin. Likes: `FILL_BEGIN_TO_END`, width > 10x height, half the view wide and centred (1 px), 16 px from the bottom; heart's left edge on the bar's left end, "Likes" right of the heart, "Hype Lv"'s right edge on the bar's right end, "Likes" and "Hype Lv" same top and height (same baseline), row and "Hype Lv" within 10 px above the bar, heart vertically centred on "Likes"; combo centred over the bar (1 px) and within 10 px above the row. Checked in a run (level-up, combo, coins), at all four sizes, after a resize and after the texts grow. Font sizes per group also tested. `test_hud_combo.gd`'s placement test now runs in a 1152x648 SubViewport and checks centred above the row and clear of the bar, labels, timer, coins and health bar.
- **No overlaps: pass.** Same file: pairwise no-intersection (with a non-zero-size check) among the health bar, likes bar, "Car Health", heart, "Likes", "Hype Lv", combo, timer and coins at 1152x648, 1280x720, 1920x1080 and 1024x576 with the longest texts (Hype Lv 99, Combo x5.75, 99999 coins), in a run, and after a resize; also clear of the screen's middle (car and popups) and of the pause strip's text and slider.
- **Existing HUD tests: pass.** `test_hud_values.gd` is byte-identical to master (`git diff master...HEAD` empty) and passes 7/7 (health, likes and level follow the run, the likes bar restarts after a level-up and stays full at the top level). `test_hud_combo.gd` passes 7/7; the counter still follows the multiplier, only the placement test changed.
- **Screenshots: pass.** `screenshots/T-113-r2-1152x648.png` and `T-113-r2-1920x1080.png` (a run from the main menu) show the health bar upright at the top left with "Car Health" directly above, flush with its left edge; the likes bar across the bottom centre, half the width, filling left to right; heart and "Likes" at the left end, "Hype Lv 2" ending at the right end, on one line; "Combo x1.75" centred above; timer and coins clear. Enlarged crops: heart's left edge and "Hype Lv"'s right edge sit exactly on the bar's ends, nothing staggered or floating. I retook the 1152x648 shot from the current code: the HUD regions are pixel-identical to the committed one (QA copy deleted). Note for the board: at 1920x1080 the text keeps its pixel size, so it reads smaller relative to the screen.
- **Docs: pass.** `docs/hud-and-menus.md`, Content, "The HUD": "Top left" and new "Bottom centre" bullets describe the new layout, plus the pause band note; the Decisions section is identical to master's. `game/README.md`, "The HUD" paragraph, describes the T-113 layout and `test_hud_layout.gd`.
- **Full suites: pass.** GUT 330/330, TESTS PASSED (the one existing inner-class warning). Python `game/tools` 125 OK, `tools` 115 OK. Godot's line-ending-only `.import` changes left uncommitted.
- 2026-10-13, in-qa → needs-playtest: QA round 2: all six criteria pass
- 2026-10-13, needs-playtest → done: LGTM (board playtest, 2026-10-13)
