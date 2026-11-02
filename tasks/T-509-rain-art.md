---
id: T-509
title: Rain art with PixelLab
status: open
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/level-design.md]
files_expected_to_change: [game/art/, art-archive/, game/data/, game/tests/unit/, docs/visual-style.md]
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

The board, 2026-11-02 (docs/level-design.md, Decisions, "Rain over the map"): make the rain's art with PixelLab and swap it in for T-507's placeholder: raindrops (a few variants, falling at the slant T-507 uses), splash animation frames where drops land, and anything else that makes the rain read well in the game's pixel-art isometric style (Visual style; it must sit well on Crash City's streets and rooftops, night and neon). The board's go (2026-11-02): "no reason to be stingy" with PixelLab generations for the rain. Still: write the planned calls and their cost in the result notes before calling, go through the style loop for each asset (refines are its regenerations; extra tries beyond the loop are fine for this feature, but count every call), keep every generation in art-archive/T-NNN/, 600 s HTTP timeout. Tune T-507's rain numbers in its JSON file if the art needs it, and keep its frame time (measure again and write it in the notes). This task's branch is built on T-497's branch, which already holds the board's new weapon trees (T-495 to T-499) and the playtest tier switch (T-500), so the board can play everything in one build. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py <id> --append <file>`, never with Edit or Bash on the ticket. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build with the weapon trees (T-495 to T-499), the power-up changes and God mode (T-501 to T-505), from the Project Lead's combined folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The rain uses PixelLab art for its drops and splashes (no placeholder drawing left), in game/art/ (screenshots in a run on a street and a rooftop, at 1x and enlarged). (QA: pass / fail)
- [ ] Every generation is in art-archive/T-NNN/ and the result notes count the calls. (QA: pass / fail)
- [ ] The ticket's Style review records the style loop for each asset with its scores. (QA: pass / fail)
- [ ] The headless frame time with rain is in the result notes, still about 1 ms or less over no rain. (QA: pass / fail)
- [ ] The full Godot test set passes in QA (the art tests included). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
