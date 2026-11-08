---
id: T-591
title: Texts: needle routes in the level creator
status: done
from: project-lead
to: narrative-theme
lead: Rails
epic: level-creator
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/data/level/creator_texts.json]
files_expected_to_change: [game/data/level/creator_texts.json, docs/level-design.md]
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

Write the level creator texts for Level design, Decisions, "Needle routes", in the voice and length of the creator's other texts (the pair tool's texts in level-design.md Content, "Pair tool", and the creator's texts file): the route tool's button and its key in the controls hint (pick a free key and say which; check the creator's existing keys in level-design.md Content), the hint while it is on (click pair lines in order), the top bar message when a pair joins a route and when the route is finished, the order switch's two choices (in order, random), a short label naming a route and its pair count, and the button to remove a pair from its route. These are a dev tool's texts for the board, so plain and short; through the style loop only if the creator's other texts were. List each with its key and where it shows in the result notes for T-592, and in level-design.md Content.

The board's review: in T-592's build.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every text listed in the description exists in the creator's texts file with a key, listed in the result notes with where it shows. (QA: pass)
- [ ] level-design.md Content lists them. (QA: pass)
- [ ] The chosen key is not used by the creator already (checked against the listed controls). (QA: pass)
- [ ] QA's full run passes, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: the needle route texts.

### 2026-11-08, In progress → In QA

Texts written (route tool on N). QA now; you'll see them in T-592's build.

### 2026-11-08, In QA → Needs playtest

QA passed 4/4. You'll see the texts in T-592's needle routes build.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Needle route texts added to game/data/level/creator_texts.json (all new keys, none changed), listed in docs/level-design.md Content (before 'Level creator: thread the needle'). Hotkey chosen: N (free; creator uses R V M H A B P T [ ] Del Esc arrows). Texts: route_tool 'Route' (top bar/Obstacles panel button, key N); route_hint 'Route: click pair lines in order' (top bar, tool on); route_pair_added 'Pair added to the route (%d).' (top bar, pair joins); route_finished 'Route finished.' (top bar); route_order_in_order 'In order' and route_order_random 'Random' (order switch); route_label 'Route: %d pairs' (beside route's pairs); route_remove_pair 'Remove from route' (top bar button); controls_hint_routes (spawn hint plus 'N: route.'; replaces controls_hint_spawn). Not run through the style loop (creator texts weren't). Tests: GUT test_creator_texts_only 4/4, test_creator_props 16/16, test_creator_street_pieces 18/18; full Godot run 3134 tests, 3133 pass, 0 fail, 1 risky/pending, in 4m15s.

Project Lead, 2026-11-08: qa_check passes tests and documents; no screenshot here because the texts first show in T-592's build (its screenshots cover them).
- 2026-11-08, needs-playtest → done: Board: played T-592's build (which holds T-581 and T-591), lgtm (2026-11-08)
