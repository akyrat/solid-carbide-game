---
id: T-217
title: GIFs of the game's current state, for a README section
status: open
from: project-lead
to: game-loop
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [README.md]
files_to_read_first: [tasks/README.md, README.md, game/README.md, docs/level-design.md, docs/enemies.md]
files_expected_to_change: [art-archive/T-217/, game/tests/fixtures/, game/tools/, README.md]
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

The board wants the repository's front page to show where the game is today (2026-10-21). Record three short GIFs from the real game on master (the run on the elevation map, with the final car, kaiju, flames and meteor effects), and add a section to the root `README.md`, "Current state of the game", that shows them with one line each:

1. **The car drifting while enemies chase it** on the street.
2. **The car jumping off a tall platform while drifting** (off a height-6 rooftop or its ramp, landing below).
3. **The kaiju chasing the car and throwing down meteors** (warning circles, meteors with their tails, impacts, boulders).

Each GIF is a few seconds long, small enough for a README (aim for under 5 MB each), and shows the game as a player sees it, with the HUD. Drive the car by script in test fixtures (as T-069, T-070 and T-102 did; `game/tools/make_turn_gif.py` and `record_meteor_fx.sh` are examples), and use the existing playtest switches to bring the kaiju in early. Save the GIFs in `art-archive/T-217/screenshots/` and link them from the README section with relative paths. Don't change any game behaviour.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] Three GIFs in `art-archive/T-217/screenshots/` show, in the real game with the HUD: the car drifting with enemies chasing it; the car jumping off a tall platform while drifting; the kaiju chasing the car while meteors fall (QA: pass / fail)
- [ ] Each GIF is under 5 MB and a few seconds long (QA: pass / fail)
- [ ] The root `README.md` has a "Current state of the game" section showing the three GIFs, each with one line, by relative path (QA: pass / fail)
- [ ] No game behaviour changed: only fixtures, recording tools and docs; the full GUT suite and all Python tool tests pass (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
