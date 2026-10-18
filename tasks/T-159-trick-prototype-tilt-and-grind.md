---
id: T-159
title: "Trick prototype: the car tilts with the arrow keys, and wall grinds"
status: cancelled
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, tasks/T-155-trick-prototype-jumps-and-new-tricks.md, tasks/T-157-trick-art-pixellab-rotation.md]
files_expected_to_change: [game/scripts/driving/trick_prototype.gd, game/scripts/driving/trick_flip.gd, game/scripts/driving/trick_obstacles.gd, a new grind script, tests under game/tests/, game/README.md, docs/drifting.md (Content, "Prototypes so far")]
model: opus
qa_rounds: 2
---

## Description

The board's next additions to the trick prototype (Drifting, Decisions, 2026-10-17). Work on a branch made from `playtest/tricks` (it has T-151 to T-157). On this line `game/project.godot` starts the trick prototype for the board's playtest; leave it so (`test_screen_flow.gd::test_the_main_scene_is_the_game_flow` is the one expected failure here).

1. **Live tilt from the arrow keys.** While the car is on the ground and an arrow key is held, the car's drawing tilts slightly toward that key's direction, so the board sees live feedback while it types a sequence. Only the last pressed key that is still held counts; releasing it falls back to the previous still-held key, or none. Directions are relative to the car (they match the tricks: Right rolls right): Up leans the nose down, Down leans the tail down, Left and Right lean the car onto that side. Slight (propose an amount), easing in and out quickly (propose a time). Drawing only: the physics and driving don't change. No tilt in the air or during a grind.
2. **Wall grinds.** When the car lands from any trick close to the edge of a wall (walls primarily: the low walls and the test room's walls; not boulders), it locks into a **grind**:
   - It snaps against the wall's edge and turns to sit across the wall, nearly perpendicular but slightly diagonal (propose an angle, for example 70 degrees to the wall), leaning the way it is travelling.
   - It keeps travelling along the wall in the direction it was going (its speed along the wall when it landed), slowing down steadily as the grind burns its speed (propose the slowdown). When it runs out of wall or speed, it drops off the wall onto the ground on the side it came from.
   - Discrete sparks fly from the contact point while it grinds: small pixel sparks in yellows and oranges (never Redgull red), drawn in code for now, more of them at higher speed.
   - The grind counts as a trick: send `trick_performed("grind")` when it locks in.
   - **Exit:** press **Space** (a new jump key: a small hop off the wall with no trick, the same hop shape as the side flip's, landing beside the wall) or do any arrow trick (it plays as usual and carries the car off the wall). On exit the car keeps the speed and direction it had along the wall.
   - "Close to the edge" is a distance you propose (for example within half a unit of the wall when the hop ends). Landings that aren't close keep the current rule (a jump never ends inside an obstacle).
3. Add a long straight low wall to the prototype, near the start, to grind on.

All new numbers are tunable constants and proposals for the board's playtest. The grind card's text is T-158, shown by T-160: no on-screen text here.

Tests: the tilt follows the last held key and falls back on release, stays off in the air; landing near a wall locks a grind and landing far from one doesn't; boulders don't start grinds; the grind moves along the wall in the landing direction and slows; it ends at the wall's end or at low speed with the car outside the wall; Space and an arrow trick both exit, keeping the speed along the wall; `trick_performed("grind")` fires once per grind; sparks spawn only while grinding.

## Acceptance criteria

- [ ] Tests show the tilt follows the last held arrow key, falls back when it is released, and is off in the air and during a grind; driving is unchanged. (QA: pass)
- [ ] Tests show landing from a trick close to a wall starts a grind, and landing far from walls or next to a boulder doesn't. (QA: pass)
- [ ] Tests show the grind runs along the wall in the landing direction, slows down, and ends with the car outside the wall when the wall or the speed runs out. (QA: pass)
- [ ] Tests show Space and an arrow trick both exit the grind, keeping the car's speed and direction along the wall. (QA: pass)
- [ ] `trick_performed("grind")` fires once per grind; sparks show only while grinding (test plus a screenshot of a grind with sparks). (QA: pass)
- [ ] The prototype has a long low wall to grind on (screenshot). `docs/drifting.md` and `game/README.md` describe the changes. All three test sets pass, apart from the expected main-scene test on this line. (QA: pass)

The board's review: play the tilt and the grinds in the trick prototype, with T-160 (one playtest build).

## Updates

### 2026-10-17, Open → In progress

Started: the car tilts toward the held arrow key on the ground; wall grinds after a trick (sparks, slowing, Space or a trick to exit), on top of the playtest build.

### 2026-10-17, In QA

Built: tilt toward the held arrow key; wall grinds (70 degrees to the wall, slowing 4 units/s each second, sparks, Space or a trick to leave) on a new 30-unit low wall. QA is checking it now.

### 2026-10-17, Needs playtest

QA passed all 6 criteria; goes into the playtest build with the GRIND! card (T-160).

### 2026-10-17, Needs playtest → In progress

Quick tuning: the board says grinding is very hard to start; making it easier.

### 2026-10-17, In progress → In QA

Grinds are easier to start: land up to 1.5 units from the wall (was 0.5), at 1 unit/s along it (was 2), at an angle, on top of the wall (snaps to the edge) or up to 1 unit past its end. In the playtest build now.

## Result notes

Driving & Drift Agent, 2026-10-17. Built on `task/T-159-trick-prototype-tilt-and-grind` (from `playtest/tricks`). The main scene stays the trick prototype.

**Proposed numbers (all tunable constants, for the board's playtest):**
- Tilt (`trick_tilt.gd`): `TILT_ANGLE_DEG` 25 (squash by cos 25 along or across the car), `TILT_SHIFT_PX` 2 drawn px lean, `EASE_TIME` 0.08 s in and out.
- Grind (`trick_grind.gd`): `REACH_UNITS` 1.0 (car centre to the wall's edge at landing, so its side within half a unit), `MIN_START_SPEED` 2 units/s along the wall, `ANGLE_DEG` 70 to the wall, `DECEL` 4 units/s per second (from cruise 11: about 15 units of wall, 2.4 s), `END_SPEED` 1.5 units/s, `DROP_OFF_GAP` 0.8 units (where the car ends up beside the wall).
- Sparks: `SPARK_RATE` 5 per second per unit/s (55/s at cruise), `SPARK_LIFE` 0.3 s, 1 or 2 drawn px, four yellows/oranges.
- Leaving by a jump: `SLIDE_TIME` 0.25 s to slide off the wall during the air (`trick_prototype.gd`). The Space hop is the side flip's hop (0.6 s, 16 px) with no roll.
- The long wall: 1 x 30 units at x 7 to 8, y -20 to 10 (to the right of the start, running the way the car starts).

**What changed:**
- `scripts/driving/trick_tilt.gd` (new): the tilt. `arrow_tricks.gd`: `held_order` and `last_held()` (the last pressed key still held, falling back on release).
- `scripts/driving/trick_grind.gd` (new): finding the wall, the grind, the sparks and their drawing.
- `trick_prototype.gd`: tilt each step (off while any trick plays or during a grind); the grind on `flip.landed` (not after the Space hop, not back onto the wall just left); Space starts the hop while grinding; an arrow trick or the hop launching from a grind releases the car with its speed and direction along the wall and slides it off; the wall left is not a jump-over; `trick_performed("grind")` once per grind.
- `trick_flip.gd`: kind `"hop"` (no roll, plain sprite).
- `car.gd`: `driven_externally` (false by default; when true `physics_step()` only emits `stepped`). Used only by the grind, so driving everywhere else is unchanged.
- `trick_obstacles.gd`: the long wall (`WALLS[GRIND_WALL]`).
- Space works only on a wall. No HUD change (T-160 adds the grind card).
- Known limits: dropping off at the wall's end or at low speed moves the car 0.8 units sideways in one step and turns the nose along the wall at once; the car is still always drawn over the obstacles.

**Tests:** `game/tests/unit/test_trick_tilt_grind.gd` (24 tests). GUT full run: 929 tests, 928 pass; the only failure is the expected `test_screen_flow.gd::test_the_main_scene_is_the_game_flow` on this line. All 145 tests in `-gselect=test_trick` pass (existing trick tests unchanged). Python: `game/tools` 293 OK (1 skipped), `tools` 182 OK.

**Screenshots** (fixture `tests/fixtures/trick_grind_demo.tscn`, `GRIND_DEMO=grind|tilt|wall`), copies in `art-archive/T-159/screenshots/`:
- `T-159_grind_sparks.png`: a grind on the long wall with sparks (frame 50).
- `T-159_tilt_right.png`: the car standing still with Right held, leaning onto its right side (zoomed in).
- `T-159_long_wall.png`: zoomed out over the start, the long wall to the right.

**Documents affected:** `docs/drifting.md` (Content, "Prototypes so far": "Trick prototype, round 3 (task T-159)"), `game/README.md` ("Trick prototype, round 3: tilt and wall grinds (T-159)").
- 2026-10-17, needs-playtest → in-progress: Board, 2026-10-17: grinding is very hard to start; make it a little easier.

**Quick tuning, 2026-10-17 (the board, word for word: "Can you make grinding a little bit easier? It's uh, very hard to do one right now"):**
- `REACH_UNITS` 1.0 -> 2.0 (the car's side within 1.5 units of the wall's edge instead of 0.5).
- `MIN_START_SPEED` 2 -> 1 unit/s along the wall. Only the part of the speed along the wall counts, so landings at an angle to the wall work (tested at 45 degrees).
- Landing on top of the wall now grinds: while a trick is over a grind wall and would grind there, the landing is no longer held in the air; the car lands and snaps onto the nearer edge. Boulders, the wall just left and a car crossing straight over a wall still hold as before (no grind).
- New `END_MARGIN` 1.0: a landing up to a unit past a wall's end starts the grind at that end.
- Checked: a nose pop beside the long wall lands into a grind.
- Still not automatic: crossing a wall straight on, landing more than 1.5 units from it, or moving slower than 1 unit/s along it does not grind.
- Tests: 6 new or changed in `test_trick_tilt_grind.gd` (thresholds, on top, angled, past the end, nose pop, straight across still no grind). GUT full run 935 tests, 934 pass (the expected main-scene failure only). Docs updated: `docs/drifting.md`, `game/README.md`.
- 2026-10-17, in-progress → in-qa: Ready for the board to play (quick tuning: easier grinds); no QA agent until the end.
- 2026-10-19, in-qa → cancelled: Board, 2026-10-19: building the trick prototype before an elevation system was a mistake. Not merged; kept as the reference for rebuilding the tricks on real height (Drifting, Content, 'Trick prototype (reference)'); code on the branch hold/trick-prototype, art in art-archive/.
