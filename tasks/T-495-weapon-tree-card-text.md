---
id: T-495
title: Level-up card text for the board's weapon upgrade trees
status: open
from: project-lead
to: narrative-theme
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/scripts/ui/level_up_texts.gd, docs/visual-style.md, docs/extended-narrative.md]
files_expected_to_change: [game/scripts/ui/level_up_texts.gd, game/tests/unit/]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-11-02, redesigned the weapon upgrade trees (docs/weapons.md, Decisions, "The board's own upgrade trees"). This task produces the level-up card text for every tier of the gun, Hot Take Exhaust, Hot Drop, Bricks and Wiper Blade (Neon Underglow is unchanged), and writes it where the game reads it (game/scripts/ui/level_up_texts.gd, keys upgrade_<weapon>.tier<N>.title/.desc, with the new tier numbers). T-496, T-498 and T-499 depend on it.

Rules (board): the board's titles stay exactly as written. Write the three empty card texts (Wiper Blade tiers 5, 7 and 8). Correct only what would be wrong in the game: numbers and counts (for example Hot Drop tier 5 says "Throw 2 molotovs at once" but tier 4 already added one, so it is 3 at once; check every "N in all" and "from X to Y" against the new order and the numbers in the Decisions entry); the tiers that moved keep their text but it must still be true at their new place. Leave the board's other wording alone; texts marked unchanged stay as they are unless a number became wrong. New texts follow the existing cards' voice (Visual style and Extended narrative; the level-up card text section of docs/weapons.md). Card texts whose tier no longer exists (gun Multi-Target Mode, Bulk Bullets, Quicker Trigger IV, Everyone Gets Exposure; flamethrower Afterglow and Sharper Drifting; molotov Spicier Fire, Double Drop, Slow Burn, Triple Drop; wiper Heavy Duty, Heavy Duty II, Longer Blade II) are removed from the file, not left behind under a wrong tier number.

