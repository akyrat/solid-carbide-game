---
id: T-494
title: Every screen scales with the window: the gift pack screen, the pause screen, and all the scan finds
status: open
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-493]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md]
files_expected_to_change: [game/scripts/, game/scenes/, game/tests/unit/, docs/hud-and-menus.md, game/docs/hud-and-menus/]
model: opus
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

The board, 2026-11-02 (HUD and menus, Decisions, "Every screen scales with the window"): every screen and menu the player meets scales with the window by the HUD's rule (Content, "The HUD scales with the window": one scale, the smaller of width / 1152 and height / 648, each screen laid out at that base size), so it covers the same share of the window at any resolution. First the two the board named: the gift pack (level-up) screen and the pause screen (with its trick list and HUD layout editor). Then everything T-493's scan flags (its report is in art-archive/T-493/): likely the main menu, garage, tutorial slides, power-up overlay, time's up, wreck and recap screens. Prefer one shared way to scale a screen (a helper both the HUD and the screens use) over per-screen numbers. Things drawn in the world at the camera's zoom (trick popups, the kaiju's health bar) stay as they are. Fonts and pixel art stay sharp (whole-number or nearest-filtered scaling where the art is pixel art). Keep keyboard and mouse working on every screen.

After the fixes, run T-493's scan again and put the before and after reports and contact sheets in art-archive/T-NNN/; every screen should keep its share of the window within about 10% across the five sizes. The board reviews in the Project Lead's swipe deck: no QA agent round. Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] T-493's scan after the fix shows every flagged screen covering about the same share of the window (within 10%) at all five sizes; the before and after reports are in art-archive/T-NNN/ and listed in the result notes. (QA: pass / fail)
- [ ] Contact sheets of the level-up screen and the pause screen at 1280 x 720 and 3840 x 2160, before and after, are saved and listed. (QA: pass / fail)
- [ ] Tests show the shared scaling gives the expected scale at 1280 x 720, 1920 x 1080, 3840 x 2160 and 3440 x 1440, and that the screens use it. (QA: pass / fail)
- [ ] The existing tests of every changed screen pass (keyboard and mouse unchanged). (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content, "The HUD scales with the window") says the screens now scale too, and how. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent, with -gselect), and the merge's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
