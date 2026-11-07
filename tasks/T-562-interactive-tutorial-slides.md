---
id: T-562
title: The interactive tutorial slides
status: done
from: project-lead
to: ui
lead: Rails
epic: ui
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/scripts/menu/tutorial_slides.gd]
files_expected_to_change: [game/scripts/menu/, game/scenes/menu/, game/tests/, docs/hud-and-menus.md]
model: opus
qa_rounds: 1
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

Build HUD and menus, Decisions, "Interactive tutorial slides", on today's tutorial_slides.gd. Six slides: (1) the loop, with the HUD's own icons as today's slide 2 chain does; (2 to 5) drift, alt drift, air spins, grind, each with its title, instruction and a practice window a bit bigger than today's clips, embedding T-561's practice scene set to that trick, with the success message over the window only after the third success; (6) today's last slide, the kaiju timeline, with Go live and Don't show again. The missions slide goes. **Keys:** on the trick slides A, D and Space drive the car, so they must not change slides or press buttons there (today they do); propose how the player moves between slides (the mouse on the arrows and Skip; say if any key still does) and how the practice window gets the keyboard. Practising is optional. Pause the practice when its slide isn't showing. All texts from T-559's keys (its result notes), no placeholder text. This ticket starts once T-559's texts have passed QA; T-560 and T-561 are merged into its branch when they pass QA (until then, build against their interfaces as described in their tickets).

The board's review: play the tutorial in the combined build (playtest/interactive-tutorial): press Start from the main menu.

Part of the interactive tutorial (board, 2026-11-07; HUD and menus, Decisions, "Interactive tutorial slides" and "A trick falls into the notebook"; Level design, Decisions, "The practice playground"; tickets T-559 to T-563). The board plays all of it at the end in one combined build (branch playtest/interactive-tutorial), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --append <file>` (write the file with the Write tool) or `--text`, and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The tutorial shows the six slides in order with T-559's texts (test). (QA: pass)
- [ ] Each trick slide embeds the practice scene set to its trick, and the success message appears over the window only after the third success (tests). (QA: pass)
- [ ] On the trick slides, A, D and Space don't change slides or press buttons, and they drive the car (test). (QA: pass)
- [ ] The arrows, Skip, Go live and Don't show again still work (tests). (QA: pass)
- [ ] docs/hud-and-menus.md Content describes the slides and the keys. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] Screenshots in art-archive/T-562/screenshots/ show each slide, a practice in progress and the success message. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: the six interactive slides, with practice windows; A, D and Space drive on the trick slides.

### 2026-11-07, In progress → In QA

Built: the six interactive slides on the real practice scene. QA now.

### 2026-11-07, In QA → Needs playtest

QA passed (7/7). Waits for you in the combined build.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### UI Agent, 2026-11-07 (first pass, built against a stand-in for T-561)

**Built.** `game/scripts/menu/tutorial_slides.gd` now has six slides:
- **The content loop:** four steps with the HUD's own pictures (the long drift illustration, the subs ring, the gift pack with weapons, a pink loop arrow drawn in code), then `tutorial.loop.point` under them.
- **Four trick slides:** drift, altdrift, airspin, grind. Each has its title, its instruction (the grind slide adds `tutorial.grind_hint`) and a 600 x 400 practice window.
- **The last slide:** unchanged (timeline, Go live, Don't show again).
- **The missions slide and the clips** are gone.

All texts are T-559's keys. No placeholder text.

**The practice windows.** Each one is a SubViewportContainer and SubViewport.
- **Built when needed:** the first time its slide shows, it instances `TutorialSlides.PRACTICE_SCENE` (`res://scenes/run/practice_session.tscn`, T-561) and calls `setup("drift" | "alt_drift" | "air_spin" | "grind")`.
- **Only the showing practice is live:** it gets `set_focused(true)` and `start()`. Every other one gets `set_focused(false)` and `pause()`, and so do all of them when the slides are hidden. Sessions are kept, so their counts survive leaving the slide.
- **The success message:** `completed` shows `tutorial.success` over that window only, with a 0.25 s pop, and it stays.
- **Rendering:** the window renders at screen pixels (container scaled 1/s and sized s times bigger).
- **The seam:** `practice_scene_path`. If the scene is missing, the window is an empty frame with one warning, and the slides work as normal.

**Keys (proposal for the playtest).**
- The Left and Right arrow keys change slides on every slide. A and D change slides only on slides 1 and 6.
- On the trick slides the practice window has the keyboard as soon as its slide shows, with no click needed. The arrows and Skip get FOCUS_NONE there and the focus is released. They work by mouse only, so A, D, Space, Enter and Tab press nothing and reach the practice.
- On slides 1 and 6, Enter or Space presses the focused button as before.

