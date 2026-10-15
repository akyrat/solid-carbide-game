---
id: T-076
title: Find the MVP's sound effects
status: open
from: project-lead
to: sfx
lead: Weapons
epic: sound
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-004]
documents_affected: [docs/unfiled-game-details.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/unfiled-game-details.md, tasks/T-002-freesound-test-download.md, tasks/T-004-freesound-license-filter.md, game/README.md]
files_expected_to_change: [sound files under game/audio/ with their metadata, game/README.md]
model: sonnet
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

**Blocked until T-004 (the licence filter) is done,** so only CC0 and CC BY sounds come in.

The MVP has basic sound effects (Unfiled game details, Sound effects in the MVP). Find them on Freesound with the existing downloader: the engine, drifting, the gun firing, the flames, hits on enemies, picking up a coin, the kaiju's meteor warning and impact. Pick one or a few candidates per sound, with source and licence metadata next to each, and say which you recommend. Hooking them into the game is T-077.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] Every sound listed has at least one file under `game/audio/` with complete metadata (source page, author, licence) (QA: pass / fail)
- [ ] A script shows every downloaded sound's licence is CC0 or CC BY (QA: pass / fail)
- [ ] The result notes list the recommended file for each sound, and the credits CC BY needs (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: listen to the recommended sounds.

## Result notes

Written by the agent when it finishes.
