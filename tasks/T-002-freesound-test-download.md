---
id: T-002
title: Freesound test run: download 3 engine idle and 3 tire drift sounds
status: done
from: project-lead
to: sfx
epic: sound
milestone: mvp
depends_on: [T-001]
documents_affected: []
files_to_read_first: [tasks/README.md, README.md, game/README.md, .env.example]
files_expected_to_change: [the Freesound download script and its tests, downloaded sound files and their metadata JSON files]
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

A test run to prove the SFX Agent can use the board's Freesound credentials to download original sound files. It depends on T-001 (done), so that `.gitignore` protects `.env` and `.secrets/` before any credentials are used.

The credentials are in `.env` at the repo root, as described in the root README's "Secrets and API keys" section. Never print secret values, write them to any other file, or put them in a commit.

1. Write a reusable download script (the SFX Agent will use it for all future sounds). It reads the credentials from `.env`, runs the Freesound OAuth2 flow, stores the access and refresh tokens in `.secrets/`, and renews the access token when it expires instead of asking the board again.
2. The one-time login needs the board: give the board the authorization link, the board logs in and approves, then pastes back the code Freesound shows. The code expires quickly, so be ready to use it as soon as it arrives. There is no redirect URI: build the authorization link from `FREESOUND_CLIENT_ID` and `response_type=code` only, so Freesound shows the code on its own page for the board to copy. The token exchange needs only the client id, the client secret (`FREESOUND_API_KEY`) and the code. If Freesound rejects a request without a redirect URI, stop and report it to the Project Lead instead of working around it.
3. Search Freesound and download the **original** files (not previews) for:
   - 3 sounds of a car engine idling
   - 3 sounds of tires screeching in a drift
4. Save them under the audio folder T-001 created, in a subfolder marked as a test run, for example `audio/sfx/_test-run/engine-idle/` and `audio/sfx/_test-run/tire-drift/`.
5. Next to each sound, write a metadata JSON file with the same base name. It must include at least: Freesound sound id, sound name, author's username, the Freesound page URL, the license name and license URL, the search query used, and the download date.
6. Write tests for the parts of the script that don't call Freesound (for example, metadata writing and token expiry handling), and run them.

This is a test of the pipeline, not a sound selection. Do not judge which sounds suit the game; the board decides that.

**Open decision for the board: which licenses are acceptable.** Freesound sounds come under licenses such as CC0, CC-BY (credit required) and CC-BY-NC (no commercial use). The board has not yet decided which ones the game can use, in particular whether non-commercial licenses are allowed. For this test run, do not filter by license: download and record whatever license each sound has. In the result notes, list the license of each of the 6 sounds, so the board can make this decision when reviewing the task. Future sound tasks follow the board's decision once it is made.

## Acceptance criteria

- [x] `engine-idle/` contains exactly 3 sound files and `tire-drift/` contains exactly 3 sound files (QA: pass)
- [x] Each of the 6 files is a valid audio file that Godot imports without errors, checked with the headless runner from T-001 (QA: pass)
- [x] Each of the 6 files has a metadata JSON next to it with the same base name, and every field listed in step 5 is present and non-empty (QA: pass)
- [x] For each sound, the Freesound id in its metadata matches the page URL in its metadata (QA: pass)
- [x] `git status` and `git ls-files` show no `.env` file and nothing under `.secrets/` (QA: pass)
- [x] No file tracked by git or staged contains the values of `FREESOUND_CLIENT_ID` or `FREESOUND_API_KEY` from `.env` (QA: pass)
- [x] Running the download script a second time does not ask the board to log in again (QA: pass)
- [x] The result notes list the license of each of the 6 sounds, and each matches the license in that sound's metadata (QA: pass)
- [x] The script's tests pass, and are run by the test command from T-001 or a documented command next to it (QA: pass)

## Result notes

**What was built**

- `game/tools/freesound.py`: a reusable Freesound downloader that uses only the Python standard library. It reads the credentials from `.env`, runs the OAuth2 flow with no redirect URI (`auth-url` prints the link, `login <code>` exchanges the code), and stores the tokens in `.secrets/freesound_token.json`. It renews the access token with the refresh token when the access token expires (60 s margin). `download` searches Freesound, picks only Godot-importable originals (wav, ogg, mp3, at most 5 MB by default) and downloads the original file through `/sounds/<id>/download/`, not the preview. It writes `<id>_<name>.json` metadata next to each sound. `--count` is the total the folder should hold, so re-running the same command downloads nothing. It never filters by license.
- `game/tools/test_freesound.py`: 23 unittest tests covering everything except the live Freesound calls. They cover .env parsing, the authorize URL (only client_id and response_type), the code exchange (no redirect_uri sent), token expiry, renewal and saving, a rejected refresh meaning a new login is needed, license name mapping, metadata building, validation and writing (all required fields non-empty, id matches page URL), file naming, and skipping unimportable formats and ids already downloaded.
- `game/tools/check_audio.gd`, `check_audio.sh`, `check_audio.ps1`: a headless audio import checker. It imports the project, then confirms that every wav, ogg and mp3 under a folder has an `.import` file and loads as a non-empty AudioStream. GUT test: `game/tests/unit/test_check_audio_tool.gd`, with fixture `game/tests/fixtures/audio/silence_100ms.wav`.
- Both tools are documented in `game/README.md`, along with the Python test command.

**How to run** (from the repo root)

