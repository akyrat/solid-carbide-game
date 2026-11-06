---
id: T-539
title: Paired meteors: drifting between a pair hurts the kaiju
status: in-qa
from: project-lead
to: enemy-behavior
lead: Rails
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/enemies.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/visual-style.md, docs/extended-narrative.md, game/scripts/enemies/kaiju_meteors.gd]
files_expected_to_change: [game/scripts/enemies/, game/data/enemies.json, game/data/meteor_fx.json, game/tests/, game/docs/enemies/, docs/enemies.md]
model: opus
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Build Enemies, Decisions, "Paired meteors hurt the kaiju". The kaiju's meteors land in pairs (propose the distance between the two, wide enough to drift through). After both have landed, a drifting car that crosses the segment between the two boulders hurts the kaiju (propose the damage next to the 1500 health and the 1-minute fight), and both boulders of that pair are destroyed at once (a short break-up effect). Show the link: for example a beam or energy line that runs from the pair to the kaiju with a hit flash on the kaiju; placeholder effect drawn in code, no generated art, no new text. Each pair pays once. Make it easy to see which two meteors are paired (for example a faint line between them). Keep the existing meteor rules (warning area, damage on landing, 10 s life) unless pairing needs a change; list any change.

The board's review: play the combined build from C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot before merging (the kaiju arrives at 3:00; God mode can help).

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Meteors land in pairs at the proposed distance (test). (QA: pass: test_meteor_pairs 10/10, pairs at data distance 9, 2026-11-06)
- [ ] A drifting car crossing between a landed pair damages the kaiju by the data's amount and destroys both boulders; driving through without drifting does neither; a pair pays only once (tests). (QA: pass: tests cover drift damage 100, both boulders removed, no drift nothing, pays once)
- [ ] The link effect from the pair to the kaiju and the hit flash play (test that they are spawned). (QA: pass: tests check beam, break-ups and kaiju flash are spawned)
- [ ] docs/enemies.md Content describes it with each proposed number. (QA: pass: docs/enemies.md has 4 meteors in 2 pairs, 9 units, 100 damage, timings)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass: qa_check 2 test sets green again at distance 9, tools set skipped)
- [ ] A GIF or frame strip in art-archive/T-539/screenshots/ shows a drift through a pair, the link and the kaiju getting hit. (QA: pass: GIF, strip and 2 stills retaken at 9 units, present in art-archive/T-539/screenshots/)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-05, Open → In progress

Started: the agent is working in C:\solid-carbide-worktrees$t.

### 2026-11-05, In progress → In QA

Built: meteors land in 2 pairs 7 units apart (4 per attack, was 3); a drift through a pair does 100 to the kaiju with a beam and breaks both. QA is checking it.

### 2026-11-05, In QA → Needs playtest

QA passed. In the combined playtest build: C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot

### 2026-11-06, Needs playtest → In progress

The board's tweak: the pair's meteors a bit further apart. Back with the agent; merges after QA.

### 2026-11-06, In progress → In QA

Tweak in: pair meteors 9 units apart (was 7). QA is checking it; it merges once QA passes.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### Enemy Behavior Agent, 2026-11-05

Built Enemies, Decisions, "Paired meteors hurt the kaiju". Placeholder effects drawn in code, no generated art, no text, SFX untouched, nothing in game/data/levels/.

