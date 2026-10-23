---
id: T-274
title: The neon underglow drawn in code instead of the generated sprite
status: needs-playtest
from: project-lead
to: weapon-behavior
lead: Coursework
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/weapons.md, game/README.md, game/data/weapons.json, tasks/T-168-the-neon-underglow-a-circle-around.md, tasks/T-175-art-the-neon-underglow-the-molotov.md, tasks/T-225-underglow-at-the-cars-height.md, tasks/T-249-hype-drift-trail.md]
files_expected_to_change: [game/scripts/weapons/, game/scenes/weapons/, game/tests/, docs/visual-style.md, game/README.md, art-archive/T-274/screenshots/]
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

The board's decision (Visual style, Decisions, "The neon underglow drawn in code", 2026-10-22): replace the generated underglow sprite (T-175) with a neon zone drawn in code, as the drift marks and hype trail (T-249) and the burning likes bar are. It marks exactly the underglow's damage circle (its radius at every tier, in the isometric view), sits under the car at the car's height (T-225), and reads as neon light on the ground: for example a bright neon ring at the edge, a fainter inner ring or floor glow, a slow pulse and a shimmer travelling round it (your proposal for the playtest). Pixel-art rules: hard pixel edges, glow as bright pixels with stepped halos, no engine blur, bloom or semi-transparent smoothing; the underglow's purple and pink; never Redgull red. Keep its look's settings (colours, ring widths, pulse speed) in one scene or resource so the board can retune. It stops moving while paused. The damage, timing and radius numbers are unchanged. Keep the T-175 sprite in `game/art/` (never delete art) with a switch back to it.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the zone at tier 1 and tier 8 (on the street and on a rooftop) and a short GIF of it pulsing round minions.

## Acceptance criteria

- [ ] Tests show the drawn zone's radius matches the damage circle at every tier and it is drawn at the car's height; damage behaviour is unchanged (QA: pass; tier 1-8 ring-vs-circle test, car-height test, diff touches only drawing code, damage tests pass)
- [ ] The look follows the pixel rules (no semi-transparent smoothing; colours from its settings; no Redgull red) and pauses with the game (tests and screenshots) (QA: pass; opaque-pixel, look-colour, no-red and paused-freeze tests pass; screenshot shows hard-edged purple/pink ring)
- [ ] The T-175 sprite is kept with a switch back to it (QA: pass; underglow.png untouched, use_sprite switch and its test)
- [ ] Screenshots and the GIF are in `art-archive/T-274/screenshots/`; Visual style and `game/README.md` describe the look; the full GUT suite and all Python tool tests pass (QA: pass; 4 PNGs + GIF present, docs updated, GUT passed, tools 451 OK, game/tools 395 OK)

The board's review: pick up the underglow and drive through minions.
Board review files: the screenshots and GIF in `art-archive/T-274/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's request: the neon zone drawn in code instead of the sprite.

### 2026-10-23, In progress → In QA

Underglow drawn in code: pixel neon ring, dithered halo and floor glow, pulse and shimmer; settings in one .tres; old sprite kept with a switch. Sent to QA.

### 2026-10-23, Needs playtest

QA passed all 4. Ready to play in the game build: underglow drawn in code; tier 8's inside looks mostly empty, a likely retune.

## Result notes

Weapon Behavior Agent (the look is a proposal for the playtest):

- The zone is drawn in code: `game/scripts/weapons/underglow_glow.gd` builds an image pixel by pixel (opaque or empty pixels, nearest filter, no blur). On the damage circle's edge: a light pink core line and a hot pink line inside it; outside, a stepped purple halo (solid band, then checker-dithered); inside, a purple floor glow (half-dithered, then sparse). The halo and floor glow pulse in two steps (2 pulses per 2 s cycle) and a lighter arc travels once round the ring per cycle. It runs in `_process`, so it stops while paused. Images are cached per radius and frame (24 frames at 12 per second).
- Every colour, width and speed: `game/scenes/weapons/neon_underglow_look.tres` (script `underglow_look.gd`). No Redgull red.
- Switch back to the T-175 sprite: `use_sprite` on that resource. The sprite `game/art/weapons/underglow.png` is untouched. Damage, timing and radius code is unchanged; the zone is still placed at the car's height (T-225) as the first child of the View.
- Tests: `test_neon_underglow.gd` (ring pixels lie exactly inside the damage circle at all 8 tiers, opaque pixels only and only the look's colours, no red, pulse and shimmer loop, frozen while paused, sprite kept with its switch) and `test_weapon_art.gd`. Full GUT suite passes; `game/tools` Python tests 395 OK (1 skipped); `tools` Python tests 451 OK.
- Screenshots and GIF in `art-archive/T-274/screenshots/`: `underglow_street_t1.png`, `underglow_street_t8.png`, `underglow_roof_t1.png`, `underglow_roof_t8.png`, `underglow_pulse_minions.gif` (fixtures `game/tests/fixtures/run_underglow_look_*.tscn`). Looked at them: ring and halo read as neon on the street and the rooftop; at tier 8 the inside is mostly empty (fixed widths), a candidate to retune.
- Documents affected: `docs/visual-style.md` (Content, "The neon underglow in code"), `game/README.md` ("The neon underglow"). No PixelLab calls.
