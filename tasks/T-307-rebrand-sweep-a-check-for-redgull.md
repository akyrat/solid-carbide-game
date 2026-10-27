---
id: T-307
title: Rebrand sweep: a check for Redgull's red, files and name in what the game loads, with screenshots of every screen
status: in-qa
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

- [ ] game/tools/check_rebrand.py (or the name chosen) and its test exist; the test shows it flags a loaded PNG with a Redgull red pixel, passes one of the kept subjects (for example the likes heart), flags a loaded file named with 'redgull' and flags a text with 'Redgull'. (QA: pass: script and 9 tests exist and pass, covering all four cases)
- [ ] Screenshots of the main menu, garage, run HUD, gift pack drop and level-up screen are in art-archive/<this ticket>/screenshots/, with their full paths in the result notes. (QA: pass: 5 PNGs in art-archive/T-307/screenshots/, paths in result notes)
- [ ] game/README.md has a section on the script and how to run it. (QA: pass: "Rebrand sweep (T-307)" section at game/README.md line 181)
- [ ] All three test sets pass in this ticket's folder. (QA: pass: GUT 1419/1419; game/tools 499 OK (1 skipped); tools/ 501 OK)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Blocked → In progress

Goal runner (G-006): started, in C:\solid-carbide-worktrees\T-307.

### 2026-10-27, In progress → In QA

Goal runner (G-006): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built `game/tools/check_rebrand.py` with `game/tools/test_check_rebrand.py` (9 tests: flags a loaded PNG with a red pixel, ignores an unloaded one, passes the likes heart as a kept subject, flags a file named 'redgull', flags 'Redgull' in a .gd string and a JSON value, skips comments, resolves %s patterns and folders, exit code 1). `KEPT_RED` names each kept subject with the doc's words (heart, alert banners, car tail lights, minion mouth, health canister, combo broken popup). Added the "Rebrand sweep (T-307)" section to game/README.md. Nothing in art or text was fixed.

**Report** (run in this folder on playtest/G-006 plus T-306; `python game/tools/check_rebrand.py`): 68 loaded PNGs checked; no file name contains 'redgull'; no player-facing text contains 'Redgull'; 10 kept-red files (the 6 alert banners, car_iso, car_iso_noshadow, health_canister, likes_heart); 8 red findings, all fire/wood oranges and browns that the loose red check flags by hue (none is the old logo red or the heart red), for the Project Lead to judge:
- art/effects/burning_flames.png ([208,53,46] and oranges)
- art/effects/exhaust_flame_sheet.png ([153,83,6], [249,126,3])
- art/level_up/weapon_flamethrower.png ([202,3,0], [253,116,1])
- art/level_up/weapon_gun.png (browns [68,33,13]...[170,110,69], the gun's wood grip)
- art/level_up/weapon_molotov.png (browns, [168,49,11])
- art/weapons/molotov_bottle.png, molotov_fire.png, molotov_fire_flip.png (oranges, browns, [98,55,70])
The red check is `style_rules.reads_as_red`; if these should be exempt, the Project Lead can add subjects to `KEPT_RED` or tighten the check. The minion's art is not flagged (its pink mouth is not within the red check).

**Tests:** GUT 1419/1419 pass (`bash game/tools/run_tests.sh`, TESTS PASSED); Python `unittest discover -s game/tools`: 499 tests OK (1 skipped).

**Screenshots** (full paths):
- C:\solid-carbide-worktrees\T-307\art-archive\T-307\screenshots\main_menu.png
- C:\solid-carbide-worktrees\T-307\art-archive\T-307\screenshots\garage.png (garage_screen_demo fixture)
- C:\solid-carbide-worktrees\T-307\art-archive\T-307\screenshots\run_hud.png (hud_from_menu_demo fixture)
- C:\solid-carbide-worktrees\T-307\art-archive\T-307\screenshots\gift_pack_drop.png (gift_drop_demo fixture)
- C:\solid-carbide-worktrees\T-307\art-archive\T-307\screenshots\level_up_screen.png (level_up_screen_demo fixture)

**Refused:** reverting Godot's line-ending-only `.import` noise (`git ls-files -m ... | xargs git checkout`) was refused as a compound command. Not essential: I committed only my own files and left the `.import` noise uncommitted; the Project Lead reverts it before merging.

Documents affected: game/README.md.
