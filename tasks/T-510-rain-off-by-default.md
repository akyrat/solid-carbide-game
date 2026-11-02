---
id: T-510
title: Rain off by default
status: in-qa
from: project-lead
to: level-challenge
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, tasks/T-507-rain-over-the-map.md]
files_expected_to_change: [game/scripts/, game/tests/unit/, game/docs/, docs/level-design.md]
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

The board, 2026-11-02, after playing the rain (docs/level-design.md, Decisions, "Rain over the map", "Off by default"): the saved setting rain_enabled defaults to false, so a new player (no saved settings, or saved settings without the rain key) has no rain until they tick the Rain checkbox in the pause settings. A player who already saved a choice keeps it. Change the default where T-507 defined it (and anywhere else it is assumed true: the pause screen's checkbox start state, tests that pin the default), update game/docs/ and docs/level-design.md Content if they say on by default. The board asked for this to be merged and pushed to itch.io straight after QA, without its own playtest. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-510 --text "..."`. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: with no saved setting (and with saved settings that lack the rain key), rain_enabled is false and no rain draws in a run. (QA: pass)
- [ ] A unit test: a saved rain_enabled true still shows rain; ticking the checkbox still turns it on at once and saves it. (QA: pass)
- [ ] The pause screen's Rain checkbox starts unticked for a new player (test). (QA: pass)
- [ ] No doc in docs/ or game/docs/ still says the rain is on by default. (QA: pass, round 2)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass)
- [ ] A screenshot of a new player's run with no rain and the unticked checkbox, under art-archive/T-NNN/screenshots/. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started: rain off by default, then QA, merge and itch push.

### 2026-11-02, In progress → In QA

Rain now defaults to off; tests, docs and a new-player screenshot are in. Ready for QA, merge and the itch push.

### 2026-11-02, In QA

QA passed on round 2 (one doc line fixed). Merging with T-511, then itch push.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Default changed: GameSettings.DEFAULT_RAIN_ENABLED false (game_settings.gd). Tests: test_rain.gd (22 pass; new: default false, saved settings without the key false, a new player's run draws no rain; tests needing rain save true first) and test_pause_rain_toggle.gd (all pass; checkbox starts unticked, toggles now go on then off, saved true is kept). Docs: game/docs/level/rain.md and docs/level-design.md Content say off by default. Screenshot: art-archive/T-510/screenshots/new_player_no_rain.png (fixture tests/fixtures/rain_default_off_demo.tscn): paused run, no rain, Rain unticked. Nothing written in game/data/levels/.

QA round 1: 5 of 6 pass (tests green, screenshot shows unticked Rain, no rain). FAIL (paperwork): docs/hud-and-menus.md line 194 still says rain_enabled is on by default; change to off by default (T-510). docs/long-gdd.md copies regenerate at merge.

QA round 2: criterion 4 now passes (docs/hud-and-menus.md line 194 says off by default; no other doc outside the generated long GDD says on by default). All 6 criteria pass.
