---
id: T-199
title: Elevation sample map: final documentation and the final screenshot set
status: in-progress
from: project-lead
to: level-challenge
lead: Goal-G-004
epic: level-challenges
milestone: mvp
goal: G-004
user_facing_text: no
changes_visuals: no
depends_on: [T-195, T-197, T-198]
documents_affected: [docs/level-design.md, docs/visual-style.md, docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/drifting.md, game/README.md, tools/screenshot.sh]
files_expected_to_change: [docs/level-design.md, docs/visual-style.md, docs/drifting.md, game/README.md, art-archive/<task id>/screenshots/]
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

The last step of the elevation sample map (Level design, Decisions, 'Elevation sample map'). With the layout (D2), the car's height (D3), the scene (D4), the depth order (D5) and the art (D6) merged into the goal's build, check that the documents describe what was built, and take the final screenshot set.

- docs/level-design.md, Content, 'Elevation sample map': the height data fields, the layout (with the overview picture), the scene, how to open it, depth order and see-through. docs/visual-style.md: the art results (generations used, weak results). docs/drifting.md: the three-layer behaviour and the scripted drive. game/README.md: the data format, the build scripts, the validator, the scene's run command and the scripted drive. Every number and layout choice is marked as a proposal for the board's playtest. Fix only what is wrong or missing; don't repeat a decision in two documents, point to the one that holds it.
- Run the scripted reachability drive (game/tools/drive_elevation_sample.sh) on the merged build and paste its log (layers reached, maximum height, airtime) in the result notes.
- The final screenshot set with the final art, in art-archive/<task id>/screenshots/: the car on the street, on a 0-to-3 ramp, on a 3-to-6 ramp, on height 3, on height 6, in the air with its shadow below, behind a see-through height-3 area and a height-6 area, and an overview of the city. List the full Windows paths in the result notes for the board.
- List the open questions left for the board (how it opens the scene, layout choices, anything the docs didn't answer) in the result notes.
No code changes in this ticket.

## Acceptance criteria

- [ ] docs/level-design.md (Content, 'Elevation sample map'), docs/visual-style.md (the art results), docs/drifting.md and game/README.md describe the height data, layout, scene, run command, scripted drive and art as built, with every number and layout choice marked as a proposal. (QA: pass / fail)
- [ ] The scripted reachability drive's log (layers 0, 3 and 6 reached, maximum height, airtime) from the merged build is pasted in the result notes. (QA: pass / fail)
- [ ] The final screenshot set is in art-archive/<task id>/screenshots/ (street, 0-to-3 ramp, 3-to-6 ramp, height 3, height 6, in the air with the shadow, see-through height-3 and height-6 areas, city overview), and the result notes list their full Windows paths. (QA: pass / fail)
- [ ] The result notes list the open questions for the board. (QA: pass / fail)
- [ ] `git diff` of this ticket's branch touches only docs, game/README.md and art-archive/ files. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-20, Blocked → In progress

Goal runner (G-004): started, in C:\solid-carbide-worktrees\T-199.

## Result notes

Written by the agent when it finishes.
