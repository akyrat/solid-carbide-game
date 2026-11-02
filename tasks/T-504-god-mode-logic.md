---
id: T-504
title: God mode: set each weapon's and power-up's tier in the current run
status: open
from: project-lead
to: game-loop
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/scripts/weapons/weapons.gd, game/scripts/data/power_up_data.gd, game/data/playtest.json]
files_expected_to_change: [game/project.godot, game/scripts/, game/tests/unit/, game/docs/]
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

The board, 2026-11-02 (docs/hud-and-menus.md, Decisions, "A secret God mode"): the logic behind the secret God mode page (T-505 builds the page and only calls this). 1. **The secret:** pressing N during a run unlocks God mode for the rest of the session (not saved; closing the game locks it again). Add an input action for N (project.godot) and a signal or flag the settings screen can read. 2. **Setting tiers:** an API that reads, for every weapon and every driving power-up, its current tier in the run and its last tier, and sets any of them to any tier from 0 (not owned) to its last tier, applied to the current run straight away, exactly as if it had been levelled up (or reset and levelled up again, for a lower tier). The gun never goes below tier 1. The level-up offers and the mission gifts then offer only what is left. A new run starts as usual (the chosen tiers are not kept). Reuse T-500's code that starts weapons at a tier where it helps. Document it in game/docs/ (game loop) and in docs/game-loop-architecture.md only if the loop changes (it shouldn't). This task's branch is built on T-497's branch, which already holds the board's new weapon trees (T-495 to T-499) and the playtest tier switch (T-500), so the board can play everything in one build. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py <id> --append <file>`, never with Edit or Bash on the ticket. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build with the weapon trees (T-495 to T-499), the power-up changes and God mode (T-501 to T-505), from the Project Lead's combined folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Pressing N during a run sets God mode unlocked for the session (unit test through the input action); a new run keeps it unlocked; it is not saved to disk. (QA: pass / fail)
- [ ] A unit test: setting a weapon to tier 5 gives the same stats as levelling it from 1 to 5; setting it lower then higher again gives the right stats; setting it to 0 removes it (except the gun, which stays at tier 1 at least). (QA: pass / fail)
- [ ] A unit test: setting a driving power-up to a tier gives the same numbers as gaining it to that tier through gifts; 0 removes it. (QA: pass / fail)
- [ ] A unit test: after God mode raises a weapon to its last tier, the level-up offers never offer it again. (QA: pass / fail)
- [ ] A unit test: a new run starts with the gun at tier 1 only, whatever God mode set before. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