- Tests: `python -m unittest discover -s game/tools -p "test_*.py"` (Python tools) and `bash game/tools/run_tests.sh` (GUT).
- Import check: `bash game/tools/check_audio.sh res://audio/sfx/_test-run`. Result: 6 of 6 load.
- Second run without login: `python game/tools/freesound.py status`, or re-run `python game/tools/freesound.py download --query "car engine idle" --count 3 --out game/audio/sfx/_test-run/engine-idle`. That command reports the folder already holds 3 and downloads nothing. Do not raise `--count`, or it will add sounds. I also tested a live renewal by setting the stored token's expiry to the past: `status` renewed it without a login.

**The 6 sounds** (search queries: "car engine idle", "tire screech drift"; downloaded 2026-10-04)

| Folder | Freesound id | Name | Author | License |
| --- | --- | --- | --- | --- |
| engine-idle | 50898 | Car Ignition Key - Engine Starting Running Idle 2.wav | RutgerMuller | CC0 1.0 |
| engine-idle | 401550 | SFX_Car_Engine_Inside_Idle.wav | GiocoSound | CC0 1.0 |
| engine-idle | 401552 | SFX_Car_Engine_Outside_Idle.wav | GiocoSound | CC0 1.0 |
| tire-drift | 737192 | Distant car tire screetch | Sadiquecat | CC0 1.0 |
| tire-drift | 593821 | drifting around a corner pass 1.wav | tim.kahn | CC BY-NC 4.0 |
| tire-drift | 593820 | drifting around a corner pass 2.wav | tim.kahn | CC BY-NC 4.0 |

For the board's license decision: 4 are CC0, which has no conditions. 2 are CC BY-NC 4.0, which requires credit and allows no commercial use. None of these 6 are plain CC BY. As the task says, this is not a sound selection. For example, 50898 includes the ignition before the idle.

**Files created or changed**

- Created: `game/tools/freesound.py`, `game/tools/test_freesound.py`, `game/tools/check_audio.gd` (+ `.uid`), `game/tools/check_audio.sh`, `game/tools/check_audio.ps1`, `game/tests/unit/test_check_audio_tool.gd` (+ `.uid`), `game/tests/fixtures/audio/silence_100ms.wav` (+ `.import`)
- Created: under `game/audio/sfx/_test-run/engine-idle/` and `game/audio/sfx/_test-run/tire-drift/`, 6 `.wav` files, 6 `.json` metadata files and 6 `.wav.import` files written by Godot
- Changed: `game/README.md` (Python tool tests, Freesound downloader, audio import checker, tools row in the folder table), `.gitignore` (added `__pycache__/` and `*.pyc`), this task file
- Local only, git-ignored: `.secrets/freesound_token.json`
- Documents affected: none (`documents_affected` is empty)

**Problems / notes**

- No problems with the OAuth flow. Freesound accepted the authorize link and the code exchange without a redirect URI.
- The two tim.kahn files are about 4 to 4.6 MB each, the largest of the six. Downloads skip originals over 5 MB by default.
- The Python test discovery command also runs the Asset Generation Agent's `test_pixellab_client.py`, because it sits in the same folder. All 45 tests pass. The full GUT suite, including T-003's test, passes.

### QA round 1

2026-10-04, QA/Integration Agent. All 9 criteria pass.

- Files: each folder holds exactly 3 `.wav` files, plus the matching `.json` and `.wav.import` files. All 6 start with a valid RIFF/WAVE header.
- Metadata: a script loaded all 6 JSON files. Every field from step 5 is present and non-empty. Each `freesound_id` matches the id in `freesound_url` and in the file name. Each license matches the table above (4 are CC0 1.0, 593820 and 593821 are CC BY-NC 4.0).
- Secrets: `.env` and `.secrets/` are absent from `git ls-files -co --exclude-standard` and from `git status --untracked-files=all`, and `.gitignore` covers both. A script read `FREESOUND_CLIENT_ID` and `FREESOUND_API_KEY` from `.env` and searched all 362 tracked, untracked and staged files: no match. A `git grep` over every commit also found no match. The values were never printed.
- No second login: `python game/tools/freesound.py status` (stdin closed) printed "Freesound login OK" and exited 0 without asking for a code. Note: `status` only checks the stored token locally and contacts Freesound only to renew an expired token. No download was run, and both folders still hold 3 sounds.
- Tests: `python -m unittest discover -s game/tools -p "test_*.py"` ran 45 tests, OK (23 of them in `test_freesound.py`).
- Godot runs were blocked for QA by the permission system, so the board ran them on the same working tree. `bash game/tools/check_audio.sh res://audio/sfx/_test-run` reported 6 of 6 audio files load correctly. `bash game/tools/run_tests.sh` reported 11 of 11 GUT tests passing in 4 scripts, including `test_check_audio_tool.gd` 5/5, and printed TESTS PASSED.

### After QA: board license decision

After this task passed QA, the board decided the game uses only CC0 and CC BY sounds. The two CC BY-NC 4.0 sounds, Freesound ids 593820 and 593821, were then deleted from `tire-drift/`, each with its `.wav`, `.json` and `.wav.import`. Nothing else referenced them. The 4 CC0 sounds are unchanged. `tire-drift/` now holds 1 sound (737192), so criterion 1's count of 3 no longer matches. That is expected, and no replacements were downloaded. Re-checked after the deletion: `bash game/tools/check_audio.sh res://audio/sfx/_test-run` reports 4 of 4 load, and the Python tests pass (45 tests). The downloader does not filter by license yet; that will be a separate task.

### Board review

2026-10-04: the board reviewed the test run and marked the task `done`.
