---
id: T-156
title: "Trick prototype: confirmation cards for the new tricks and the jump-over bonus"
status: open
from: project-lead
to: ui
lead: Tricks
epic: hud-menus
milestone: final-release
user_facing_text: yes
changes_visuals: yes
depends_on: [T-154]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-152-trick-prototype-input-hud.md, tasks/T-154-trick-prototype-text-round-2.md, tasks/T-155-trick-prototype-jumps-and-new-tricks.md, game/README.md]
files_expected_to_change: [game/scripts/hud/trick_hud.gd, tests under game/tests/, game/README.md]
model: sonnet
qa_rounds: 0
---

## Description

Builds on T-155 (work on a branch made from T-155's branch). The trick prototype's HUD (T-152) shows SIDE FLIP! when a trick completes. Extend it:

1. Show the right name for each trick id, from one table: `side_flip_right`, `side_flip_left`, `nose_launch` (T-154 items 1 and 2; if T-154 renames the right flip, use the new name).
2. Show the **jump-over bonus** (`jump_over`, T-154 item 3) as its own card, in the same comic look. When it comes during or just after a trick's card, the cards stack (the newer one above, a small gap) instead of replacing each other.
3. The key display's matched-steps rings follow whichever sequence is in progress (T-155's detector says which one, or the longest match; agree it with what T-155 exposes).

Use exactly T-154's text; no other words. Never Redgull red.

Tests: each trick id shows its own name; the bonus card shows and stacks with a trick card; the rings follow the new sequences.

## Acceptance criteria

- [ ] Tests show each of the three trick ids shows exactly its T-154 (or T-150) name. (QA: pass / fail)
- [ ] A test shows the jump-over bonus card shows with T-154's text and stacks with a trick card without overlapping. (QA: pass / fail)
- [ ] A test shows the matched rings follow the left flip and nose launch sequences. (QA: pass / fail)
- [ ] No other text appears and nothing is Redgull red. `game/README.md` is updated. All three test sets pass. (QA: pass / fail)

The board's review: play the trick prototype with T-155 (one playtest build).

## Updates

## Result notes
