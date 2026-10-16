---
id: T-150
title: "Text: the side flip trick's name and the input HUD label in the trick prototype"
status: in-qa
from: project-lead
to: narrative-theme
lead: Tricks
epic: narrative
milestone: final-release
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/drifting.md, docs/hud-and-menus.md, tasks/T-151-arrow-key-trick-prototype.md, tasks/T-152-trick-prototype-input-hud.md]
files_expected_to_change: [tasks/T-150-trick-prototype-text.md]
model: sonnet
qa_rounds: 0
---

## Description

The board wants a quick prototype of arrow-key tricks (Drifting, Decisions, 2026-10-16): the player chains arrow keys and the car does a trick. The first and only trick for now is a side flip to the right, done with Up, Right, Down, Left in a row. When the player completes the sequence, a short comic-style confirmation animation plays on screen (task T-152).

Write the final text for:

1. **The trick's name**, shown big in the confirmation animation when the sequence is completed. A short shout in the style of the existing trick popups (FULL 360!, ALT DRIFT!, LONG DRIFT!; HUD and menus, "Trick popups"). Bangers font, capitals only. At most 14 characters.
2. **The input HUD's label** (optional): a short label above the four arrow keys in the bottom-right corner, if one fits the game's tone; at most 10 characters. Say "none" if the HUD reads better without one.

Write the final text in the result notes, one line per item, with a one-line reason each.

## Acceptance criteria

- [ ] The result notes give the final text for item 1, in capitals, at most 14 characters. (QA: pass / fail)
- [ ] The result notes give item 2 (text of at most 10 characters, or "none"). (QA: pass / fail)

## Updates

### 2026-10-16, Open → In progress

Started: the Narrative Theme Agent writes the side flip's name and the HUD label.

## Result notes

1. Trick name: **SIDE FLIP!** (10 characters). Plain and readable, in the same shout style as FULL 360! and ALT DRIFT!, and it names exactly what the car does.
2. Input HUD label: **TRICK** (5 characters). One short word that tells the player what the four arrow keys are for, in the same tone as the popups.
