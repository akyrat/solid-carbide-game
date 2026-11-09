---
id: T-612
title: The kaiju plays its walk, windup and death animations (placeholder frames)
status: in-progress
from: project-lead
to: enemy-behavior
lead: Polish
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/enemies.md, docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/docs/enemies/kaiju.md, game/scripts/enemies/kaiju.gd, game/scripts/enemies/kaiju_sprite.gd, game/scripts/enemies/kaiju_boss.gd, game/scripts/enemies/kaiju_meteors.gd, game/data/enemies.json]
files_expected_to_change: [game/scripts/enemies/, game/scripts/game/, game/data/, game/art/placeholders/, game/tests/, game/docs/, docs/enemies.md, docs/game-loop-architecture.md]
model: opus
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

Build Enemies, Decisions, "The kaiju is animated" (board, 2026-11-09), with placeholder frames; the final art comes from the linked art task T-613, which swaps its frames in for yours.

Today the kaiju is five still sprites (`game/art/kaiju/kaiju_e|n|ne|s|se.png`, the other directions mirrored). Make it play three animations, each per drawn direction:

- **Walk:** a looping cycle while the kaiju walks.
- **Windup:** during the 1 second windup before each meteor attack, in place of the placeholder yellow rings above its head, which go. After it, the kaiju goes back to walking.
- **Death:** when its health reaches zero it plays the death animation once, then disappears, and only then are its coins added and the run ends as a win (today both happen at once). While it plays, the kaiju does not move, does not hurt the car and is no longer a target for the weapons. Propose its length, what the kaiju's health bar does, and what happens if the run's timer reaches zero while it plays (the kaiju was killed in time, so propose that the win stands); write the win's new timing in Game loop architecture's Content where it describes the win.

The frames must be swappable without touching code: define one frame format (file names or sheets per animation and direction, frame size and anchor, frame count and speed in `game/data/enemies.json`) and write it in `game/docs/enemies/kaiju.md` so T-613 can deliver exactly that. Placeholder frames are free: made in code or by a script from the five current sprites (for example a bob and squash for the walk, a rear-up for the windup, a sink and fade for the death). No PixelLab call in this ticket, and no Greenbull colours. Animations stop while the game is paused. The red flash, the depth order, the height drawing and the ground shadow keep working on the animated kaiju.

Propose the frame counts and speeds. Update Enemies, Content: "The kaiju" (Look, Death) and "The kaiju's meteor attack" (Windup).

The board's review: play it from C:\solid-carbide-worktrees\T-612\game\project.godot: reach the kaiju, watch it walk, wind up before its meteors, and kill it to see the death before the win screen (placeholder frames; the final art is T-613).

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test checks that while the kaiju walks its drawn frame advances through the walk animation of its facing direction and loops, and that the frame does not advance while the game is paused. (QA: pass / fail)
- [ ] A test checks that during a meteor attack's windup the windup animation of the facing direction plays, the yellow rings are no longer drawn, and the walk animation plays again after the windup. (QA: pass / fail)
- [ ] A test checks that at zero health the death animation plays once for the length in `game/data/enemies.json`, and that until it ends the kaiju does not move, deals no contact damage and is not returned as a weapon target. (QA: pass / fail)
- [ ] A test checks that the kaiju's coins are added and the run ends as a win only when the death animation has finished, and that the case of the timer reaching zero during the death behaves as the result notes say. (QA: pass / fail)
- [ ] A test checks that the frames are read from the files and the numbers named in `game/data/enemies.json` (replacing a frame file or a frame count there changes what is drawn, with no code change), and `game/docs/enemies/kaiju.md` describes the frame format (files, frame size, anchor, counts, speeds) for T-613. (QA: pass / fail)
- [ ] The existing tests of the kaiju's red flash, depth order, height and ground shadow pass on the animated kaiju. (QA: pass / fail)
- [ ] No PixelLab call was made: `game/art/pixellab-generation-log.jsonl` has no new line from this ticket. (QA: pass / fail)
- [ ] Recordings in art-archive/T-612/screenshots/: one GIF each of the walk, the windup and the death in the game, plus a still of the kaiju walking. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Every document in documents_affected is updated, and the proposals made for the playtest are listed in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-09, Open → In progress

Started: the Enemy Behavior Agent is building the kaiju's walk, windup and death animations with placeholder frames; the art (T-613) follows.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### Enemy Behavior Agent, 2026-11-09: done

