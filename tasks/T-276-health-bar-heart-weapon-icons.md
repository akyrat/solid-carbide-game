---
id: T-276
title: A bigger health bar with the heart under it, and the car's weapons as icons beside it
status: in-qa
from: project-lead
to: ui
lead: Coursework
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/weapons.md, game/README.md, game/scripts/hud/, game/scenes/hud/, game/art/hud/likes_heart.png, game/art/level_up/, tasks/T-113-hud-vertical-health-and-likes-bars.md, tasks/T-174-art-one-level-up-card-image.md, tasks/T-243-airtime-counter-hud.md]
files_expected_to_change: [game/scripts/hud/, game/scenes/hud/, game/tests/unit/, docs/hud-and-menus.md, game/README.md, art-archive/T-276/screenshots/]
model: sonnet
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

The board's decision (HUD and menus, Decisions, "A bigger health bar with the heart, and the weapons beside it", 2026-10-22), for the top left of the HUD:

1. **Health bar:** still upright and filling from the bottom up (green), but 3 times wider and twice as tall: from 24 x 160 to **72 x 320 pixels** at the default 1152 x 648 window. The "Car Health" label goes. The likes bar's red heart (`game/art/hud/likes_heart.png`, the same picture, board-approved red) sits centred under the bar.
2. **Weapon icons:** to the right of the bar, a column of small square icons, one per weapon the car has (the starting gun included, proposal; say if you leave it out), in the order taken, each a small version of its level-up card picture (T-174, `game/art/level_up/weapon_*.png`, nearest filtering, no new art). A weapon taken more than once shows its count next to its icon as "x2", "x3" ... (its tier), in the HUD's comic font (Bangers with a black outline, as the combo counter and the airtime counter; this is the combo counter's "x{n}" form, no new words). The column fits the space beside the bar (icon size your proposal so eight-tier counts and all five weapons fit) and updates the moment a gift pack's weapon is taken or upgraded.

Nothing overlaps the run timer, the counters or the screen edge at the default window and zoom; the HUD scales with the window as today.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. T-273 is changing the likes bar at the bottom on its own branch in parallel; keep to the top-left elements. End with screenshots of the top left with no weapon but the gun, and with all five weapons at mixed tiers.

## Acceptance criteria

- [ ] The health bar is upright, 72 x 320 at the default window, filling from the bottom; the "Car Health" label is gone; the likes heart sits under it (screenshot, layout test) (QA: pass; bar 72x320, fills bottom up, label gone, heart centred 6px under it in layout test and screenshots)
- [ ] Tests show an icon appears for each weapon the car has, in the order taken, with "x{n}" for tiers above 1, updating when a weapon is taken or upgraded, in the comic font (QA: pass; test_hud_weapon_icons.gd covers gun at start, order, x2 to x8 updates and Bangers outline; changed tests keep their intent, "top half" to "top 60 percent" fits the taller bar)
- [ ] Nothing overlaps at the default window; no new art; no Redgull red besides the approved heart (screenshot) (QA: pass; no overlap with timer, coins or car in both screenshots; no new art; only the heart is red)
- [ ] Screenshots are in `art-archive/T-276/screenshots/`; HUD and menus, Content, and `game/README.md` describe the new top left; the full GUT suite and all Python tool tests pass (QA: fail; screenshots and docs ok, Python 451 and 395 OK, but the full GUT suite exits 139 on this branch in test_combo_broken_popup.gd:104 (await process_frame) on 4 runs, also with -gdir=res://tests/unit/hud, while that test alone passes and master's full suite exits 0 twice)

The board's review: take a few weapons from gift packs and look at the top left.
Board review files: the screenshots in `art-archive/T-276/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's request: a 72 x 320 upright health bar with the heart under it and weapon icons beside it.

### 2026-10-23, In progress → In QA

Upright health bar 72x320, label gone, heart under it, weapon icons column with x2 to x8 counts. Sent to QA.

### 2026-10-23, In progress

QA failed 1 of 4: the full test suite crashes every time on this branch (in the combo popup test). Sent back to the UI agent to fix, then QA round 2.

### 2026-10-23, In progress → In QA

No branch cause found: master crashes the same way (2 of 3 runs of the HUD tests); 3 full runs here passed. Sent to QA round 2.

## Result notes

Built (UI Agent). Top left of the HUD:
- Health bar: upright, 72 x 320 (`Hud.HEALTH_BAR_SIZE`), fills bottom up; the "Car Health" label and `health_label` are gone. A second copy of the likes heart picture (`hud.health_heart`, same texture, board-approved red) sits centred 6 px under the bar. The likes bar's own heart at the bottom is untouched (T-273 owns it).
- Weapon icons: new `scripts/hud/weapon_icons.gd` (`WeaponIcons`, `hud.weapon_icons`), bound by `hud.bind_weapons(run.weapons)` in `run.gd`. One 48 x 48 row per weapon the car has, the gun included, in the order taken; icon = `LevelUpScreen.weapon_image(id)` (the T-174 card picture at 3x, nearest, no new art); "x2" ... "x8" beside it above tier 1, Bangers 32, white with a black outline. It follows each weapon's `tier_changed`, so a taken or upgraded weapon shows at once; a new run drops back to the gun.
- QA round 1, exit 139: no cause in this branch found, no code changed. The crash is the engine's signal 11 at the first `await get_tree().process_frame` of the first test file in the HUD directory (`test_combo_broken_popup.gd:104`). It happens on master too: a detached checkout of master (bd3d839) crashed with 139 in 2 of 3 runs of `-gdir=res://tests/unit/hud`; on this branch with `bind_weapons` commented out it still crashed; the file alone passes 3 of 3. Full suite on this branch afterwards: 3 runs in a row, all exit 0 (1372 tests); both Python sets OK (395 + 451). It looks like a load-dependent engine flake.
- Proposals for the playtest: the gun is shown; icon 48 px with 8 px gaps (five weapons take 272 of the bar's 320 px); count size 32 in white; icons start 12 px right of the bar at its top. Bangers is all caps, so the count reads "X2" on screen (the text is "x2").
- `gift_arrows.gd`'s HUD keep-clear rectangles now name the heart and the icons instead of the label.
- Tests: new `tests/unit/hud/test_hud_weapon_icons.gd` (gun only at the start, order taken, count and its updates to x8, comic font and outline, new run resets, five weapons at tier 8 fit beside the bar, bar 72 x 320 with the heart and no label); the layout, combo, combo-hidden, values and gift-drops tests updated (layout tests now run with all five weapons at mixed tiers; "Car Health" checks became heart and icon checks; "top half" became top 60 percent).
- Results: full GUT suite 1372/1372 passed (exit 0); `python -m unittest discover -s game/tools` 395 OK (1 skipped); `python -m unittest discover -s tools` 451 OK.
- Screenshots (fixtures `tests/fixtures/weapon_icons_gun.tscn`, `weapon_icons_mixed.tscn`): `art-archive/T-276/screenshots/top_left_gun_only.png` and `top_left_all_five_mixed.png` (gun x2, wiper x3, flamethrower tier 1, molotov x8, underglow x2). Nothing overlaps the timer, coins or car at 1152 x 648; no Redgull red besides the heart. The heart is small (the same 22 x 20 picture as the likes bar's); say if it should be bigger.
- Documents updated: `docs/hud-and-menus.md` (Content, Top left), `game/README.md` (HUD section). 0 PixelLab generations.
- 2026-10-23, in-qa → in-progress: QA round 1: full GUT suite exits 139 in test_combo_broken_popup.gd:104 on this branch (reproducible, master passes); other criteria pass
