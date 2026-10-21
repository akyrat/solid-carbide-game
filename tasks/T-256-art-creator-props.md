---
id: T-256
title: "Art: the creator's props, in four rotations"
status: blocked
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-253]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, tasks/T-253-placeable-props.md, game/tools/pixellab_client.py]
files_expected_to_change: [game/art/props/, game/art/pixellab-generation-log.jsonl, art-archive/T-256/, art-archive/README.md, game/data/level/, docs/visual-style.md, game/README.md]
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

The board's go for PixelLab (Level design, Decisions, "Level creator piece set", 2026-10-22: up to 100 generations across the creator's art tickets). **This ticket's cap: 40 generations.** T-253 added eight props with code-drawn placeholders, each in four rotations: concrete barrier, traffic cones, crate stack, AC unit, water tank, roof vent, street lamp, rooftop sign. Generate their final art: one isometric sprite per prop and rotation (north, east, south, west), at the game's scale (32 art pixels per unit, drawn at 0.5) and fitted to T-253's footprints, in the city's palette (Visual style, Decisions, "City colours"; amber light on the lamp and sign; the sign shows Japanese-like marks that aren't real words, no brands), with the pixel-art rules, never Redgull red.

Choose the cheapest way that keeps the four rotations consistent (for example one generation per prop and PixelLab's rotate or rotations call for the others, or mirroring by script where a prop is symmetric, as free fixes first). Plan your calls and their cost in the result notes before calling (`docs/working-with-the-board.md`, "Art and money"; 600 s timeout), one round only: report weak results, don't regenerate, and stop and report if a call costs more than planned or the cap would be passed. Log every call, keep every generation (game-ready in `game/art/props/`, the rest in `art-archive/T-256/`), and swap them in through T-253's props data only.

Your folder is built on T-253's branch (the Project Lead makes it). End with a screenshot of every prop in its four rotations in the creator, and one in a run.

## Acceptance criteria

- [ ] The result notes list the planned calls and cost before the calls, and the generations used, at most 40; every call is in the generation log (QA: pass / fail)
- [ ] All 8 props have art in four rotations that read as the same object, fit their footprints, pass `check_sprite_rules.py`, and have no Redgull red (screenshot) (QA: pass / fail)
- [ ] The props use the new art through T-253's data; every generation is kept (QA: pass / fail)
- [ ] Screenshots are in `art-archive/T-256/screenshots/`; Visual style and `game/README.md` record the art; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: place every prop in each rotation and judge the art.
Board review files: the screenshots in `art-archive/T-256/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