**What was built.** The kaiju now has three animations: walk, windup and death. Each animation has one sheet per drawn direction (e, se, s, ne, n; the other three are mirrored). The sheets are read from a new data section, `game/data/enemies.json`, "kaiju_animations" (sheet path, frames, fps, loop; frame_size 224, feet [112, 203], head_top_y 17).
- Walk: the T-069 sheets (`game/art/kaiju/kaiju_<dir>.png`). They loop while the kaiju walks and stop while the game is paused, because the frame clocks are in `_process`.
- Windup: plays during the meteor attack's 1 s windup, starting from its first frame and holding its last. The walk comes back after it. The yellow rings above the head have been removed from `kaiju_meteors.gd`.
- Death: plays once at the kill. Until it ends, the kaiju does not move, cannot hurt the car, is no longer in the "enemies" group, is off the enemies' collision layer and has `is_dead()` true. When the death ends, the kaiju disappears, then its coins are added, then `kaiju_defeated` is sent, then `RunState.kaiju_killed()` ends the run as a win. The ground shadow fades along with the death.
- The red flash, depth order, height drawing and ground shadow are all still on the same sprite node and work on every animation (their existing tests pass).
- Placeholder frames are free and use no PixelLab. A script, `game/tools/build_kaiju_anim_placeholders.py`, makes them from the first walk frame, using nearest neighbour and no new colours: the windup rears the kaiju up (stretched taller and narrower about the feet); the death buckles it, then sinks it into the ground while it fades. They are in `game/art/placeholders/kaiju/` (kaiju_windup_<dir>.png and kaiju_death_<dir>.png).
- The frame format for T-613 is written in `game/docs/enemies/kaiju.md`, "The kaiju's animations": files, sheet layout, frame size, feet anchor, head top, counts, speeds, loop, mirroring and what happens when a file is missing. Swapping in new art means changing paths or counts in the data section, with no code change.

**The win flow (RunState, `game/scripts/run/run_state.gd`).** New `kaiju_dying()` and `kaiju_win_due`. At the kill, the boss calls `kaiju_dying()`, which makes the win stand from then on:
- the clock holds at 0:00 instead of starting the time's up;
- a wreck waits at its end instead of losing;
- a kill on the very step the clock reached 0:00 calls the time's up off (the T-413 tie rule) and the death plays.
Calling `kaiju_killed()` on its own still works as before. The new timing is written in Game loop architecture, Content, "The run scene" (and the flowchart).

**Proposals for the playtest:**
1. Walk: 6 frames at 5.4 a second, the kaiju's old speed of 0.9 cycles a second.
2. Windup: 6 frames at 6 a second (1 s, matching windup_seconds), played once and held. The kaiju keeps walking towards the car during the windup, as before (the ticket did not say it should stop). Open question: should it stand still while it winds up?
3. Death: 12 frames at 8 a second = 1.5 s. The coins and the win come after it.
4. Health bar: it goes at the killing blow, so the death plays without it.
5. The timer reaching 0:00 during the death: the win stands. The clock holds at 0:00 and there is no time's up screen.
6. A wreck during the death, which the ticket did not ask about: the win also stands. The wreck plays, waits at its end for the death, then the run is won.
7. During the death the rest of the run goes on as usual: minions, likes and damage to the car. The kill counts in the recap at the killing blow.
8. The shadow fades out with the death.
9. A windup in progress when the kaiju is killed still drops its meteors, as before T-612.

**Tests (all run in the foreground, all passing):**
- New: `game/tests/unit/enemies/test_kaiju_animations.gd`, 13 tests. They cover criteria 1 to 5, including the data and doc format check, the timer and tie cases and the wreck case.
- Updated:
  - `test_kaiju.gd`: 3 tests now play the death through before checking the win.
  - `test_kaiju_health_bar.gd`: waits one step for the bar to hide.
  - `test_kaiju_meteors.gd`: WINDUP_COLOR removed from the colour list.
- `bash game/tools/run_tests.sh -gselect=test_kaiju`: 97/97 passed, over 7 scripts (test_kaiju 26, test_kaiju_animations 13, test_kaiju_meteors 28, test_kaiju_path_size 8, test_kaiju_sprite 6, test_kaiju_health_bar 9, test_kaiju_signs 7).
- Related files with -gselect, all passed: test_run_state 10, test_wreck 37, test_time_up 16, test_enemy_data 10, test_meteor 41, test_enemies_drop_off_ledges 13, test_height_scaled_shadows 8, test_starting_gun 31, test_four_minute 24, test_run_recap 12, test_rusty_overcoat 12, test_enemy_flash (passed), test_hit 5.
- Python: `python -m unittest test_build_kaiju_anim_placeholders` (game/tools): 4/4 OK.
- I did not run the full sets (QA does).

**No PixelLab call:** `game/art/pixellab-generation-log.jsonl` is unchanged on the branch.

**Recordings** in `art-archive/T-612/screenshots/`:
- `kaiju_walk.gif`
- `kaiju_windup.gif` (the red flash in it is the starting gun hitting it)
- `kaiju_death.gif` (the death, then the win's recap screen)
- the still `kaiju_walking.png`

The recording script is `bash game/tools/record_kaiju_anim_gif.sh <walk|windup|death> <out.gif> [seconds]`, which uses the fixture `game/tests/fixtures/kaiju_anim_demo.tscn`.

**Documents affected:**
- docs/enemies.md, Content: "The kaiju" (Look, Death) and "The kaiju's meteor attack" (Windup). The old Look line still described the T-045 code-drawn placeholder; it now describes the T-069 art and the animations.
- docs/game-loop-architecture.md, Content: One run flowchart and "The run scene", the win's new timing.
- Also updated: game/docs/enemies/kaiju.md (Death, and the new "The kaiju's animations" section) and game/docs/enemies/meteors.md (the rings are gone).