**Numbers proposed:**
- The window is 600 x 400 at (565, 214) with a 4 px frame. The old slide 1 clip box was 546 x 364.
- The instruction is Bangers 32 and the hint is muted 24.
- The success message is gold Bangers 64, outline 12, with a 0.25 s back-out pop.

**For the playtest:** the kickers of slides 1 to 5 show only "n / 6", because T-559 has kicker topics for the last slide only (the Project Lead says this is fine; noted for the playtest).

**Waiting on the merge of T-561 and T-560 into this branch (the Project Lead's plan):**
- The real-scene check: `game/tests/unit/test_tutorial_practice_real.gd`, pending until the scene exists.
- The seam wiring: PLAYGROUND_PATH `res://data/level/practice_playground.json`, start ids drift, alt_drift, air_spin, grind, and GOAL_TEXT_KEYS set to T-559's keys. Both live in T-561's practice_session.gd.
- The screenshots in `art-archive/T-562/screenshots/` (each slide, a practice in progress, the success message). None are taken yet, so that criterion is open.

**Also changed:**
- `game/tests/unit/game/test_tutorial_flow.gd`: it walks SLIDE_COUNT - 1 arrows and uses the stand-in.
- `game/tools/screen_gallery.gd`: it shoots six slides.
- New fixture `game/tests/fixtures/fake_practice_session.tscn/.gd`: a stand-in with T-561's API.

**A refusal:** a hook refused a temporary `cp` of T-561's files into this folder (for the real-scene check). Nothing was copied, and the Project Lead confirmed not to copy.

**Tests run (foreground, the changed code only):**
- `test_tutorial_slides`: 33/33, 410 asserts.
- `test_tutorial_flow`: 8/8, 49 asserts.
- `test_shared_button`: 12/12, 6610 asserts.
- `test_tutorial_practice_real`: 4 tests, all pending until T-561 is merged.
- The full run is left to QA.

**Documents affected:**
- `docs/hud-and-menus.md`: Content, new "The interactive slides (T-562)", and the T-485 heading marked as replaced.
- `game/docs/hud-and-menus/tutorial-slides.md`: scenes, practice windows, keys and tests.

### UI Agent, 2026-11-07 (second pass, after T-560 and T-561 were merged into this branch)

**The merge was clean.** No conflicts. `practice_scene_path` already defaults to the real scene (`res://scenes/run/practice_session.tscn`), so no change was needed. The playground path and the goal-text keys are T-561's own (`res://data/level/practice_playground.json` and T-559's `tutorial.goal.*`), and they came in with the merge.

**Real-scene check.** `game/tests/unit/test_tutorial_practice_real.gd` now runs: 6/6 tests, 76 asserts. It checks:
- each trick slide holds the real session, set to its trick;
- only the showing window runs and has the keyboard (the car's `input_enabled`);
- Space reaches the car and presses no button;
- the grind window opens with the Jump gift;
- end to end on all four trick slides: three successes of the slide's trick (the grind takes the Jump gift first, and the car then has Jump) make the notebook read 3/3, with the success message hidden until the third;
- W and A/D, held through `Input.parse_input_event`, drive and steer the car on the drift slide without changing slides.

**Other tests, rerun after the merge:**
- `test_tutorial_slides`: 33/33, 410 asserts.
- `test_tutorial_flow`: 8/8, 49 asserts.
- `test_shared_button`: 12/12, 6610 asserts.

**Screenshots** are in `art-archive/T-562/screenshots/`. All are 1280 x 720, taken from `tests/fixtures/tutorial_slides_demo*.tscn`. The fixture gained `drive`, `take_gift` and `complete`, plus the scenes `_5`, `_6`, `_drive`, `_success` and `_airspin_drive`. I opened each one to check it.
- `slide1_loop.png`: the content loop.
- `slide2.png` to `slide5.png`: the four trick slides with their practice windows. On the grind slide (`slide5.png`) the Jump gift is open in the window.
- `slide6.png`: the last slide.
- `practice_in_progress_drift.png`: the car drifting with tyre marks and smoke, the notebook at "Drifts 0/3".
- `success_grind.png`: "CONTENT SECURED!" over the grind window only, three GRIND! popups and the notebook line struck through.

**For the playtest:**
- **The car looks small** in the 600 x 400 window. The framing is T-561's zoom (the run's framing at the window's height).
- **The notebook covers part of the window** at the top left.
- **The gift overlay's title** in the grind window reads "MISSION DONE: PIMP YOUR RIDE", the run's power-up overlay text that T-561 reuses.
- **The kickers of slides 1 to 5** show only "n / 6" (the Project Lead says this is fine).
- 2026-11-07, needs-playtest → done: Board: interactive tutorial build played, lgtm
