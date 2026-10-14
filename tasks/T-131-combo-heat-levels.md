---
id: T-131
title: Combo heats up at x2, x3 and x4, with comic-style combo and Hype Lv text and a burning likes bar
status: needs-playtest
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, docs/game-loop-architecture.md, game/README.md, game/scripts/hud/hud.gd, game/scenes/hud/hud.tscn, game/scripts/hud/trick_popup_art.gd, game/data/combo.json, tasks/T-116-hide-combo-at-no-combo.md]
files_expected_to_change: [game/scripts/hud/hud.gd, game/scenes/hud/hud.tscn, new HUD effect script(s) under game/scripts/hud/, tests under game/tests/unit/hud/, a screenshot fixture under game/tests/fixtures/, game/README.md, docs/hud-and-menus.md]
model: opus
qa_rounds: 1
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

The board wants the combo to feel like it is heating up as the player chains tricks (decision: `docs/hud-and-menus.md`, Decisions, board 2026-10-14). Three heat steps on top of today's look:

- **Below x2** (combo above x1.0, the counter showing): the base look.
- **Step 1, from x2:** the combo counter changes look for the first time: noticeably bigger, a hotter colour, a light pulse.
- **Step 2, from x3:** it changes more: bigger again, hotter again, more energy (for example a stronger pulse, a slight shake or a glow). It must read clearly as a step up from x2.
- **Step 3, from x4 up to the cap (x6 today, `combo.json`):** maxed out. The counter is at its most intense, and the likes bar looks like it is on fire: animated, flickering pixel flames along the bar.

When the combo drops (drain or a collision cut), the look drops to the step that matches the new multiplier. The steps are decided by the multiplier the counter shows (two decimals), so x1.99 is the base look and x2.00 is step 1. Keep the thresholds (2, 3, 4) as named constants in one place so they are easy to change.

**Comic look for the text.** The combo counter ("Combo x{multiplier}") and the level text ("Hype Lv {level}") move from the plain placeholder labels to the game's comic look: the Bangers font already in the game (`game/fonts/bangers/`, used by the trick popups), with hard pixel edges (no smoothing). The words stay exactly as they are (T-048 and T-082 text). Bangers has capitals only, so they show in capitals, as the popups do. The "Likes" word next to the heart takes the same font so the row matches. Keep the layout from T-113 and T-116: same places, the counter still hidden at x1.0, hiding it moves nothing, no overlaps at the tested window sizes.

**Fire and colour.** Everything is drawn in code (shaders, particles or drawn pixels; your choice), no PixelLab. Flames are oranges and yellows (whites at the hottest), pixel-art style with hard edges, never Redgull red (the only red on the HUD stays the heart). The flames must not hide the bar's fill so much that the player can't read how full it is, and must not reach into the "Likes / Hype Lv" row or the combo counter so they become unreadable. The effects follow pause like the rest of the HUD (they stop moving while the game is paused).

No sound (board, 2026-10-14). The trick popups are not part of this task.

Add a screenshot fixture that shows each step (base, x2, x3, x4+) in a run, so the board and QA can see them side by side, and say in the result notes how to run it. Update `docs/hud-and-menus.md` (Content, "The HUD") and `game/README.md` (the HUD section) with what was built.

The board's review: play a run in this task's folder, chain tricks up past x2, x3 and x4, and judge whether each step feels like it is heating up, whether the comic text fits, and whether the likes bar reads as on fire at x4.
Board review files: screenshots made by the step fixture (listed in the result notes)

## Acceptance criteria

