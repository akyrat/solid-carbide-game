---
id: T-229
title: Re-record the README's GIFs of the game's current state
status: in-qa
from: project-lead
to: game-loop
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [README.md]
files_to_read_first: [tasks/README.md, README.md, game/README.md, tasks/T-217-gifs-of-the-game-for-the-readme.md, game/tests/fixtures/readme_gif_demo.gd, game/tools/record_readme_gif.sh]
files_expected_to_change: [art-archive/T-229/, game/tests/fixtures/, game/tools/, README.md]
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

T-217 put three GIFs in the root README's "Current state of the game" section. Since then the board has approved: the car in 32 directions (T-102), the aerial tricks with no drifting in the air (T-219), health drops with their canister art (T-220, T-221), the pickup magnet (T-222), the flame, bullet and burning art (T-071), the meteors' comet tail and impact (T-070), enemies following up ramps and dropping off ledges (T-207, T-226), the underglow at the car's height (T-225), the camera following the car's height (T-228), and the new drift and airtime combo mechanics (board, 2026-10-22): the airtime trick with its HANG TIME! popup (T-242), the live airtime counter (T-243), a drift paying once at its end with LONG DRIFT! (T-246) and the live drift counter (T-247). Two of T-217's GIFs are also weak: the first is on the gravel square rather than a street, and the kaiju one shows the kaiju beside its shadow (a bug T-226 fixed).

Re-record the README's GIFs from today's master with T-217's fixtures and tools:

1. **The car drifting on a street while enemies chase it** (on asphalt; place the car where the scripted drive isn't stopped by boulders, and enough minions to read as a chase), with the drift counter counting and the drift paying out as LONG DRIFT! when it ends.
2. **The car drifting off a height-6 rooftop and landing**, with the camera following its height.
3. **An aerial trick:** an air 360 off a rooftop, with its AIR 360! popup, the airtime counter counting while the car is up, and HANG TIME! on landing.
4. **The kaiju chasing the car while meteors fall**, standing on its shadow, with the meteors' tails and impacts.
5. **Enemies dropping off a ledge** after the car, and **pickups (coins, a health canister) pulled in by the magnet**: one GIF or two, your choice.

Each a few seconds, under 5 MB, from the real game with the HUD. Save them in `art-archive/T-229/screenshots/` and update the README section to show them, one line each (keep T-217's GIFs in the archive; never delete art). Don't change game behaviour.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] GIFs in `art-archive/T-229/screenshots/` show, from the real game with the HUD: drifting on a street with enemies chasing, the drift counter counting and LONG DRIFT! at the drift's end; drifting off a height-6 rooftop; an air 360 with AIR 360!, the airtime counter and HANG TIME!; the kaiju on its shadow with meteors falling; enemies dropping off a ledge; pickups pulled in by the magnet (QA: pass; I checked frames of all six: street drift with minions, drift counter, FULL 360! and LONG DRIFT! with COMBO; rooftop drift with the camera following height; air 360 with airtime counter, AIR 360! and HANG TIME!; kaiju on its shadow with warning circles and meteors; minions at the rooftop edge; coins and canisters near the car. Weak but present: tiny minions, canisters and meteor tails)
- [x] Each GIF is under 5 MB and a few seconds long (QA: pass; 2.5, 3.9, 3.7, 3.4, 3.9 and 4.0 MB; 2.1 to 4.7 s each)
- [x] The root README's "Current state of the game" section shows the new GIFs by relative path, one line each (QA: pass; README lines 11 to 31 show the six GIFs by relative path art-archive/T-229/screenshots/, one line each)
- [x] No game behaviour changed; the full GUT suite and all Python tool tests pass (QA: pass; T-229's own commits touch only README.md, the fixture, game/tools script, art-archive and its ticket, and the game/scripts diff is the merged tickets only; GUT 1329/1329, game/tools Python 393 OK, tools Python 446 OK)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Started at the board's word, on master plus the camera, airtime trick, drift pay and both counters (all passed QA, not yet played).

### 2026-10-22, In progress → In QA

Six new GIFs recorded, including the drift and airtime counters, LONG DRIFT! and HANG TIME!. Some are weak (tiny minions and canisters). Sent to QA.

## Result notes

Written by the agent when it finishes.

Six GIFs in `art-archive/T-229/screenshots/` (T-217's three stay in `art-archive/T-217/screenshots/`), all from the real game with the HUD, recorded with `bash game/tools/record_readme_gif.sh <mode> ...` (Godot movie maker, 30 fps, every second frame kept). I looked at frames of each:

- `drift_chasers_long_drift.gif` (3.9 MB, 5.3 s): car on asphalt, 8 minions placed round it (the run's own spawner adds more), a straight run then one long drift; the drift counter counts, FULL 360! pops mid-drift and LONG DRIFT! +0.75 pays as the drift ends, COMBO shows. Weakness: minions are small at this zoom, and the car starts beside a boulder.
- `drift_off_rooftop.gif` (3.7 MB, 3.3 s): drift along the height-6 rooftop, off its east edge, landing in the street; the camera follows the car's height (rooftop fills the view, then the street). Drift counter, then the airtime counter in the air.
- `air_360_hang_time.gif` (2.5 MB, 2.3 s): off the rooftop with W and D held in the air: the airtime counter counting, AIR 360! and HANG TIME! popups on landing, COMBO X1.7. Short because the jump is.
- `kaiju_meteors.gif` (3.9 MB, 3.3 s): the kaiju (standing on its shadow, health bar over it) close to the car, orange warning circles, meteors falling, impacts and boulders. Weak: the zoom (20) that keeps both in view makes the car small and the meteor tails hard to see; the gravel's noise forced a low scale (0.55) and 96 colours.
- `enemies_drop_off_ledge.gif` (3.4 MB, 4.3 s): the car parked in the street under the height-3 rooftop's south edge; minions walk off the edge and fall to it. Weak: the minions are small and look yellowish in the palette; the fall is only a few frames.
- `pickups_magnet.gif` (4.0 MB, 3.5 s): coins and health canisters beside the car's path are pulled in; the coin count rises and the health bar (held at half for this GIF only) refills. Weak: the canisters are tiny red specks.

Changes: `game/tests/fixtures/readme_gif_demo.gd` has the modes street (trick detection on, minions placed), jump, trick, kaiju, magnet and drop; it only drives and sets up the run, no game behaviour changed. `game/tools/record_readme_gif.sh`'s usage line lists the modes. The root README section shows the six GIFs, one line each. A shared palette was tried first and dropped (it turned the HUD heart brown); the finals use per-frame palettes (`--colors 128` for street, jump, trick and drop; `--colors 96 --scale 0.55` for kaiju and magnet), `--crop 0.95`, with `--first/--last` windows.

Tests: full GUT suite 1329/1329 pass; `python -m unittest discover -s game/tools -p "test_*.py"` 393 OK (1 skipped); `python -m unittest discover -s tools -p "test_*.py"` 446 OK. No refusals.
