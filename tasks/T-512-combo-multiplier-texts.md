---
id: T-512
title: Texts for the combo multiplier beside the car
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
files_to_read_first: [docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/extended-narrative.md, tasks/README.md]
files_expected_to_change: [game/data/, docs/hud-and-menus.md]
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

Write the player-facing text the switch back to the combo multiplier needs, through the style loop, into the game's text files (where the HUD, recap and tutorial texts already live), and list them in docs/hud-and-menus.md Content. Pieces: (1) the multiplier beside the car, its format (for example "x2.50"; any label word is your call, short); (2) a trick popup's amount: the multiplier it added (for example "+x0.5"), replacing the viewers amount; (3) a crash's loss on the multiplier, if it shows one (replacing "-{viewers}"); (4) the recap's peak line, now the peak multiplier (replacing "Peak engagement" with viewers); (5) the tutorial slides that say "live viewers" (slide1.controls, slide2.chain, slide2.step2_title, slide2.step2_caption, slide2.step3_caption and any other): rewrite them for tricks raise the multiplier, tricks and drifting bring subs, subs fill the sub goal; (6) anything else in the game's text files that names viewers or WATCHING (grep for it), each replaced or marked unused. Keep the keys the code reads; add new keys where needed and list them in the result notes for the UI Agent (T-514).

The board, 2026-11-02: the live viewers are confusing; back to the combo multiplier number, shown beside the car; tricks also pay subs. Decisions: docs/game-loop-architecture.md, "Back to the combo multiplier; tricks pay subs", and docs/hud-and-menus.md, "The multiplier beside the car". The board plays T-512..T-514 together in one playtest build before anything merges. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every text listed in the description exists in the game's text files with its key, and docs/hud-and-menus.md Content lists each with where it appears. (QA: pass / fail)
- [ ] Each new or rewritten line scored 8 or more in the style loop (the Style review section shows the scores). (QA: pass / fail)
- [ ] No text in game/data/*.json that the player sees still says viewers or WATCHING, except keys the result notes mark as unused after T-514. (QA: pass / fail)
- [ ] The result notes list every key, new or changed, for T-514. (QA: pass / fail)
- [ ] The Godot tests that read these text files pass (the agent runs the ones it touched). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
