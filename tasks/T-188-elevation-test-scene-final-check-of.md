---
id: T-188
title: Elevation test scene: final check of its documentation in Drifting, Level design and the game README
status: in-progress
from: project-lead
to: driving-drift
lead: Goal-G-003
epic: driving
milestone: mvp
goal: G-003
user_facing_text: no
changes_visuals: no
depends_on: [T-182, T-183, T-184, T-185, T-186, T-187]
documents_affected: [docs/drifting.md, docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/level-design.md, game/README.md, game/data/level/elevation_test.json, game/scripts/driving/car_height.gd, game/scripts/level/ground_height.gd, game/scripts/driving/elevation_test.gd]
files_expected_to_change: [docs/drifting.md, docs/level-design.md, game/README.md]
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

Documentation only. Once the elevation test scene is built (ground data, the car's height, the edges, the drawing, the art and the bigger-when-high option), bring its documentation together so it matches the final build, each decision written once and the others pointing to it:

- docs/drifting.md, Content, 'Elevation test scene': where the scene is, how to run it, what the car's height does (on the ground, takeoff, gravity, landing, the edges, the bigger-when-high option), every proposed number marked as a proposal for the board's playtest, pointing to game/README.md for code details.
- docs/level-design.md, Content: the test platform, ramp and drop-off edges and the height data format, pointing to game/README.md for the file's fields.
- game/README.md, 'Elevation test scene': the scene's path, how to run it, its data format, the code's main functions (ground-height query, car height model, drawing, shadow, scale switch) and the proposed numbers.

Check each number written in the docs against the code and data, and correct the docs where they differ. No game code changes.

## Acceptance criteria

- [ ] docs/drifting.md, Content, has an 'Elevation test scene' section with the scene's path, how to run it, what the car's height does, and every proposed number marked as a proposal. (QA: pass / fail)
- [ ] docs/level-design.md, Content, describes the test platform, ramp and drop-off edges and the height data format. (QA: pass / fail)
- [ ] game/README.md has the scene's path, how to run it, its data format and the code's main functions. (QA: pass / fail)
- [ ] Every number in those sections matches the code or data (gravity, takeoff, platform and ramp sizes and heights, the scale switch's value). (QA: pass / fail)
- [ ] No file under `game/` other than `game/README.md` changes; the full GUT suite still passes headless. (QA: pass / fail)
- [ ] The docs staleness check (`python tools/check_docs_staleness.py` or the project's equivalent) passes after the long GDD is regenerated. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-19, Blocked → In progress

Goal runner (G-003): started, in C:\solid-carbide-worktrees\T-188.

## Result notes

Checked every number in the three 'Elevation test scene' sections against `car_height.gd`, `elevation_test.gd`, `car_shadow.gd` and `elevation_test.json`. All match: gravity 12, takeoff minimum speed 4, takeoff factor 1, curb step 0.1, sample step 0.05, platform 16 x 16 at (-8, -8) and 3 high, ramp 12 x 8 at (8, -4) from 0 to 3, start (26, 0) facing west, shadow 3.2 x 1.2, 16 px per unit, bigger-when-high 0.05 per unit.

Gaps fixed:
- `docs/drifting.md`: the task range now reads T-182 to T-187. The 'Placeholders' bullet said the platform and ramp are drawn by script only. It is now a T-186 PixelLab art bullet, with the two final-art screenshots, plus a bullet saying the script drawing is the fallback.
- `docs/level-design.md`: the ramp's position and a pointer to the art in Drifting, Content.
- `game/README.md`: the section's intro now lists T-186 and T-187.

No game code changed.

Not run, because the project settings don't pre-approve them: the GUT suite and `tools/generate_long_gdd.py` with the staleness check. The goal runner regenerates the long GDD itself. Only docs changed, so the GUT suite is unaffected.
