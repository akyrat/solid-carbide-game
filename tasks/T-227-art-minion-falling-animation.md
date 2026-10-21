---
id: T-227
title: "Art: the minion's falling animation (PixelLab)"
status: in-progress
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-226]
documents_affected: [art-archive/README.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/enemies.md, tasks/T-226-enemies-jump-down-off-ledges.md, art-archive/README.md, game/README.md]
files_expected_to_change: [game/art/minion/, game/scripts/enemies/, game/tests/unit/, art-archive/T-227/, art-archive/README.md, game/README.md, game/art/pixellab-generation-log.jsonl]
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

The final art for the falling minion (Enemies, Decisions, "Enemies jump down off ledges": a falling enemy plays a falling animation from the edge until it lands, board, 2026-10-21). T-226 builds the fall with a placeholder animation made by script and leaves a hook for real frames; this task makes those frames from the approved minion art in `game/art/minion/` (the same character, palette and size), in its directions, and swaps them in through T-226's hook without changing behaviour.

The board has given its go for this task's PixelLab generations (2026-10-21). Plan the calls and cost in the result notes before calling, and stop and report if a call costs more than planned. Sample first (`docs/working-with-the-board.md`, "Art and money"): one direction's falling frames, shown to the board as a GIF, then the rest after approval. One round; problems are reported, not regenerated; free script fixes first. Follow Visual style's technical rules.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a GIF of minions falling off a rooftop in a run.

## Acceptance criteria

- [ ] A check script shows every new frame follows Visual style's technical rules and matches the minion's palette (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after (QA: pass / fail)
- [ ] In a run, a falling minion plays the new frames from the edge until it lands, behaving as before (GIF; T-226's tests pass) (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: first the one-direction sample as a GIF, then minions falling in a run.
Board review files: the GIFs in `art-archive/T-227/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Blocked → In progress

Started: PixelLab falling frames for the minion, one direction as a GIF sample first.

## Result notes

Written by the agent when it finishes.

**Sample round (south-east only), stopped for the board's review.**

Plan (before calling): 1 call, `POST /animate-with-text-v3` (the endpoint T-068's walk used, which cost 1 generation), first frame `art-archive/T-068/rotations/minion_rot8_2.png` (the minion facing south-east, 48 px), 8 frames, `no_background`, seed 227001, 600 s timeout, no retry. Expected cost 1 generation; stop if more. Prompt: "a lizard falling through the air: legs splayed out and flailing, body tilted and tumbling slightly, tail whipping behind, mouth open in alarm, no ground beneath it, no shadow". Consulted: `docs/visual-style.md`, `T-068/walk2_req.json`, the rotation image.

Done: that one call. Cost 1 generation, as planned. Balance before 4803 of 5000, after 4802. It returned 9 frames (`art-archive/T-227/fall_se/`, records beside them, call log `fall_se_call.log`, request `fall_se_req.json`, also in `game/art/pixellab-generation-log.jsonl`). One round, no regeneration.

Free fix: `game/tools/build_minion_fall_sheets.py` keeps frames 0 to 7 (frame 8 repeats the start pose) and snaps every colour to the nearest colour in the minion's walk sheets (raw had 36 colours, 12 not in the minion's palette, mostly a hot-pink tongue and red-browns; the snap turns the tongue grey-brown). Result `game/art/minion/minion_fall_se.png` (384 x 48): `check_sprite_rules.py` passes all 8 frames (24 to 25 colours, no semi-transparent pixels), and every colour is in the walk sheets. Unit test added (`game/tools/test_build_minion_fall_sheets.py`); game/tools tests: 395 OK. The GUT suite was not run for this sample (no GDScript changed; the hook is T-226's and already loads the sheet).

Judgment (mine, honestly): the frames are the same lizard, same green and shading, and read as falling more than the walk does: legs splayed, tail whipping up, the head and mouth open. But the change between frames is small: it is mostly a leg and tail wiggle, with the body staying level, not a tumble, so at the game's size it reads as a flailing scramble rather than a dramatic fall. Frame 0 and frame 8 are almost the same, so the loop is smooth. In the run the minions that fall facing south-east show it and look right against the wall; minions facing other directions still show T-226's tilted placeholder, so the GIF mixes both. After the snap the open mouth is a dull grey-brown (the pink tongue is gone); the board may want the tongue kept, which would add pink to the minion's palette.

Run recording: `art-archive/T-227/minion_fall_se_sample_in_run_close.gif` (3x close-up) and `minion_fall_se_sample_in_run.gif` (whole view), from T-226's fixture `enemies_drop_gif.tscn` with Godot's movie maker. Review stills: `review_fall_se_row_dark.png` / `_light.png` (raw), `review_fall_se_snapped_dark.png` / `_light.png`, `review_run_close_contact.png`.

Refused: `rm -rf` of the scratch frame folder (guard, thought it might be a ticket) and, once, Godot's non-console exe and a `--headless --import` run of the console exe. Skipped and not retried in another form; I used a new scratch folder and `run_scene_headless.py` (which imports the project) instead, then the console exe for the movie, which was allowed.

Remaining: the other directions (s, e, ne, n) after approval: 4 calls, about 4 generations. Not started.
