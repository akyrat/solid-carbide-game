---
id: T-522
title: Minions' ramp and kaiju health paced for the 4-minute run
status: done
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
files_to_read_first: [docs/enemies.md, docs/game-loop-architecture.md, docs/weapons.md, tasks/README.md]
files_expected_to_change: [game/scripts/enemies/, game/data/enemies.json, game/tests/unit/, docs/enemies.md]
model: sonnet
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

Pace the enemies for the 4-minute run (docs/enemies.md, Decisions, "Paced for the 4-minute run"): the minions' growth over the run (spawn rate, health or whatever scales with time) is compressed so it peaks before the kaiju arrives at 3:00 instead of 7:00, and the kaiju's health is set so a player with about 3 weapons near their last tier (5-tier trees, docs/weapons.md) can defeat it in the last minute but not trivially (show your estimate of that damage per second and the kill time in the result notes). Don't move the kaiju's arrival itself (T-521 does) but read the boss time rather than assume 7:00 wherever the ramp needs it. Keep the meteors and minions' rules as they are. Update docs/enemies.md Content.

The board, 2026-11-03: the run is shortened to 4 minutes (3:00 build, kaiju 3:00 to 4:00). Decisions: docs/game-loop-architecture.md "A 4-minute run: 3 minutes to build, 1 minute of kaiju"; docs/weapons.md "Shorter trees: 5 tiers"; docs/drifting.md "Two tiers and three slots for the driving power-ups"; docs/enemies.md "Paced for the 4-minute run"; docs/hud-and-menus.md "Weapon and power-up slots". T-519 to T-523 are built in parallel and combined by the Project Lead into one build (T-521's folder) that the board plays before anything merges. Many existing tests assume the 8-minute run, the kaiju at 7:00 and 8 tiers: update the ones your change breaks (say which in the result notes), never delete a test's purpose. Numbers you choose are proposals for the playtest, in game/data with a _comment. Never write, move or commit anything in game/data/levels/. SFX stay off. Stage files by name, never .uid/.import noise. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play the one combined build (T-519 to T-523) from C:\solid-carbide-worktrees\T-521\game\project.godot before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: the minions' growth reaches its peak by the boss time read from data (3:00 after T-521; the test reads the value, not a constant). (QA: pass)
- [ ] A unit test: the kaiju's health matches the proposal, and the result notes show the damage-per-second estimate behind it. (QA: pass)
- [ ] No enemy code assumes 7:00 or 8:00 (grep in the result notes). (QA: pass)
- [ ] docs/enemies.md Content describes the new pacing and points to the data. (QA: pass)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass)
- [ ] A screenshot of the swarm near 3:00 (a fixture is fine), under art-archive/T-NNN/screenshots/. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-03, Open → In progress

Started: enemy pacing for the 4-minute run.

### 2026-11-03, In progress → In QA

Minion ramp now peaks at 3:00 (read against the boss time); kaiju health 1500 for a 3-weapon last-tier build (~19 s nominal, ~37 s at half effectiveness). Ready for QA.

### 2026-11-03, In QA → Needs playtest

QA passed; play it in T-521's combined 4-minute-run build.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. Minions: growth_until_seconds 420 -> 180 (enemies.json; same 1.2 s -> 0.3 s rates, so peak 4/s at 3:00, ~375 minions by then, was 875). The boss time lives in RunState (RUN_SECONDS - BOSS_TIME_LEFT, T-521 changes it); the test reads it from there and asserts growth_until <= boss time, so it holds for 3:00 or 7:00. Kaiju health 500 -> 1500 (proposal; kaiju._comment has the working). DPS estimate (weapon data, gun/flame/underglow at last tier = new tier 5 power = old tier 8): gun 4 bullets x 4 dmg / 0.234 s = 68.5/s; flame 12/s x 0.3 on kaiju = 3.6; underglow 4.5/0.5 s = 9 -> ~81/s if all lands: 1500 in ~19 s. Gun shares aim with the crowd, so at half effectiveness (~40/s) ~37 s of the 60 s. Gun one tier short (old tier 7, 21/s; build ~34/s): 44 s if all lands, ~89 s at half -> not finished. Won in the last minute but not trivially. Greps: no 7:00/8:00/420/480 left in enemy code or data (only the 500 loop count and a seed). Tests updated: test_enemy_data.gd (health 1500; spawning test now reads boss time from RunState; time-to-kill test rewritten as a 3-weapon build using max_tier so it also holds for the 5-tier trees), test_minions.gd (7:00 assertion -> peaks by boss time), test_meteors_minions_pickups.gd (420 -> 180 in its fake data). Ran: test_enemy_data 10/10, test_minions 44/44, test_meteors_minions_pickups 11/11, test_kaiju 26/26. Docs: docs/enemies.md Content (spawning, arrival, health), game/docs/enemies/minions.md and kaiju.md. Screenshot: art-archive/T-522/screenshots/swarm_at_3min.png (fixture game/tests/fixtures/swarm_at_3min_demo.tscn; 60 minions + kaiju at the growth end; the clock shows 5:00 left only because RUN_SECONDS is still 480 here until T-521 combines). Not run: full sets (QA).

QA round: all 6 criteria pass; both test sets green. Boss time read from RunState in the test; only remaining 420 in enemy data is a historical mention in a _comment. DPS estimate (~81/s if all lands, ~40/s at half; 1500 HP = 19-37 s of the last minute) looks reasonable. Screenshot shows swarm and kaiju.
- 2026-11-03, needs-playtest → done: Combined 4-minute run build lgtm (board, 2026-11-03); merged into master through T-521's combined branch
