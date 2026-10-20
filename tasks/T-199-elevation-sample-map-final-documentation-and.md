---
id: T-199
title: Elevation sample map: final documentation and the final screenshot set
status: in-qa
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
- [ ] The scripted reachability drive's log (layers 0, 3 and 6 reached, maximum height, airtime) from the merged build is pasted in the result notes. (QA: fail: the pasted log is T-195's, not from the merged build; QA's own run of drive_elevation_sample.sh was also refused, so it could not be rerun) (QA round 2: pass: the pasted log is the drive test's output on this branch, which has T-193 to T-198 merged; QA reran test_drive_elevation_sample, 4/4 passed, and the log is identical: layers 0, 3, 6, max height 6.89, airtime 1.00 s. The .sh itself was not run, same code)
- [ ] The final screenshot set is in art-archive/<task id>/screenshots/ (street, 0-to-3 ramp, 3-to-6 ramp, height 3, height 6, in the air with the shadow, see-through height-3 and height-6 areas, city overview), and the result notes list their full Windows paths. (QA: pass: all 9 PNGs present; notes give the folder's full path and abbreviate the rest with "...", and note weak air shadow and off-centre overview) (QA round 2: pass: all 9 full Windows paths now listed; 9 PNGs present)
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

### 2026-10-20, In progress → In QA

Goal runner (G-004): the agent is done; QA is checking it.

## Result notes

**Docs.** Checked level-design, visual-style, drifting and game/README against the merged build: the height data, layout, scene, depth order, see-through, art (8 generations of 50, weak results noted) and scripted drive were already described and marked as proposals. Only gap fixed: docs/level-design.md now has the art, the scripted drive and the final screenshot set (pointers, no repeated decisions). visual-style.md, drifting.md, game/README.md needed no change.

**Scripted drive log (round 2, from the merged build).** `bash game/tools/drive_elevation_sample.sh` was refused again (not pre-approved). The same drive (the same `tools/drive_elevation_sample.gd` code, `Drive.plan` + `Drive.drive` + `Drive.log_lines` on the real `elevation_sample_map.tscn`) is run by the unit test `tests/unit/test_drive_elevation_sample.gd`, which prints the log. I ran it with the pre-approved test runner on this branch, which holds the goal's build with T-195, T-196, T-197 and T-198 merged (HEAD's parent chain includes `798dbbb Merge task/T-198... into playtest/G-004`): `bash game/tools/run_tests.sh -gselect=test_drive_elevation_sample -glog=3` → 4/4 passed, 31 asserts. The log it printed:
```
Elevation sample drive (T-195): from the street (-81.0, -50.0) up ramp-nw-0-3 onto roof-nw-3, up ramp-nw-3-6 onto roof-nw-6, then off its edge
Layers reached, in order: 0 at 0.00 s, 3 at 1.82 s, 6 at 5.30 s, 0 at 7.32 s
Waypoints: the 0-to-3 ramp's foot 0.22 s; on the height-3 rooftop 1.20 s; the run-up to the 3-to-6 ramp 3.18 s; the 3-to-6 ramp's foot 3.74 s; the 3-to-6 ramp's top 4.54 s; the height-6 edge 6.26 s; past the edge 7.08 s
Jump 1, off a ramp's top at 1.10 s: from height 3.08, takeoff vertical speed 4.13 units/s, max height 3.75, airtime 0.70 s, landed on height 3.0 at 1.80 s (impact -4.28 units/s)
Jump 2, off a ramp's top at 4.52 s: from height 6.04, takeoff vertical speed 4.62 units/s, max height 6.89, airtime 0.76 s, landed on height 6.0 at 5.28 s (impact -4.50 units/s)
Jump 3, off the height-6 edge at 6.30 s: from height 6.00, takeoff vertical speed 0.00 units/s, max height 6.00, airtime 1.00 s, landed on the street (0) at 7.30 s (impact -12.00 units/s)
Maximum height: 6.89 units, at 4.92 s
Airtime of the jump off the height-6 edge: 1.00 s
Wall and obstacle hits: 0
Ended at (6.4, -82.3), height 0.00, after 7.82 s
PASS: the street, height 3 and height 6 reached, and the car landed off the height-6 edge
```
Same numbers as T-195's run: the art and depth-order work since did not change the drive. The .sh itself (it adds only the optional CSV and plot files) still needs a rerun by someone allowed to run it, if wanted.

**Screenshots** (final art, from the existing elevation_sample fixtures with game/tools/screenshot.sh; the overview from a temporary fixture with zoom 150 centred on (0,0)):
- C:\solid-carbide-worktrees\T-199\art-archive\T-199\screenshots\street.png (the car on the street)
- C:\solid-carbide-worktrees\T-199\art-archive\T-199\screenshots\ramp-0-3.png (on a 0-to-3 ramp)
- C:\solid-carbide-worktrees\T-199\art-archive\T-199\screenshots\ramp-3-6.png (on a 3-to-6 ramp)
- C:\solid-carbide-worktrees\T-199\art-archive\T-199\screenshots\height-3.png (on height 3)
- C:\solid-carbide-worktrees\T-199\art-archive\T-199\screenshots\height-6.png (on height 6)
- C:\solid-carbide-worktrees\T-199\art-archive\T-199\screenshots\air.png (in the air, with its shadow)
- C:\solid-carbide-worktrees\T-199\art-archive\T-199\screenshots\behind-height-3.png (behind a see-through height-3 area)
- C:\solid-carbide-worktrees\T-199\art-archive\T-199\screenshots\behind-height-6.png (behind a see-through height-6 area)
- C:\solid-carbide-worktrees\T-199\art-archive\T-199\screenshots\city-overview.png (overview of the city)
Weak: in air.png the car's shadow is not clearly visible (it falls on the rooftop under the car); the overview is off-centre by the camera follow offset.

**Left in the worktree, not committed:** an untracked temporary fixture game/tests/fixtures/elevation_sample_overview_tmp.tscn, and Godot's .import line-ending noise under game/; deleting/reverting them was refused (not pre-approved). Delete the fixture and `git checkout -- game` before merging.

**Open questions for the board:** (1) How it opens the scene (proposed: editor + F6, or the run command; no menu button). (2) Layout choices: two garages (NW and SE), start at (-81,-50), 12-unit ramps 10 wide, 4 buildings and 8 boulders left out. (3) Whether the overview needs a dedicated fixture or a scene option. (4) Whether the car shadow in the air reads well enough.

Refusals: the drive script run (round 1 and again in round 2); removing the temporary fixture and reverting .import noise.
- 2026-10-20, in-qa → in-progress: QA failed: The scripted reachability drive's log (layers 0, 3 and 6 reached, maximum height, airtime) from the merged build is pasted in the result notes. (QA: fail: the pasted log is T-195's, not from the merged build; QA's own run of drive_elevation_sample.sh was also refused, so it could not be rerun) Back to the agent on opus.