- [x] The combo counter shows four distinct looks, chosen from the multiplier as shown at two decimals: base (above x1.0 and below x2.00), step 1 (x2.00 to below x3.00), step 2 (x3.00 to below x4.00), step 3 (x4.00 and up). A GUT test sets the multiplier to values on each side of each threshold (for example 1.99, 2.00, 2.99, 3.00, 3.99, 4.00, 6.00) and checks the step the HUD reports. (QA: pass) test_step_from_the_multiplier_at_two_decimals checks 1.99/2.00/2.99/3.00/3.99/4.00/6.00 on the HUD, plus 1.994/1.996 rounding
- [x] Each step is visibly bigger or more intense than the one before: a test checks the counter's size (font size or scale) grows from base to step 1 to step 2 to step 3, and the step fixture's screenshots show four different looks. (QA: pass) test_each_step_is_bigger_than_the_one_before, font 30/36/42/50 and on-screen width growing; the four screenshots show four different looks: pink, bigger yellow, bigger orange with glow ring, biggest white-hot
- [x] The likes bar's fire shows only at step 3: a test checks the fire is off below x4.00 and on at x4.00 and x6.00, and the step 3 screenshot shows flames along the likes bar. (QA: pass) test_fire_only_at_the_top_step; step 3 screenshot shows flames along the bar, none at base/step 1/step 2
- [x] When the combo drops (drain, collision cut, back to x1.0) the look follows it down: a test raises the combo to x4+, lowers it through each step, and checks the step and the fire at each point; at x1.0 the counter is hidden as before (T-116). (QA: pass) test_the_look_follows_the_combo_down walks 6.0 to 1.0 checking step, fire and the counter hidden at x1.0; test_a_collision_cuts_the_heat
- [x] The combo counter, "Likes" and "Hype Lv {level}" use the Bangers font with smoothing off, and their words are unchanged apart from capitals (checked against T-048 and T-082 text in a test). (QA: pass) test_comic_font_with_the_words_unchanged, Bangers with antialiasing none on all three labels, T-048/T-082 words unchanged
- [x] No part of the effects uses Redgull red: a test samples the fire's and the counter's colours (or the colours in the code that draws them) and finds none within the Redgull red range the existing art tests use (for example `test_trick_popup_art.gd`). (QA: pass) test_no_redgull_red over 30 animation frames; my own pixel scan of the four screenshots' bottom HUD found 0 red pixels outside the heart
- [x] The layout still holds: the existing `test_hud_layout.gd` and `test_hud_combo_hidden.gd` pass unchanged, and at step 3 the counter and the "Likes / Hype Lv" row stay inside the screen and do not overlap each other at 1152x648, 1280x720, 1920x1080 and 1024x576. (QA: pass) test_hud_layout.gd and test_hud_combo_hidden.gd unchanged on the branch and passing; test_layout_holds_at_the_top_step at the four sizes; my step 3 screenshots at 1024x576, 1152x648, 1280x720 and 1920x1080 show no overlap and everything on screen
- [x] The effects stop moving while the game is paused (a test advances time while paused and checks the animation state does not change). (QA: pass) test_effects_stand_still_while_paused
- [x] It works in a run started from the main menu, and the whole GUT suite passes. (QA: pass) test_in_a_run_started_from_the_main_menu; the fixture runs start from the main menu; full GUT suite 536/536
- [x] `docs/hud-and-menus.md` (Content, "The HUD") and `game/README.md` (the HUD section) describe the steps, the thresholds, the fire and the fixture. (QA: pass) both describe the steps, thresholds, fire and fixture

## Result notes

UI Agent, 2026-10-14. Branch `task/T-131-combo-heat-levels`, folder `C:\solid-carbide-worktrees\T-131`. No PixelLab calls (everything is drawn in code), no sound, trick popups untouched.

