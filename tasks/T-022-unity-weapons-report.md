---
id: T-022
title: Report on the starting gun and the exhaust flamethrower in the board's Unity prototype
status: open
from: project-lead
to: weapon-behavior
epic: weapons
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/weapons/unity-weapons-report.md, docs/weapons.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/weapons.md, docs/game-loop-architecture.md, docs/drifting.md, docs/drifting/unity-prototype-report.md, .claude/agents/weapon-behavior.md]
files_expected_to_change: [docs/weapons/unity-weapons-report.md, docs/weapons/ (pictures, if any), docs/weapons.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board decided Solid Carbide's two MVP weapons copy the behaviour of the matching weapons in its Unity prototype (Weapons, Decisions): the **starting gun** and the **exhaust flamethrower**. This task studies how those two behave there and writes it up, the way T-006 did for the driving (`docs/drifting/unity-prototype-report.md`). It builds nothing in Godot.

**The Unity project:** `C:\Users\andre\drift-to-survive`, its current state. **Strictly read-only:** do not change, add or delete any file, run no git command that changes it, and do not open it in Unity or build it. Skip `Library/`, `Temp/`, `Logs/`, `Builds/`, `ProfilerCaptures/` and `Assets.zip`. The weapons are in `Assets/Scripts/Combat/` (for example `SimpleGunWeapon.cs`, `FlameExhaustWeapon.cs`, `Bullet.cs`, `WeaponData.cs`, `WeaponStats.cs`, `WeaponUpgradeTierData.cs`, `WeaponTierEffectApplicator.cs`) and `Assets/Data/Weapons/` (for example `Weapon_MachineGun.asset`, `Weapon_FlameExhaust.asset`). Work out which Unity weapon is the board's "starting gun" (the prototype has more than one gun) and say how you decided.

Write `docs/weapons/unity-weapons-report.md` for the board, plain language first, exact detail after, with these sections:

1. **Summary:** how each of the two weapons behaves, in a few paragraphs.
2. **Starting gun:** when it fires (range, interval), how it chooses and aims at a target, the bullets (speed, size, lifetime, what they hit, damage, knockback), and anything else it does.
3. **Exhaust flamethrower:** what turns it on and off (how the prototype decides the car is drifting), where the flame comes from and its shape and size, how it damages enemies (per hit, per second, area), and anything else it does (for example any effect on the car's handling).
4. **Every value:** one table per weapon with each parameter, the value the game uses (after asset or scene overrides), its unit, what it does, and where it is set (file and line or field).
5. **Upgrades and level-ups in the prototype:** the board decided Solid Carbide copies these two weapons' upgrades too (Weapons, Decisions). Describe how the two weapons tier up there, every tier and what it changes (with values), and how the prototype's level-up chooses what to offer (weapons, weapon upgrades, and anything else it offers, such as car upgrades), including what happens once a weapon is at its last tier. The board has already decided Solid Carbide's level-up flow (Weapons, Decisions); describe the prototype's for comparison and point out any difference.
6. **Porting to Godot 4.6:** for each Unity feature used, the closest Godot equivalent and anything that won't carry over exactly. Use the same units as the driving (1 unit = the car's width, 50 physics steps per second; Drifting, Decisions).
7. **Open questions** for the board: anything that could not be worked out from the files.

Then, in `docs/weapons.md`, add a `### Unity prototype weapons` subsection under Content (a few factual bullet points and a link to the report) and link the report in References. Do not change Summary, Decisions or Open questions: decisions come from the board. Follow `docs/README.md`.

Describe the prototype faithfully: do not improve or redesign the weapons. The other Unity weapons (Shotgun, Molotov, Neon, Windshield Wipers) are not part of this task.

## Acceptance criteria

- [ ] `docs/weapons/unity-weapons-report.md` exists and has the 7 sections listed above, in that order, and says which Unity weapon is the starting gun and why (QA: pass / fail)
- [ ] For 5 values picked by QA from the two tables, the value and its file and line or field match the Unity project's files, including any asset or scene override (QA: pass / fail)
- [ ] The flamethrower section names exactly what turns it on and off in the prototype's code, matching the code (QA: pass / fail)
- [ ] `docs/weapons.md` has the `### Unity prototype weapons` subsection and links the report, still follows the five-section structure, and its Summary, Decisions and Open questions are unchanged (QA: pass / fail)
- [ ] The Unity project is unchanged: in `C:\Users\andre\drift-to-survive`, `git rev-parse HEAD` prints `126e7ec3845fa4023aa0854569a5449be3d4c2a6`, `git status --porcelain` prints exactly ` M .cursor/rules/project.mdc`, ` M docs/ideas.md` and `?? docs/ISOMETRIC_MAP_GENERATOR_PLAN.md`, and `git diff | sha256sum` prints `428db3b753a54e4752759f534f28e444bebd7dd54c30894f960e66e98fadcd30` (QA: pass / fail)
- [ ] No file under `game/`, `.claude/agents/` or other `docs/` files changed, apart from `docs/weapons.md` and `docs/weapons/` (QA: pass / fail)

The board's review: read the report and judge whether it matches the weapons as the board remembers them.

## Result notes

Written by the agent when it finishes.
