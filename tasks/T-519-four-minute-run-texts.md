---
id: T-519
title: Texts for the 4-minute run: merged weapon cards, 2-tier power-ups, the heal
status: open
from: project-lead
to: narrative-theme
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [docs/weapons.md, docs/drifting.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, tasks/README.md]
files_expected_to_change: [game/data/, game/tools/text_inventory.py, game/tests/, docs/hud-and-menus.md]
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

Write the player-facing text the 4-minute run needs, through the style loop, into the game's text files where the level-up cards, power-up cards and HUD texts already live, and list them in docs/hud-and-menus.md Content. (1) Every weapon's level-up cards for the new tiers 2 to 5 (docs/weapons.md, Decisions, "Shorter trees: 5 tiers"): the board's titles where a tier keeps one upgrade; for merged tiers combine the board's titles or write one in the same voice; the card text gives the merged numbers exactly. A new weapon's own card now gives it at tier 2: its text says what the player gets. (2) The driving power-ups' card texts for 2 tiers (docs/drifting.md, Decisions, "Two tiers and three slots"): tier 2 is today's tier 4. (3) The message when a full sub goal heals the car because all 3 weapons are maxed (where it shows: a popup like the reward popup; short). (4) Any text that names 8 minutes, 7 minutes or the kaiju's arrival time (tutorial slides, time's up, recap, mission text): grep and update to the 4-minute run. List every key, new or changed, in the result notes for T-520, T-521 and T-523.

The board, 2026-11-03: the run is shortened to 4 minutes (3:00 build, kaiju 3:00 to 4:00). Decisions: docs/game-loop-architecture.md "A 4-minute run: 3 minutes to build, 1 minute of kaiju"; docs/weapons.md "Shorter trees: 5 tiers"; docs/drifting.md "Two tiers and three slots for the driving power-ups"; docs/enemies.md "Paced for the 4-minute run"; docs/hud-and-menus.md "Weapon and power-up slots". T-519 to T-523 are built in parallel and combined by the Project Lead into one build (T-521's folder) that the board plays before anything merges. Many existing tests assume the 8-minute run, the kaiju at 7:00 and 8 tiers: update the ones your change breaks (say which in the result notes), never delete a test's purpose. Numbers you choose are proposals for the playtest, in game/data with a _comment. Never write, move or commit anything in game/data/levels/. SFX stay off. Stage files by name, never .uid/.import noise. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play the one combined build (T-519 to T-523) from C:\solid-carbide-worktrees\T-521\game\project.godot before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every weapon has card text for tiers 2 to 5 matching docs/weapons.md's merged numbers exactly, and every power-up has card text for tiers 1 and 2 (a test reads the text files against weapons.json/power_ups.json shapes or against a list in the test). (QA: pass / fail)
- [ ] The heal message exists with its key. (QA: pass / fail)
- [ ] No player-facing text in game/data/*.json still says 8 minutes, 7 minutes or 7:00 for the run (grep in the result notes). (QA: pass / fail)
- [ ] Each new or rewritten line scored 8 or more in the style loop (Style review section). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content lists the texts; the result notes list every key. (QA: pass / fail)
- [ ] The text inventory and the tests that read these files pass (the agent runs the ones it touched). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
