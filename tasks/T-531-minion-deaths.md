---
id: T-531
title: Minion deaths: death animation (code placeholder), physics green spill, knockable corpses that fade 2 s after their last hit
status: in-qa
from: project-lead
to: enemy-behavior
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/enemies.md]
files_to_read_first: [docs/enemies.md, docs/visual-style.md, game/docs/enemies/minions.md, game/data/enemies.json, tasks/README.md]
files_expected_to_change: [game/scripts/enemies/, game/scripts/weapons/, game/data/enemies.json, game/tests/, game/docs/enemies/minions.md, docs/enemies.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Build docs/enemies.md, Decisions, "Minion deaths". When a minion dies: (1) it plays a death animation; until T-532's PixelLab frames exist, a placeholder drawn in code from its current sprite and facing (for example it tips over and flattens), built so T-532 can swap frames in by dropping sheets in game/art/minion/ (document the file names and frame layout T-532 must deliver). (2) It spills a pixelated green liquid, drawn in code, physics simulated: droplets burst out with some velocity, fall under gravity in the isometric view, land and spread into small pools that follow the ground's height (rooftops and ramps included); hard-edged pixels, no engine blur, a slimy alien green of its own clear of Greenbull's brand greens (Visual style). (3) Its corpse stays as a body that the car knocks back when it drives into it, and that the knockback weapons' hits push too (the bricks wave, the wiper, the Polarized Steering Wheel's shock; say in the result notes whether others do and why). Every hit restarts a 2 s timer; when it runs out the corpse and its liquid fade out and are freed. A corpse never damages the car, is never targeted by weapons' aiming, doesn't count as a kill again, and doesn't block minions' paths in a way that traps them. Coins and health drops stay as today (dropped at death). Numbers in game/data/enemies.json (`minion` > a new `death` block), each a proposal with a reason: knockback strength per source, corpse friction, droplet count and speeds, pool size and lifetime, the fade time (2 s, the board's), and safety caps on live corpses and droplets (oldest fade first) so a big crowd doesn't slow the game. Measure with the perf recorder (game/docs/game-loop/perf-recorder.md, the headless run if there is one) with many minions dying at once and report frame times before and after in the result notes. Document in game/docs/enemies/minions.md and docs/enemies.md Content. Screenshots: a death mid-animation with its spill, corpses being knocked, and a field of corpses fading.

The board, 2026-11-03: docs/enemies.md, Decisions, "Minion deaths: an animation, a green spill, corpses that can be knocked about", and docs/visual-style.md, Decisions, "The minion's death animation and green spill". The board plays the functional build (T-531, code placeholder animation) and reviews the art sample (T-532) before anything merges or reaches itch.io. No new player-facing text. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). Godot: the worktree has no .env; give GODOT_BIN from C:\solid-carbide-game\.env (CR and quotes stripped) to one command at a time, with no `export VAR=$(...)` and no `timeout` wrapper, never copy .env; don't leave Godot processes running (if one hangs, tell the Project Lead, don't kill it). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A dying minion plays the placeholder death animation in its facing, then lies as a corpse (test of the state sequence). (QA: pass)
- [ ] The spill's droplets move under physics and settle into pools at the ground's height, including on a rooftop (test with a rooftop death). (QA: pass)
- [ ] The car and the bricks wave, wiper and wheel shock knock corpses back; each hit restarts the 2 s timer; after 2 s with no hit the corpse fades and is freed (tests). (QA: pass)
- [ ] A corpse never damages the car, is never a weapon target and never counts as a second kill (tests). (QA: pass)
- [ ] The caps on live corpses and droplets hold under a mass death (test), and the result notes give perf recorder frame times before and after. (QA: pass)
- [ ] The frame layout T-532's art must deliver is written in game/docs/enemies/minions.md. (QA: pass)
- [ ] docs/enemies.md Content and game/docs/enemies/minions.md describe it; the numbers are in enemies.json with reasons. (QA: pass)
- [ ] The Godot test set passes. (QA: pass)
- [ ] Screenshots in art-archive/T-531/screenshots/. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-03, Open → In progress

Enemy agent: death animation placeholder, physics green spill, knockable corpses.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built. Corpse keeper (minion_corpses.gd), spill (minion_spill.gd), Minion corpse state, sprite death animation (code placeholder; art hook + frame layout in game/docs/enemies/minions.md 'Death': minion_death_{e,se,s,ne,n}.png, 8 frames 48x48 in a row, last frame = lying corpse). Numbers + reasons in enemies.json minion.death. Knockers: car (speed-scaled), bricks wave, wiper, Polarized wheel shock (via Bricks). Not the underglow (its ticks would pin corpses; open question in docs/enemies.md), gun/flame/molotov don't knock back. Caps: 24 whole corpses (oldest fades), 48 total, 80 droplets, 160 pools. Tests: tests/unit/enemies/test_minion_deaths.gd (23 pass); test_minions.gd's 'removed' assertion updated (corpse freed after fade). Full Godot set: 2761 tests, only my own one failed on first run (tolerance), fixed, rerun of that file passes. PERF: perf_sample_run (all weapons, from 2:00, 60 s, no vsync): corpses off mean 2.27 ms p99 8.79 max 21.5; on mean 2.16 p99 8.79 max 24.2 (weapons kill too few at once to matter; <=43 minions alive). Stress tools/corpse_bench.sh (kills 10 every 0.5 s with a 70-minion crowd, caps reached): corpse keeper step avg 0.4 ms, p99 1.4 ms; headless physics A/B is order-noisy (+-1.5 ms), so no clear loss. Screenshots: art-archive/T-531/screenshots (tools/death_shots.gd). Tools added: corpse_bench, death_shots, perf_sample_run --no-corpses. Note: Godot tests need GODOT_BIN since worktree has no .env.
