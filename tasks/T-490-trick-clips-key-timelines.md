---
id: T-490
title: Record clips for FULL 360!, AIR 360!, HANG TIME! and THREAD THE NEEDLE!, and a key timeline for every clip
status: in-qa
from: project-lead
to: driving-drift
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, tasks/T-483-tutorial-clips.md, game/tests/fixtures/tutorial_clip_demo.gd, game/tools/record_tutorial_clips.py, game/tools/gif_to_sheet.py, game/art/tutorial/clips/alt_drift.json]
files_expected_to_change: [game/tests/fixtures/, game/tools/, game/art/tutorial/clips/, game/tests/unit/, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-11-01 (HUD and menus, Decisions, "Each trick shows the keys that make it"): every trick gets a clip of the real car, made with T-483's pipeline (the clip fixture with scripted inputs, record_tutorial_clips.py, then gif_to_sheet.py for the game's frame sheets; nearest-neighbour, the same size and look as the existing clips, no HUD or popups).

1. New clips: `three_sixty` (a drift that spins a full circle the same way: FULL 360!), `air_three_sixty` (a fast ramp jump with a full turn in the air: AIR 360!; the board says a fast ramp jump flies far enough on today's numbers, at the base air-turn speed, no upgrade), `airtime` (a ramp jump with W only and no spin: HANG TIME! alone), `thread_the_needle` (the car drives between two paired obstacles on a plain fixture without touching either: THREAD THE NEEDLE!). The recorder's trick check must show each clip's trick (and no unwanted extra trick in `airtime`).
2. A key timeline for every clip (the new four and the existing long_drift, alt_drift, ramp_jump and drift): for each GIF frame, which of W, A, S, D the script held, written into each clip's `_sheet.json` (for example `keys_per_frame`: a string per frame like "WA"), made by the recorder from the scripted parts so it always matches. The UI ticket draws the live key pad from it.
3. HUD and menus (Content, "Tutorial clips") lists the new clips and the key timeline field.

Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The four new clips exist as GIF and frame sheets (each sheet page at most 3840 px, as T-485's web limit), and the recorder's output in the result notes shows each clip's trick fired (airtime: HANG TIME! with no AIR 180! or AIR 360!). (QA: pass / fail)
- [ ] Every clip's sheet JSON has a key timeline with one entry per frame, matching the scripted inputs; a test checks it for at least alt_drift (W, then W+A, then S+A, then W). (QA: pass / fail)
- [ ] Screenshots: a contact sheet of a few frames of each new clip is saved and listed in the result notes. (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content, "Tutorial clips") lists the new clips and the key timeline field. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent, with -gselect / unittest on the changed modules), and QA's full run passes (tasks/README.md, "Which tests run when"), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

From the board's go: recording clips for FULL 360!, AIR 360!, HANG TIME! and THREAD THE NEEDLE!, plus key timelines. Driving & Drift agent started.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done by the Driving & Drift Agent (2026-11-01). Four new clips in game/art/tutorial/clips/ (GIF, frame sheet, record JSON; 480x320, 16.7 fps): three_sixty (74 frames, 4.44 s, 1,242,173 B; trick three_sixty at step 123), airtime (51 frames, 3.06 s, 1,425,990 B; airtime 1.12 s vs 0.30 s min, no air_one_eighty/air_three_sixty, 0 deg turned), air_three_sixty (60 frames, 3.6 s, 1,438,329 B; trick air_three_sixty at step 172, airtime 1.90 s, 370 deg turned at the base air-turn speed with steer 0.82; taller ramp fixture tests/fixtures/data/tutorial_ramp_high.json, 0 to 6, start speed 16.5), thread_the_needle (44 frames, 2.64 s, 237,351 B; trick thread_the_needle at step 50, real ThreadTheNeedle on two script-drawn boulders, no touch). The recorder (game/tools/record_tutorial_clips.py) checks each take's trick (EXPECT) and prints PROBLEM lines (none). Sheets: every page at most 3840 px. Key timeline: the fixture logs held keys per physics step, the recorder writes keys_per_frame into each record, gif_to_sheet.py copies it into each _sheet.json (merged identical frames handled; drift has 149 sheet frames vs 150 recorded). The four old clips: a re-record gave slightly different bytes, so I kept the approved GIFs and sheet PNGs (git checkout) and only added keys_per_frame to their records and sheets. alt_drift keys: W, WA, A (one frame), AS, W. Screenshots: art-archive/T-490/screenshots/ (<name>_contact.png, 6 frames each, plus the GIFs); takes in art-archive/T-490/takes/. Tests: python -m unittest game/tools/test_record_tutorial_clips.py game/tools/test_gif_to_sheet.py: 14 OK; bash game/tools/run_tests.sh -gselect=test_tutorial_clips: 6 tests, 51 asserts, passing. Doc: docs/hud-and-menus.md (Tutorial clips). Nothing in game/data/levels/ touched. Untracked .uid and .import noise from a fresh import is not committed.
- 2026-11-01, in-progress → in-qa: Four new clips, key timelines in every sheet JSON, tests pass; ready for QA
