---
id: T-286
title: "A weapon visibly grows, animated, when a size upgrade is picked"
status: needs-playtest
from: project-lead
to: weapon-behavior
lead: Coursework
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/README.md, game/data/weapons.json, game/scripts/weapons/, game/scripts/ui/level_up_screen.gd, tasks/T-266-wiper-stronger-knockback.md, tasks/T-267-smaller-exhaust-flame-hit-matches-art.md, tasks/T-274-underglow-drawn-in-code.md]
files_expected_to_change: [game/scripts/weapons/, game/tests/, docs/weapons.md, game/README.md, art-archive/T-286/screenshots/]
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

The board's playtest note on the game build (Weapons, Decisions, "Size upgrades grow on screen", 2026-10-24): "When something is upgraded for its size, like the wipers or the underglow or the flame, after I click it, I want to see the weapon enlarge, animated."

Today a size tier's new size just appears. When the board picks a level-up card or gift pack that raises a weapon's size, the weapon should visibly grow from its old size to its new one once the game resumes.

- **Which weapons:** every tier that raises a weapon's size in `weapons.json`: the wiper's sweep, the underglow's radius, the flamethrower's flame, and the molotov's fire area if it has size tiers. List which tiers count in the result notes.
- **The grow animation:** a short grow with a small overshoot that settles on the new size, like T-273's likes bar spring. The length and overshoot are your proposal, in one place, with reasons.
- **Damage:** the damage area follows the drawn size throughout, so nothing is hit outside what is drawn. Damage and timing are otherwise unchanged.
- **Other tiers:** a tier that doesn't change size plays no grow.

Built on the game build: the Project Lead makes your folder from `playtest/game-build`, so the board plays it there. End with a short GIF of each of these growing after its card is picked: the wiper, the underglow and the flame.

## Acceptance criteria

- [ ] Tests show that picking a size tier makes the weapon's drawn size go from the old to the new size over the proposed time, settling exactly on the data's new size, for each size-upgrading weapon; that a non-size tier plays no grow; and that it pauses while the game is paused (QA: pass; test_size_grow.gd covers curve 0.4 s settling exactly, each weapon old to new, every data size tier grows and others do not, pause stands still)
- [ ] Tests show the damage area matches the drawn size during the grow, and the weapons' existing damage and tier tests pass unchanged (QA: pass; drawn ring, reach and flame scale equal the hit area per step; diff only adds test files, none changed; wiper tier 1 art scale is 1.0 so unchanged, hit area uses the same length())
- [ ] Weapons, Content, and `game/README.md` describe it with the numbers and reasons; the GIFs are in `art-archive/T-286/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass; weapons.md and README give 0.4 s / 3.0 with reasons; 3 GIFs present; GUT 1419/1419 exit 0, tools 451 OK, game/tools OK)

The board's review: pick size upgrades for the wiper, underglow and flamethrower and watch each grow.
Board review files: the GIFs in `art-archive/T-286/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-24, Open → In progress

Started: weapons grow on screen, animated, when a size upgrade is picked; built on the game build.

### 2026-10-24, In progress → In QA

Grow built: wiper, underglow and flame grow to their new size in 0.4 s with a small overshoot when a size card is picked; damage follows. Wiper art now also stretches with its tiers. Sent to QA.

## Result notes

Written by the agent when it finishes.

- **Built:** `game/scripts/weapons/size_grow.gd` (`SizeGrow`): the whole curve in one place. `DURATION` 0.4 s, `OVERSHOOT` 3.0 (ease-out-back like T-273's `LikesSpring`; passes the new size by about 20% of the step, about 5% of the size, then settles exactly on the data's size). Reasons: long enough to read as growing, short enough not to wait for; a small pop, not a wobble; a little longer than the likes bar's 0.25 s because a weapon is bigger. Each size weapon holds a `grow`, advances it first in its physics `step` (so it stands still while paused) and reads its size from it: wiper `length()`, underglow `radius()`, flame `drawn_scale()` (`grow.value * drift ramp`). The drawing and the hit area read the same value, so damage follows the drawn size at every step.
- **Which tiers grow (the data's size effects):** wiper 2 and 6 (length x1.2, x1.3); underglow 2, 5, 8 (radius x1.2, x1.25, x1.3); flamethrower 2, 4, 6 (size x1.2, x1.2, x1.3). Every other tier plays no grow. **Molotov tiers 2 and 7 (fire radius) do not grow:** each fire is made at its bottle's size when it lands, so there is no standing weapon; the next bottle is simply bigger. Easy to add for fires already burning if the board wants it.
- **Only a picked upgrade grows:** `weapon.gd` flags `upgrade()` (what the level-up and gift pack call). `set_tier()` called directly (new run, tests), getting the weapon (0 to 1) and a tier that keeps the size snap. This kept every existing weapon test unchanged.
- **Found and fixed on the way:** the wiper's art (T-175 sheet) was never stretched, so the drawn blade stayed the same size at every tier and only the hit area grew. It is now stretched by `length() / 2.5` (`WiperDrawing.art_k`). The wiper art is thin and dark; at tier 1 it is unchanged.
- **Tests:** new `game/tests/unit/weapons/test_size_grow.gd` (9 tests): curve start, overshoot and exact end; each of the three weapons goes old to new, overshoots and settles exactly on the data's size; every size tier in the data grows and every other tier does not; getting a weapon or a new run does not grow; it stands still while paused and carries on after; wiper reach, underglow circle (drawn ring equals damage circle at every step) and flame outline (drawn scale equals hit scale, outline grows by the data's ratio) follow the drawn size. Full GUT suite: 1419/1419, exit 0, no 139. Python: `tools` 451 OK; `game/tools` 395 OK (1 skipped).
- **Docs:** `docs/weapons.md` (Content, "Size upgrades grow on screen (built in task T-286)") and `game/README.md` ("Size upgrades grow"). The long GDD is not regenerated (the Project Lead's merge step does it).
- **GIFs (frames looked at through contact sheets):** `art-archive/T-286/screenshots/wiper_grow.gif` (tier 2 at 1 s, tier 6 at 3 s; the blade visibly lengthens, though thin), `underglow_grow.gif` (tiers 2 and 5; the ring swells, small pop visible), `flamethrower_grow.gif` (drifting circle, tiers 2 and 4; the flame is bigger after each, less obvious because the drift ramp also moves its size). Fixture: `game/tests/fixtures/weapons/size_grow_demo.tscn`, picked by the environment variable `SIZE_GROW_WEAPON`.
- **Open point for the playtest:** the underglow rebuilds its pixel image on each radius change, so during the 0.4 s grow it rebuilds about 20 images; not noticed in the recording, but worth watching on a slow computer.
- **Refusals:** one hook refusal of `which ffmpeg` (not needed; I used Pillow). I also ran two small edits as inline Python by mistake against the instruction to use Edit; they were applied and checked with git diff.
