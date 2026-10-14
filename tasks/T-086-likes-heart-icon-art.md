---
id: T-086
title: Art: the heart icon on the likes bar
status: done
from: project-lead
to: asset-generation
lead:
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-049]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, tasks/T-048-text-hud.md, tasks/T-049-hud-run-values.md, game/README.md]
files_expected_to_change: [art files under game/art/ and their records, the HUD scene, game/README.md]
model: opus
qa_rounds: 2
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

T-049 (the HUD, with a placeholder heart) is done. Since T-131 the "LIKES" and "HYPE LV" texts are in the Bangers comic font with a dark outline.

The likes bar shows the word "Likes" with a heart icon at its left end (T-048, approved by the board). The icon: a small flat heart in Redgull red, like a social app's like button. **Board, 2026-10-14:** it matches the HUD's comic look: a thick dark outline like the "LIKES" and "HYPE LV" text's, a little chunky, sized to the height of the "LIKES" text so it sits level with it. **Drawn by script, no PixelLab** (a hand-placed pixel grid, like the kaiju warning signs in T-130): 0 generations. Follow Visual style's technical rules (pixel art, no anti-aliasing, no semi-transparent pixels, transparent background). The red is the Redgull red the placeholder uses (the only red on the HUD). Swap it in for T-049's placeholder heart (`tasks/README.md`, "Art replaces placeholders"); keep T-113/T-131's layout (nothing else moves). Game-ready art in `game/art/`, any other versions in `art-archive/T-086/`, with the record Visual style asks for.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A screenshot of the HUD in a run shows the final heart next to "LIKES", level with it, about the same height, with a dark outline like the text's; also one at combo step 3 (likes bar on fire) so the heart reads next to the flames (QA: pass)
- [ ] A check script or GUT test shows the icon has a transparent background, no semi-transparent pixels, few colours, and uses the HUD's Redgull red (QA: pass)
- [ ] No PixelLab call was made: the result notes say so and the art is made by a committed script that can rebuild it (QA: pass)
- [ ] T-049's, T-113's and T-131's HUD tests (layout, combo hidden, combo heat) still pass (QA: pass)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass)
- [ ] `game/README.md` (the HUD section) says where the heart art is and how it is made (QA: pass)

The board's review: play a run in this task's folder and judge the heart's look next to "LIKES".
Board review files: the HUD screenshots listed in the result notes

## Result notes

Made by the Asset Generation Agent, 2026-10-14. **No PixelLab call was made (0 generations).**