**What it does**
- Each kaiju attack now drops 2 pairs (4 meteors). The two of a pair land 7 units apart (centre to centre), both within 10 units of the car, both on spots the single-meteor rules accept, and the ground between the two boulders is checked open for the car (no building, boulder or prop in the gap). If no pair fits, fewer pairs fall.
- A faint cyan dashed line joins the two of a pair on the ground from the warning on; once both have landed it turns brighter and pulses (armed).
- Once both have landed, a car that is drifting (car.model.is_drifting and not airborne, the same state the drift marks use) and whose physics step crosses the line between the two boulder centres strikes the pair: the kaiju takes 100, both boulders are removed from the map at once with a break-up (rock chunks in the boulder colours plus a magenta ring, 0.55 s), and a jagged cyan/pink beam shoots from the pair's middle to the kaiju's chest (0.15 s travel, 0.7 s total) with a burst of rings and rays on the kaiju plus its usual red hit flash (from take_damage).
- Not drifting does nothing. Each pair pays once. A pair whose boulder faded away or was never placed pays nothing, and so does any pair when no live kaiju is on the map.

**Proposed numbers (the board's playtest), in game/data/enemies.json, meteor_attack**
- `pair_distance_units` 7: leaves 4 units of free ground between the two 3-unit boulders (four car widths), so a car sliding sideways fits with room to spare. It is above the 4.5 the existing clearance rule needs between boulders, and it fits two pairs within the 10-unit landing radius.
- `pair_damage_to_kaiju` 100: 1/15 of the 1500 health, about 2.5 s of a strong build's fire at half effectiveness (kaiju._comment's 40/s). The 60 s fight holds 7 attacks (14 pairs), so drifting through 5 pairs is a third of its health: worth chasing, but it doesn't replace the weapons.
- `meteors_per_attack` 4 (was 3): **a change to the existing rules**, because pairing needs an even number. I picked 2 pairs over 1 so there are more chances to strike. This means one extra hazard per attack near the car.
- Placeholder timing constants (code rules, like the dust's 0.5 s) in meteor_pair_fx.gd: LINK_SECONDS 0.7, LINK_TRAVEL_SECONDS 0.15, KAIJU_BURST_SECONDS 0.45, BREAKUP_SECONDS 0.55. In kaiju_meteors.gd: PARTNER_TRIES 16, GAP_CLEAR_RADIUS 0.5 (the car's half width), GAP_SAMPLE_UNITS 0.5.
- Everything else is unchanged: the warning area and its 2 s, damage and knockback on landing, the 10 s life and 2 s fade, the schedule. Struck boulders vanish at once and don't fade.
- Choices the ticket left open: the crossing counts on the line between the boulder centres (the boulders are solid, so in practice that means through the gap). A pair whose boulder is still waiting for the car to move off counts as landed, and a strike drops that waiting boulder too. The damage carries no weapon source, so the recap's weapon kills are untouched.

