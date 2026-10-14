---
id: T-051
title: Text: the level-up (gift pack) screen
status: needs-playtest
from: project-lead
to: narrative-theme
lead: Weapons
epic: narrative
milestone: mvp
user_facing_text: yes
changes_visuals: no
depends_on: [T-040, T-043]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, .claude/agents/narrative-theme.md, docs/weapons.md, tasks/T-040-weapon-data.md, tasks/T-043-level-up-weapon-choices.md, tasks/T-052-level-up-screen.md]
files_expected_to_change: [tasks/T-051-text-level-up-screen.md (result notes only)]
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

**Blocked until T-040 (what each upgrade tier changes) and T-043 (the choice ids) are done,** so the text describes what the weapons actually do.

Text for the level-up screen (HUD and menus, Decisions), where Redgull's gift pack offers 2 choices (Weapons, Decisions):
- **levelup.title:** the screen's heading. Up to 30 characters.
- For every choice id in T-043, a **title** (up to 30 characters) and a **description** (up to 90 characters). The weapons need names (Extended narrative, Decisions: this agent writes them): the starting gun and the exhaust flamethrower. Each upgrade tier's description says what that tier changes, from T-040's data.
- **levelup.take:** the label of the button that takes a choice. Up to 15 characters.


Write the final text in this task's result notes, as a table: key, where it appears, the text, and its length in characters. The building task uses exactly this text (`tasks/README.md`, "User-facing text and visuals"). Write in Extended narrative's voice: satirical, Redgull out of touch, the player's fun slightly unethical. Players see "likes", never "XP". Don't describe anything the game doesn't do.

## Acceptance criteria

- [x] The result notes have levelup.title, levelup.take, and a title and description for every choice id in T-043 (QA: pass)
- [x] Each upgrade description matches what that tier changes in T-040's data (QA: pass)
- [x] Every text in the table fits the length limit given for it (QA: pass)
- [x] No text contains "XP" or "experience" (QA: pass)

The board's review: read the text and judge whether it has the right voice.

## Result notes

