---
id: T-144
title: Gift pack drop: a helicopter drops the gift pack, and driving over it opens the level-up screen (placeholders)
status: open
from: project-lead
to: game-loop
lead: Art
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, docs/weapons.md, docs/visual-style.md, game/README.md, tasks/T-052-level-up-screen.md, tasks/T-043-level-up-weapon-choices.md, tasks/T-112-level-up-particles-placeholder.md]
files_expected_to_change: [the run and level-up flow scripts and scenes, new helicopter and package scenes with placeholder art, their GUT tests, docs/game-loop-architecture.md, game/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decision (Game loop architecture, Decisions, "Gift pack drop", 2026-10-16): the level-up screen should no longer just appear. When the player levels up, a **helicopter sent by Redgull flies over the screen and drops a package** (the gift pack). **When the player drives over the package, the level-up screen opens** (the existing gift pack screen from T-052, with the same offers from T-043).

This task builds that flow with **placeholders**, so the board can play it before any art exists:

- On a level-up, the level-up screen does not open. The level-up effect (T-112) and the likes bar behave as they do now.
- A placeholder helicopter (a simple shape, not Redgull red: `docs/working-with-the-board.md`, "Placeholders never use Redgull red") flies across the screen and drops a placeholder package, which falls and lands on the map.
- The package stays on the ground as an object the car can drive over. When the car touches it, the package disappears and the level-up screen opens, pausing the run as it does now; the choice works as before.
- Build it so the art tasks (T-145 helicopter, T-146 package) can swap their sprites in without changing behaviour: one clearly named sprite node or texture path each, written in `game/README.md`.

Any number that tunes the flow (helicopter speed, drop height, fall time and so on) goes in the game's data files, not in code, so it can be tuned in playtests.

**Open questions for the board** (answered before work starts; the Project Lead writes the answers here and in Game loop architecture):
1. Does the run keep going (clock, enemies, likes) while the helicopter comes and the package waits on the ground, with the pause only when the screen opens?
2. Where does the package land: near the car, ahead of it, or somewhere else on the map?
3. Several level-ups before a pickup (or at once): one package each, or one package holding all the choices in turn?
4. Does the package stay until picked up, or disappear after a while?
5. If the package lands off screen, is there a pointer to it?

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A GUT test shows that a level-up no longer opens the level-up screen by itself, and instead starts the helicopter, which crosses the screen and drops a package that lands on the map (QA: pass / fail)
- [ ] A GUT test shows that when the car overlaps the landed package, the package is removed and the level-up screen opens with the same offers as before (T-043), and the run pauses as it did (QA: pass / fail)
- [ ] GUT tests cover the board's answers to the open questions above (QA: pass / fail)
- [ ] The placeholder helicopter and package are not Redgull red, and the tuning numbers are read from a data file (a test checks both) (QA: pass / fail)
- [ ] `game/README.md` says which node or texture each art task replaces, and `docs/game-loop-architecture.md` describes the built flow (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: play a run, level up, watch the helicopter drop the package, and drive over it to open the level-up screen.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