**Files**
- C:\solid-carbide-worktrees\T-539\game\scripts\enemies\kaiju_meteors.gd (pick_pair, gap_is_clear, add_pair_warnings, is_pair_armed, car_is_drifting, _check_pair_crossings, strike_pair, the pair_struck signal, pair line and strike drawing hooks)
- C:\solid-carbide-worktrees\T-539\game\scripts\enemies\meteor_pair_fx.gd (new: placeholder drawings)
- C:\solid-carbide-worktrees\T-539\game\data\enemies.json (meteor_attack: two new keys, meteors_per_attack 4, reasons in _comment)
- C:\solid-carbide-worktrees\T-539\game\scripts\data\enemy_data.gd (doc comment only)
- C:\solid-carbide-worktrees\T-539\game\tests\unit\enemies\test_meteor_pairs.gd (new, 10 tests), C:\solid-carbide-worktrees\T-539\game\tests\unit\test_enemy_data.gd (new keys; 28 meteors in the kaiju minute, was 21; whole pairs)
- C:\solid-carbide-worktrees\T-539\game\tests\fixtures\meteor_pair_strike_demo.tscn/.gd and C:\solid-carbide-worktrees\T-539\game\tools\record_meteor_pair_gif.sh (the recording)
- Docs: C:\solid-carbide-worktrees\T-539\docs\enemies.md (Content: new "Paired meteors hurt the kaiju (built in task T-539)" with every number; the meteor attack's warning now says 4 circles in 2 pairs), C:\solid-carbide-worktrees\T-539\game\docs\enemies\meteors.md ("Paired meteors (T-539)").
- Kaiju, minion and spawner files untouched (to stay clear of T-538).

**Tests run (the changed code's, foreground)**
- test_meteor_pairs.gd 10/10 (pairs at the data distance, near the car, open gap; a drift through a landed pair does the data's damage, removes both boulders and spawns the beam, two break-ups and the kaiju's flash; no drift does nothing; pays once; crossing beyond a boulder, before both have landed, or after the fade does nothing; a new run clears it; drawings run)
- test_kaiju_meteors.gd 28/28 (the partner is kept within the landing radius after the first run caught one 13.7 units out), test_enemy_data.gd 10/10
- Also the other meteor users: test_meteors_minions_pickups.gd 11/11, test_meteor_fx.gd 8/8, test_run_sounds.gd 17/17, test_run_hearts.gd 16/16, test_game_map.gd 12/12, test_run_data.gd 12/12. No SCRIPT ERROR in any log. The full sets were not run (QA's job).

**Screenshots** (C:\solid-carbide-worktrees\T-539\art-archive\T-539\screenshots\)
- meteor_pair_strike.gif: the pair lands with its line, the car really drives with W and steering (drift state on, drift marks showing) through the gap, both boulders break, the beam runs to the kaiju standing to one side, it flashes red and its health bar drops (1500 to 1400).
- meteor_pair_strike_strip.png: 8 frames of the same.
- meteor_pair_strike_beam.png (the beam and the burst on the kaiju), meteor_pair_landed_line.png (the landed pair with its line).
- To re-record from the repo root: `bash game/tools/record_meteor_pair_gif.sh <out.gif> 4 2` (GIF_ARGS="--scale 0.6 --shared --crop 0.8 --first 30" was used).

Documents affected: docs/enemies.md (and game/docs/enemies/meteors.md).

### QA, 2026-11-05
All 6 criteria pass. qa_check: 2 test sets passed (tools set skipped), documents changed, 4 screenshots, 6 marks pass.
- 2026-11-06, needs-playtest → in-progress: The board: space the meteors of a pair a bit further apart, so it is easier to drift through. No board QA needed: pass QA and merge.

### Enemy Behavior Agent, 2026-11-06: the board's tweak (quick tuning)

The board, after playing: "space the meteor a bit further apart to make it easier to drift through." `pair_distance_units` 7 -> **9** (game/data/enemies.json, meteor_attack; reason in its _comment). The free ground between the two 3-unit boulders goes from 4 units to 6 (six car widths). It still fits: 9 is under the 20-unit diameter of the 10-unit landing radius and above the 4.5 the clearance rule needs. Both meteors of a pair still land within 10 units of the car, and the gap check still runs. In the test, both pairs were found in 12 of 12 seeded attacks. No other number changed.
- docs/enemies.md Content, 'Paired meteors hurt the kaiju': 9 units apart, 6 units of free ground, citing the board's tweak.
- test_meteor_pairs.gd: the pairs-found check is now at least 11 of 12 attacks (was 10), so a distance too wide for the landing radius would fail it. The other tests read the distance from the data.
- Tests (foreground): test_meteor_pairs.gd 10/10, test_kaiju_meteors.gd 28/28, test_enemy_data.gd 10/10, no SCRIPT ERROR.
- Screenshots retaken at 9 units in art-archive/T-539/screenshots/: meteor_pair_landed_line.png, and also meteor_pair_strike.gif, meteor_pair_strike_strip.png and meteor_pair_strike_beam.png. The fixture's drift still strikes the pair at 2.3 s, kaiju 1500 -> 1400.

### QA, 2026-11-06 (after the 7 to 9 tweak)
All 6 criteria pass. qa_check: 2 test sets passed (tools set skipped), documents changed, 4 screenshots. pair_distance_units is 9 in data and docs/enemies.md.
