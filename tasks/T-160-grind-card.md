---
id: T-160
title: "Trick prototype: the grind's card"
status: open
from: project-lead
to: ui
lead: Tricks
epic: hud-menus
milestone: final-release
user_facing_text: yes
changes_visuals: yes
depends_on: [T-158]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-156-trick-prototype-hud-new-tricks.md, tasks/T-158-grind-text.md, tasks/T-159-trick-prototype-tilt-and-grind.md, game/README.md]
files_expected_to_change: [game/scripts/hud/trick_hud.gd, tests under game/tests/, game/README.md]
model: sonnet
qa_rounds: 0
---

## Description

Builds on T-159 (work on a branch made from T-159's branch). When the trick prototype sends `trick_performed("grind")`, show T-158's text as a card in the same comic look and stacking as the other trick cards (T-156): add it to the one text table. Use exactly T-158's text. Never Redgull red.

## Acceptance criteria

- [ ] A test shows `grind` shows exactly T-158's text as a card, stacking with other cards without overlap. (QA: pass / fail)
- [ ] No other new text, nothing Redgull red; `game/README.md` updated; all three test sets pass, apart from the expected main-scene test on this line. (QA: pass / fail)

The board's review: play it with T-159 (one playtest build).

## Updates

## Result notes
