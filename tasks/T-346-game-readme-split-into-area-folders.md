---
id: T-346
title: Token spend: split game/README.md into one folder per game area
status: in-qa
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
- [ ] ~~No ticket that is not done or cancelled still lists `game/README.md` alone; each lists the area file(s) it needs.~~ Moved to T-353 by the Project Lead (2026-10-28): the guard refused the bulk ticket edit, and the board decides how it may be done. QA skips this one. (QA: moved)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-28, Open → In progress

Started: the agent is splitting game/README.md into area folders.

### 2026-10-28, In progress → In QA

Built: game/README.md is now a short index with area files under game/docs/. The guard refused the bulk rewrite of other tickets' reading lists; nothing worked around it. I moved that step into T-353 for you to decide. QA is checking the rest.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent (Sonnet) at the end of the build. No screenshots: nothing to picture (docs only).

**Status: blocked on one criterion (the ticket list).** A hook refused the one command that rewrites other tickets' `files_to_read_first` (`PreToolUse:Bash`: "inline code that names task files"). I did not work around it. The script is ready at `C:\Users\andre\AppData\Local\Temp\claude\C--solid-carbide-game\2c104619-72b8-44ca-a9af-e1e03eadc5a7\scratchpad\fix_tickets.py` (maps 33 open/blocked tickets to area files; run from the worktree). The Project Lead must run it or hand it to someone allowed, then QA criterion 5.

**What was done**
- `game/README.md` is now a 5.6 KB index (one line per file). The old text is in `game/docs/`, moved by script, not rewritten: `setup/` (4 files), `driving/` (drift, collisions, tricks, effects), `enemies/` (minions, ledges-and-rooftops, kaiju, meteors), `weapons/` (shared plus starting-gun, flamethrower, neon-underglow, molotovs, windshield-wiper, bricks), `level/` (mvp-map, challenge-check, elevation-test-scene, elevation-sample-map, level-creator, level-creator-pieces), `game-loop/` (screen-flow, the-run, gift-pack-and-pickups), `hud-and-menus/` (main-menu, hud, popups, pause-screen, camera, level-up-screen), `garage/`, `art/` (pixellab, car-sprites, ground-and-props, rebrand-sweep), `sound/` (3), `data/`. 43 files. The rebrand sweep and first-road-tile sections were kept whole, not shrunk.
- Check 1: index 5612 bytes, every `game/docs` file listed, none unlisted. Check 2: every old `## ` heading found in the new files, 0 missing. Check 3: largest file 30 KB (level-creator-pieces.md), none over 40 KB; weapons/ has one file per weapon (6) plus shared.md.
- Links: the old README was linked only without anchors. Every reference to `game/README.md` with a named section, in docs/, agent-notes/, README.md, tasks/README.md, game code, tools and data, now points at the right area file. Left on purpose: docs/timeline.md, docs/long-gdd.md (regenerated at merge), the art-archive/T-306 script, goals/ and tools/goal_agent tests (history, or the index is right). `test_snapping.gd` read `res://README.md` for SNAP_DISTANCE; it now reads `res://docs/level/level-creator.md`. `docs/README.md` got one line about `game/docs/`.
- Tests: `python -m unittest discover -s game/tools` 620 OK (1 skipped); `python -m unittest discover -s tools` 529 OK; `bash game/tools/run_tests.sh` all GUT tests passed.
