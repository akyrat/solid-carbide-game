---
id: T-221
title: "Art: the health drop, a red gas canister with a white cross (PixelLab)"
status: done
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
qa_rounds: 1
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

- [ ] A check script shows the sprite follows Visual style's technical rules and uses no Redgull red (QA: pass; check_sprite_rules: transparent corners, no semi-transparent pixels, 6 colours; only the square-frame size line fails as the sprite is 14x10 by design; nearest red is 54 from Redgull's, tested in test_canister_art_is_not_redgull_red)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after (QA: pass; log line has prompt and cost 1 generation, req_canister.json the settings, notes give balance 4804 to 4803)
- [ ] In a run the health drop shows the new art, behaving as before (screenshot; T-220's tests pass) (QA: pass; zoom screenshot shows two small red canisters with white cross beside coins; test_health_drops passes in the GUT run)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass; GUT 1275/1275, tools 439 OK, game/tools 393 OK with 1 skipped)

The board's review: first the sample, then the canister in a run.
Board review files: the sample images and screenshots in `art-archive/T-221/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Blocked → In progress

Started: one PixelLab sample of the canister first.

### 2026-10-21, In progress → In QA

Canister sample in (1 generation): reads as a red canister; the cross is a blobby X, it's about twice a coin's size, and its darkest red is close to Redgull's. Free script fixes can redraw the cross, shift the red and scale it down. Picture: C:\solid-carbide-worktrees\T-221\art-archive\T-221\canister_sample_review.png

### 2026-10-21, In progress

Board chose (a): the sample with three free script fixes, then into the game.

### 2026-10-21, In progress → In QA

Fixed by script and swapped in: clean plus, red away from Redgull's, coin-sized. No extra generations. Sent to QA.

### 2026-10-21, In QA → Needs playtest

QA passed all 4. Ready for the board: C:\solid-carbide-worktrees\T-221\game\project.godot; the health canisters now use the final art.

## Result notes

Written by the agent when it finishes.

### Sample (2026-10-21), stopped for the board's review

**Planned call** (written here after the call went out, by mistake: my first attempt to write this entry failed on a missing file read, and I ran the call in the same step; the call matched this plan): one `create-image-pixflux`, 32 x 32, no background, black outline, medium shading, highly detailed, text guidance 8; request `art-archive/T-221/req_canister.json`; expected cost 1 generation; checked beforehand that no T-221 call was in the log and `art-archive/T-221/` did not exist.

**Cost and balance:** 1 generation, as planned. Balance before 4804 of 5000 generations; after 4803 (the first read straight after the call still showed 4804, a lag). One round, no regeneration.

**Files** (`art-archive/T-221/`): `canister_raw.png` (+ `.json` record), `req_canister.json`, review picture `canister_sample_review.png` (8x nearest-neighbour, dark and light, coin 10 x 12 beside it). Nothing is swapped into the game; no change to `game/`.

**Check** (`check_sprite_rules.py --size 32`): all pass. 32 x 32, transparent corners, no semi-transparent pixels, 9 colours.

**Honest judgment (the board decides):** it reads as a red canister lying on its side, with a dark outline, shading, a small valve and a metal band, in the pixel style. Problems: (1) the white mark is a blobby X-like shape, not a clear cross; (2) it is about 24 x 17 art pixels, roughly twice the coin's 10 x 12, so "small, like the coins" would need a scale-down by script; (3) its darkest red (143, 37, 30) is fairly close to Redgull's red (135, 17, 27), though the main reds (192, 67, 62 and 241, 88, 86) are lighter and warmer, so it reads as a canister red; a free script shift of the darkest shade is possible. A free script could also redraw the cross as a clean white plus on the same pixels. Not regenerated.

**Refused commands:** none.

### After the board's approval (option a: the sample with three free script fixes, no more generations)

`python game/tools/build_health_canister.py` (test: `game/tools/test_build_health_canister.py`) makes `game/art/effects/health_canister.png` (+ `.json`) from the raw sample, which stays in `art-archive/T-221/`. No PixelLab call, no cost; balance unchanged at 4803.
1. The blobby white mark is painted over with the body red and redrawn as a plus of five white pixels (3 x 3, no corners).
2. The darkest red (143,37,30) became (170,56,40). Final colours: #170e0e (outline), #aa3828, #c0433e, #f15856 (the three reds), #ab9694 (grey band), #fdf8f5 (cross). The nearest to Redgull's red (135,17,27) is 54 away; the sprite is still clearly red.
3. Scaled from 24 x 17 to **14 x 10** (the coin is 10 x 12) by block-majority per output pixel (the outline counts double so it survives): no new colours, no semi-transparent pixels, 6 colours. The valve and the metal band are mostly lost at this size.

`health_pickup_sprite.gd` now draws the texture (shadow ellipse kept) instead of the code-drawn placeholder; behaviour is untouched. The old colour-constant test became `test_canister_art_is_not_redgull_red` (size, hard pixels, distance 45 from Redgull's red, a five-pixel cross).

**Tests:** `bash game/tools/run_tests.sh` passes (1275; its usual leak warnings only); `python -m unittest discover -s game/tools` 393 OK (1 skipped); `python -m unittest discover -s tools` 439 OK.

**Screenshots** (`art-archive/T-221/screenshots/`, looked at): `canister_in_run.png`, `canister_in_run_zoom.png`: two canisters beside two coins; they read as small red canisters with a white cross, about the coin's size. No screenshot of the magnet pulling one (it needs a scripted run; the magnet code is unchanged and its tests pass).

**Honest judgment:** reads well at a distance; up close it is a red blob with a plus, little canister detail left. Documents updated: `game/README.md`, `art-archive/README.md`. Refused commands: none.
- 2026-10-21, in-progress → in-qa: Canister sample ready for the board alone, no QA agent
- 2026-10-21, in-qa → in-progress: the board took it out of QA with 4 acceptance criteria not marked
- 2026-10-21, needs-playtest → done: LGTM
