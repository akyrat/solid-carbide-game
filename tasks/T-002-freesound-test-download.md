---
id: T-002
title: Freesound test run: download 3 engine idle and 3 tire drift sounds
status: blocked
from: project-lead
to: sfx
depends_on: [T-001]
documents_affected: []
files_to_read_first: [README.md, game/README.md, .env.example]
files_expected_to_change: [the Freesound download script and its tests, downloaded sound files and their metadata JSON files]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

A test run to prove the SFX Agent can use the board's Freesound credentials to download original sound files. Blocked until T-001 is done, so that `.gitignore` protects `.env` and `.secrets/` before any credentials are used.

The credentials are in `.env` at the repo root, as described in the root README's "Secrets and API keys" section. Never print secret values, write them to any other file, or put them in a commit.

1. Write a reusable download script (the SFX Agent will use it for all future sounds). It reads the credentials from `.env`, runs the Freesound OAuth2 flow, stores the access and refresh tokens in `.secrets/`, and renews the access token when it expires instead of asking the board again.
2. The one-time login needs the board: give the board the authorization link, the board logs in and approves, then pastes back the code Freesound shows. The code expires quickly, so be ready to use it as soon as it arrives.
3. Search Freesound and download the **original** files (not previews) for:
   - 3 sounds of a car engine idling
   - 3 sounds of tires screeching in a drift
4. Save them under the audio folder T-001 created, in a subfolder marked as a test run, for example `audio/sfx/_test-run/engine-idle/` and `audio/sfx/_test-run/tire-drift/`.
5. Next to each sound, write a metadata JSON file with the same base name. It must include at least: Freesound sound id, sound name, author's username, the Freesound page URL, the license name and license URL, the search query used, and the download date.
6. Write tests for the parts of the script that don't call Freesound (for example, metadata writing and token expiry handling), and run them.

This is a test of the pipeline, not a sound selection. Do not judge which sounds suit the game; the board decides that.

**Open decision for the board: which licenses are acceptable.** Freesound sounds come under licenses such as CC0, CC-BY (credit required) and CC-BY-NC (no commercial use). The board has not yet decided which ones the game can use, in particular whether non-commercial licenses are allowed. For this test run, do not filter by license: download and record whatever license each sound has. In the result notes, list the license of each of the 6 sounds, so the board can make this decision when reviewing the task. Future sound tasks follow the board's decision once it is made.

## Acceptance criteria

- [ ] `engine-idle/` contains exactly 3 sound files and `tire-drift/` contains exactly 3 sound files (QA: pass / fail)
- [ ] Each of the 6 files is a valid audio file that Godot imports without errors, checked with the headless runner from T-001 (QA: pass / fail)
- [ ] Each of the 6 files has a metadata JSON next to it with the same base name, and every field listed in step 5 is present and non-empty (QA: pass / fail)
- [ ] For each sound, the Freesound id in its metadata matches the page URL in its metadata (QA: pass / fail)
- [ ] `git status` and `git ls-files` show no `.env` file and nothing under `.secrets/` (QA: pass / fail)
- [ ] No file tracked by git or staged contains the values of `FREESOUND_CLIENT_ID` or `FREESOUND_API_KEY` from `.env` (QA: pass / fail)
- [ ] Running the download script a second time does not ask the board to log in again (QA: pass / fail)
- [ ] The result notes list the license of each of the 6 sounds, and each matches the license in that sound's metadata (QA: pass / fail)
- [ ] The script's tests pass, and are run by the test command from T-001 or a documented command next to it (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
