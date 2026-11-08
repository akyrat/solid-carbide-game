---
id: T-597
title: No R on the tutorial's keycaps
status: in-qa
from: project-lead
to: ui
lead: Rails
epic: tutorial
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/scripts/run/practice_session.gd, game/docs/hud-and-menus/tutorial-slides.md]
files_expected_to_change: [game/scripts/, game/tests/, game/docs/hud-and-menus/]
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

Build HUD and menus, Decisions, "No R on the tutorial's keycaps": the keycaps in the practice window's top-right corner (T-574 tweak 9, KeyPad.full()) show W, A, S, D and Space only. Remove R from that pad and its layout; R keeps doing what it did (the stage reset), and the recorded demos still replay. If the trick list's key pad shares the code, keep it unchanged.

The board's review: play it from C:\solid-carbide-worktrees\T-597\game\project.godot: open the tutorial's trick slides.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The practice window's keycaps show W, A, S, D and Space, and no R (a test and a screenshot). (QA: pass / fail)
- [ ] R still resets the stage, and the demos still replay (the existing tests pass). (QA: pass / fail)
- [ ] The trick list's key pad is unchanged (its tests pass). (QA: pass / fail)
- [ ] game/docs/hud-and-menus/tutorial-slides.md and docs/hud-and-menus.md Content say so. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A screenshot in art-archive/T-597/screenshots/ shows the keycaps without R. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, In progress → In QA

R is gone from the tutorial keycaps (W, A, S, D, Space); R still resets. QA now.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Removed R from the practice window's keycaps: KeyPad.full() now draws W, A, S, D and Space (KEYS_WITH_R deleted); PracticeSession.held_keys() no longer reports R (R still resets the stage; _r_lit kept, harmless). Trick list key pad untouched (KeyPad.attach). Test updated in test_practice_take.gd (no R key, Space bar, reset lights no R). Docs: game/docs/hud-and-menus/tutorial-slides.md updated; docs/hud-and-menus.md already had the decision line. Tests: full Godot set 3250 tests, 3249 pass, 0 fail, 1 risky/pending, 284 scripts. Screenshot: art-archive/T-597/screenshots/keycaps_no_r.png (new tools/shots/keypad_shots.tscn).
