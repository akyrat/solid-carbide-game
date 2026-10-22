---
id: T-229
title: Re-record the README's GIFs of the game's current state
status: blocked
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

- [ ] GIFs in `art-archive/T-229/screenshots/` show, from the real game with the HUD: drifting on a street with enemies chasing, the drift counter counting and LONG DRIFT! at the drift's end; drifting off a height-6 rooftop; an air 360 with AIR 360!, the airtime counter and HANG TIME!; the kaiju on its shadow with meteors falling; enemies dropping off a ledge; pickups pulled in by the magnet (QA: pass / fail)
- [ ] Each GIF is under 5 MB and a few seconds long (QA: pass / fail)
- [ ] The root README's "Current state of the game" section shows the new GIFs by relative path, one line each (QA: pass / fail)
- [ ] No game behaviour changed; the full GUT suite and all Python tool tests pass (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
