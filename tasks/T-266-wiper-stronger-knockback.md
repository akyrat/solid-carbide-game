---
id: T-266
title: The windshield wiper pushes minions about twice the car's length
status: done
from: project-lead
to: game-data
lead: Coursework
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/data/weapons.json, game/README.md, tasks/T-170-the-windshield-wiper-sweeps-in-front.md]
files_expected_to_change: [game/data/weapons.json, game/tests/, docs/weapons.md, game/README.md, art-archive/T-266/screenshots/]
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

The board's decision (Weapons, Decisions, "A stronger wiper push", 2026-10-22): when the windshield wiper is first picked up (tier 1), a minion it hits is pushed back about twice the car's size, taken as twice the car's length: **6 units** (the car is 1 unit wide and 3 long; today `knockback_distance` is 1.5). Change the number in `game/data/weapons.json`; the tiers keep their multipliers (tier 5 still x1.5), so the final tier pushes 9. The kaiju is still never pushed. If a 6-unit push needs the code to move the minion over several steps rather than at once (so it doesn't jump through a wall, boulder or off a ledge oddly), say so and do it; minions still stop at obstacles and fall off ledges as today. Update Weapons, Content (the wiper's numbers) and `game/README.md`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a short GIF of the wiper pushing minions at tier 1.

## Acceptance criteria

- [ ] `weapons.json` has the wiper's tier-1 push at 6 units, the tier multipliers unchanged (final 9); a test shows a minion hit at tier 1 ends about 6 units from where it was, and the kaiju is not pushed (QA: pass; json 6, tiers 5/8 = 9, new test measures about 6 units, kaiju test passes)
- [ ] A pushed minion still stops at buildings and boulders and drops off ledges as before (tests) (QA: pass; existing wall, boulder and ledge knockback tests pass at the new size, full GUT green)
- [ ] Weapons, Content, and `game/README.md` give the new numbers; the GIF is in `art-archive/T-266/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass; docs and README show 6 and 9, GIF and contact sheet present and show minions flung out, GUT 1366/1366, Python 451 and 395 OK; tier 5 card text changed only 1.5/2.25 to 6/9 and matches the data)

The board's review: pick up the wiper and watch minions fly.
Board review files: the GIF in `art-archive/T-266/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's request: the wiper pushes minions 6 units at its first level.

### 2026-10-23, In progress → In QA

Wiper push built: 6 units at tier 1, 9 at the last tier (data only). The tier 5 card's numbers now read 6 to 9. Sent to QA.

### 2026-10-23, Needs playtest

QA passed all 3. Ready to play in the game build: wiper pushes 6, last tier 9.

### 2026-10-25, Needs playtest → Done

Played and approved by the board in the game build; merged into master.

## Result notes

Done (Game Data Agent).

- `game/data/weapons.json`: wiper `knockback_distance` 1.5 -> 6; tier multipliers unchanged (tier 5 x1.5, final 9).
- No code change needed: the minion's knockback already moves it in even shares over 0.15 s (about 0.8 unit per physics step) through the same obstacle, boulder and ledge handling as walking; the existing tests in test_minions.gd (walls and boulders at 6) and the two ledge tests (8 units) already cover pushes of this size and pass.
- Tests: new `test_the_tier_1_push_is_6_units_and_the_last_tier_9` in test_windshield_wiper.gd (a real minion ends about 6 units from where it was hit, straight away from the car; tiers 1/5/8 = 6/9/9; the kaiju test is unchanged and passes); test_weapon_data.gd updated (6 and 9). Full GUT suite: 1366/1366 pass. Python: `tools` set OK (451); `game/tools` set OK (395) once the level-up text below was fixed.
- Side effect to flag: the tier 5 level-up card said "from 1.5 to 2.25". I changed it to "from 6 to 9" in `game/scripts/ui/level_up_texts.gd`, its test, and the text table in T-171's ticket (which a checker script compares against). A Narrative Theme read of that line may be wanted.
- Docs: `docs/weapons.md` (Content numbers, built-wiper knockback line) and `game/README.md` updated. The long GDD was not regenerated (the Project Lead's merge step does it).
- Screenshots: `art-archive/T-266/screenshots/wiper_push_tier1.gif` (tier 1, minions flung from the arm; the recording log showed each hit minion moving about 5.2 units in 0.3 s, i.e. 6 minus the walk back towards the car) and `wiper_push_frames.png` (contact sheet I looked at: the arm sweeps and minions end up scattered several car lengths out). Recording fixture: `game/tests/fixtures/weapons/wiper_push_gif_demo.tscn`.
- Refusals: one hook refusal (a Godot recording command chained after rm/mkdir); I reran the Godot part on its own, as the hook said. No other.
- 2026-10-25, needs-playtest → done: The board played the game build and checked every objective on the patch notes: happy with everything (2026-10-25).
