---
id: T-004
title: Freesound downloader: accept only CC0 and CC BY sounds
status: done
from: project-lead
to: sfx
lead: Weapons
epic: sound
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-002]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/unfiled-game-details.md, game/README.md, game/tools/freesound.py, game/tools/test_freesound.py, tasks/T-002-freesound-test-download.md]
files_expected_to_change: [game/tools/freesound.py, game/tools/test_freesound.py, game/README.md]
qa_rounds: 2
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board decided the game uses only sounds licensed CC0 or CC BY (see "Sound licenses" in `docs/unfiled-game-details.md`). The Freesound downloader built in T-002 does not filter by license, so in T-002 it downloaded two CC BY-NC sounds, which then had to be deleted. Make the downloader enforce the license rule, so a disallowed sound can never be saved.

1. Filter at search time: add a license condition to the Freesound search so results include only CC0 and CC BY sounds. Check the Freesound API documentation for the exact filter syntax and the license names it uses.
2. Check again before saving: even if a disallowed sound comes back from the search, the downloader must skip it and never write its file or metadata. Any other license (CC BY-NC, Sampling+, or anything unrecognised) counts as disallowed.
3. Keep the allowed licenses in one clearly named place in the script, so a future board decision changes a single line.
4. When a sound is skipped for its license, print one line saying which sound and why, so the reason is visible.
5. Update `game/README.md` ("Downloading sounds from Freesound") to say the downloader accepts only CC0 and CC BY, and point to `docs/unfiled-game-details.md` for the rule instead of repeating it.
6. Write tests for the new behaviour using faked Freesound responses. No test may call Freesound.

Do not download any new sounds for this task, and do not change the test-run sounds from T-002.

## Acceptance criteria

- [ ] The search request the downloader builds includes a license filter for CC0 and CC BY only, shown by a test that checks the built request (QA: PASS)
- [ ] A test feeds the downloader faked search results containing CC0, CC BY, CC BY-NC, Sampling+ and an unrecognised license, and only the CC0 and CC BY sounds are saved (QA: PASS)
- [ ] A test confirms that a skipped sound leaves no audio file and no metadata JSON behind (QA: PASS)
- [ ] The allowed licenses are defined in exactly one place in `freesound.py` (QA: PASS)
- [ ] All Python tool tests pass with `python -m unittest discover -s game/tools -p "test_*.py"`, and the GUT suite still passes with `bash game/tools/run_tests.sh` (QA: PASS)
- [ ] `game/README.md` says the downloader accepts only CC0 and CC BY and links to `docs/unfiled-game-details.md` for the rule (QA: PASS)
- [ ] No files under `game/audio/` changed in this task (QA: PASS)

## Updates

### 2026-10-15, Done

The Freesound downloader now keeps only CC0 and CC BY sounds: the search asks Freesound for those two licenses only, and any other license is skipped with a printed reason before a file is written. QA checked the license names against Freesound's API docs. Tooling, so merged after QA. The first real search (T-076) should confirm the filter returns results.

## Result notes

- Search filter: `search_filter` now adds `license:("Creative Commons 0" OR "Attribution")` (Freesound's own license names; not checked against the live docs or API, since no test or download may call Freesound).
- Second check: `pick_sounds` skips any result whose license is not in `ALLOWED_LICENSES` (CC BY-NC, Sampling+, unknown, empty), before any download or metadata write, and prints one `skipped <id> (<name>) by <user>: license '<x>' is not allowed` line.
- One place: `ALLOWED_LICENSES` in `game/tools/freesound.py`.
- Tests (faked responses only) in `game/tools/test_freesound.py`: filter in built request, CC0/BY/BY-NC/Sampling+/unknown/empty mix saves only CC0 and CC BY, skipped sounds leave an empty folder, single definition, skip line. An existing pick test got a license on its fake results.
- `game/README.md` updated and points to `docs/unfiled-game-details.md`.
- Ran: game/tools unittest (257, OK), tools unittest OK, GUT 671/671 passing. Reverted Godot `.import` line-ending noise; nothing under `game/audio/` changed.
- Documents affected: game/README.md (updated).

## QA round 1

All 7 criteria PASS. Python tests 257 OK (1 skipped), GUT passed, nothing under game/audio/ changed, ALLOWED_LICENSES defined once.
Freesound docs check (API v2 resources page): license values are exactly `Attribution`, `Attribution NonCommercial`, `Creative Commons 0`; multi-word filter values need double quotes. So the two allowed names MATCH. Only caveat: the docs show OR only for single-word values (`type:(wav OR aiff)`); `license:("Creative Commons 0" OR "Attribution")` is not documented verbatim, so the first live search should confirm it (not tested, no live calls allowed).
- 2026-10-15, in-qa → done: QA pass
