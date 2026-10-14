---
id: T-086
title: Art: the heart icon on the likes bar
status: in-qa
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-049]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, tasks/T-048-text-hud.md, tasks/T-049-hud-run-values.md, game/README.md]
files_expected_to_change: [art files under game/art/ and their records, the HUD scene, game/README.md]
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

T-049 (the HUD, with a placeholder heart) is done. Since T-131 the "LIKES" and "HYPE LV" texts are in the Bangers comic font with a dark outline.

The likes bar shows the word "Likes" with a heart icon at its left end (T-048, approved by the board). The icon: a small flat heart in Redgull red, like a social app's like button. **Board, 2026-10-14:** it matches the HUD's comic look: a thick dark outline like the "LIKES" and "HYPE LV" text's, a little chunky, sized to the height of the "LIKES" text so it sits level with it. **Drawn by script, no PixelLab** (a hand-placed pixel grid, like the kaiju warning signs in T-130): 0 generations. Follow Visual style's technical rules (pixel art, no anti-aliasing, no semi-transparent pixels, transparent background). The red is the Redgull red the placeholder uses (the only red on the HUD). Swap it in for T-049's placeholder heart (`tasks/README.md`, "Art replaces placeholders"); keep T-113/T-131's layout (nothing else moves). Game-ready art in `game/art/`, any other versions in `art-archive/T-086/`, with the record Visual style asks for.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A screenshot of the HUD in a run shows the final heart next to "LIKES", level with it, about the same height, with a dark outline like the text's; also one at combo step 3 (likes bar on fire) so the heart reads next to the flames (QA: fail: the heart itself is right (level with "LIKES", about its height, dark outline, readable beside the step-3 flames), but the description's "nothing else moves" is broken: "LIKES", "HYPE LV" and the combo counter all sit 4 px lower than on master, because the shorter heart (20 px, was 26) shrinks the row height `_layout_bottom()` takes from the row's minimum size)
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
