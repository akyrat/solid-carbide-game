---
id: T-257
title: "Art: the small and long buildings"
status: blocked
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-254]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, tasks/T-254-smaller-and-longer-buildings.md, tasks/T-064-building-art.md, game/tools/pixellab_client.py]
files_expected_to_change: [game/art/buildings/, game/art/pixellab-generation-log.jsonl, art-archive/T-257/, art-archive/README.md, game/data/level/, docs/visual-style.md, game/README.md]
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

The board's go for PixelLab (Level design, Decisions, "Level creator piece set", 2026-10-22: up to 100 generations across the creator's art tickets). **This ticket's cap: 12 generations.** T-254 added a small square building (6 x 6 units) and a long building (12 x 6, and 6 x 12 rotated) with code-drawn placeholders. Generate their final art in the style of today's short buildings (T-064; Visual style, Decisions, "Buildings, redesigned", "City brief" and "City colours": roofs that show, steel and glass, pale lit windows, small amber accents, light damage, pavement drawn round them inside the footprint), at the game's scale, two looks for the small one if the cap allows, with the pixel-art rules, never Redgull red. Mirrors by script are free.

Plan your calls and their cost in the result notes before calling (`docs/working-with-the-board.md`, "Art and money"; 600 s timeout), one round only: report weak results, don't regenerate, and stop and report if a call costs more than planned or the cap would be passed. Log every call, keep every generation (game-ready in `game/art/buildings/`, the rest in `art-archive/T-257/`), and swap them in through T-254's data only.

Your folder is built on T-254's branch (the Project Lead makes it). End with a screenshot of the new buildings beside today's in the creator.

## Acceptance criteria

- [ ] The result notes list the planned calls and cost before the calls, and the generations used, at most 12; every call is in the generation log (QA: pass / fail)
- [ ] The small and long buildings (both rotations) have art that fits their footprints and matches today's short buildings, passes `check_sprite_rules.py`, no Redgull red (screenshot) (QA: pass / fail)
- [ ] They use the new art through T-254's data; every generation is kept (QA: pass / fail)
- [ ] The screenshot is in `art-archive/T-257/screenshots/`; Visual style and `game/README.md` record the art; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: place the new buildings and judge the art.
Board review files: the screenshot in `art-archive/T-257/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
