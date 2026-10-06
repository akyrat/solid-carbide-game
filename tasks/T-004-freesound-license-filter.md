---
id: T-004
title: Freesound downloader: accept only CC0 and CC BY sounds
status: open
from: project-lead
to: sfx
epic: sound
milestone: mvp
depends_on: [T-002]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/unfiled-game-details.md, game/README.md, game/tools/freesound.py, game/tools/test_freesound.py, tasks/T-002-freesound-test-download.md]
files_expected_to_change: [game/tools/freesound.py, game/tools/test_freesound.py, game/README.md]
qa_rounds: 0
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

- [ ] The search request the downloader builds includes a license filter for CC0 and CC BY only, shown by a test that checks the built request (QA: pass / fail)
- [ ] A test feeds the downloader faked search results containing CC0, CC BY, CC BY-NC, Sampling+ and an unrecognised license, and only the CC0 and CC BY sounds are saved (QA: pass / fail)
- [ ] A test confirms that a skipped sound leaves no audio file and no metadata JSON behind (QA: pass / fail)
- [ ] The allowed licenses are defined in exactly one place in `freesound.py` (QA: pass / fail)
- [ ] All Python tool tests pass with `python -m unittest discover -s game/tools -p "test_*.py"`, and the GUT suite still passes with `bash game/tools/run_tests.sh` (QA: pass / fail)
- [ ] `game/README.md` says the downloader accepts only CC0 and CC BY and links to `docs/unfiled-game-details.md` for the rule (QA: pass / fail)
- [ ] No files under `game/audio/` changed in this task (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
