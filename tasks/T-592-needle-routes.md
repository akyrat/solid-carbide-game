---
id: T-592
title: Needle routes: thread-the-needle pairs played in order or at random
status: open
from: project-lead
to: level-challenge
lead: Rails
epic: level-creator
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, tasks/T-581-creator-free-placement.md, game/scenes/level_creator/, game/scripts/level_creator/, game/scripts/run/]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/run/, game/scripts/level/, game/data/, game/tests/, game/docs/level/, docs/level-design.md, game/tools/check_level.py]
model: opus
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

Build Level design, Decisions, "Needle routes". This branch starts from T-581's (free placement and moving pieces) with T-591's texts merged in; both wait for the board's playtest, so build on them (Project Lead, 2026-11-08: the texts are only seen in this build, so it doesn't wait for T-591 to be done). In the creator: a route tool (T-591's texts and key) where clicking pairs' dashed lines adds them to a route in click order; each route has an order switch (in order, cycling; or random) and a way to take a pair out; routes save in the level file (keep old levels loading; check_level.py accepts them). In a run: only each route's active pair pays thread the needle; it is drawn bright and the route's other pairs faint; threading it makes the next active (in order, wrapping; or a random other pair). Pairs in no route work as today, and so does the flash of T-451. Proposals with reasons in data: brightness levels; whether threading a waiting pair does anything (proposal: nothing). Never touch game/data/levels/: make your own test levels in game/tests/fixtures/.

The board's review: play it from C:\solid-carbide-worktrees\T-592: make a route in the level creator ("C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" --path C:\solid-carbide-worktrees\T-592\game res://scenes/level_creator/level_creator.tscn), test it, in order and random.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] In the creator, clicking pair lines with the route tool makes a route in click order, the order switch and taking a pair out work, and routes save and load (tests). (QA: pass / fail)
- [ ] Levels without routes load and play as before (the existing tests pass) and check_level.py accepts a level with routes. (QA: pass / fail)
- [ ] In a run, only the active pair pays; in order cycles back after the last; random never repeats the same pair twice in a row when the route has more than one (tests). (QA: pass / fail)
- [ ] Active pairs draw bright and waiting ones faint (a test or screenshot). (QA: pass / fail)
- [ ] docs/level-design.md Content and game/docs/level/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-592/screenshots/ show a route in the creator and its active and waiting pairs in a run. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
