---
id: T-307
title: Rebrand sweep: a check for Redgull's red, files and name in what the game loads, with screenshots of every screen
status: blocked
from: project-lead
to: qa-integration
lead: Goal-G-006
epic: tooling
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: no
depends_on: [T-300, T-302, T-303, T-304, T-305, T-306]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/tools/style_rules.py, game/tools/check_sprite_rules.py]
files_expected_to_change: [game/tools/check_rebrand.py, game/tools/test_check_rebrand.py, game/README.md]
model: sonnet
qa_rounds: 0
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

The goal is done when a run of the game shows no Redgull name, logo or brand red anywhere the player can see. Write a script in game/tools/ (for example check_rebrand.py, with a test) that lists every PNG the game's scenes and scripts load (res:// paths in .tscn, .tres and .gd files under game/scenes and game/scripts) and reports:

- any loaded PNG with pixels the red check (style_rules.py's, renamed by D9) flags, apart from the subjects whose red the docs keep (Visual style, Decisions, 'Red after the rebrand': the likes heart, alert signs, tail lights, the minion's mouth, the health canister, the combo broken popup), each exception named in the script with the doc's line;
- any loaded file whose name contains 'redgull';
- any player-facing text containing 'Redgull' in game/scripts, game/scenes and game/data.

Run it in this ticket's folder, made from playtest/G-006 once every ticket it depends on is merged there, and put its report in the result notes. Take screenshots with the screenshot tool of the main menu, the garage, the run's HUD, a gift pack drop and the level-up screen, in art-archive/<this ticket>/screenshots/, with full paths in the result notes. Add a short section on the script to game/README.md. Report what the check finds; don't fix art or text here (any finding goes back to the Project Lead).

## Acceptance criteria

- [ ] game/tools/check_rebrand.py (or the name chosen) and its test exist; the test shows it flags a loaded PNG with a Redgull red pixel, passes one of the kept subjects (for example the likes heart), flags a loaded file named with 'redgull' and flags a text with 'Redgull'. (QA: pass / fail)
- [ ] Screenshots of the main menu, garage, run HUD, gift pack drop and level-up screen are in art-archive/<this ticket>/screenshots/, with their full paths in the result notes. (QA: pass / fail)
- [ ] game/README.md has a section on the script and how to run it. (QA: pass / fail)
- [ ] All three test sets pass in this ticket's folder. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
