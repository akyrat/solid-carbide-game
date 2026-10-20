---
id: T-204
title: Art: the car's 16 frames without their drop shadow (free script)
status: open
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
goal: G-004
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/drifting.md, game/README.md, game/art/car/car_iso.png, game/art/car/car_iso.json, tasks/T-014-car-sprites-16-directions.md]
files_expected_to_change: [game/tools/build_car_noshadow.py, game/tools/test_build_car_noshadow.py, game/art/car/car_iso_noshadow.png, game/art/car/car_iso_noshadow.json, art-archive/T-204/, game/README.md, docs/visual-style.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

The board saw, in the elevation sample map's screenshots, that the car in the air shows two shadows: the round shadow on the ground and the drop shadow drawn into the car's own sprite, which travels up with it (board, 2026-10-20). In the air the car must be drawn without it (Drifting, Decisions, "No sprite shadow in the air"; Visual style, Decisions, "The car without its shadow").

Make a shadowless copy of the car's 16-direction sheet with a free script, no PixelLab: `game/tools/build_car_noshadow.py` reads `game/art/car/car_iso.png` (and its record) and writes `game/art/car/car_iso_noshadow.png` with the same size, frames, centre and record fields, removing only the drop-shadow pixels outside the car's body and leaving every other pixel exactly as it is. The shadow shares its near-black with the car's outline: tell them apart by where they are (the shadow lies outside the car's silhouette, mostly down and to the right of the wheels and body), not by colour alone; an earlier hand-tried script edit (T-014) left marks, so check every frame. Running the script again gives a byte-identical file. The original sheet is not changed.

Screenshots (`tasks/README.md`, "Screenshots"), in `art-archive/T-204/screenshots/`: all 16 frames, original and shadowless side by side, enlarged with nearest-neighbour, on a dark and on a light background. Note any frame where the result is doubtful.

This ticket only makes the art; T-205 uses it in the air.

The board's review: All 16 frames side by side, original and shadowless, judged in the elevation sample map's playtest (goal G-004).
Board review files: art-archive/T-204/screenshots/

## Acceptance criteria

- [ ] `game/art/car/car_iso_noshadow.png` exists with the same size and frame layout as `car_iso.png`, a record `car_iso_noshadow.json` with the same frame fields, and `car_iso.png` is unchanged (QA: pass / fail)
- [ ] Tests (`game/tools/test_build_car_noshadow.py`, standard-library Python plus the tools the other art scripts use) show the script is byte-identical on a rerun, removes only pixels outside the car's silhouette, keeps every other pixel equal to the original, and leaves no new colours (QA: pass / fail)
- [ ] `python -m unittest discover -s game/tools -p "test_*.py"` and `bash game/tools/run_tests.sh` pass (QA: pass / fail)
- [ ] Screenshots in `art-archive/T-204/screenshots/` show all 16 frames, original and shadowless side by side, on dark and light backgrounds, listed in the result notes with any doubtful frames named (QA: pass / fail)
- [ ] `game/README.md` and `docs/visual-style.md` say how the sheet is made and where it is used (QA: pass / fail)

## Updates

## Result notes
