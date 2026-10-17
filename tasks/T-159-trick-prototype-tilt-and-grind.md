---
id: T-159
title: "Trick prototype: the car tilts with the arrow keys, and wall grinds"
status: open
from: project-lead
to: driving-drift
lead: Tricks
epic: driving
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, tasks/T-155-trick-prototype-jumps-and-new-tricks.md, tasks/T-157-trick-art-pixellab-rotation.md]
files_expected_to_change: [game/scripts/driving/trick_prototype.gd, game/scripts/driving/trick_flip.gd, game/scripts/driving/trick_obstacles.gd, a new grind script, tests under game/tests/, game/README.md, docs/drifting.md (Content, "Prototypes so far")]
model: opus
qa_rounds: 0
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

- [ ] Tests show the tilt follows the last held arrow key, falls back when it is released, and is off in the air and during a grind; driving is unchanged. (QA: pass / fail)
- [ ] Tests show landing from a trick close to a wall starts a grind, and landing far from walls or next to a boulder doesn't. (QA: pass / fail)
- [ ] Tests show the grind runs along the wall in the landing direction, slows down, and ends with the car outside the wall when the wall or the speed runs out. (QA: pass / fail)
- [ ] Tests show Space and an arrow trick both exit the grind, keeping the car's speed and direction along the wall. (QA: pass / fail)
- [ ] `trick_performed("grind")` fires once per grind; sparks show only while grinding (test plus a screenshot of a grind with sparks). (QA: pass / fail)
- [ ] The prototype has a long low wall to grind on (screenshot). `docs/drifting.md` and `game/README.md` describe the changes. All three test sets pass, apart from the expected main-scene test on this line. (QA: pass / fail)

The board's review: play the tilt and the grinds in the trick prototype, with T-160 (one playtest build).

## Updates

## Result notes
