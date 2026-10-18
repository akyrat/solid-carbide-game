---
id: T-170
title: The windshield wiper: sweeps in front of the car, damages and pushes minions back (placeholder look)
status: in-qa
from: project-lead
to: weapon-behavior
lead: Goal-G-002
epic: weapons
milestone: mvp
goal: G-002
user_facing_text: no
changes_visuals: yes
depends_on: [T-166, T-167]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/enemies.md, docs/visual-style.md, docs/extended-narrative.md, game/data/weapons.json, game/scripts/weapons/weapons.gd, game/scripts/weapons/weapon.gd, game/scripts/enemies/minion.gd, game/tests/unit/weapons/test_starting_gun.gd, game/tests/unit/weapons/test_exhaust_flamethrower.gd, game/README.md]
files_expected_to_change: [game/scripts/weapons/windshield_wiper.gd, game/scripts/weapons/weapons.gd, game/tests/unit/weapons/test_windshield_wiper.gd, game/tests/unit/weapons/test_starting_gun.gd, game/tests/unit/weapons/test_exhaust_flamethrower.gd, docs/weapons.md, game/README.md]
model: opus
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

Build the windshield wiper (docs/weapons.md, Decisions, 2026-10-18): one wiper in front of the car that sweeps back and forth in a semicircle, all the time, turning with the car. An enemy it hits takes damage; minions are knocked back through the minion knockback call (D2); the kaiju is damaged but never pushed. It is the only weapon that pushes. Add a weapon script to the rack (id `wiper`), not owned at the start of a run, given and upgraded through `rack.upgrade("wiper")`, with all numbers and tiers 2 to 8 from its weapons.json entry (D1). Damage through take_damage, times the garage damage multiplier. How often the same enemy can be hit by one sweep is your proposal: write it in the result notes. Placeholder look: a wiper blade drawn in code in front of the car, never Redgull red; the final art comes later (D10). Do not add the level-up choice: that is D7.

The board's review: Play a run from the task folder with the wiper given and see the placeholder wiper sweep and push minions away.

## Acceptance criteria

- [ ] A new run has no wiper; after `rack.upgrade("wiper")` a test shows the wiper's angle sweeps back and forth across a semicircle in front of the car and the semicircle turns when the car turns. (QA: pass)
- [ ] A test shows a fake minion the wiper reaches takes the damage from weapons.json (times the garage damage multiplier) and is moved away from the car through the knockback call; a test shows the kaiju (or a fake big enemy) is damaged but not moved. (QA: pass)
- [ ] A test shows the gun's bullets and the flamethrower still never move an enemy. (QA: pass)
- [ ] A test per tier 2 to 8 applies the tier from code and checks the change weapons.json gives it; tests show it stops while paused and is removed on a new run. (QA: pass)
- [ ] A placeholder wiper drawn in code, in no shade of Redgull red, shows in front of the car; `docs/weapons.md` Content and `game/README.md` 'Weapons' describe the wiper, and the game's test set passes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Blocked → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-170.

### 2026-10-18, In progress → In QA

Goal runner (G-002): the agent is done; QA is checking it.

## Result notes

Written by the agent when it finishes.

**Weapon Behavior Agent, 2026-10-18.** Built the windshield wiper (`game/scripts/weapons/windshield_wiper.gd`, id `wiper`) and added it to the rack's `WEAPON_SCRIPTS` (`run.weapons.wiper`). Not owned at the start of a run; `rack.upgrade("wiper")` gives it and applies tiers 2 to 8, every number from `weapons.json` "wiper" through `WeaponData.wiper_at()`, damage times the garage damage multiplier. No level-up choice was added (D7).

**Proposals, for the board's playtest:**
- **How often one enemy is hit:** at most once per pass (one sweep from one side to the other), and never twice within the data's `hit_cooldown` (0.5 s). At tier 1 a pass takes 0.75 s, so an enemy that stays in front is hit about every 0.75 s. At tier 8 a pass takes about 0.46 s, so the 0.5 s cooldown can sometimes skip a pass for an enemy near one end of the sweep.
- **The arm:** it turns round the nose of the car's 1-unit physics body (0.5 units ahead of the centre, `PIVOT_OFFSET_UNITS`, a placement in code). It sweeps the 180-degree semicircle in front of the car and starts each run at one end. An enemy is hit when the arm touches its body (the rack's `radius_of()`: 0.5 for a minion, 2 for the kaiju) during the step's sweep.
- **The push:** straight away from the car's centre, by the data's `knockback_distance`, through the minion's `apply_knockback()` (T-167). Only enemies with that call that are not in the `kaiju` group are pushed (the real kaiju has no such call anyway). `knockback_kaiju` from the data is honoured.

**Placeholder look:** a blade drawn in code in the run's `View`, from the car's nose to the arm's tip: dark outline, dark steel arm, pale grey rubber blade. No red. It is drawn over the car sprite while it points down the screen and under it while it points up. The car sprite is drawn larger than the 1-unit body, so part of the blade near the pivot is hidden under the sprite. The visible part sweeps clearly (screenshot `screenshots/wiper2.png` in the task folder; not committed).

**Extra files, beyond files_expected_to_change:**
- `game/data/playtest.json`: new switch `wiper_at_start` (false), the same pattern as the other new weapons, so the board can play the wiper.
- `game/tests/fixtures/weapons/fake_minion.gd`: a test minion that records knockback calls.
- `game/tests/fixtures/weapons/wiper_demo.gd` / `.tscn`: a demo and screenshot scene.

**For the board's review:** open `C:\solid-carbide-worktrees\T-170\game\project.godot`, then open `tests/fixtures/weapons/wiper_demo.tscn` and press F6. Or set `wiper_at_start` to `true` in `game/data/playtest.json` and press F5.

**Tests:**
- `game/tests/unit/weapons/test_windshield_wiper.gd`: 26 tests covering every criterion: the sweep and turning with the car, damage times the multiplier, the push through the knockback call (fake and real minion), the kaiju (two fakes and the real one) damaged but not moved, once per pass and the cooldown, pause, run end, a new run, the playtest switch, one test per tier 2 to 8, and the blade's place and colours.
- New `test_bullets_never_move_an_enemy` (`test_starting_gun.gd`) and `test_flame_never_moves_an_enemy` (`test_exhaust_flamethrower.gd`).
- Results: full GUT suite 932/932 passed; `python -m unittest discover -s game/tools` OK (278); `python -m unittest discover -s tools` OK (303).

**Documents updated:**
- `docs/weapons.md`: Content, "The windshield wiper (built in task T-170)".
- `game/README.md`: Weapons, "The windshield wiper".

**PixelLab:** none used (0 generations).

**Refusals:** a PreToolUse hook refused one Bash command: an inline `python -c` that edited `game/scripts/weapons/weapons.gd`. The hook's message was about task statuses, so it looks like a false match on the word "status" in the command. I made the same edits with the Edit tool instead. Not essential, not blocked.

**Not committed:** Godot's line-ending-only `.import` changes in the working copy, as the working rules say.
