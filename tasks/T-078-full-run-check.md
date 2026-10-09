---
id: T-078
title: QA: a full run from the main menu, before the MVP playtest
status: blocked
from: project-lead
to: qa-integration
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-055, T-052, T-050, T-046, T-061, T-060, T-062]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, docs/garage-design.md, game/README.md]
files_expected_to_change: [an end-to-end test or script, game/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until the screen flow (T-055), the HUD (T-050), the level-up screen (T-052), the kaiju's attack (T-046) and the garage upgrades (T-060, T-061, T-062) are done.**

Before the board plays the MVP, check that everything runs together, as Game loop architecture describes a run: from the main menu, Start begins a run; the car drives on the map; challenges and drifts give likes and level-ups; the level-up screen applies a choice; minions come in, are shot and drop coins; the kaiju arrives with 1:00 left and attacks; a win and a loss both return to the main menu; the coins are banked and the garage can spend them; the upgrades bought apply in the next run.

Write it as an automated end-to-end test where it can be, and a short manual checklist for what can't be automated. Report anything that doesn't connect.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The end-to-end test runs the steps above and passes, or the result notes list each step that fails, with what happened (QA: pass / fail)
- [ ] `game/README.md` says how to run the end-to-end test and has the manual checklist (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
