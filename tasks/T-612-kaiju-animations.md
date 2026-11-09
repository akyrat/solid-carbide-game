---
id: T-612
title: The kaiju plays its walk, windup and death animations (placeholder frames)
status: open
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

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
