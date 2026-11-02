---
id: T-493
title: A scan of every screen at several resolutions that lists what doesn't scale
status: open
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/tools/screen_gallery.py, game/tools/screen_gallery.gd]
files_expected_to_change: [game/tools/, docs/hud-and-menus.md]
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

The board, 2026-11-02 (HUD and menus, Decisions, "Every screen scales with the window"): the gift pack (level-up) screen and the pause screen look very small on big resolutions; run a game-wide scan to find everything that doesn't scale.

Extend the screen gallery (T-479, `game/tools/screen_gallery.py`) with a `--sizes` option that captures every screen it already reaches at 1280 x 720, 1920 x 1080, 2560 x 1440, 3840 x 2160 and 3440 x 1440 (the window really at that size, or the root viewport resized; say which). For each screen it measures the share of the window its visible content covers (for example the bounding box of its visible Controls, or of non-background pixels), compares it with 1280 x 720, and writes a report (`scaling_report.md` plus JSON) listing each screen and piece that shrinks as the window grows, worst first, with a side-by-side contact sheet per screen across the sizes. Run it on master and put the report and the contact sheets in art-archive/T-NNN/ (the fix ticket reads them). It should take minutes, not hours.

The board reviews in the Project Lead's swipe deck: no QA agent round. Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `python game/tools/screen_gallery.py --sizes` captures every reachable screen at the five sizes; the result notes give the time it took. (QA: pass / fail)
- [ ] The report lists every screen with its coverage at each size against 1280 x 720 and flags the ones that shrink; the level-up and pause screens are among them if they still don't scale. (QA: pass / fail)
- [ ] Contact sheets per screen across the sizes are saved under art-archive/T-NNN/ and listed in the result notes. (QA: pass / fail)
- [ ] Python tests cover the report's coverage maths and flagging (game/tools set). (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content, "The MVP pass") says how to run the scan. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
