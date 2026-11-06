---
id: T-547
title: The board's new Kaiju City becomes the default map
status: open
from: project-lead
to: level-challenge
lead: Rails
epic: level-challenges
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/level/game-map.md]
files_expected_to_change: [game/data/level/kaiju_city_map.json, game/tests/, game/docs/level/game-map.md, docs/level-design.md]
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

Build Level design, Decisions, "The board's new Kaiju City is the default map". The board edited its level Kaiju City in the level creator; the file is C:\solid-carbide-game\game\data\levels\kaiju_city.json in the main checkout (untracked, git-ignored, so it is NOT in your worktree: read it from that path, never change it). Make game/data/level/kaiju_city_map.json a byte-for-byte copy of it, the way game/docs/level/game-map.md describes, and run the level checks it names (check_level.py, check_heights...) on it. It holds 72 rails, 28 ramps and 12 platforms. Fix nothing in the board's level: if a check fails, report it to the Project Lead with the details instead. Update any test that counted the old map's pieces (T-546 left the default map with no rails; it now has the board's rails), and game/docs/level/game-map.md.

The board's review: start a run from C:\solid-carbide-worktrees\T-547\game\project.godot and check it is the map you made.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (the board's own levels; reading is fine where the ticket says so). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/level/kaiju_city_map.json is byte-for-byte the board's game/data/levels/kaiju_city.json (same hash, given in the result notes). (QA: pass / fail)
- [ ] The level checks game/docs/level/game-map.md names pass on it, with their output in the result notes. (QA: pass / fail)
- [ ] A run starts on it, and the rails grind (test). (QA: pass / fail)
- [ ] game/docs/level/game-map.md and docs/level-design.md Content describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-547/screenshots/ show the new map in a run, including a few of its rails and ramps. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
