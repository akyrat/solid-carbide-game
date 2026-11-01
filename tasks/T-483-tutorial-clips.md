---
id: T-483
title: Record the tutorial clips: a zoomed-out drift, a long drift, an alt drift, and a ramp jump with hang time and an air spin
status: open
from: project-lead
to: driving-drift
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/drifting.md, game/scenes/drift_prototype/, game/scenes/elevation_test/]
files_expected_to_change: [game/tools/, game/tests/, game/art/tutorial/clips/, docs/hud-and-menus.md]
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

The board, 2026-11-01 (HUD and menus, Decisions, "The tutorial slides are redrawn, with clips of the real car"): the redrawn tutorial slides show short looping clips of the real car, recorded from the game on a simple background (like the drift prototype's plain grid), never cut from run recordings with the city and the HUD. The board rejected clips cut from old test GIFs. Record four clips, as GIFs, by script so they can be re-recorded:

1. **The drift, zoomed out** (slide 1): seen from higher up than the run's camera (zoomed out), so the whole path shows: the car driving straight, then turning with W held so it breaks into a drift, its tyre marks and smoke tracing the path it takes from where the drift starts. The camera holds still (or follows slowly) so the trajectory reads.
2. **Long drift** (slide 2): one long unbroken drift.
3. **Alt drift** (slide 2): drifting one way, then flicking into a drift the other way, as the ALT DRIFT! trick counts it.
4. **Ramp jump** (slide 2): the car takes a ramp at speed, flies into the air with enough airtime for HANG TIME!, and spins while airborne (an air 180 or 360), then lands, all in one clip.

Each clip: the real car code and art, a simple background with nothing else (no HUD, no enemies, no popups), a few seconds long and looping cleanly, about 480 x 320 pixels, nearest-neighbour, small enough for a slide (aim under 1.5 MB each). Drive the car by script (inputs), the way the existing recording tools do. Put the final GIFs in game/art/tutorial/clips/ (they will be shown on the slides later; nothing in the game uses them yet), with a short record JSON per clip saying how it was made. Keep every take you record in art-archive/<this ticket>/ (never delete). No game behaviour changes. Never write, move or commit anything in game/data/levels/.

The board's review: watch the four clips; the Project Lead puts them on the draft page.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Four GIFs exist in game/art/tutorial/clips/: the zoomed-out drift, the long drift, the alt drift and the ramp jump, each with a record JSON; the result notes list their sizes, lengths and file sizes. (QA: pass / fail)
- [ ] Each clip shows only the car (with its tyre marks, smoke and shadow) on a simple background: no HUD, enemies, popups or city. (QA: pass / fail)
- [ ] The drift clip's camera is zoomed out enough that the drift's path from its start shows in the frame (the result notes say the zoom used against the run's). (QA: pass / fail)
- [ ] The ramp clip shows the car leaving a ramp, airborne long enough for the airtime trick (the result notes give the airtime against the HANG TIME! threshold) and turning at least 180 degrees in the air before landing. (QA: pass / fail)
- [ ] A script re-records all four (the result notes say how to run it); a test checks the script's output (four files, the expected size). (QA: pass / fail)
- [ ] Only tools, tests, the clips and docs change: no game script or scene behaviour changes. (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content) says where the clips are and how to re-record them. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1800 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
