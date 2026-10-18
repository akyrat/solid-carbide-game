---
id: T-156
title: "Trick prototype: confirmation cards for the new tricks and the jump-over bonus"
status: cancelled
from: project-lead
to: ui
lead: Coursework
epic: hud-menus
milestone: final-release
user_facing_text: yes
changes_visuals: yes
depends_on: [T-154]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-152-trick-prototype-input-hud.md, tasks/T-154-trick-prototype-text-round-2.md, tasks/T-155-trick-prototype-jumps-and-new-tricks.md, game/README.md]
files_expected_to_change: [game/scripts/hud/trick_hud.gd, tests under game/tests/, game/README.md]
model: sonnet
qa_rounds: 1
---

## Description

Builds on T-155 (work on a branch made from T-155's branch). The trick prototype's HUD (T-152) shows SIDE FLIP! when a trick completes. Extend it:

1. Show the right name for each trick id, from one table: `side_flip_right`, `side_flip_left`, `nose_launch` (T-154 items 1 and 2; if T-154 renames the right flip, use the new name).
2. Show the **jump-over bonus** (`jump_over`, T-154 item 3) as its own card, in the same comic look. When it comes during or just after a trick's card, the cards stack (the newer one above, a small gap) instead of replacing each other.
3. The key display's matched-steps rings follow whichever sequence is in progress (T-155's detector says which one, or the longest match; agree it with what T-155 exposes).

Use exactly T-154's text; no other words. Never Redgull red.

Tests: each trick id shows its own name; the bonus card shows and stacks with a trick card; the rings follow the new sequences.

## Acceptance criteria

- [ ] Tests show each of the three trick ids shows exactly its T-154 (or T-150) name. (QA: pass) -- test_each_trick_id_shows_its_own_name; TEXT_TRICKS has RIGHT FLIP!, LEFT FLIP!, NOSE POP! exactly
- [ ] A test shows the jump-over bonus card shows with T-154's text and stacks with a trick card without overlapping. (QA: pass) -- test_bonus_card_shows_and_stacks_without_overlap; CLEARED IT! text; screenshot shows stacked cards
- [ ] A test shows the matched rings follow the left flip and nose launch sequences. (QA: pass) -- test_rings_follow_left_flip_and_nose_launch
- [ ] No other text appears and nothing is Redgull red. `game/README.md` is updated. All three test sets pass. (QA: pass) -- no other new text, no red in file or screenshot; game/README.md updated; GUT 897/896 (only the accepted test_screen_flow main-scene failure), game/tools Python 281 OK, tools Python 182 OK

The board's review: play the trick prototype with T-155 (one playtest build).

## Updates

### 2026-10-17, Open → In progress

Started: trick cards for RIGHT FLIP!, LEFT FLIP!, NOSE POP! and the CLEARED IT! bonus, on top of T-155.

### 2026-10-17, In QA

Built: cards for RIGHT FLIP!, LEFT FLIP!, NOSE POP!, and CLEARED IT! stacking above a flip's card. QA is checking it now.

### 2026-10-17, Needs playtest

QA passed all 4 criteria. The playtest build now has round 2 (jumps, left flip, nose pop, new cards), with the code roll until T-157's art is in.

## Result notes

Done by the UI Agent, only `game/scripts/hud/trick_hud.gd`, `game/tests/unit/test_trick_hud.gd`, a screenshot fixture (`game/tests/fixtures/trick_hud_cards_demo.gd/.tscn`) and `game/README.md`.
- One table `TEXT_TRICKS` with the T-154 text; `jump_over` has its own card; the two cards stack (newer above, 16 px gap, tested for no overlap). The rings follow the presses (so already any sequence); `candidate_ids` is read from `arrow_tricks.candidates()` on `progress_changed` (not `target_sequence()`).
- Tests: 5 new in test_trick_hud.gd (10 pass). Full run: 897 tests, 896 pass; the one failure is `test_screen_flow.gd::test_the_main_scene_is_the_game_flow` (project.godot's main scene is the trick prototype on this line), the only failure.
- Screenshot: C:\solid-carbide-worktrees\T-156rt-archive\T-156\hud_cards.png (LEFT FLIP! with CLEARED IT! above it, keys part way).
- No red anywhere. Other test sets (python tools tests) untouched by this change.
- 2026-10-19, needs-playtest → cancelled: Board, 2026-10-19: building the trick prototype before an elevation system was a mistake. Not merged; kept as the reference for rebuilding the tricks on real height (Drifting, Content, 'Trick prototype (reference)'); code on the branch hold/trick-prototype, art in art-archive/.
