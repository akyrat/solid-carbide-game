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
model: opus
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

The last step of the elevation sample map (Level design, Decisions, 'Elevation sample map'). With the layout (D2), the car's height (D3), the scene (D4), the depth order (D5) and the art (D6) merged into the goal's build, check that the documents describe what was built, and take the final screenshot set.

- docs/level-design.md, Content, 'Elevation sample map': the height data fields, the layout (with the overview picture), the scene, how to open it, depth order and see-through. docs/visual-style.md: the art results (generations used, weak results). docs/drifting.md: the three-layer behaviour and the scripted drive. game/README.md: the data format, the build scripts, the validator, the scene's run command and the scripted drive. Every number and layout choice is marked as a proposal for the board's playtest. Fix only what is wrong or missing; don't repeat a decision in two documents, point to the one that holds it.
- Run the scripted reachability drive (game/tools/drive_elevation_sample.sh) on the merged build and paste its log (layers reached, maximum height, airtime) in the result notes.
- The final screenshot set with the final art, in art-archive/<task id>/screenshots/: the car on the street, on a 0-to-3 ramp, on a 3-to-6 ramp, on height 3, on height 6, in the air with its shadow below, behind a see-through height-3 area and a height-6 area, and an overview of the city. List the full Windows paths in the result notes for the board.
- List the open questions left for the board (how it opens the scene, layout choices, anything the docs didn't answer) in the result notes.
No code changes in this ticket.

## Acceptance criteria

- [ ] docs/level-design.md (Content, 'Elevation sample map'), docs/visual-style.md (the art results), docs/drifting.md and game/README.md describe the height data, layout, scene, run command, scripted drive and art as built, with every number and layout choice marked as a proposal. (QA: pass: the four docs describe the data, layout, scene, run command, drive and art, proposals marked; level-design gained pointers only)
- [ ] The scripted reachability drive's log (layers 0, 3 and 6 reached, maximum height, airtime) from the merged build is pasted in the result notes. (QA: fail: the pasted log is T-195's, not from the merged build; QA's own run of drive_elevation_sample.sh was also refused, so it could not be rerun)
- [ ] The final screenshot set is in art-archive/<task id>/screenshots/ (street, 0-to-3 ramp, 3-to-6 ramp, height 3, height 6, in the air with the shadow, see-through height-3 and height-6 areas, city overview), and the result notes list their full Windows paths. (QA: pass: all 9 PNGs present; notes give the folder's full path and abbreviate the rest with "...", and note weak air shadow and off-centre overview)
- [ ] The result notes list the open questions for the board. (QA: pass)
- [ ] `git diff` of this ticket's branch touches only docs, game/README.md and art-archive/ files. (QA: pass: the ticket's own commits touch only docs/level-design.md, art-archive/T-199 and the task file; the untracked temp fixture is uncommitted and must be deleted before merge)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-20, Blocked → In progress

Goal runner (G-004): started, in C:\solid-carbide-worktrees\T-199.

### 2026-10-20, In progress → In QA

Goal runner (G-004): the agent is done; QA is checking it.

### 2026-10-20, In QA → In progress

Goal runner (G-004): failed QA once; back to the agent on opus.

## Result notes

**Docs.** Checked level-design, visual-style, drifting and game/README against the merged build: the height data, layout, scene, depth order, see-through, art (8 generations of 50, weak results noted) and scripted drive were already described and marked as proposals. Only gap fixed: docs/level-design.md now has the art, the scripted drive and the final screenshot set (pointers, no repeated decisions). visual-style.md, drifting.md, game/README.md needed no change.

**Scripted drive log.** I could not run `bash game/tools/drive_elevation_sample.sh` in this ticket: it is not on the pre-approved list and was refused. The last log of the same drive, from T-195 (the merged build changed only art and depth order since; the drive is physics only), pasted from tasks/T-195:
```
Layers reached, in order: 0 at 0.00 s, 3 at 1.82 s, 6 at 5.30 s, 0 at 7.32 s
Jump 1, off a ramp's top at 1.10 s: from height 3.08, max height 3.75, airtime 0.70 s, landed on height 3.0
Jump 2, off a ramp's top at 4.52 s: from height 6.04, max height 6.89, airtime 0.76 s, landed on height 6.0
Jump 3, off the height-6 edge at 6.30 s: from height 6.00, airtime 1.00 s, landed on the street (0)
Maximum height: 6.89 units, at 4.92 s
```
QA or the board should rerun the .sh on the merged build.

**Screenshots** (final art, from the existing elevation_sample fixtures with game/tools/screenshot.sh; the overview from a temporary fixture with zoom 150 centred on (0,0)):
- C:\solid-carbide-worktrees\T-199\art-archive\T-199\screenshots\street.png
- ...\ramp-0-3.png, ...\ramp-3-6.png, ...\height-3.png, ...\height-6.png, ...\air.png, ...\behind-height-3.png, ...\behind-height-6.png, ...\city-overview.png (same folder)
Weak: in air.png the car's shadow is not clearly visible (it falls on the rooftop under the car); the overview is off-centre by the camera follow offset.

**Left in the worktree, not committed:** an untracked temporary fixture game/tests/fixtures/elevation_sample_overview_tmp.tscn, and Godot's .import line-ending noise under game/; deleting/reverting them was refused (not pre-approved). Delete the fixture and `git checkout -- game` before merging.

**Open questions for the board:** (1) How it opens the scene (proposed: editor + F6, or the run command; no menu button). (2) Layout choices: two garages (NW and SE), start at (-81,-50), 12-unit ramps 10 wide, 4 buildings and 8 boulders left out. (3) Whether the overview needs a dedicated fixture or a scene option. (4) Whether the car shadow in the air reads well enough.

Refusals: the drive script run; removing the temporary fixture and reverting .import noise.
- 2026-10-20, in-qa → in-progress: QA failed: The scripted reachability drive's log (layers 0, 3 and 6 reached, maximum height, airtime) from the merged build is pasted in the result notes. (QA: fail: the pasted log is T-195's, not from the merged build; QA's own run of drive_elevation_sample.sh was also refused, so it could not be rerun) Back to the agent on opus.
