---
id: T-148
title: Tests never read the player's real saved progress
status: done
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
qa_rounds: 1
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

- [ ] With a real `user://progress.json` holding bought upgrades (put one there for the check, and put the original back afterwards), the full GUT suite passes (QA: pass)
- [ ] The real `user://progress.json` and `user://settings.cfg` are byte-identical before and after the full suite (QA: pass)
- [ ] `game/README.md` says tests use a test save path, never the real one (QA: pass)
- [ ] All Python tool tests pass (QA: pass)

## Updates

### 2026-10-16, Open → In progress

Started (board said yes).

## Result notes

Which tests touched the real save: none wrote it, but every test that started a run through GameFlow or the main menu (`test_starting_gun`, and any other that builds `GameFlow`) read the real `progress.json` because `PlayerProgress.path` defaulted to it; and 14 test files reset `GameSettings.path` / `PlayerProgress.path` to `DEFAULT_PATH` in their cleanup, so every later test fell back to the real files.

Changes: new `tests/helpers/test_save.gd` (`TestSave`) and `tests/helpers/pre_run.gd` (set as `pre_run_script` in `.gutconfig.json`) point both paths at empty per-run test files before the first test; those 14 files now call `TestSave.restore_*()` instead of `DEFAULT_PATH`; `post_run.gd` fails the run if either path is still the real one. `game/README.md` documents it.

Checked on the board's computer with its real save (a bought damage upgrade): GUT 777/777 pass, `python -m pytest tools` 180 passed, `python -m pytest game/tools` 265 passed, 1 skipped. SHA-256 of `progress.json` and `settings.cfg` identical before and after (backed up first; the suite never changed them, so no restore was needed).
- 2026-10-16, in-progress → in-qa: Tests now point PlayerProgress/GameSettings at per-run test files before the first test; GUT 777/777 with the board's real save; pytest 180 + 265 pass; real save hashes unchanged.

### QA round 1 (QA/Integration Agent, 2026-10-16)

Merged master into the branch first (no conflicts).
- Full GUT suite with the board's real save (bought upgrade) in place: 777/777 pass, 125317 asserts, exit 0 (QA: pass)
- `progress.json` and `settings.cfg` byte-identical before and after (SHA-256 f2dedbdb...f715f and eed9a68d...37440); no restore needed (QA: pass)
- `game/README.md` has "Tests never use the real save (T-148)" (QA: pass)
- `python -m pytest tools` 182 passed; `python -m pytest game/tools` 265 passed, 1 skipped (QA: pass)
- Guard: `.gutconfig.json` sets `pre_run_script` (pre_run.gd) and `post_run_script`; `post_run.gd` fails the run (exit code 1) if `TestSave.touches_real_save()` (wired).
- 2026-10-16, in-qa → done: QA round 1 passed; GUT 777/777 with the real save, hashes unchanged
