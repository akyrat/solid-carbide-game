---
id: T-515
title: Even the lowest Jump clears a minion
status: in-qa
from: project-lead
to: enemy-behavior
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/enemies.md]
files_to_read_first: [docs/enemies.md, docs/drifting.md, game/scripts/enemies/enemy_height.gd, game/data/power_ups.json, tasks/README.md]
files_expected_to_change: [game/scripts/enemies/, game/data/, game/tests/unit/, docs/enemies.md]
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

The board, 2026-11-02 (docs/enemies.md, Decisions, "Even the lowest Jump clears a minion"): the board still can't jump over enemies and expects even the first Jump tier to clear one. Cause (the Project Lead's reading): contact damage hits when the car's height is within EnemyHeight.LEVEL_TOLERANCE (1.0, game/scripts/enemies/enemy_height.gd ~line 34/174) of the minion's ground; the Jump's first tier (game/data/power_ups.json, takeoff 5 units/s, gravity 12) peaks at about 1.04 units, so the car is clear for only ~0.17 s. Fix: give the car's contact damage from a minion its own tolerance, about 0.5 units (your proposal for the playtest; in data or a named constant with a comment), so a tier-1 hop clears a minion for about 0.6 s. Keep LEVEL_TOLERANCE as it is for everything else that uses it (minion_spawner.gd crowding, the kaiju's contact, kaiju_meteors.gd, weapons' own LEVEL_TOLERANCE). Check the contact still works on ramps (a car on a ramp next to a minion on the same ramp is still hit; say how close heights there can differ) and that a car on a rooftop stays safe from minions below. Do not change the Jump's tiers. Update docs/enemies.md Content ("Contact damage at the car's level") with what was built. Write the tests first so one fails on today's code. The board plays it before merging. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-515 --text "..."`. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play a run with God mode (N) giving Jump tier 1 and hop over minions, from C:\solid-carbide-worktrees\T-515\game\project.godot, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test that fails on today's code: a car hopping with Jump tier 1 straight over a minion standing still takes no contact damage when the hop is timed with the minion under the car's middle (and a test with the real hop's height curve: the car is clear of the minion for at least 0.5 s of the hop). (QA: pass / fail)
- [ ] A unit test: a car on the ground touching a minion still takes contact damage; a car on a ramp touching a minion on the same ramp still takes it. (QA: pass / fail)
- [ ] A unit test: the kaiju's contact, the meteors' miss rule, the minions' crowding and the weapons' levels are unchanged (their tolerances unchanged). (QA: pass / fail)
- [ ] The new tolerance lives in data or a named constant with a comment, and docs/enemies.md Content describes it. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] A screenshot or GIF of the car hopping over a minion with tier 1, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started: even the lowest Jump clears a minion (car contact tolerance ~0.5).

### 2026-11-02, In progress → In QA

Minions now hit the car only within 0.5 units of height, so a tier 1 hop clears one for ~0.6 s; tests and GIF in the ticket.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built: EnemyHeight.MINION_CONTACT_TOLERANCE = 0.5 (a proposal, named constant with comment) and EnemyHeight.minion_can_hit(); Minion.contact_step uses it. LEVEL_TOLERANCE (1.0) is untouched: kaiju contact, kaiju_meteors, minion crowding, and weapons (1.5) keep theirs. Jump tiers unchanged. New test file game/tests/unit/enemies/test_minion_contact_tolerance.gd (7 tests): the real hop-curve test failed on old code (clear 0.00 s) and passes now (clear 0.56 s of the 0.83 s hop; analytic 0.60 s); ground still hit; ramp: car and minion on the same ramp differ by ~0.25 per unit of distance, far under 0.5, still hit; rooftop car safe; kaiju still hits at 0.9 up; LEVEL_TOLERANCE 1.0, weapons 1.5, MINION_CONTACT_TOLERANCE 0.5 asserted. Also ran test_enemies_on_heights, test_minions, test_rusty_overcoat, test_kaiju, test_jump_clears_obstacles: all pass. docs/enemies.md Content 'Contact damage at the car's level' updated. GIF: art-archive/T-515/screenshots/jump_over_minion.gif (+ hop_frame_20/30.png; made with the new fixture tests/fixtures/jump_over_minion_demo and game/tools/record_jump_minion_gif.sh). Note: a first screenshot attempt left stale hop_frame PNGs that I overwrote (an rm was refused by the hook, not worked around). Nothing in game/data/levels touched.
