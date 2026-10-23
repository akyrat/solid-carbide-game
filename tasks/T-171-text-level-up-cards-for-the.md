---
id: T-171
title: Text: level-up cards for the neon underglow, the molotovs and the windshield wiper
status: done
from: project-lead
to: narrative-theme
lead: Goal-G-002
epic: narrative
milestone: mvp
goal: G-002
user_facing_text: yes
changes_visuals: no
depends_on: [T-166]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/weapons.md, docs/hud-and-menus.md, game/data/weapons.json, game/scripts/ui/level_up_texts.gd]
files_expected_to_change: []
model: sonnet
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The level-up (gift pack) screen shows one card per choice, each with a title and a description (`game/scripts/ui/level_up_texts.gd`, from T-051). Three new weapons join the MVP (docs/weapons.md, Decisions, 2026-10-18): the neon underglow, the molotovs and the windshield wiper. Write the cards for each: `get_<weapon>` (getting it, tier 1) and `upgrade_<weapon>.tier2` to `tier8` (each upgrade), with weapon ids `underglow`, `molotov` and `wiper`: 24 title and description pairs. Each description must state what that tier really does, with the numbers from its weapons.json entry (D1), the way the gun's and the flamethrower's cards do. Keep the same length and tone as the existing cards (short title, one or two short sentences, the influencer and Redgull voice from the Extended narrative), no real brand names and nothing the Extended narrative forbids for Redgull. Write the final text as a table in your result notes, keyed exactly as `level_up_texts.gd` keys them; the UI task (D8) copies it word for word.

The board's review: Read the 24 card texts in the ticket's result notes; they show on the level-up cards in the goal's playtest.

## Acceptance criteria

- [ ] The result notes hold a table of 24 title and description pairs keyed `get_underglow`, `upgrade_underglow.tier2` to `tier8`, and the same for `molotov` and `wiper`, with no key missing or repeated. (QA: pass: 24 rows, keys complete and unique)
- [ ] Each description states the change its tier makes as written in weapons.json (the same effect and number). (QA: pass: all 24 match weapons.json, e.g. 0.75 and 0.67 intervals as 25% and 33% sooner, molotov 2.4 s / 3 dmg / 4.5 s, knockback 1.5 to 2.25)
- [ ] Each title and description is no longer than the longest existing one in `level_up_texts.gd`, and none contains a real brand name or a word the Extended narrative rules out for Redgull. (QA: pass: longest new description about 73 chars vs 78 existing, titles at most 16 vs 19; no real brands, nothing the narrative rules out)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Blocked → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-171.

### 2026-10-18, In progress → In QA

Goal runner (G-002): the agent is done; QA is checking it.

### 2026-10-18, In QA → Needs playtest

Goal runner (G-002): QA passed; merged into playtest/G-002.

## Result notes

24 cards written (narrative-theme), numbers from game/data/weapons.json (T-166). Titles are 16 characters or fewer and descriptions 78 or fewer, within the longest existing ones (16 and 78). No brand names. Keys follow `level_up_texts.gd`: add `.title` / `.desc` to each key. The UI task copies this word for word.

| Key | Title | Description |
|---|---|---|
| get_underglow | Neon Underglow | A neon ring burns enemies near your car, 1 damage a second. So aesthetic. |
| upgrade_underglow.tier2 | Brighter Glow | Glow radius up 20%. Redgull says be seen. |
| upgrade_underglow.tier3 | Hotter Glow | Glow damage up 50%, to 1.5. Looks expensive. |
| upgrade_underglow.tier4 | Faster Pulse | Glow hits come 25% sooner. Stay on the beat. |
| upgrade_underglow.tier5 | Wider Glow | Glow radius up another 25%. Own the whole block. |
| upgrade_underglow.tier6 | Hotter Glow II | Glow damage up another 50%, to 2.25. Peak aesthetic. |
| upgrade_underglow.tier7 | Faster Pulse II | Glow hits come 33% sooner. Never drop the beat. |
| upgrade_underglow.tier8 | Blinding Glow | Glow radius up 30%. Sunglasses recommended. |
| get_molotov | Hot Drop | Throws a molotov every 3 seconds. Fire lasts 3 seconds. Very shareable. |
| upgrade_molotov.tier2 | Bigger Blaze | Fire radius up 20%. Redgull loves a big reveal. |
| upgrade_molotov.tier3 | Quick Throw | Throws 20% sooner, every 2.4 seconds. Content never sleeps. |
| upgrade_molotov.tier4 | Spicier Fire | Molotov damage up 50%, to 3. Redgull calls it flavour. |
| upgrade_molotov.tier5 | Double Drop | Throw 2 molotovs at once. Twice the content. |
| upgrade_molotov.tier6 | Slow Burn | Fire lasts 1.5 seconds longer, 4.5 in all. Linger for likes. |
| upgrade_molotov.tier7 | Bigger Blaze II | Fire radius up another 30%. Think bigger. |
| upgrade_molotov.tier8 | Triple Drop | Throw 3 molotovs at once. Redgull sends its regards. |
| get_wiper | Wiper Blade | A giant wiper sweeps a half circle for 3 damage and shoves minions back. |
| upgrade_wiper.tier2 | Longer Blade | Wiper length up 20%. Clean up more of the city. |
| upgrade_wiper.tier3 | Heavy Duty | Wiper damage up 40%. Redgull calls it deep cleaning. |
| upgrade_wiper.tier4 | Faster Sweep | Wiper sweeps 25% faster. No streaks left behind. |
| upgrade_wiper.tier5 | Hard Shove | Knockback up 50%, from 6 to 9. Minions only, never the kaiju. |
| upgrade_wiper.tier6 | Longer Blade II | Wiper length up another 30%. A wider view for the viewers. |
| upgrade_wiper.tier7 | Heavy Duty II | Wiper damage up another 40%. Squeaky clean, as promised. |
| upgrade_wiper.tier8 | Faster Sweep II | Wiper sweeps another 30% faster. Always in frame. |

Notes: tier 4 and 7 of the underglow shorten the tick by 0.75 and 0.67, so the text says hits come 25% and 33% sooner. No files changed; no documents affected.
- 2026-10-18, in-qa → needs-playtest: QA passed every criterion (goal G-002).
- 2026-10-18, needs-playtest → done: Board's playtest of G-002 (2026-10-18): works great.
