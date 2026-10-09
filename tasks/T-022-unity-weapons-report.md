---
id: T-022
title: Report on the starting gun and the exhaust flamethrower in the board's Unity prototype
status: needs-playtest
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
model: opus
qa_rounds: 1
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

- [x] `docs/weapons/unity-weapons-report.md` exists and has the 7 sections listed above, in that order, and says which Unity weapon is the starting gun and why (QA: pass)
- [x] For 5 values picked by QA from the two tables, the value and its file and line or field match the Unity project's files, including any asset or scene override (QA: pass)
- [x] The flamethrower section names exactly what turns it on and off in the prototype's code, matching the code (QA: pass)
- [x] `docs/weapons.md` has the `### Unity prototype weapons` subsection and links the report, still follows the five-section structure, and its Summary, Decisions and Open questions are unchanged (QA: pass)
- [x] The Unity project is unchanged: in `C:\Users\andre\drift-to-survive`, `git rev-parse HEAD` prints `126e7ec3845fa4023aa0854569a5449be3d4c2a6`, `git status --porcelain` prints exactly ` M .cursor/rules/project.mdc`, ` M docs/ideas.md` and `?? docs/ISOMETRIC_MAP_GENERATOR_PLAN.md`, and `git diff | sha256sum` prints `428db3b753a54e4752759f534f28e444bebd7dd54c30894f960e66e98fadcd30` (QA: pass)
- [x] No file under `game/`, `.claude/agents/` or other `docs/` files changed, apart from `docs/weapons.md` and `docs/weapons/` (QA: pass)

The board's review: read the report and judge whether it matches the weapons as the board remembers them.

## Result notes

Done by the Weapon Behavior Agent, 2026-10-09.

**Produced:** `docs/weapons/unity-weapons-report.md`, with the 7 sections in the order asked: 1 Summary, 2 Starting gun, 3 Exhaust flamethrower, 4 Every value (one table per weapon), 5 Upgrades and level-ups in the prototype (both tier tables, the level-up's offer logic, and a table of differences from Solid Carbide's decided flow), 6 Porting to Godot 4.6, 7 Open questions (11). Read-only study: no code was written, so there are no tests to run.

**Starting gun:** the Unity "Simple Gun" (`SimpleGunWeapon`, asset `Weapon_MachineGun.asset`). It is the only weapon on the Player in all three stage scenes and `PlayerInventory.EnsureStartingWeapon` puts it in slot 1; the Shotgun (the other gun) is only added when picked at a level-up. The report's opening explains this.

**What turns the flame on and off:** `FlameExhaustWeapon.IsExhaustActive` (lines 120-130): on when `PlayerCarController.IsDrifting` (line 44: W or S held with steer input beyond 0.01) and speed >= 0.85 units/s, plus a 0.2 s linger (`Weapon_FlameExhaust.asset` line 22), or always after the tier 8 upgrade.

**Findings the board may want to know about** (all in the report's section 7 as questions, nothing changed):
- The flame's damage (2) comes from the gun's stats via the shared `WeaponStats`; the flame asset's own damage (1) and fire interval (0.1) are never used.
- The flame's "Hotter flame" tier and the Damage power-up have no effect at damage 2 (2 x 1.2 = 2.4 rounds back to 2).
- The flame's damage area is up to 41% bigger when the car faces diagonally (it uses the car collider's world bounding box).
- Non-piercing bullets have no lifetime; bullets that miss fly forever. The bullet's hit circle is 2 units across though it is drawn 0.32 units across.
- The gun checks for targets only once every 1.26 s.
- Knockback needs the Knockback power-up, which Solid Carbide's level-up does not offer.

**Unity project:** unchanged. Checked at the end: `git rev-parse HEAD` = `126e7ec3845fa4023aa0854569a5449be3d4c2a6`, `git status --porcelain` = the three expected lines, `git diff | sha256sum` = `428db3b7...cd30`. Registry read with `reg query` only (level-up settings: armed offers all off).

**For the Project Lead:** `python tools/generate_long_gdd.py --check` reports exit 1 (weapons.md changed since the long GDD was generated; structure fine). The long GDD was not regenerated here, since this task may change only `docs/weapons.md` and `docs/weapons/`.

**Documents affected:**
- `docs/weapons/unity-weapons-report.md` (new).
- `docs/weapons.md`: new `### Unity prototype weapons` subsection under Content (replacing "(To be written.)"), and the References entry is now a link to the report. Summary, Decisions and Open questions unchanged.

### QA round 1

QA/Integration Agent, 2026-10-09. Checked in `C:\solid-carbide-worktrees\T-022` on `task/T-022-unity-weapons-report`. The Unity project was only read (files and read-only git commands).

