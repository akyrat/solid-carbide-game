---
id: T-131
title: Combo heats up at x2, x3 and x4, with comic-style combo and Hype Lv text and a burning likes bar
status: open
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

- [ ] The combo counter shows four distinct looks, chosen from the multiplier as shown at two decimals: base (above x1.0 and below x2.00), step 1 (x2.00 to below x3.00), step 2 (x3.00 to below x4.00), step 3 (x4.00 and up). A GUT test sets the multiplier to values on each side of each threshold (for example 1.99, 2.00, 2.99, 3.00, 3.99, 4.00, 6.00) and checks the step the HUD reports. (QA: pass / fail)
- [ ] Each step is visibly bigger or more intense than the one before: a test checks the counter's size (font size or scale) grows from base to step 1 to step 2 to step 3, and the step fixture's screenshots show four different looks. (QA: pass / fail)
- [ ] The likes bar's fire shows only at step 3: a test checks the fire is off below x4.00 and on at x4.00 and x6.00, and the step 3 screenshot shows flames along the likes bar. (QA: pass / fail)
- [ ] When the combo drops (drain, collision cut, back to x1.0) the look follows it down: a test raises the combo to x4+, lowers it through each step, and checks the step and the fire at each point; at x1.0 the counter is hidden as before (T-116). (QA: pass / fail)
- [ ] The combo counter, "Likes" and "Hype Lv {level}" use the Bangers font with smoothing off, and their words are unchanged apart from capitals (checked against T-048 and T-082 text in a test). (QA: pass / fail)
- [ ] No part of the effects uses Redgull red: a test samples the fire's and the counter's colours (or the colours in the code that draws them) and finds none within the Redgull red range the existing art tests use (for example `test_trick_popup_art.gd`). (QA: pass / fail)
- [ ] The layout still holds: the existing `test_hud_layout.gd` and `test_hud_combo_hidden.gd` pass unchanged, and at step 3 the counter and the "Likes / Hype Lv" row stay inside the screen and do not overlap each other at 1152x648, 1280x720, 1920x1080 and 1024x576. (QA: pass / fail)
- [ ] The effects stop moving while the game is paused (a test advances time while paused and checks the animation state does not change). (QA: pass / fail)
- [ ] It works in a run started from the main menu, and the whole GUT suite passes. (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` (Content, "The HUD") and `game/README.md` (the HUD section) describe the steps, the thresholds, the fire and the fixture. (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
