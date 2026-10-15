---
id: T-059
title: Text: the garage screen
status: open
from: project-lead
to: narrative-theme
lead: Weapons
epic: narrative
milestone: mvp
user_facing_text: yes
changes_visuals: no
depends_on: [T-056]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, .claude/agents/narrative-theme.md, docs/garage-design.md, tasks/T-056-garage-data.md, tasks/T-058-garage-screen.md]
files_expected_to_change: [tasks/T-059-text-garage.md (result notes only)]
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

**Blocked until T-056 (what each upgrade does) is done.**

Text for the plain MVP garage screen (Garage design, Decisions). Redgull funds the car's upgrades (Extended narrative, Decisions):
- **garage.title:** the screen's heading. Up to 30 characters.
- For each upgrade (acceleration, car health, damage bonus): a **name** (up to 25 characters) and a **description** (up to 80 characters) of what it does.
- **garage.level** (with where the number goes), **garage.price** (with where the number goes), **garage.coins** (with where the number goes), **garage.buy**, **garage.maxed** (shown when an upgrade is at its last level), **garage.too_poor** (shown when the player can't afford it) and **garage.back**. Each up to 25 characters.


Write the final text in this task's result notes, as a table: key, where it appears, the text, and its length in characters. The building task uses exactly this text (`tasks/README.md`, "User-facing text and visuals"). Write in Extended narrative's voice: satirical, Redgull out of touch, the player's fun slightly unethical. Players see "likes", never "XP". Don't describe anything the game doesn't do.

## Acceptance criteria

- [ ] The result notes have garage.title, a name and description for each of the 3 upgrades, and garage.level, garage.price, garage.coins, garage.buy, garage.maxed, garage.too_poor and garage.back (QA: pass / fail)
- [ ] Every text in the table fits the length limit given for it (QA: pass / fail)
- [ ] No text contains "XP" or "experience" (QA: pass / fail)

The board's review: read the text and judge whether it has the right voice.

## Result notes

Written by the agent when it finishes.
