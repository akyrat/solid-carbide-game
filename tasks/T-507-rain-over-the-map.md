---
id: T-507
title: Rain over the map
status: open
from: project-lead
to: level-challenge
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md]
files_expected_to_change: [game/scripts/, game/scenes/, game/data/, game/tests/unit/, docs/level-design.md, game/docs/]
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

The board, 2026-11-02 (docs/level-design.md, Decisions, "Rain over the map"): it rains on the map during a run. Build the rain with a placeholder look drawn in code (T-509 makes the art with PixelLab and swaps it in): drops falling at a slant that suits the isometric view, over the whole visible map, drawn over the map and enemies and under the HUD, with small splashes where drops land on the ground and rooftops. Steady light rain for the whole run. It changes nothing in driving or enemies. It reads a saved setting `rain_enabled` (default true), stored with the other settings the same way they are saved, and shows or hides at once when it changes (T-508 adds the toggle). Keep it cheap: measure the frame time with and without rain headless and write both in the result notes (the board watches frame drops, T-481); it must also work in the web export (no features the web build lacks). Make the look's numbers (density, speed, angle, splash count) data in a JSON file so T-509 and the playtest can tune them. Describe it in docs/level-design.md (Content) and game/docs/. This task's branch is built on T-497's branch, which already holds the board's new weapon trees (T-495 to T-499) and the playtest tier switch (T-500), so the board can play everything in one build. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py <id> --append <file>`, never with Edit or Bash on the ticket. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build with the weapon trees (T-495 to T-499), the power-up changes and God mode (T-501 to T-505), from the Project Lead's combined folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A run shows rain over the visible map, falling at a slant, with splashes on the ground (screenshots on a street and on a rooftop). (QA: pass / fail)
- [ ] The rain is drawn over the map and enemies and under the HUD (screenshot and a test of the draw order or layers). (QA: pass / fail)
- [ ] A unit test: with rain_enabled false no rain draws; switching it on or off takes effect at once; the setting is saved and loaded like the other settings, default true. (QA: pass / fail)
- [ ] Its numbers (density, speed, angle, splashes) come from a JSON data file. (QA: pass / fail)
- [ ] The headless frame time with and without rain is in the result notes, and rain adds no more than about 1 ms per frame. (QA: pass / fail)
- [ ] Driving and enemies are unchanged (the existing driving and enemy tests pass). (QA: pass / fail)
- [ ] docs/level-design.md (Content) describes the rain. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
