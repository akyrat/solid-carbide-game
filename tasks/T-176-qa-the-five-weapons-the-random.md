---
id: T-176
title: QA: the five weapons, the random offers and the card images together in a run
status: in-progress
from: project-lead
to: qa-integration
lead: Goal-G-002
epic: weapons
milestone: mvp
goal: G-002
user_facing_text: no
changes_visuals: no
depends_on: [T-172, T-173, T-174, T-175]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, game/README.md, game/data/playtest.json, game/scripts/weapons/level_up_offers.gd]
files_expected_to_change: [game/tests/unit/weapons/test_all_weapons_run.gd]
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

Check the goal's work together before the board's single playtest of `playtest/G-002`. Run the game from the main menu with all five weapons owned (the `all_weapons_at_start` playtest switch from D7, set only in the test, never committed as true) headless for 60 seconds. Drive a run through repeated level-ups until several weapons reach tier 8, checking no repeated or maxed choice is offered. Run all three test sets and the staleness check. Write a test for the repeated level-up run so it can be rerun. Report results per criterion; fix nothing in game code yourself.

## Acceptance criteria

- [ ] A run started from the main menu with all five weapons owned runs headless for 60 seconds with no script errors in the log. (QA: pass: test_run_from_the_main_menu_with_all_five_weapons_for_60_seconds passes in the full GUT run, no script errors)
- [ ] A test levels a run up repeatedly until at least three weapons reach tier 8, with no offer ever holding the same id twice or a choice for a weapon at tier 8, and no error. (QA: pass: test_repeated_level_ups_take_three_weapons_to_tier_8_with_valid_offers passes; note tier 8 is reached via gift-pack choices, since max_level 12 gives only 11 level-ups)
- [ ] The game's tests, the tools tests and the docs checks all pass, and the staleness check reports nothing stale after the long GDD and the short GDD fingerprint are regenerated. (QA: fail: GUT 962/962, game/tools 282 OK, tools 303 OK; but the long GDD / fingerprint regeneration and staleness check are not pre-approved commands and were not run. Docs changed on this branch (weapons, enemies, hud-and-menus, visual-style), so staleness is unverified; the Project Lead must run it at merge)
- [ ] `data/playtest.json` as committed has every switch false. (QA: pass: all five *_at_start keys and kaiju_early_arrival.enabled are false)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Blocked → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-176.

### 2026-10-18, In progress → In QA

Goal runner (G-002): the agent is done; QA is checking it.

### 2026-10-18, In QA → In progress

Goal runner (G-002): failed QA once; back to the agent on opus.

## Result notes

New test: `game/tests/unit/weapons/test_all_weapons_run.gd` (3 tests, 349 asserts, ~14 s). No game code changed.

1. **60 s run from the main menu, all five weapons: PASS.** The test starts the run through the menu's Start button with `all_weapons_override = 1` (never the file), checks all five weapons owned, then runs 60 s of run time (Engine.time_scale 6, level-ups taken as they come, car health made huge so enemies don't end the run). No script errors in the log.
2. **Repeated level-ups to three tier-8 weapons: PASS**, with a finding. `run.json` `max_level` is 12, so a real run has only 11 level-ups, but three weapons at tier 8 need 21 upgrades. The test takes the real level-ups first and, once `is_max_level()`, opens the remaining choices the way the gift pack does (`RunState.open_choice`). Every offer had 1 or 2 different ids, never a weapon at tier 8, no error; the choice resumes the run each time. For the Project Lead: in a real run only about 11 upgrades happen, so tier 8 is reached only through gift-pack choices.
3. **Test sets and staleness: PARTIAL / not fully checked.** Game GUT suite: TESTS PASSED (962 tests). Python `game/tools` tests: 282 OK (1 skipped). Python `tools` tests: 303 OK. Staleness check (`python tools/generate_long_gdd.py --check`) and the regeneration of the long GDD and short GDD fingerprint were REFUSED (not in the pre-approved commands), so not run. No docs changed in this task (documents_affected is empty), so nothing should be stale from this branch.
4. **`data/playtest.json` all switches false: PASS** (read, and the new test checks every key including `kaiju_early_arrival.enabled`).
- 2026-10-18, in-qa → in-progress: QA failed: The game's tests, the tools tests and the docs checks all pass, and the staleness check reports nothing stale after the long GDD and the short GDD fingerprint are regenerated. (QA: fail: GUT 962/962, game/tools 282 OK, tools 303 OK; but the long GDD / fingerprint regeneration and staleness check are not pre-approved commands and were not run. Docs changed on this branch (weapons, enemies, hud-and-menus, visual-style), so staleness is unverified; the Project Lead must run it at merge) Back to the agent on opus.
- 2026-10-18, round 2 (agent): no code to fix. The only failing criterion (3) needs `python tools/generate_long_gdd.py --check` and the regeneration of the long GDD and the short GDD fingerprint (`python tools/generate_long_gdd.py`, `python tools/update_short_gdd_fingerprint.py`). I tried the check again and it was REFUSED by the permission system: only `python game/tools/*` is pre-approved, not `python tools/*`. I did not work around it. Nothing on the branch changed since round 1 (GUT 962 passed, game/tools 282 OK, tools 303 OK). To pass criterion 3, either the board adds those three commands to `permissions.allow`, or the Project Lead runs them at merge of `playtest/G-002`. Blocked on that.
