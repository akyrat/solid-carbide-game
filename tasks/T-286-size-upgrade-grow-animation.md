---
id: T-286
title: "A weapon visibly grows, animated, when a size upgrade is picked"
status: in-progress
from: project-lead
to: weapon-behavior
lead: Coursework
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/README.md, game/data/weapons.json, game/scripts/weapons/, game/scripts/ui/level_up_screen.gd, tasks/T-266-wiper-stronger-knockback.md, tasks/T-267-smaller-exhaust-flame-hit-matches-art.md, tasks/T-274-underglow-drawn-in-code.md]
files_expected_to_change: [game/scripts/weapons/, game/tests/, docs/weapons.md, game/README.md, art-archive/T-286/screenshots/]
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

The board's playtest note on the game build (Weapons, Decisions, "Size upgrades grow on screen", 2026-10-24): "When something is upgraded for its size, like the wipers or the underglow or the flame, after I click it, I want to see the weapon enlarge, animated."

Today a size tier's new size just appears. When the board picks a level-up card or gift pack that raises a weapon's size, the weapon should visibly grow from its old size to its new one once the game resumes.

- **Which weapons:** every tier that raises a weapon's size in `weapons.json`: the wiper's sweep, the underglow's radius, the flamethrower's flame, and the molotov's fire area if it has size tiers. List which tiers count in the result notes.
- **The grow animation:** a short grow with a small overshoot that settles on the new size, like T-273's likes bar spring. The length and overshoot are your proposal, in one place, with reasons.
- **Damage:** the damage area follows the drawn size throughout, so nothing is hit outside what is drawn. Damage and timing are otherwise unchanged.
- **Other tiers:** a tier that doesn't change size plays no grow.

Built on the game build: the Project Lead makes your folder from `playtest/game-build`, so the board plays it there. End with a short GIF of each of these growing after its card is picked: the wiper, the underglow and the flame.

## Acceptance criteria

- [ ] Tests show that picking a size tier makes the weapon's drawn size go from the old to the new size over the proposed time, settling exactly on the data's new size, for each size-upgrading weapon; that a non-size tier plays no grow; and that it pauses while the game is paused (QA: pass / fail)
- [ ] Tests show the damage area matches the drawn size during the grow, and the weapons' existing damage and tier tests pass unchanged (QA: pass / fail)
- [ ] Weapons, Content, and `game/README.md` describe it with the numbers and reasons; the GIFs are in `art-archive/T-286/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: pick size upgrades for the wiper, underglow and flamethrower and watch each grow.
Board review files: the GIFs in `art-archive/T-286/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-24, Open → In progress

Started: weapons grow on screen, animated, when a size upgrade is picked; built on the game build.

## Result notes

Written by the agent when it finishes.
