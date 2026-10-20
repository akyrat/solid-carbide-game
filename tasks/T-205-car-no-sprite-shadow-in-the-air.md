---
id: T-205
title: The car is drawn without its sprite shadow while in the air
status: blocked
from: project-lead
to: driving-drift
lead:
epic: driving
milestone: mvp
goal: G-004
user_facing_text: no
changes_visuals: yes
depends_on: [T-204]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/scripts/driving/car_sprite.gd, game/art/car/car_iso_noshadow.json]
files_expected_to_change: [game/scripts/driving/car_sprite.gd, game/tests/unit/, game/README.md, docs/drifting.md, art-archive/T-205/screenshots/]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

Uses T-204's shadowless car sheet (Drifting, Decisions, "No sprite shadow in the air"; board, 2026-10-20): while the car is in the air (its height above the ground under it is more than zero, in the elevation scenes), it is drawn from `game/art/car/car_iso_noshadow.png` instead of `car_iso.png`, same frame for its heading; on the ground it uses `car_iso.png` as now. Only the drawing changes. The round shadow, the depth order and the see-through stay as they are. Everywhere the car never leaves the ground (the run, the drift prototype) nothing changes.

This branch starts from T-204's branch (it needs its art) and is merged into the elevation sample map's build (`playtest/G-004`) with it, before the board's playtest.

Screenshots (`tasks/README.md`, "Screenshots"), in `art-archive/T-205/screenshots/`: the car in the air off a rooftop in the elevation sample map (one shadow only, the round one), and the car on the street (its sprite shadow as before); a short GIF of a jump if a still doesn't show the switch at takeoff and landing.

The board's review: Jump off a rooftop in the elevation sample map: one shadow in the air, the sprite's own on the ground.
Board review files: art-archive/T-205/screenshots/

## Acceptance criteria

- [ ] A GUT test shows the car's drawing uses the shadowless sheet whenever its height is above the ground under it and the normal sheet on the ground, with the same frame for the same heading, and that the switch happens on the step it takes off and the step it lands (QA: pass / fail)
- [ ] A GUT test shows the run's car and the drift prototype's car always use the normal sheet (QA: pass / fail)
- [ ] The full GUT suite passes (`bash game/tools/run_tests.sh`) (QA: pass / fail)
- [ ] Screenshots in `art-archive/T-205/screenshots/` show the car in the air with only the round shadow and on the street with its sprite shadow, listed in the result notes (QA: pass / fail)
- [ ] `docs/drifting.md` (Content, elevation) and `game/README.md` describe the switch (QA: pass / fail)

## Updates

## Result notes