Written by the narrative-theme agent. All lengths are within limits; no text says XP or experience. Each description matches T-040's tier data (weapons.json). The two `weapon.*.name` rows give the weapons' names (extra rows, not on a card; `get_flamethrower.title` is the flamethrower's name). Tier 2 gives 3 bullets in all, tier 6 gives 5; tier 5 range 12 to 18; tier 8 pierce 1 means the bullet hits a second enemy.

| Key | Where it appears | Text | Length |
|---|---|---|---|
| weapon.gun.name | Name of the starting gun (extra, not on a card) | Sponsor Special | 15/30 |
| weapon.flamethrower.name | Name of the flamethrower (extra, not on a card) | Hot Take Exhaust | 16/30 |
| levelup.title | Heading of the screen | Redgull Sent a Gift Pack! | 25/30 |
| levelup.take | Button on each card | Take it | 7/15 |
| get_flamethrower.title | Card title | Hot Take Exhaust | 16/30 |
| get_flamethrower.desc | Card description | Flames from your tailpipe while you drift. Great content. Mind the neighbours. | 78/90 |
| upgrade_gun.tier2.title | Card title | Bonus Bullets | 13/30 |
| upgrade_gun.tier2.desc | Card description | Two extra bullets per volley, 3 in all. Redgull calls it generosity. | 68/90 |
| upgrade_gun.tier3.title | Card title | Quicker Trigger | 15/30 |
| upgrade_gun.tier3.desc | Card description | Fires 20% faster. The audience is getting restless. | 51/90 |
| upgrade_gun.tier4.title | Card title | Quicker Trigger II | 18/30 |
| upgrade_gun.tier4.desc | Card description | Fires 20% faster again. Engagement waits for no one. | 52/90 |
| upgrade_gun.tier5.title | Card title | Long Reach | 10/30 |
| upgrade_gun.tier5.desc | Card description | Bullet range grows by half, from 12 to 18. Shoot from a safe distance. | 70/90 |
| upgrade_gun.tier6.title | Card title | More Bonus Bullets | 18/30 |
| upgrade_gun.tier6.desc | Card description | Two more bullets per volley, 5 in all. Redgull is feeling generous. | 67/90 |
| upgrade_gun.tier7.title | Card title | Quicker Trigger III | 19/30 |
| upgrade_gun.tier7.desc | Card description | Fires 20% faster once more. Content never sleeps. | 49/90 |
| upgrade_gun.tier8.title | Card title | Through and Through | 19/30 |
| upgrade_gun.tier8.desc | Card description | Bullets pass through the first enemy and hit a second. Twice the impact. | 72/90 |
| upgrade_flamethrower.tier2.title | Card title | Wider Burn | 10/30 |
| upgrade_flamethrower.tier2.desc | Card description | The flame area grows 20%. More reach, more views. | 49/90 |
| upgrade_flamethrower.tier3.title | Card title | Hotter Burn | 11/30 |
| upgrade_flamethrower.tier3.desc | Card description | Flame damage up 20%. Redgull calls it a spicy take. | 51/90 |
| upgrade_flamethrower.tier4.title | Card title | Wider Burn II | 13/30 |
| upgrade_flamethrower.tier4.desc | Card description | The flame area grows another 20%. Scale your content. | 53/90 |
| upgrade_flamethrower.tier5.title | Card title | Afterglow | 9/30 |
| upgrade_flamethrower.tier5.desc | Card description | Burning enemies glow orange 0.5 seconds longer. Looks great on camera. | 70/90 |
| upgrade_flamethrower.tier6.title | Card title | Wider Burn III | 14/30 |
| upgrade_flamethrower.tier6.desc | Card description | The flame area grows 30%. Redgull says think bigger. | 52/90 |
| upgrade_flamethrower.tier7.title | Card title | Sharper Drifting | 16/30 |
| upgrade_flamethrower.tier7.desc | Card description | The car steers 20% faster. Easier to keep the flames on. | 56/90 |
| upgrade_flamethrower.tier8.title | Card title | Always Lit | 10/30 |
| upgrade_flamethrower.tier8.desc | Card description | The flame never goes out, even when you aren't drifting. Pure brand energy. | 75/90 |

### QA round 1 (QA/Integration Agent, 2026-10-15)

All four criteria pass. Text only; no code changed, so no tests to run.

- **Coverage: pass.** The choice ids in `game/scripts/weapons/level_up_offers.gd` and game/README.md "The level-up offers" are `upgrade_gun`, `get_flamethrower`, `upgrade_flamethrower`. The table has levelup.title, levelup.take, `get_flamethrower` (tier 1) and a title and description for every upgrade tier the offers can apply: gun tiers 2 to 8 (the gun starts at tier 1) and flamethrower tiers 2 to 8 (getting it is tier 1). 34 rows in all.
- **Matches the data: pass**, checked against `game/data/weapons.json` and `WeaponData.gun_at()`/`flame_at()`:
  - Gun tiers 2 and 6: +2 bullets each, 1 to 3 to 5. Exact.
  - Gun tier 5: range x1.5, 12 to 18. Exact.
  - Gun tier 8: pierce 1, a bullet is done after its second hit. Exact.
  - Gun tiers 3, 4, 7 "20% faster": the data's `fire_rate_multiplier` is 1.2, but the interval is `1.2 / rate + 0.06`, so the fixed 0.06 s keeps the real gain a little under 20%: interval 1.26 to 1.06 to 0.893 to 0.754 s, so volleys per second rise 18.9%, 18.7% and 18.4%. Within about 1.5 points of 20%; fair for a card.
  - Flame tier 3: damage x1.2 (2 to 2.4). Exact. Tier 5: burn flash +0.5 s (0.38 to 0.88 s), flash tint is orange. Matches. Tier 7: steering x1.2. Exact. Tier 8: always on. Exact.
  - Flame tiers 2, 4, 6 "flame area grows 20% / another 20% / 30%": the multiplier scales the rectangle's width and depth, which is what docs/weapons.md calls "the area bigger (x1.2, x1.2, x1.3)". Read literally as surface, it grows more (x1.44 and x1.69). Passed because it matches the documents' own wording; if the board wants it exact, "The flames grow 20% bigger" would be.
- **Lengths: pass.** Counted every text with a script: all within limits (titles max 19/30, descriptions max 78/90, levelup.take 7/15) and every length column is correct.
- **No "XP" or "experience": pass.** Case-insensitive search of every text, no hits.