The board's tree, tier by tier (tier 1 is getting the weapon; its get-it card text is unchanged):
Gun tier 2: title "Extra Bullet"; card text "+1 bullet per volley, 2 in all. A free sample, courtesy of Greenbull." (unchanged text)
Gun tier 3: title "Another Extra Bullet"; card text "+1 bullet per volley, 3 in all. Greenbull feels generous on camera." (unchanged text)
Gun tier 4: title "Quicker Trigger"; card text "Fires 20% faster. The audience is getting restless." (unchanged text)
Gun tier 5: title "Quicker Trigger II"; card text "Fires 20% faster again. Engagement waits for no one." (unchanged text)
Gun tier 6: title "Bullet Bundle"; card text "+1 bullet per volley, 4 in all. Buy more, shoot more." (unchanged text, new tier number)
Gun tier 7: title "Quicker Trigger III"; card text "Fires 20% faster. Content never sleeps." (unchanged text, new tier number)
Gun tier 8: title "Exposure for Everyone"; card text "Massively increased fire rate." (the board's)
Hot Take Exhaust tier 2: title "Wider Burn"; card text "The flame area grows 20%. More reach, more views." (unchanged text)
Hot Take Exhaust tier 3: title "Hotter Burn"; card text "Flame damage up 20%. Greenbull's hottest take yet, pending legal review." (unchanged text)
Hot Take Exhaust tier 4: title "Wider Burn II"; card text "The flame area grows 30%. Scale your content." (the board's)
Hot Take Exhaust tier 5: title "Flammable Material"; card text "Enemies burn for 1 second longer. Looks great on camera." (the board's)
Hot Take Exhaust tier 6: title "Wider Burn III"; card text "The flame area grows 30%. Go big or go viral." (unchanged text)
Hot Take Exhaust tier 7: title "Hot Stuff"; card text "Additional 1s burn duration." (the board's)
Hot Take Exhaust tier 8: title "Lit 24/7"; card text "The flame never goes out, even when you aren't drifting. Spark it up." (the board's)
Hot Drop tier 2: title "Bigger Blaze"; card text "Fire radius up 20%. Greenbull loves a big reveal." (unchanged text)
Hot Drop tier 3: title "Quick Throw"; card text "Throws 20% sooner, every 2.4 seconds. Content never sleeps." (unchanged text)
Hot Drop tier 4: title "Another one"; card text "Additional molotov thrown." (the board's)
Hot Drop tier 5: title "ANOTHER ONE"; card text "Throw 2 molotovs at once. Twice the content." (the board's)
Hot Drop tier 6: title "Quick Fire"; card text "Throws molotovs 30% faster." (the board's)
Hot Drop tier 7: title "Bigger Blaze II"; card text "Fire radius up another 30%. Think bigger." (unchanged text)
Hot Drop tier 8: title "MOREEEE"; card text "Additional Molotov." (the board's)
Bricks tier 2: title "Wider Wave"; card text "Each landing's impact wave reaches further. Greenbull calls it ground-breaking content." (unchanged text)
Bricks tier 3: title "Harder Landing"; card text "Your landing wave hits harder. Greenbull calls it a high-impact brand activation." (unchanged text)
Bricks tier 4: title "Shove Factor"; card text "Impact waves knock minions back harder. Never the kaiju; it doesn't take feedback." (unchanged text)
Bricks tier 5: title "Wider Wave II"; card text "Each landing's wave spreads wider again. Greenbull calls it expanding the brand footprint." (unchanged text)
Bricks tier 6: title "Harder Landing II"; card text "Your landing wave hits harder again. Greenbull is trademarking the thud." (unchanged text)
Bricks tier 7: title "Shove Factor II"; card text "Landing waves shove minions even further, never the kaiju. Greenbull calls it outreach." (unchanged text)
Bricks tier 8: title "Widest Wave"; card text "Your landing wave reaches its widest yet. Brace for impact!" (the board's)
Wiper Blade tier 2: title "Longer Blade"; card text "Wiper length up 20%. Clean up more of the city." (unchanged text)
Wiper Blade tier 3: title "Faster Sweep"; card text "Wiper sweeps 25% faster. No streaks left behind." (unchanged text, new tier number)
Wiper Blade tier 4: title "Hard Shove"; card text "Knockback up 50%, from 6 to 9. Minions only, never the kaiju." (unchanged text, new tier number)
Wiper Blade tier 5: title "Even Longer Blade"; card text "" (the board's)
Wiper Blade tier 6: title "Faster Sweep II"; card text "Wiper sweeps another 30% faster. Always in frame." (unchanged text, new tier number)
Wiper Blade tier 7: title "Longest Blade!"; card text "" (the board's)
Wiper Blade tier 8: title "Back Wiper"; card text "" (the board's)

Run the style loop on the texts you write or change. List every final title and card text, tier by tier, in the result notes. Never write, move or commit anything in game/data/levels/. SFX stay off.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/scripts/ui/level_up_texts.gd has a title and a non-empty card text for every tier 2 to 8 of gun, flamethrower, molotov, bricks and wiper, keyed by the new tier numbers, and no keys left for gun tiers 9 to 11. (QA: pass / fail)
- [ ] Every title is exactly the board's title from the list in the description. (QA: pass / fail)
- [ ] Card texts marked unchanged in the description are identical, unless the result notes name a number that became wrong and its correction. (QA: pass / fail)
- [ ] Every number or count in a card text matches the Decisions entry (checked by hand at least for Hot Drop tiers 4, 5 and 8, Gun tier 6 and Wiper Blade tier 4). (QA: pass / fail)
- [ ] The three empty texts (Wiper Blade tiers 5, 7, 8) are written, and the style loop's scores are in the result notes. (QA: pass / fail)
- [ ] The Godot unit tests that cover level-up texts pass (-gselect on those test files). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