- **Art:** `game/art/hud/likes_heart.png` (11 x 10 px) and its record `game/art/hud/likes_heart.json`. A hand-placed 9 x 8 pixel grid, flat Redgull red (219, 26, 41 = `Hud.HEART_COLOR`) with a 1 px dark outline all round (8, 8, 15 = `Hud.OUTLINE_COLOR`, the text's outline colour). Two colours, transparent background, no semi-transparent pixels. The HUD shows it at 2x (22 x 20 on screen, nearest), about the height of "LIKES" with its outline, level with it.
- **Script:** `python game/tools/build_heart_icon.py build` rebuilds it (byte-identical every run); `check` verifies the committed PNG. Tests: `game/tools/test_build_heart_icon.py` (Python) and `game/tests/unit/hud/test_hud_heart_art.gd` (GUT: art rules, colours, the HUD uses the art at 2x, nearest, about text height).
- **HUD:** `game/scripts/hud/hud.gd`: `heart` is now a `TextureRect` with the art (the `Polygon2D` placeholder and `_heart_points` are gone; `HEART_SIZE` replaced by `HEART_SCALE`). Layout code untouched. `test_hud_values.gd`'s placeholder-shape check now checks the art.
- **Tests:** full GUT suite 557/557 pass (T-049, T-113, T-116 and T-131 HUD tests included); Python tool tests pass.
- **Screenshots** (in `art-archive/T-086/screenshots/`; also in `screenshots/`, which is gitignored): `T-086_hud.png` (HUD in a run, from `hud_from_menu_demo.tscn`), `T-086_hud_combo_step3.png` (combo step 3, likes bar on fire, `combo_heat_step3.tscn`), and x4 crops of each (`..._crop_x4.png`). Enlarged heart on dark and light: `art-archive/T-086/heart_dark_light_x16.png`. Commands: `bash game/tools/screenshot.sh res://tests/fixtures/hud_from_menu_demo.tscn screenshots/T-086_hud.png 30` and the same with `combo_heat_step3.tscn`.
- **Looks like:** the heart sits level with "LIKES", a touch taller than the letters, outline matching the text's. At step 3 the flames start right of the heart's column under the row (the flames' low spans cover the whole row), the heart stays clear and readable. Weak spots, for the board to judge: it is slightly taller than the letters; the 1 art px (2 screen px) outline is a little thinner than the text's 3 px outline.
- Documents affected: `game/README.md` (HUD section).

## QA notes

QA/Integration Agent, round 1, 2026-10-14. Result: **fail** (one criterion).

- **Rebuild:** `python game/tools/build_heart_icon.py build` gives a byte-identical `likes_heart.png` (same SHA-256 before and after, record unchanged); `check` passes every line (11 x 10, transparent corners, 0 semi-transparent pixels, 2 colours, only (219, 26, 41) and (8, 8, 15)).
- **No PixelLab:** the script has no network or `.env` use; the only "PixelLab" mentions in the diff say no call was made; `"prompt": null` in the record. 0 generations.
- **Tests:** full GUT suite 557/557 pass (`bash game/tools/run_tests.sh`); Python tool tests `game/tools` and `tools` 371 passed, 1 skipped.
- **Screenshots** remade from this folder (`screenshots/qa_T-086_hud.png`, `screenshots/qa_T-086_step3.png`, gitignored) and the same two fixtures shot on master (3541c53) for comparison. The heart looks right: red pixels at x 290-307, y 591-606, "LIKES" letters y 591-605, so level and about the same height; dark outline matches the text's; at step 3 it stays clear and readable next to the flames.
- **The fail, layout moved:** compared with master, at 1152x648: "LIKES" top 587 -> 591, "HYPE LV" 587 -> 591, the combo counter at step 3 (y 519-575 -> 523-579): all 4 px lower; the likes bar did not move. ("LIKES" also moves 4 px left, which follows from the narrower heart.) Cause: `_layout_bottom()` sets `row_h` from `likes_row.get_combined_minimum_size().y`, which was the placeholder's 26 px and is now the art's 20 px, so the row (bottom-anchored on the bar) gets shorter and everything centred in it or placed above it drops. The layout tests do not catch it because they check relations (no overlap, shared baseline), not absolute positions. Suggested fix, for the Project Lead to decide: keep the heart's control 26 px tall (art centred inside, still 2x, nearest) or give the row a 26 px minimum height, so the row and everything above it stays where T-113/T-131 put it; a GUT test that the row's height/top and the combo counter's position equal the pre-T-086 values would hold it.
- Godot's line-ending-only `.import` noise from the test and screenshot runs was not committed.

## Round 2

Fix by the Asset Generation Agent, 2026-10-14. **Still no PixelLab call (0 generations).**

- **Cause and fix:** the 20 px art shrank the likes row's minimum height from 26 px, which `_layout_bottom()` reads. The heart now sits in `hud.heart_box`, a 26 x 26 px `Control` (`Hud.HEART_BOX`) in the row, with the `TextureRect` (still 22 x 20, 2x, nearest) at the box's left edge and 2 px above its vertical centre (level with the letters of "LIKES"). Layout code untouched; row, "LIKES", "HYPE LV" and combo counter are where master has them.
- **Measured from master** (f6ff2eb, a temporary worktree, deleted; a throwaway test printed the rects at 1152x648 with "Hype Lv 99"): likes row (288, 584, 67 x 26), "LIKES" (320, 584, 35 x 26), "HYPE LV" (792, 584, 72 x 26), likes bar (288, 616, 576 x 16), combo counter layout rect at x1.5 (516, 547, 120 x 33), x2 (501, 541, 150 x 39), x3 (488, 534, 176 x 46), x4.5 (473, 525, 207 x 55).
- **New test:** `game/tests/unit/hud/test_hud_positions_t086.gd` pins all of these (the combo counter's position and size before the heat's time-varying pulse scale), plus the heart box 26 x 26 and the heart's top. It fails on the round 1 layout.
- **Screenshots remade** (`art-archive/T-086/screenshots/`, crops x4 too; `screenshots/` is gitignored) and compared with master's of the same two fixtures: the row's text region and the combo counter region are pixel-identical to master. The heart's red is at y 587-602 (letters 587-601), x 290-307.
- **Tests:** full GUT suite 560/560; Python tool tests `game/tools` and `tools` 371 passed, 1 skipped.
- Documents affected: `game/README.md` (HUD section, the heart box).

## QA notes, round 2

QA/Integration Agent, round 2, 2026-10-14. Result: **pass** (all six criteria).

- **Layout against master (criterion 1):** shot `hud_from_menu_demo.tscn` and `combo_heat_step3.tscn` on master (f6ff2eb, a temporary detached worktree, removed afterwards) and on this branch at 1152x648. Each fixture is deterministic (two shots of the same code are pixel-identical). Branch vs master: the "LIKES" area, "HYPE LV", the combo counter region, the likes bar and the top HUD band are pixel-identical, at the base look and at step 3; the only HUD difference is the heart (red at x 290-307, y 587-602; "LIKES" letters y 587-601, so level and about the same height, dark outline like the text's, clear of the step-3 flames). Outside the HUD the level-up sparkle particles (base) and a few flame-tip pixels of the trick popup above the car (step 3) differ, both deterministic per build: the effects' animation/random phase, not layout; noted for the board's playtest, not a criterion.
- **Pinning test:** the pinned values match master: a copy of `test_hud_positions_t086.gd` without the heart-box test (which uses `Hud.HEART_BOX`, absent on master) passes 2/2 on master. Against round 1's `hud.gd` (a369319, swapped in temporarily, then restored, no diff left): the real file fails to parse (`HEART_BOX` missing), and the same copy without the heart-box test fails 2/2 with every position 4 px low (row y 588 not 584, height 22 not 26; combo x1.5 to x4.5 y 551/545/538/529 not 547/541/534/525), so it catches the round-1 shift. On the branch it passes.
- **Art:** `python game/tools/build_heart_icon.py build` is byte-identical (PNG SHA-256 7e42654c..., record unchanged); `check` passes every line (2 colours, (219, 26, 41) and (8, 8, 15), 0 semi-transparent pixels, transparent background).
- **No PixelLab:** round 2 adds no network or `.env` use; 0 generations.
- **Tests:** full GUT suite 560/560 pass (`bash game/tools/run_tests.sh`), the HUD tests (54, incl. T-049's, T-113's, T-116's and T-131's) included; Python tool tests `game/tools` and `tools` 371 passed, 1 skipped.
- **game/README.md:** the HUD section says where the heart art is, how it is built, the heart box and the pinning test.
- Godot's line-ending-only `.import` noise from the runs was not committed.
- 2026-10-14, needs-playtest → done: board playtest: LGTM
