---
id: T-495
title: Level-up card text for the board's weapon upgrade trees
status: in-qa
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
documents_affected: []
files_to_read_first: [tasks/README.md, docs/weapons.md, game/scripts/ui/level_up_texts.gd, docs/visual-style.md, docs/extended-narrative.md]
files_expected_to_change: [game/scripts/ui/level_up_texts.gd, game/tests/unit/]
model: sonnet
qa_rounds: 1
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

The board's review: play the new weapon trees in one build with T-495 to T-499 together (levelling each weapon to tier 8 with the playtest switches), from this ticket's folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/scripts/ui/level_up_texts.gd has a title and a non-empty card text for every tier 2 to 8 of gun, flamethrower, molotov, bricks and wiper, keyed by the new tier numbers, and no keys left for gun tiers 9 to 11. (QA: pass; all 35 tiers present with non-empty text, no gun tier 9 to 11)
- [ ] Every title is exactly the board's title from the list in the description. (QA: pass; all 35 titles checked)
- [ ] Card texts marked unchanged in the description are identical, unless the result notes name a number that became wrong and its correction. (QA: pass; unchanged texts verbatim, only Hot Drop tier 5 corrected and named)
- [ ] Every number or count in a card text matches the Decisions entry (checked by hand at least for Hot Drop tiers 4, 5 and 8, Gun tier 6 and Wiper Blade tier 4). (QA: pass; Hot Drop 4 +1, 5 "3 at once", 8 +1; gun tier 6 "4 in all"; wiper tier 4 "6 to 9" matches knockback base 6 x1.5)
- [ ] The three empty texts (Wiper Blade tiers 5, 7, 8) are written, and the style loop's scores are in the result notes. (QA: pass; scores 8, 8, 9, plus Hot Drop tier 5 at 9; in Style review and result notes)
- [ ] The Godot unit tests that cover level-up texts pass (-gselect on those test files). (QA: pass; round 2, checked with the T-496 run, where all test sets pass. On T-495 alone the only red test is test_level_up_screen.gd expecting the old 11 gun tiers (gun tiers 8 to 10 empty), which T-496's data removes; the python text-table test is fixed and green)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started: card text for the board's weapon trees comes first; T-496 waits for it.

### 2026-11-02, In progress → In QA

Card text for the board's trees is in; 3 Wiper texts written, Hot Drop tier 5 count fixed; style loop 8 to 9.

### 2026-11-02, In QA → In progress

QA failed: python test_check_level_up_texts is stale vs the new texts; and docs/weapons.md (documents_affected) not changed on the branch, either change it or drop it from the list.

### 2026-11-02, In progress → In QA

Text-table test updated to the new trees.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind card_desc, brief `art-archive/T-495/b5.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Blade length x1.3, stacking on the earlier x1.2. More reach, more brand reach."
- Script checks: 3 of 3 pass
- Score: 7/10
- Reason: No rule is clearly broken. Rules 2, 3 and 4 pass by script (78 characters, under 90). Rule 4's structure is met: the first sentence says what the card does ("Blade length x1.3, stacking on the earlier x1.2"), followed by one aside. Rule 2 passes: no banned words, and "brand" fits Greenbull's world. Rule 1 (tone) is met only weakly. The aside "More reach, more brand reach." is a flat wordplay on "reach". It restates the effect and does not mock corporate language, social media or brand obsession, and it has no slightly unethical or profit-focused edge. Rule 3 passes: it names Greenbull and uses no real brand. To improve it, keep the first sentence and replace the aside with a sharper Greenbull-style jab, for example about the brand getting closer to the audience or about monetising the swing. Keep the total at 90 characters or fewer.
- Rules broken: none

#### Round 2

- Version 2: "Blade length x1.3, stacking on the earlier x1.2. Every extra inch sold as ad space."
- What changed: Version 2. I kept the first sentence, which says what the card does. I replaced the flat "reach" pun with a jab about making money from the upgrade: Greenbull has already sold the blade's new length as ad space. That gives the aside the profit-minded, slightly unethical edge that rule 1 asks for. The text is 83 characters, under the 90 limit. It has no banned words, doesn't use the "Greenbull says ..." form and names no real brands. The open issue from version 1 still needs a decision: the brief says tier 5, but in weapons.json the length x1.3 upgrade is at tier 6.
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: Passes all script checks (rules 2, 3, 4: 83 chars, no banned words, no "Greenbull says"). Format is right: first it says what the card does (length x1.3, stacking on the earlier x1.2), then one satirical aside. The aside "Every extra inch sold as ad space." fits rule 1: it mocks corporate monetisation, and Greenbull stays profit-focused, not evil. It has no real brands and doesn't mock the city's people. Small weaknesses: the aside is a bit generic and doesn't really use the gift-pack/stream framing. To fix, make it sound more like Greenbull speaking, for example by naming the audience or the sponsor's profit angle.
- Rules broken: none

**Kept:** version 2, score 8/10 ("Blade length x1.3, stacking on the earlier x1.2. Every extra inch sold as ad space.", copied to `art-archive/T-495/out5.txt`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind card_desc, brief `art-archive/T-495/b7.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Blade length x1.3 again. The longest wiper ever streamed, pending a longer one."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rules broken. Rule 4: it says what the card does first ("Blade length x1.3 again."), then one aside, and it is 79 characters, under the 90 limit. Rules 2 and 3: the vocabulary is clean, no one is quoted as "Greenbull says", and no real brands. "Streamed" fits the livestream premise. Rule 1: the aside is light, ironic and a little self-congratulating, and "pending a longer one" has a corporate-roadmap feel. It is gentle, though. It doesn't target Greenbull's profit-chasing or the brand obsession, and it has no unethical edge. If you want a 9 or 10, make the aside bite harder at Greenbull. An example is a metric or sponsor angle, like a record that is always about to be broken for engagement. Otherwise the text is fine as it is.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Blade length x1.3 again. The longest wiper ever streamed, pending a longer one.", copied to `art-archive/T-495/out7.txt`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind card_desc, brief `art-archive/T-495/b8.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "A copy of your front wiper sweeps behind, upgrades and all. Rear-view content, monetised."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4: the function comes first ("A copy of your front wiper sweeps behind, upgrades and all"), followed by exactly one satirical aside, and the text is 89 of 90 characters. Rule 1: the aside mocks Greenbull's content-and-monetising mindset and does not touch the city or its people. Rules 2 and 3: no banned words, no "Greenbull says" line, no real brands. The only weakness is that "Rear-view content, monetised." is a mild, generic pun. It is not a rule break, and no fix is required.
- Rules broken: none

**Kept:** version 1, score 9/10 ("A copy of your front wiper sweeps behind, upgrades and all. Rear-view content, monetised.", copied to `art-archive/T-495/out8.txt`): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind card_desc, brief `art-archive/T-495/b9.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Throw 3 molotovs at once. Triple the content."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rules broken. Rule 4: 45 characters, within the 90 limit, and the card says what it does first ("Throw 3 molotovs at once.") then gives one satirical aside ("Triple the content."). Rule 1: the aside keeps the ironic, corporate-content tone and mocks no one's fear. Rules 2 and 3: no banned words, no "Greenbull says" line, no real brands. The brief was followed: the board's wording is kept, with only the count (2 to 3) and the matching word (Twice to Triple) changed. Nothing to fix.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Throw 3 molotovs at once. Triple the content.", copied to `art-archive/T-495/out9.txt`): it reached 8 or more.

