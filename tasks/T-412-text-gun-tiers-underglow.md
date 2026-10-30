---
id: T-412
title: Text: level-up cards for the gun's tiers 2 to 11 and the stronger neon underglow
status: open
from: project-lead
to: narrative-theme
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/extended-narrative.md, game/scripts/weapons/level_up_texts.gd, tasks/T-408-gun-one-shot-and-targets.md, tasks/T-409-underglow-two-ticks-and-push.md]
files_expected_to_change: [docs/weapons.md]
model: sonnet
qa_rounds: 0
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

The level-up cards show a title and a line per weapon tier (`game/scripts/weapons/level_up_texts.gd`, `upgrade_gun.tier2` to `tier8`, `get_underglow`, `upgrade_underglow.*`), so the board's weapon changes of 2026-10-30 (Weapons, Decisions, "The gun one-shots minions ..." and "The neon underglow kills a minion in 2 ticks ..."; T-408, T-409) need new text before the code. Write it in the same voice and length as today's lines, in Weapons, Content, under a new "Level-up card text (T-410)" heading, keyed as in `level_up_texts.gd`, where T-408 and T-409 copy it.

The numbers (the Project Lead's, for the playtest; the code follows them):
- **Gun, tiers 2 to 11 (titles and lines):** 2: +1 bullet (2 a volley); 3: +1 bullet (3); 4: fires 20% faster; 5: fires 20% faster again; 6: aims at up to 3 enemies at once; 7: +1 bullet (4); 8: +1 bullet (5); 9: fires 20% faster; 10: fires 20% faster again; 11 (the last): aims at up to 5 enemies at once. Replace today's tier 2 to 8 lines.
- **Neon underglow:** `get_underglow` now says 2 damage a second (was 1) and that it pushes enemies back a little; `upgrade_underglow.tier3` damage to 3 (was 1.5) and `tier6` to 4.5 (was 2.25). The other underglow lines keep their wording unless a number in them changes.

Run each line through the style loop (pass each title and line alone).

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Weapons, Content, "Level-up card text (T-410)" lists titles and lines for the gun's tiers 2 to 11 and the changed underglow lines, keyed as in level_up_texts.gd, with the numbers in the description. (QA: pass / fail)
- [ ] Each went through the style loop, with its score in the Style review. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
