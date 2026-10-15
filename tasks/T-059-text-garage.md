---
id: T-059
title: Text: the garage screen
status: in-qa
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

Written by the narrative-theme agent. All lengths within limits; no XP or experience. Matches game/data/garage.json: 10 levels each; acceleration time to top speed 2.3 s down 0.1 s per level; car health 100 up 10 per level; damage bonus +5% per level. {n} is where the number goes (lengths count the placeholder as written).

| Key | Where it appears | Text | Length |
|---|---|---|---|
| garage.title | Heading of the garage screen | Redgull Pit Stop | 16/30 |
| garage.acceleration.name | Upgrade name | Sponsored Throttle | 18/25 |
| garage.acceleration.desc | Upgrade description | Top speed 0.1 s sooner per level. More drifting, more content. | 62/80 |
| garage.car_health.name | Upgrade name | Reinforced Chassis | 18/25 |
| garage.car_health.desc | Upgrade description | +10 car health per level. Redgull says you'll be fine. | 54/80 |
| garage.damage_bonus.name | Upgrade name | Brand Impact | 12/25 |
| garage.damage_bonus.desc | Upgrade description | +5% weapon damage per level. Redgull calls it synergy. | 54/80 |
| garage.level | Each upgrade row; {n} is the current level | Level {n} | 9/25 |
| garage.price | Each upgrade row; {n} is the price of the next level | Price: {n} | 10/25 |
| garage.coins | Player's coins; {n} is the coin total | Coins: {n} | 10/25 |
| garage.buy | Buy button on each upgrade | Buy | 3/25 |
| garage.maxed | Shown instead of the price/buy at the last level | Fully Funded | 12/25 |
| garage.too_poor | Shown when the player can't afford the next level | Not enough coins | 16/25 |
| garage.back | Button back to the main menu | Back | 4/25 |

