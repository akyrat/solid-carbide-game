---
id: T-023
title: Report on the three regular enemies in the board's Unity prototype
status: open
from: project-lead
to: enemy-behavior
epic: enemies
milestone: mvp
depends_on: []
documents_affected: [docs/enemies/unity-enemies-report.md, docs/enemies.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/enemies.md, docs/game-loop-architecture.md, docs/drifting/unity-prototype-report.md, .claude/agents/enemy-behavior.md]
files_expected_to_change: [docs/enemies/unity-enemies-report.md, docs/enemies/ (pictures, if any), docs/enemies.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The MVP has one minion type (Final GDD), and the board will pick it from the three regular enemies in its Unity prototype: **Monster1, Monster4 and Monster7**. This task describes all three side by side so the board can choose, the way T-006 did for the driving (`docs/drifting/unity-prototype-report.md`). It builds nothing in Godot and makes no choice.

**The Unity project:** `C:\Users\andre\drift-to-survive`, its current state. **Strictly read-only:** do not change, add or delete any file, run no git command that changes it, and do not open it in Unity or build it. Skip `Library/`, `Temp/`, `Logs/`, `Builds/`, `ProfilerCaptures/` and `Assets.zip`. The enemies are in `Assets/Data/EnemyTypes/` (`EnemyType_Monster1.asset`, `EnemyType_Monster4.asset`, `EnemyType_Monster7.asset`) and `Assets/Scripts/Enemies/` (for example `EnemyTypeData.cs`, `EnemyCarController.cs`, `EnemyHealth.cs`, `EnemyContactDamage.cs`, `EnemyElite.cs`, `EnemyBurnStatus.cs`, `EnemyDeathSequence.cs`), plus wherever the prototype spawns enemies.

Write `docs/enemies/unity-enemies-report.md` for the board, plain language first, exact detail after, with these sections:

1. **Summary:** the three enemies side by side in a short table (how each looks, moves and hurts the car, and how tough it is), then a paragraph on each.
2. **Monster1, Monster4 and Monster7:** one subsection each: how it looks (describe the sprites; include or link pictures from the project's art if they can be copied as images without changing the project), how it moves, how it damages the car (contact damage, knockback), its health, and anything else it does.
3. **What they share:** health, contact damage, knockback, "elite" enemies, the burn status (and what applies it, for example the Flame Exhaust weapon), death, and what they drop. **Note:** the prototype's enemies drop XP, but in Solid Carbide XP comes only from driving and enemies drop coins (Game loop architecture, Decisions); describe the prototype's drop without suggesting it carries over.
4. **Spawning:** how and where the prototype spawns enemies (for example from the screen edges) and how their numbers grow over a run.
5. **Every value:** one table per enemy, plus one for the shared and spawning values: each parameter, the value the game uses (after asset or scene overrides), its unit, what it does, and where it is set (file and line or field).
6. **Porting to Godot 4.6:** for each Unity feature used, the closest Godot equivalent and anything that won't carry over exactly. Use the same units as the driving (1 unit = the car's width, 50 physics steps per second; Drifting, Decisions).
7. **Open questions** for the board.

Then, in `docs/enemies.md`, add a `### Unity prototype enemies` subsection under Content (a few factual bullet points and a link to the report) and link the report in References. Do not change Summary, Decisions or Open questions. Follow `docs/README.md`.

Describe the prototype faithfully; do not recommend which enemy to pick. The bosses (Monster3, 6, 8) are not part of this task.

## Acceptance criteria

- [ ] `docs/enemies/unity-enemies-report.md` exists and has the 7 sections listed above, in that order, covering Monster1, Monster4 and Monster7 (QA: pass / fail)
- [ ] For 5 values picked by QA from the tables, the value and its file and line or field match the Unity project's files, including any asset or scene override (QA: pass / fail)
- [ ] The report says the prototype's enemies drop XP and does not suggest carrying that over (QA: pass / fail)
- [ ] `docs/enemies.md` has the `### Unity prototype enemies` subsection and links the report, still follows the five-section structure, and its Summary, Decisions and Open questions are unchanged (QA: pass / fail)
- [ ] The Unity project is unchanged: in `C:\Users\andre\drift-to-survive`, `git rev-parse HEAD` prints `126e7ec3845fa4023aa0854569a5449be3d4c2a6`, `git status --porcelain` prints exactly ` M .cursor/rules/project.mdc`, ` M docs/ideas.md` and `?? docs/ISOMETRIC_MAP_GENERATOR_PLAN.md`, and `git diff | sha256sum` prints `428db3b753a54e4752759f534f28e444bebd7dd54c30894f960e66e98fadcd30` (QA: pass / fail)
- [ ] No file under `game/`, `.claude/agents/` or other `docs/` files changed, apart from `docs/enemies.md` and `docs/enemies/` (QA: pass / fail)

The board's review: read the report and pick the MVP minion.

## Result notes

Written by the agent when it finishes.