**What was built**
- `game/scripts/hud/combo_heat.gd` (`ComboHeat`, new): picks the heat step from the multiplier at two decimals (`step_for()`; thresholds in one place, `ComboHeat.THRESHOLDS = [2.0, 3.0, 4.0]`, fire from `FIRE_STEP = 3`) and restyles the combo counter per step (`STEPS`): base pink 30 px (today's look, now in Bangers); step 1 yellow 36 px, light pulse; step 2 orange 42 px, yellow glow ring round the dark outline, stronger and faster pulse; step 3 white-hot 50 px, glow ring flickering between oranges and yellows, strongest pulse, likes bar on fire. The pulse is a quick pop on each beat in 1/12 s pixel-art frames, scaled from the counter's bottom centre so it never grows into the row and stays centred.
- `game/scripts/hud/likes_fire.gd` (`LikesFire`, new): pixel flames drawn in code (2 px squares, white-hot base, yellow, orange-yellow, orange tips, a few sparks) along the top of the likes bar, flickering in the same frames. Tallest (26 px) over the filled part and in the gap between the texts, 8 px under "Likes" and "Hype Lv" (drawn under them), 4 px over the empty part, and only 4 px into the bar's top, so the fill stays readable; never reaches the counter.
- `game/scripts/hud/hud.gd`: `Hud.comic_font()` (Bangers, smoothing off) on the counter, "Likes" and "Hype Lv" (words unchanged; Bangers shows capitals); the heat and fire nodes; `combo_step()` and `fire_on()`. Both effect nodes are pausable, so they stand still while paused. Layout unchanged (T-113, T-116).
- Tests: `game/tests/unit/hud/test_hud_combo_heat.gd` (13 tests, one or more per criterion: step at 1.99/2.00/2.99/3.00/3.99/4.00/6.00, font size and width growing per step, fire only from x4.00, the drain walking down 6.0 -> 4.25 -> 3.75 -> 3.25 -> 2.75 -> 2.25 -> 1.75 -> 1.0 with step and fire checked at each and hidden at x1.0, a collision putting the fire out, Bangers with antialiasing off and the T-048/T-082 words, no colour within 0.5 of the heart red (the trick popup art test's rule) or a red hue in any counter, glow or flame colour over 30 animation frames, step-3 layout inside the screen with no overlaps at the four window sizes over a whole pulse, the flames clear of the counter and only 4 px into the bar, paused effects not moving, a run from the main menu). `game/tools/test_combo_heat_strip.py` for the strip tool.

**Step fixture:** from the task folder, `bash game/tools/combo_heat_shots.sh screenshots` (four runs from the main menu at x1.5, x2.0, x3.0 and x4.5; fixtures `game/tests/fixtures/combo_heat_{base,step1,step2,step3}.tscn`, script `combo_heat_demo.gd`). Screenshots (git-ignored):
- `C:\solid-carbide-worktrees\T-131\screenshots\combo_heat_steps.png` (the bottom of the four screens stacked, 2x: the side-by-side view)
- `C:\solid-carbide-worktrees\T-131\screenshots\combo_heat_base.png`, `combo_heat_step1.png`, `combo_heat_step2.png`, `combo_heat_step3.png` (full screens)

**My own look at the screenshots:** the four steps read as a clear escalation (pink -> bigger yellow -> bigger orange with a glow ring -> biggest white-hot with flames under it). Things the board may want to judge in play: the flames are a first pass (tongues of flame over the filled part, a low burning line over the empty part, and a white-hot strip over the bar's top 4 px); Bangers at the 20 px row size is small and its "1" looks a little like a "7" ("HYPE LV 1"); the pulse and flicker only show in motion, so play it. With the new font, "Likes" now sits at the top of its row like "Hype Lv" (both share a baseline, as T-113 requires).

**Tests:** full GUT suite 536/536 (50 scripts, `bash game/tools/run_tests.sh`); `game/tools` pytest 235 passed, 1 skipped; `tools` pytest 130 passed. Godot's line-ending-only `.import` changes were not committed.

**Documents affected (updated):** `docs/hud-and-menus.md` (Content, "The HUD": the comic font and the combo heat steps, thresholds, fire and fixture) and `game/README.md` (the HUD section: `ComboHeat`, `LikesFire`, `comic_font()`, the tests and the step fixture).

**QA round 1 (QA/Integration Agent, 2026-10-14): all 10 criteria pass.**
- Full GUT suite: 536/536 passing (50 scripts, `bash game/tools/run_tests.sh`). Python tests: `game/tools` 235 passed, 1 skipped; `tools` 130 passed.
- Ran `bash game/tools/combo_heat_shots.sh screenshots` and looked at the five images: four clearly escalating looks, flames only at step 3, no Redgull red outside the heart, the bar's purple fill and its fill edge still easy to read under the flames, the counter clear of the "Likes / Hype Lv" row. The flames lick the bottom of "Likes" and "Hype Lv" but both stay readable.
- Extra QA screenshots of step 3 at 1024x576, 1280x720 and 1920x1080 (Godot `--resolution`, same fixture): `C:\solid-carbide-worktrees\T-131\screenshots\qa_step3_sizes.png` (bottom HUD of all three) and `qa_step3_<size>.png`. Layout holds at every size; at 1024x576 the flame tips come close to the counter's outline but do not touch it.
- For the board's playtest (not failures): the pulse and flicker can only be judged in motion; "HYPE LV 1" in Bangers at 20 px reads a little like "7" (the UI Agent noted this too); at 1920x1080 the bottom HUD is small relative to the screen (the HUD does not scale, as before this task).
- Godot's line-ending-only `.import` changes in the working tree were left uncommitted.
