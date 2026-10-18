---
id: T-171
title: Text: level-up cards for the neon underglow, the molotovs and the windshield wiper
status: in-progress
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

The level-up (gift pack) screen shows one card per choice, each with a title and a description (`game/scripts/ui/level_up_texts.gd`, from T-051). Three new weapons join the MVP (docs/weapons.md, Decisions, 2026-10-18): the neon underglow, the molotovs and the windshield wiper. Write the cards for each: `get_<weapon>` (getting it, tier 1) and `upgrade_<weapon>.tier2` to `tier8` (each upgrade), with weapon ids `underglow`, `molotov` and `wiper`: 24 title and description pairs. Each description must state what that tier really does, with the numbers from its weapons.json entry (D1), the way the gun's and the flamethrower's cards do. Keep the same length and tone as the existing cards (short title, one or two short sentences, the influencer and Redgull voice from the Extended narrative), no real brand names and nothing the Extended narrative forbids for Redgull. Write the final text as a table in your result notes, keyed exactly as `level_up_texts.gd` keys them; the UI task (D8) copies it word for word.

The board's review: Read the 24 card texts in the ticket's result notes; they show on the level-up cards in the goal's playtest.

## Acceptance criteria

- [ ] The result notes hold a table of 24 title and description pairs keyed `get_underglow`, `upgrade_underglow.tier2` to `tier8`, and the same for `molotov` and `wiper`, with no key missing or repeated. (QA: pass / fail)
- [ ] Each description states the change its tier makes as written in weapons.json (the same effect and number). (QA: pass / fail)
- [ ] Each title and description is no longer than the longest existing one in `level_up_texts.gd`, and none contains a real brand name or a word the Extended narrative rules out for Redgull. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Blocked → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-171.

## Result notes

Written by the agent when it finishes.
