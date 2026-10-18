---
id: T-175
title: Art: the neon underglow, the molotov and its fire area, and the windshield wiper in the world (PixelLab)
status: in-qa
from: project-lead
to: asset-generation
lead: Goal-G-002
epic: art
milestone: mvp
goal: G-002
user_facing_text: no
changes_visuals: yes
depends_on: [T-168, T-169, T-170]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/weapons.md, docs/working-with-the-board.md, game/scripts/weapons/neon_underglow.gd, game/scripts/weapons/molotovs.gd, game/scripts/weapons/molotov_fire.gd, game/scripts/weapons/windshield_wiper.gd, tools/pixellab_client.py, tools/check_sprite_rules.py]
files_expected_to_change: [game/art/weapons/, art-archive/, game/scripts/weapons/neon_underglow.gd, game/scripts/weapons/molotovs.gd, game/scripts/weapons/molotov_fire.gd, game/scripts/weapons/windshield_wiper.gd, game/tests/unit/test_pixellab_assets.gd, docs/visual-style.md, game/README.md]
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

The three new weapons were built with placeholders drawn in code (D3, D4, D5). Generate their in-world art with PixelLab and swap it in: the underglow effect under the car, the molotov bottle in flight and its fire area (animated if you propose it), and the wiper. This is a goal run: the goal is the board's go for PixelLab up to its art cap (40 generations, shared with D9), no sample review, one generation round only. Write the planned calls and cost in the result notes before calling, with a 600 s timeout. Follow the Visual style pixel rules (32 art pixels per unit, drawn at scale 0.5, hard edges, no semi-transparent pixels); the placeholders' rule holds for the art too: no Redgull red. Game-ready art in `game/art/` with records; every other generation in `art-archive/<task id>/`.

The board's review: Look at the in-world weapon art in a run with the three weapons owned; judged in the goal's final playtest.

## Acceptance criteria

- [ ] The result notes list the planned calls and their cost before any call, and the total with D9 stays within the goal's art cap; only one generation round was made. (QA: pass / fail)
- [ ] The underglow, the molotov bottle, the fire area and the wiper are in `game/art/` with records, at 32 art pixels per unit, and `tools/check_sprite_rules.py` passes on each. (QA: pass / fail)
- [ ] In a run with the three weapons owned (the `all_weapons_at_start` switch or a fixture), the scripts draw the art at scale 0.5 instead of the placeholders, shown in a screenshot fixture. (QA: pass / fail)
- [ ] The weapon behaviour tests still pass, and every other generation is in `art-archive/<task id>/`; `docs/visual-style.md` records any art decision made. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Blocked → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-175.

### 2026-10-18, In progress → In QA

Goal runner (G-002): the agent is done; QA is checking it.

## Result notes

### Planned calls and cost (written before any call)

Four calls to `/create-image-pixflux`, one round, no regenerations, 600 s HTTP timeout (the client's default), `no_background`. 1 generation each = **4 generations**, within the 35 left under the goal's art cap (D9 shares it). Requests are in `art-archive/T-175/req_<piece>.json`. Raw outputs go to `art-archive/T-175/`; game-ready versions (free script clean-up, `game/tools/build_weapon_art.py`) go to `game/art/weapons/`.

| Piece | Size (art px) | Why this size |
|---|---|---|
| underglow ring | 224 x 112 | the damage circle (2.5 units) seen in iso is 113 x 57 screen px, drawn at 0.5 |
| molotov bottle | 32 x 32 | about 0.3 x 0.6 units |
| molotov fire area | 136 x 68 | the 1.5-unit circle in iso is 68 x 34 screen px |
| wiper arm | 96 x 24, pointing right | 2.5 units long; the script turns it into a 32-direction sheet (flat angle, iso-projected), so the engine never rotates pixel art |

The fire flickers by script (a mirrored second frame, free); no PixelLab animation call.

### Result

- **Generations used: 4** (one round, no regenerations), one log line each in `game/art/pixellab-generation-log.jsonl`. Raw PNGs, records and requests: `art-archive/T-175/`.
- Game-ready art in `game/art/weapons/` with records: `underglow.png` (224x112), `molotov_bottle.png` (32x32), `molotov_fire.png` and `molotov_fire_flip.png` (136x68), `wiper_sheet.png` (2048x512, 32 frames of 256x128). Made by `game/tools/build_weapon_art.py` (free fixes: hard alpha, and flame shades near Redgull's red pushed to orange; no palette cut was needed). `build_weapon_art.py check`: all pass (no semi-transparent pixels, at most 30 colours, transparent corners, no Redgull red). `check_sprite_rules.py --size 32` passes on the bottle (it only checks square frames, so the other pieces use the builder's own check).
- The four scripts draw the art at scale 0.5 (preload; a `load()` inside `_draw` drew white rectangles in the screenshot). The placeholders remain only as a fallback branch. The wiper arm is picked from 32 pre-turned, iso-projected frames; the fire flickers between the art and its mirror (free). The bottle still spins by engine rotation (kept from the placeholder).
- Screenshot fixture `game/tests/fixtures/weapons/weapon_art_demo.tscn` (all five weapons owned): `art-archive/T-175/weapon_art_screenshot.png` (underglow, wiper, bottles in flight) and `weapon_art_screenshot_fire.png` (fire areas).
- Tests: new `game/tests/unit/weapons/test_weapon_art.gd`; full set 959/959.
- Quality notes (not judged by me): the wiper art generated with its pivot in the middle, so only its right half is used, stretched to the 2.5-unit length; it reads thin on screen. The underglow is a filled purple disc with a pink rim rather than a transparent-centre ring, and more purple than cyan. The fire is static apart from the mirror flicker.
- Documents affected, updated: `docs/visual-style.md`, `game/README.md`. Hand-edit: none.
- Refusals: one `python -c` check was refused by a hook (task-status false positive), skipped; a `sed` was not pre-approved, done with the editor instead.