| # | Criterion | Result |
|---|---|---|
| 1 | Report exists, 7 sections in order, names the starting gun and why | **pass**: sections 1 to 7 in the order asked (report lines 15, 27, 63, 139, 209, 289, 311). Says the starting gun is the Simple Gun (`Weapon_MachineGun.asset`). Checked the reasons: the `Stage_Grass.unity` line 75228 `weaponData` guid is `Weapon_MachineGun.asset.meta`'s, and `PlayerInventory.EnsureStartingWeapon` (lines 54-67) adds the `SimpleGunWeapon` data with tier 1 |
| 2 | 5 table values match the Unity files, overrides included | **pass**: 9 table rows checked, all match (list below) |
| 3 | Flamethrower on/off matches the code | **pass**: `IsExhaustActive` (FlameExhaustWeapon.cs 120-130) returns true when `exhaustAlwaysActive` is set, or while `Time.time < _exhaustLingerUntil`, which every frame the gate holds is pushed to now + linger. `IsDriftGateSatisfied` (113-118) = `_car.IsDrifting` and speed squared >= 0.85 squared. `IsDrifting` (PlayerCarController.cs 44) = (accelerate or reverse > 0) and abs(steer) > 0.01. Linger comes from `weaponData.flamePostDriftLingerSeconds` (lines 132-137) = 0.2 (asset line 22); the 0.5 fallback is used only when there is no data. Tier 8 calls `SetExhaustAlwaysActive(true)` (WeaponTierEffectApplicator.cs 166-168). All as the report says |
| 4 | `docs/weapons.md` subsection, link, five sections, Summary, Decisions and Open questions unchanged | **pass**: `git diff master...HEAD -- docs/weapons.md` changes only Content ("(To be written.)" replaced by `### Unity prototype weapons` with a link to the report) and the References entry (now a link). Headings are still Summary, Decisions, Content, Open questions, References |
| 5 | Unity project unchanged | **pass**: HEAD `126e7ec3845fa4023aa0854569a5449be3d4c2a6`; `git status --porcelain` shows exactly ` M .cursor/rules/project.mdc`, ` M docs/ideas.md`, `?? docs/ISOMETRIC_MAP_GENERATOR_PLAN.md`; `git diff \| sha256sum` = `428db3b753a54e4752759f534f28e444bebd7dd54c30894f960e66e98fadcd30` |
| 6 | No other files changed | **pass**: `git diff master...HEAD --name-only` lists only `docs/weapons.md`, `docs/weapons/unity-weapons-report.md` and this task file. Nothing under `game/` or `.claude/agents/`; working tree clean |

**Claims checked against the Unity source (all match):**

1. Gun range 12, base interval 1.2, damage 2 (`baseDamage`), bullet speed 15, 1 bullet per volley: `Weapon_MachineGun.asset` lines 42, 43, 45, 46, 47. `WeaponData.damage` returns `baseDamage` (WeaponData.cs 171, 189).
2. Scene overrides: `delayBetweenBullets` 0.05, `extraDelayBetweenVolleys` 0.06, both overrides 0 (`Stage_Grass.unity` lines 75229-75232).
3. 1.26 s target check: `EffectiveFireInterval` = base / (attack speed x tier) + extra delay (SimpleGunWeapon.cs 64-73); `Update` sets `_timer = 0` (line 82) before `TryFire`, which returns at once with no targets (line 91). So targets are checked only once per interval.
4. The flame uses the gun's damage: `GetEffectiveDamage` (FlameExhaustWeapon.cs 355-363) reads `_weaponStats.Damage`. `WeaponStats.EnsureInit` (lines 27-35) seeds it from the `SimpleGunWeapon`'s data (damage 2). The flame asset's `damage: 1` (line 45) is used only when there is no `WeaponStats`. Rounding is at line 324.
5. Bullet hit circle compared with drawn size: prefab scale 2 (`Bullet.prefab` line 33), trigger (line 154), `m_Radius: 0.5` (line 159), so radius 1. The sprite is 16 px wide at 100 px per unit (`Bullet.png.meta` lines 54, 121-122): 0.16 x 2 = 0.32. Colour (line 88) and sorting order 5 (line 85) also match.
6. Bullet lifetime: `Bullet.Update` (lines 103-110) checks distance only when the pierce mode is not None, so non-piercing bullets that miss are never removed. Non-pierce is released on the first hit (lines 129-131); PierceFirstEnemy after 2 hits (132-134); 36 units (line 27).
7. Flame rectangle: half-width 1.05, depth 2.6, inner 0.35 (lines 54, 57, 60, 284-286); `RangeReference` 12 (line 15); asset range 30 (line 42); car half-size from the collider's world bounds (307-315); collider 1 x 1 (`Stage_Grass.unity` line 75305); ramp 0.5 to 1 over 1 s (lines 46, 50, 200-205); tick 0.2 (line 21); burn 0.38 s and tint (1, 0.62, 0.38) (lines 73, 76).
8. Gun tiers: asset steps (lines 48-69) are +2 bullets, Fire rate + and ++, Reach, +2 bullets, Fire rate +++, Pierce. Effects: +2 projectiles, fire rate x 1.2, range multiplier 1.5, pierce first (WeaponTierEffectApplicator.cs 68-79). Tier 3 is 1.2/1.2 + 0.06 = 1.06 s; tier 5 is 12 x 1.5 = 18.
9. Flame tiers: asset steps (lines 48-70) are Bigger plume x 2, Hotter flame, Longer burn tint, Bigger plume (+30%), Steering, Always-on. Effects: plume x 1.2, damage x 1.2, burn +0.5 s, plume x 1.3, turn speed +20% of current, always on (lines 150-168). Tier 2 is a multiplier of 2.5 x 1.2 = 3.0; tier 6 is a total of 1.2 x 1.2 x 1.3 = 1.872.
10. The Flame Exhaust is added at pick-up and switches off the tyre smoke (PlayerInventory.cs 208-214). The tier cap is checked in `TryUpgradeWeaponTier` (232-245).

**Not a fail, for the Project Lead:** the long GDD is now stale for Weapons (`docs/weapons.md` changed). That is expected; the Project Lead regenerates it at merge.
