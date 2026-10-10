---
id: T-082
title: Text: the trick names and the combo counter
status: needs-playtest
from: project-lead
to: narrative-theme
epic: narrative
milestone: mvp
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/drifting.md, .claude/agents/narrative-theme.md, tasks/T-083-hud-combo-and-trick-popups.md]
files_expected_to_change: [tasks/T-082-text-combo.md (result notes only)]
model: sonnet
qa_rounds: 1
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

Text for the combo (HUD and menus, Decisions), shown in T-083:
- **trick.extended_drift**, **trick.360**, **trick.alternate_drift:** the name each trick pops out with, in comic-style letters. Short and punchy: up to 16 characters each. The board calls them extended drift, 360 and alternate drift (Drifting, Decisions); the popup names may be more fun, but each must still be recognisable as that trick.
- **combo.label:** the label of the combo counter next to the likes bar, with where the multiplier goes (for example a `{multiplier}` placeholder). Up to 15 characters.
- **combo.added:** how the popup shows what a trick added, with where the number goes. Up to 8 characters.

Write the final text in this task's result notes, as a table: key, where it appears, the text, and its length in characters. The building task uses exactly this text (`tasks/README.md`, "User-facing text and visuals"). Write in Extended narrative's voice: satirical, Redgull out of touch, the player's fun slightly unethical. Players see "likes", never "XP".

## Acceptance criteria

- [ ] The result notes have trick.extended_drift, trick.360, trick.alternate_drift, combo.label and combo.added (QA: pass / fail)
- [ ] Every text in the table fits the length limit given for it (QA: pass / fail)
- [ ] No text contains "XP" or "experience" (QA: pass / fail)

The board's review: read the text and judge whether it has the right voice.

## Result notes

Text for T-083, final. Use exactly this text. Lengths are characters as shown to the player.

| Key | Where it appears | Text | Length |
|---|---|---|---|
| trick.extended_drift | Small popup from the car, every second of an extended drift | LONG DRIFT! | 11 |
| trick.360 | Popup from the car when the heading turns a full 360 | FULL 360! | 9 |
| trick.alternate_drift | Popup from the car on each forward/backward switch in an alternate drift | ALT DRIFT! | 10 |
| combo.label | Combo counter next to the likes bar; `{multiplier}` is replaced by the current multiplier, e.g. "Combo x2.5" | Combo x{multiplier} | 10 as shown with a one-digit multiplier (e.g. "Combo x2.5"); 11 at "x12.5"; the template itself is 19 because of the placeholder |
| combo.added | Next to the trick name in the popup; `{amount}` is replaced by what the trick added to the multiplier, e.g. "+0.3" | +{amount} | 5 as shown with e.g. "+0.3"; 8 at most for "+{amount}" with a value up to "+10.5" |

Notes: names are plain and recognisable as the tricks (the board prefers simple labels) and written in capitals with an exclamation mark for the comic look. Nothing contains "XP" or "experience". The multiplier multiplies likes in the game, so the counter says only "Combo".

### QA round 1

Lengths counted by QA, as the player sees them (placeholders at their largest realistic value).

- Criterion 1, all five keys present in the result notes: pass.
- Criterion 2, lengths within limits: pass. "LONG DRIFT!" 11, "FULL 360!" 9, "ALT DRIFT!" 10 (limit 16 each). "Combo x12.5" 11 (limit 15). "+10.5" 5 (limit 8). Minor note: "+0.3" is 4 characters, not 5 as the table says; this does not affect the limit.
- Criterion 3, no "XP" or "experience": pass.

Only this task file changed versus master. The board's voice review is left to the board.