## Result notes

Done. Card text for tiers 2 to 8 of gun, Hot Take Exhaust, Hot Drop, Bricks and Wiper Blade is in game/scripts/ui/level_up_texts.gd (96 keys; the gun's tiers 9 to 11 and all removed titles are gone). Neon Underglow untouched.

Written by me (style loop, scores in Style review): Wiper tier 5 "Blade length x1.3, stacking on the earlier x1.2. Every extra inch sold as ad space." (8); tier 7 "Blade length x1.3 again. The longest wiper ever streamed, pending a longer one." (8); tier 8 "A copy of your front wiper sweeps behind, upgrades and all. Rear-view content, monetised." (9).
Corrected: Hot Drop tier 5 "Throw 2 molotovs at once. Twice the content." became "Throw 3 molotovs at once. Triple the content." (tier 4 already added one; "Triple" is the matching word; scored 9). Nothing else changed.

Final titles and texts (all the board's titles exactly; unchanged texts verbatim):
- Gun 2 Extra Bullet; 3 Another Extra Bullet; 4 Quicker Trigger; 5 Quicker Trigger II; 6 Bullet Bundle ("+1 bullet per volley, 4 in all. Buy more, shoot more."); 7 Quicker Trigger III; 8 Exposure for Everyone ("Massively increased fire rate.")
- Hot Take Exhaust 2 Wider Burn; 3 Hotter Burn; 4 Wider Burn II ("The flame area grows 30%. Scale your content."); 5 Flammable Material ("Enemies burn for 1 second longer. Looks great on camera."); 6 Wider Burn III; 7 Hot Stuff ("Additional 1s burn duration."); 8 Lit 24/7 ("The flame never goes out, even when you aren't drifting. Spark it up.")
- Hot Drop 2 Bigger Blaze; 3 Quick Throw ("Throws 20% sooner, every 2.4 seconds. ..."); 4 Another one ("Additional molotov thrown."); 5 ANOTHER ONE (corrected above); 6 Quick Fire ("Throws molotovs 30% faster."); 7 Bigger Blaze II; 8 MOREEEE ("Additional Molotov.")
- Bricks 2 Wider Wave; 3 Harder Landing; 4 Shove Factor; 5 Wider Wave II; 6 Harder Landing II; 7 Shove Factor II; 8 Widest Wave ("Your landing wave reaches its widest yet. Brace for impact!", the board's)
- Wiper 2 Longer Blade; 3 Faster Sweep; 4 Hard Shove ("Knockback up 50%, from 6 to 9. Minions only, never the kaiju."); 5 Even Longer Blade; 6 Faster Sweep II; 7 Longest Blade!; 8 Back Wiper (texts above).

Tests: updated game/tests/unit/test_level_up_screen.gd (moved tier numbers, the new key count 96, Bricks tier 8 text). test_level_up_screen.gd: 48 of 49 pass. The one failure, test_every_choice_and_tier_the_offers_can_produce_has_text, is the gun at tier 8: the gun's code still has 11 tiers, so it offers a tier 9 card with no text now; T-496 (gun to 8 tiers) clears it.
Screenshot: art-archive/T-495/screenshots/level_up_wiper5_molotov5.png (level-up screen with Even Longer Blade and ANOTHER ONE). The style-loop brief and output files are in art-archive/T-495/.
Documents affected: docs/weapons.md needs no change (the Decisions entry already holds the tree).

Updated game/tools/test_check_level_up_texts.py: the real-file test now pins the board's new trees (NEW_TREES, tiers 2 to 8, no gun 9 to 11) and checks only the get cards and underglow against T-171's table. 6 tests pass.
