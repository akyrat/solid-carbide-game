---
id: T-337
title: The sub goal square in place of the likes bar, with the gift pack inside it
status: needs-playtest
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-331]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, game/README.md, game/scripts/hud/, game/art/gift_pack/package.png]
files_expected_to_change: [game/scripts/hud/, game/scenes/, game/tests/unit/hud/, game/README.md, docs/hud-and-menus.md, art-archive/T-337/]
model: opus
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decisions (2026-10-28): HUD and menus, Decisions, "The HUD looks like a livestream"; Game loop architecture, Decisions, "Subs instead of likes". The likes bar and its "Likes ... Hype Lv" row are replaced by the **sub goal**, as the board designed it on its layout page (https://claude.ai/artifact/CSHYCDV9xZbSYwQGUt5SJ4):

- A **black square** that **fills green from the bottom** as subs come in (today's likes XP within the level), with today's spring when subs arrive (the fill shoots up with a small overshoot, T-273) and the drain emptying it slowly as now.
- **The gift pack inside it**, centred, filling 80% of the square (a 10% margin on each side; crop `art/gift_pack/package.png` to its box first, as the page does), **greyed out and dimmed** while the goal isn't reached. When the goal is reached it **lights up** in full colour and bounces, the square glows, and the level-up goes on as today (the helicopter brings the gift pack), then the square starts again from empty.
- **Under the square:** T-331's label, "{subs} / {goal}" with the subs icon or word.
- **"Hype Lv" is gone for good** (the board, 2026-10-28): remove the text, its code (`TEXT_LEVEL` and its placement in `hud.gd`) and the level-up pop that used it (`level_up_flash.gd`), and the same in the tests, comments and game/README.md. The level now shows only through the sub goal: the square fills, the gift lights up, the level-up goes on. Nothing replaces the text.
- Today's level-up animation on the bar (T-139) and the bar's heat (fire at the top combo step) are carried over to the square where they fit, or dropped with a reason in the result notes.
- **Position and size:** from the layout page; the Project Lead writes the saved numbers in this ticket's Updates when it starts; the board has put it on the right edge, about two thirds down (x988, y340, 128 x 180 at 1152 x 648), so anchor it to the right edge, not the bottom centre.
- If T-339's art (the square's frame, the subs icon) is in the branch you start from, use it; otherwise placeholders in code.

The board's review: play a run: the square fills as you drift, the gift lights up at the goal, and the gift pack comes.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The likes bar and its row are gone; the sub goal square shows at the layout page's position (at 1152 x 648), anchored to the right edge, and no "Hype Lv" text or code is left (test). (QA: pass)
- [ ] The square's fill is the share of the current goal, with the spring on gains, and empties with the drain (tests). (QA: pass)
- [ ] The gift is centred at 80% of the square, greyed until the goal and in full colour at it; the level-up and gift pack drop work as before (tests). (QA: pass)
- [ ] The label under it shows "{subs} / {goal}" from T-331's text (test). (QA: pass)
- [ ] HUD and menus, Content and game/README.md describe it. (QA: pass)
- [ ] Screenshots (or a GIF for anything that moves) are in `art-archive/T-337/screenshots/`: the square part-filled with the grey gift, and a GIF of it reaching the goal. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-28, Open → In progress

Started from the playtest build (T-331 approved). Layout from the board's page (1152x648): subgoal x988 y340 w128 h180, anchored to the right edge.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

UI Agent, 2026-10-28. Built in `C:\solid-carbide-worktrees\T-337` on `task/T-337-the-sub-goal-square` (from the livestream HUD playtest build). 0 PixelLab generations: it uses T-339's art (`art/hud/subgoal_frame.png`, `art/hud/subs_icon.png`) and the existing `art/gift_pack/package.png`.

**What it does**
- `game/scripts/hud/sub_goal.gd` (`SubGoal`, `hud.sub_goal`): 128 x 180 at x988 y340 at 1152 x 648, from `game/data/hud.json` `sub_goal.layout` (new block, the board's numbers from this ticket's Updates). Anchored to the right edge (36 px margin at any width) and at 340/648 of the height.
- The square is T-339's frame at 2x. The fill is drawn over its black inside row by row in art pixels (56 rows, following the rounded inner corners), green from the bottom, with a lighter top line. The green is the HUD's health green (64, 217, 115), not Greenbull's light green (Visual style rule 6).
- The fill is today's spring (`LikesSpring`, T-273): it springs on gains with a small overshoot, the drain empties it with no spring, it stops while paused, and it is never drawn past full. The gift never lights from an overshoot that stays short of the goal.
- The gift is `package.png` cropped to its used box (40 x 43), centred in a 102 x 102 box (80% of 128, a 10% margin), kept to its shape, nearest filtering. Until the goal it is greyed and dimmed (luminance x 0.6, a proposal). From the moment the goal is reached it shows in full colour.
- Under the square: the subs icon at 2x and T-331's `TEXT_SUB_GOAL` ("42 / 156 SUBS"), Bangers 20. The row is about 150 px wide, a little wider than the square, centred under it, and stays on screen.
- At the goal, the level-up fires at once, as before (the helicopter and the gift pack are untouched). The square springs to full and `celebrate()` plays for 1 s (12 frames at 1/12 s, `PROCESS_MODE_ALWAYS`): the gift bounces (up to 1.2x, dips to 0.94, settles) and a 2-art-pixel glow ring (white, pale mint, green) flickers round the frame. Meanwhile the spring holds full: `LikesSpring.fill_then(ratio, hold)` gained a `hold`, default 0, so old callers are unchanged. The label reads "{goal} / {goal} SUBS". Then the square restarts from empty, the gift greys, and the label shows the next goal. The look and timings are proposals for the playtest.
- "Hype Lv" is gone for good. Removed: `TEXT_LEVEL`, `level_label`, the likes bar (`likes_bar`, `LIKES_BAR_*`, `LIKES_COLOR`), its row (`likes_row`, `likes_label`, `heart`, `heart_box`, `HEART_BOX`, `TEXT_LIKES`, `LABEL_GAP`, `COMBO_GAP`), and `level_up_flash.gd` with its test, its 7 fixtures, `level_up_flash_shots.sh`, `level_up_flash_strip.py` and its test. A test checks that none of it is left in `hud.gd` or on screen. `health_heart` (under the health bar) stays: it belongs to T-338.
- Carried over or dropped:
  - The T-139 bar animation is replaced by the square's glow and bounce. Its sweep across the bar and the "Hype Lv" pop have no place on a square with no level text.
  - The combo heat's fire (`LikesFire`) was carried over. It is now a child of the sub goal, on the square's top edge, burning full height along it. `ComboHeat` is unchanged, so T-336's work on the heat isn't touched.
- The combo counter stays at the bottom centre, exactly where it was (`Hud.COMBO_BOTTOM` 116, pinned by `test_hud_positions_t086.gd`), until T-336 moves it. It now also re-lays itself out when its text gets shorter, which the likes row's resizes used to trigger by accident.
- Bug fixed on the way: a level-up still showing when a new run started kept the old bar's pending restart. A level lower than the last now stops the celebration and snaps the square empty.
- `game/scripts/run/gift_arrows.gd`: `hud_rects()` now keeps the arrows clear of the sub goal and its flames instead of the removed bar and row (a one-line change outside the HUD scripts).
- Overlap with T-336 and T-341: my edits in `hud.gd` are the bottom area (`_build_bottom`, `_layout_bottom`), the xp and level-up handlers and the constants and vars above. Expect a merge conflict in `_layout_bottom` / `combo_label` placement with T-336, and a small one in `data/hud.json` (a new `sub_goal` block appended at the end).

**Tests** (all in the foreground, 2026-10-28)
- `python -m unittest discover -s game/tools -p "test_*.py"`: 645 tests, OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 545 tests, OK.
- `bash game/tools/run_tests.sh`: 146 scripts, 1763 tests, 1763 passing, TESTS PASSED.
- New: `game/tests/unit/hud/test_hud_sub_goal.gd`, 17 tests: the layout and anchoring, the art, the inside rows, the fill share, spring and drain, the gift at 80% with its crop, grey and dimmed then full colour, the label and icon, the celebration, colours clear of Greenbull's and the heart red, a new run, a run from the main menu. Also new: the hold test in `test_likes_spring.gd`, the no-Hype-Lv test in `test_hud_values.gd`, and a `--box` test in `game/tools/test_likes_spring_gif.py`.
- Updated for the removal: `test_hud_values`, `test_hud_layout`, `test_hud_combo`, `test_hud_combo_heat`, `test_hud_combo_hidden`, `test_hud_positions_t086` (only the combo part is left), `test_hud_heart_art`, `test_hud_weapon_icons`, `test_likes_spring`, `run/test_gift_drops`, `run/test_run_likes_drain`.

**Screenshots** (`art-archive/T-337/screenshots/`, made with `bash game/tools/record_sub_goal.sh`, fixture `game/tests/fixtures/sub_goal_demo.tscn`)
- `sub_goal_part.png`: a whole run screen with the square 58% filled and the grey gift.
- `sub_goal_lit.png`: the goal just reached: full, the gift lit, the glow ring.
- `sub_goal_reaching_goal.gif`: the right edge at 2x. Subs come in with the spring, the square reaches the goal, celebrates, holds and restarts at the next goal ("0 / 125 SUBS").

**For the playtest**
- When lit, the gift is Greenbull green over the green fill, so it reads less clearly than when grey. If the board wants more contrast, a darker fill or a dark band behind the gift are cheap code changes.
- I couldn't read the board's layout page (https://claude.ai/artifact/CSHYCDV9xZbSYwQGUt5SJ4). The artifact tool said it was not found or not shared with this account. I used the numbers from this ticket's Updates, so the fill colour, glow and grey level are my proposals.

**Process notes**
- Two shell commands were refused by the ticket guard hook: a `timeout`-wrapped Godot import, and a subshell around `run_tests.sh`. I ran the parts on their own, as the hook's message says. A `git update-index --refresh` was also refused, and I left it.
- The worktree shows about 250 `.import` files as modified, with an empty `git diff` (line-ending noise from Godot's import). None are committed.

**Documents affected**
- `docs/hud-and-menus.md` (Content): the Bottom centre bullet is replaced by "Sub goal (task T-337)". The level-up animation bullet is marked replaced. The combo heat's fire is now on the square. The texts section is updated (subs icon, and the Subs word no longer shown on its own).
- `game/docs/hud-and-menus/hud.md`: in place of `game/README.md`. A new "The sub goal (task T-337)" paragraph, and the HUD, heart, spring and level-up paragraphs are marked updated or removed.
- `game/README.md`: the index line for hud.md.

**QA, round 1 (QA agent, 2026-10-28):** all 7 criteria pass. qa_check: 3 test sets pass, documents changed, 3 screenshots present. Square, grey gift, label and the part-filled screenshot checked by eye. No "Hype Lv" or likes-bar code is left except comments and tests that assert its absence. The README criterion is met by game/docs/hud-and-menus/hud.md, the index in game/README.md and docs/hud-and-menus.md. Test counts as reported by the agent: 645 / 545 / 1763 (qa_check confirmed all sets pass).
