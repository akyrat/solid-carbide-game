---
id: T-255
title: "Art: new rooftop, car park, wall and ramp textures for the creator's resizable pieces"
status: blocked
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-251]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, tasks/T-198-art-rooftops-and-parking-garage-ramps.md, tasks/T-251-resizable-rooftops-and-ramps.md, game/tools/pixellab_client.py]
files_expected_to_change: [game/art/elevation/, game/art/pixellab-generation-log.jsonl, art-archive/T-255/, art-archive/README.md, game/scenes/level/, game/data/level/, docs/visual-style.md, game/README.md]
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

The board's go for PixelLab (Level design, Decisions, "Level creator piece set", 2026-10-22: up to 100 generations across the creator's art tickets). **This ticket's cap: 10 generations.** T-251 draws the creator's rooftops and ramps at any size from tileable textures, with T-198's as placeholders; T-198's were judged weak (Visual style: the roof reads as big paved tiles with strong seams, the wall is very dark, the parapet thin). Generate a new set of seamless, tileable 128 x 128 textures for T-251's texture settings, in the city's palette (Visual style, Decisions, "City colours": cool blue-grey concrete, pale lit windows, small amber accents; the pixel-art rules; never Redgull red):

- **Roof tops:** a concrete rooftop, and a car park deck (asphalt with faded white bay lines), so the board can build both rooftops and parking garages.
- **Walls:** an office wall with lit windows (lighter than T-198's), and a plain concrete garage wall with openings.
- **Ramp surface** (asphalt with chevrons pointing up the slope) and **ramp side** (concrete).
- **Edge strip:** a parapet or kerb for the top's edge.

Plan your calls and their cost in the result notes before calling (PixelLab, `docs/working-with-the-board.md`, "Art and money"; 600 s timeout), one round only: report weak results, don't regenerate, and stop and report if a call costs more than planned or the cap would be passed. Make the seams tile by script where you can (free fixes first). Log every call, keep every generation (game-ready in `game/art/elevation/`, the rest in `art-archive/T-255/`), and swap them into T-251's texture settings, with the option to switch back to T-198's.

Your folder is built on T-251's branch (the Project Lead makes it). End with screenshots of a creator level using each texture, beside the same level with T-198's.

## Acceptance criteria

- [ ] The result notes list the planned calls and cost before the calls, and the generations used, at most 10; every call is in the generation log (QA: pass / fail)
- [ ] Each texture tiles without visible seams across a large rooftop or wall (screenshot) and passes `check_sprite_rules.py`; no Redgull red (QA: pass / fail)
- [ ] T-251's resizable pieces use the new textures, with T-198's selectable; every generation is kept (`game/art/elevation/` or `art-archive/T-255/`) (QA: pass / fail)
- [ ] Screenshots are in `art-archive/T-255/screenshots/`; Visual style and `game/README.md` record the textures; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: build rooftops, a car park and ramps, and judge the new textures against T-198's.
Board review files: the screenshots in `art-archive/T-255/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
