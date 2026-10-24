---
id: T-285
title: "A script that adds a generated piece to the level creator's catalogue"
status: open
from: project-lead
to: level-challenge
lead: Coursework
epic: level-challenges
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md, docs/visual-style.md]
files_to_read_first: [tasks/README.md, game/README.md, docs/visual-style.md, docs/level-design.md, game/tools/build_creator_assets.py, game/data/level/creator_assets.json, game/scripts/level_creator/, game/tools/check_level.py, tasks/T-262-creator-panel-grouped.md]
files_expected_to_change: [game/tools/, game/data/level/, game/tests/, game/README.md, docs/visual-style.md]
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

The board's decision (Level design, Decisions, "Asking for a new piece from the creator", 2026-10-24). When the Asset Generation Agent has made a piece the board asked for, one script has to make it a creator piece, so the agent never edits the catalogue by hand. Write it, for example `python game/tools/add_creator_piece.py <png> --kind building|obstacle|decoration --label "<text>" [--footprint WxH] --request <id> --ticket <T-id>`. It should:

- **Check the art first:** 32 art pixels per unit, hard pixel edges, no semi-transparent pixels, no Redgull red (Visual style, Decisions). It refuses art that breaks a rule and says which one. Where the existing art pipeline already fixes something (cropping, an alpha cut-off), it does the same.
- **Store the piece:** in a folder of its own for requested pieces, for example `game/art/creator_requested/`, with its PixelLab record next to it.
- **Add it to the catalogue:** to a catalogue of requested pieces kept next to `creator_assets.json`, so the generated catalogue is never hand-edited. The entry gets a new family in the kind's group (Buildings, Obstacles or Decoration), its label, and its footprint.
  - **Footprint:** the one given, or worked out from the art's base when none is given (your proposal).
  - **Collision:** buildings and obstacles collide like their group's pieces; decoration doesn't.
- **Keep levels valid:** `check_level.py` accepts levels that use a requested piece, the run draws it, and a piece can't be added twice.

Built on the level creator's build: the Project Lead makes your folder from `playtest/creator-set`. Test it with an existing PNG from `game/art/`, as if it were new art; no PixelLab calls.

## Acceptance criteria

- [ ] Tests show a good PNG becomes a piece in the right group with its footprint, collision and label, and that a PNG with semi-transparent pixels, Redgull red or the wrong scale is refused with the rule it breaks (QA: pass / fail)
- [ ] Tests show a level using a requested piece passes `check_level.py`, opens in the creator and is drawn in a run; the existing catalogue and its tests are unchanged (QA: pass / fail)
- [ ] `game/README.md` and Visual style, Content, describe the script and the checks; the full GUT suite and all Python tool tests pass (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
