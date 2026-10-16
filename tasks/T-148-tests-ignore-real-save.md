---
id: T-148
title: Tests never read the player's real saved progress
status: in-progress
from: project-lead
to: game-loop
lead: Playtest
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, game/README.md, tasks/T-089-wire-garage-button.md, tasks/T-057-save-and-buy.md]
files_expected_to_change: [the affected tests, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

`test_starting_gun.gd::test_new_run_from_the_main_menu_starts_with_the_base_gun` fails on the board's computer (base damage 2.1, expected 2.0) because a run started from the main menu reads the real saved progress (`user://progress.json`), where the board bought a weapon damage upgrade in the garage. Tests must never depend on, read or write the player's real save. Make every test that goes through the main menu or `GameFlow` use a test progress path (as other tests do with `RunPaths`) or an injected empty progress, and check the whole suite for any other test that touches the real `progress.json` or `settings.cfg`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] With a real `user://progress.json` holding bought upgrades (put one there for the check, and put the original back afterwards), the full GUT suite passes (QA: pass / fail)
- [ ] The real `user://progress.json` and `user://settings.cfg` are byte-identical before and after the full suite (QA: pass / fail)
- [ ] `game/README.md` says tests use a test save path, never the real one (QA: pass / fail)
- [ ] All Python tool tests pass (QA: pass / fail)

## Updates

### 2026-10-16, Open → In progress

Started (board said yes).

## Result notes

Written by the agent when it finishes.
