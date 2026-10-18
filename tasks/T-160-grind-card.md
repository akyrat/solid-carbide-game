---
id: T-160
title: "Trick prototype: the grind's card"
status: cancelled
from: project-lead
to: ui
lead: Coursework
epic: hud-menus
milestone: final-release
user_facing_text: yes
changes_visuals: yes
depends_on: [T-158]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-156-trick-prototype-hud-new-tricks.md, tasks/T-158-grind-text.md, tasks/T-159-trick-prototype-tilt-and-grind.md, game/README.md]
files_expected_to_change: [game/scripts/hud/trick_hud.gd, tests under game/tests/, game/README.md]
model: sonnet
qa_rounds: 1
---

## Description

Builds on T-159 (work on a branch made from T-159's branch). When the trick prototype sends `trick_performed("grind")`, show T-158's text as a card in the same comic look and stacking as the other trick cards (T-156): add it to the one text table. Use exactly T-158's text. Never Redgull red.

## Acceptance criteria

- [ ] A test shows `grind` shows exactly T-158's text as a card, stacking with other cards without overlap. (QA: pass) test_grind_shows_its_card_and_stacks_with_the_bonus passes; text matches T-158; stacks above the bonus card, no overlap.
- [ ] No other new text, nothing Redgull red; `game/README.md` updated; all three test sets pass, apart from the expected main-scene test on this line. (QA: pass) Only the grind entry added to the table; no colour changes; README updated; GUT 930 run, 929 pass, sole failure test_the_main_scene_is_the_game_flow (expected); game/tools 293 OK; tools 206 OK.

The board's review: play it with T-159 (one playtest build).

## Updates

### 2026-10-17, Open → In progress

Started: the GRIND! card, on top of T-159.

### 2026-10-17, In QA

GRIND! card built; in the playtest build with T-159's tilt and grinds. QA is checking it.

### 2026-10-17, Needs playtest

QA passed both criteria; waiting for your playtest with T-159.

## Result notes

Added `"grind": "GRIND!"` (T-158's exact text) to `TEXT_TRICKS` in `game/scripts/hud/trick_hud.gd`. It uses the shared trick card, so the look, pop, fade and stacking are the same as the other cards. No other new text, no red. New test `test_grind_shows_its_card_and_stacks_with_the_bonus` (text exact, stacks with the bonus card without overlap); the table size test is now 5. `game/README.md` updated (T-156 paragraph).

Tests: GUT 930 run, 929 pass, 1 expected failure (`test_the_main_scene_is_the_game_flow`, the main scene is the trick prototype on this line); `game/tools` Python 293 ok (1 skipped); `tools` Python 206 ok.
- 2026-10-19, needs-playtest → cancelled: Board, 2026-10-19: building the trick prototype before an elevation system was a mistake. Not merged; kept as the reference for rebuilding the tricks on real height (Drifting, Content, 'Trick prototype (reference)'); code on the branch hold/trick-prototype, art in art-archive/.
