---
id: T-346
title: Token spend: split game/README.md into one folder per game area
status: open
from: project-lead
to: project-lead
lead: Tokens
epic: token-spend
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/README.md]
files_to_read_first: [tasks/README.md, game/README.md]
files_expected_to_change: [game/README.md, game/docs/, tasks/, docs/README.md]
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

`game/README.md` is about 400 KB (about 100k tokens), listed in 246 of 341 tickets' files to read first, and agents re-read it several times in one ticket (T-235, T-240, T-312). The board approved this layout (2026-10-28):

- `game/README.md`: a short index only, one line per file.
- `game/docs/setup/` (setup, folder layout, tests, screenshots), `driving/` (drift, collisions, tricks, effects: marks, smoke, boost, hype), `enemies/` (minions, kaiju, ledges and rooftops, meteors), `weapons/` (one file per weapon plus a shared file), `level/` (MVP map, elevation, level creator, challenge check), `game-loop/` (screen flow, the run), `hud-and-menus/` (menus, HUD, popups, camera), `garage/`, `art/` (PixelLab, car sprites, ground and props), `sound/`, `data/`.

Move the text, don't rewrite it; one-off history sections (for example the rebrand sweep, the first road tile) may shrink to a line and a ticket id. Each fact lives in one file and others link to it. Fix links into the old README across the repo, and replace `game/README.md` in the files to read first of every ticket that is not done or cancelled with the file(s) it actually needs. Do it with a script where you can (a split map from heading to file).

Part of the token-spend epic (board, 2026-10-28; `tasks/README.md`, "Epics and milestones"). The evidence behind it is the Tokens session's recon of 2026-10-28 (summarised in `docs/timeline.md`, "2026-10-28: The token-spend epic"). Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/README.md` is under 10 KB and lists every file under `game/docs/`; the folders match the layout in the description. (QA: pass / fail)
- [ ] No section of the old README is lost: every old `## ` heading is found in a new file or named in the index as shrunk (a script's check, its output in the result notes). (QA: pass / fail)
- [ ] No file under `game/docs/` is over 40 KB, and `weapons/` holds one file per weapon. (QA: pass / fail)
- [ ] No link in the repo points to a removed README anchor (a link check's output in the result notes). (QA: pass / fail)
- [ ] No ticket that is not done or cancelled still lists `game/README.md` alone; each lists the area file(s) it needs. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
