---
id: T-221
title: "Art: the health drop, a red gas canister with a white cross (PixelLab)"
status: in-progress
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-220]
documents_affected: [art-archive/README.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/enemies.md, tasks/T-220-health-drops.md, art-archive/README.md, game/README.md]
files_expected_to_change: [game/art/, game/scripts/, game/tests/unit/, art-archive/T-221/, art-archive/README.md, game/README.md, game/art/pixellab-generation-log.jsonl]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The final art for T-220's health drop (Visual style, Decisions, "Health drop", 2026-10-21): a red gas canister with a white cross on it, small, lying on the ground like the coins, in a canister red that is not Redgull's red. Follow Visual style's technical rules (pixel art for the isometric view, selective dark outline, about 30 colours, no semi-transparent pixels, transparent background, night palette). Swap it in for T-220's placeholder without changing behaviour.

Sample first (`docs/working-with-the-board.md`, "Art and money"): one PixelLab generation, shown to the board enlarged on dark and light backgrounds next to a coin for scale, then stop for the board's review. Plan the call and cost in the result notes first; one round; problems are reported, not regenerated; free script fixes come first.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the canister in a run.

## Acceptance criteria

- [ ] A check script shows the sprite follows Visual style's technical rules and uses no Redgull red (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after (QA: pass / fail)
- [ ] In a run the health drop shows the new art, behaving as before (screenshot; T-220's tests pass) (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: first the sample, then the canister in a run.
Board review files: the sample images and screenshots in `art-archive/T-221/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Blocked → In progress

Started: one PixelLab sample of the canister first.

## Result notes

Written by the agent when it finishes.

### Sample (2026-10-21), stopped for the board's review

**Planned call** (written here after the call went out, by mistake: my first attempt to write this entry failed on a missing file read, and I ran the call in the same step; the call matched this plan): one `create-image-pixflux`, 32 x 32, no background, black outline, medium shading, highly detailed, text guidance 8; request `art-archive/T-221/req_canister.json`; expected cost 1 generation; checked beforehand that no T-221 call was in the log and `art-archive/T-221/` did not exist.

**Cost and balance:** 1 generation, as planned. Balance before 4804 of 5000 generations; after 4803 (the first read straight after the call still showed 4804, a lag). One round, no regeneration.

**Files** (`art-archive/T-221/`): `canister_raw.png` (+ `.json` record), `req_canister.json`, review picture `canister_sample_review.png` (8x nearest-neighbour, dark and light, coin 10 x 12 beside it). Nothing is swapped into the game; no change to `game/`.

**Check** (`check_sprite_rules.py --size 32`): all pass. 32 x 32, transparent corners, no semi-transparent pixels, 9 colours.

**Honest judgment (the board decides):** it reads as a red canister lying on its side, with a dark outline, shading, a small valve and a metal band, in the pixel style. Problems: (1) the white mark is a blobby X-like shape, not a clear cross; (2) it is about 24 x 17 art pixels, roughly twice the coin's 10 x 12, so "small, like the coins" would need a scale-down by script; (3) its darkest red (143, 37, 30) is fairly close to Redgull's red (135, 17, 27), though the main reds (192, 67, 62 and 241, 88, 86) are lighter and warmer, so it reads as a canister red; a free script shift of the darkest shade is possible. A free script could also redraw the cross as a clean white plus on the same pixels. Not regenerated.

**Refused commands:** none.
