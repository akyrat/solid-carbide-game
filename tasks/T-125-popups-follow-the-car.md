---
id: T-125
title: Trick popups follow the car while they are on screen
status: in-progress
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/README.md, tasks/T-091-trick-popups.md, tasks/T-084-trick-popup-art.md, game/scripts/hud/trick_popups.gd]
files_expected_to_change: [game/scripts/hud/trick_popups.gd, its tests, game/README.md, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's playtest of the comic popups (T-084, 2026-10-13): today a popup appears above the car and then stays where it appeared while the car drives away, so at drift speed it is left behind and hard to read. The board wants each popup to **stay with the car**: it follows the car for its whole life (HUD and menus, Decisions, 2026-10-13).

**Branch:** create your branch `task/T-125-popups-follow-the-car` from `task/T-084-trick-popup-art` (not from master), in your own folder `C:\solid-carbide-worktrees\T-125`, so the board playtests the new look and this together. T-084 merges first, then this task.

1. A popup is placed relative to the car and moves with it every frame: it still pops above the car, grows and rises its 40 pixels relative to the car, and fades as before; only its anchor changes from a fixed world point to the car.
2. Several popups at once (for example an extended drift every second during a long drift, plus a 360) must stay readable: stack or offset them so they don't sit on top of each other; propose how and say so in the result notes.
3. It must not shake: follow the car's drawn position (the same position the camera follows), not its physics position.
4. Works in the run (including from the main menu) and in the drift prototype, and for the challenge popup ("Trending!").
5. Update HUD and menus, Content ("Trick popups"), and game/README.md.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Do not merge.

## Acceptance criteria

- [ ] GUT tests show a popup keeps the same offset from the car's drawn position while the car moves (apart from its own rise), for its whole life (QA: pass / fail)
- [ ] GUT tests show two or more popups shown close together don't overlap each other (QA: pass / fail)
- [ ] Two screenshots during a fast drift, a fraction of a second apart, show the popup still above the car (QA: pass / fail)
- [ ] HUD and menus, Content, and game/README.md say the popups follow the car (QA: pass / fail)
- [ ] T-091, T-083, T-092 and T-084's tests, the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest tricks at speed (together with T-084's look) and judge whether the popups are readable.

## Result notes

Written by the agent when it finishes.
