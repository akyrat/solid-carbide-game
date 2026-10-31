---
id: G-009
title: Mission packs and driving power-ups, as decided by the board on 202...
status: building
art_cap: 40
art_used: 0
iteration: 2
max_iterations: 20
created: 2026-10-31
lead: Goal-G-009
session: Greenbull
---

## Goal

Mission packs and driving power-ups, as decided by the board on 2026-10-31 (Game loop architecture, Decisions, 'Mission packs'; Drifting, Decisions, 'Driving power-ups'): one mission at a time on a pixel-art notebook page on the left side of the HUD with checkbox goals, quantity progress and crossing off; 30 missions a run, reset every run, the first 5 fixed and missions 6 to 30 generated at random from trick combinations; a completed mission pauses the run and offers 2 driving power-ups (new or next tier) on an overlay distinct from the weapons' gift menu; the four power-ups Rev Charge, Jump, Bouncy Bumpers and Rusty Overcoat with tiers and icons, and Rev Charge's visible effect. Text for every new label comes from the Narrative Theme agent first.

## Goal acceptance criteria

- [ ] On playtest/G-009 the game's three test sets (Godot GUT, the Python tool tests, the data checks) all pass, and the new tests cover the missions, the power-up gift and the four power-ups. (QA: pass / fail)
- [ ] Starting a run in the main game scene shows mission 1 on a pixel-art notebook page on the left side of the HUD (art made with PixelLab, in game/art/), with one checkbox per goal. A screenshot is in the ticket's art-archive folder. (QA: pass / fail)
- [ ] A headless test drives the five fixed missions in order: (1) drift 4 s continuously, (2) 10 alt drifts, (3) 3 s of airtime, (4) 3 air 180s, (5) an air 360. Each one completes from simulated trick events, and quantity goals show their progress (for example '2/10'). (QA: pass / fail)
- [ ] In every run, missions 6 to 30 come from the mission generator, using only the trick types and amount rules in the data file. A test over several seeds checks that each run has exactly 30 missions and that the first 5 are always the same. A new run starts again from mission 1. (QA: pass / fail)
- [ ] When a goal is completed its checkbox is ticked and the goal is crossed off. When every goal of a mission is done, the run pauses and the driving power-up gift overlay opens with exactly 2 choices, each a new power-up or the next tier of one the car already has. A screenshot shows that this overlay looks different from the weapons' level-up screen. (QA: pass / fail)
- [ ] Each of the four power-ups (Rev Charge, Jump, Bouncy Bumpers, Rusty Overcoat) has a data entry with tiers, a PixelLab icon in game/art/ and its own passing tests: Rev Charge charges while W and S are held and fires a boost when S is released, with a visible charge and boost effect; Jump hops on Space and its airtime counts towards the airtime and air-trick goals; Bouncy Bumpers makes the wall bounce longer; Rusty Overcoat damages enemies on contact. (QA: pass / fail)
- [ ] Every new label the player sees (the notebook header, the goal phrasings, the overlay header, the power-up names and the tier descriptions) is read from the Narrative Theme agent's text entries. A test or grep shows no hard-coded or placeholder strings in the new scenes and scripts. (QA: pass / fail)

## Open questions

- Do the driving power-ups last only for the run (reset like the missions), or carry over? The docs say missions reset every run but don't say this for power-ups.
- How many tiers does each power-up have? The docs leave the tier numbers to Driving & Drift, but not whether the four share a tier count, or how it compares with the weapons' 8.
- What does the overlay offer once every power-up is at its last tier (the weapons give 4 coins)? And what if only one choice is left?
- If a mission completes while the weapons gift screen is open, or both come due at once, which comes first, or do they queue?
- Which tricks may the generator use for missions 6 to 30 (thread the needle, jump-overs, grinds, flips, HANG TIME, FULL 360, drift duration)? Can a mission mix several tricks, and is 'without crashing' or 'within a time' a goal type?
- Space is already used to leave a grind and to take a level-up card. With Jump owned, does Space on a wall still leave the grind, or hop?
- Does Rusty Overcoat damage the kaiju too, and does contact still hurt the car (lose a heart) while it is owned?
- Can Rev Charge's boost go past the 3.0x top speed, and does it pay a trick or count for missions?
- Does a completed mission show a celebration (sound, animation) before the overlay? Is SFX in scope for this goal?
- After mission 30, what does the notebook show for the rest of the run?
- Is the notebook page one of the HUD pieces the player can move (T-452/T-453), and where on the left is its default spot on the board's HUD layout page?

## Sub-goals

| rank | id | title | score | why | verdict | tickets |
|---|---|---|---|---|---|---|
| 1 | S2 | Mission and power-up data (Game Data, numbers proposed by Driving & Drift) | unblocks 12, value 5 | The mission tracker, the generator, the overlay and each power-up read their rules and tier numbers from data. | covered | T-455 |
| 2 | S3 | Mission tracker and generator in the run (Game Loop) | unblocks 6, value 5 | This is the core of the goal: missions progress from tricks, complete one at a time, reset every run and trigger the gift. | covered | T-457, T-455 |
| 3 | S1 | Text for missions and driving power-ups (Narrative Theme) | unblocks 5, value 5 | The rule is that player-facing text comes first and is never a placeholder. The notebook, the overlay and the power-up cards all need it. | in-flight | T-456 |
| 4 | S5 | Driving power-up gift overlay (UI + Game Loop) | unblocks 3, value 5 | A completed mission must pause the run and offer 2 power-ups on an overlay that is clearly distinct from the weapons' gift menu. | in-flight | T-459 |
| 5 | S4 | Notebook mission page on the HUD, placeholder art (UI) | unblocks 2, value 5 | The board asked for the current mission to show on a notebook page on the left with checkboxes, progress and crossing off. | in-flight | T-458 |
| 6 | S6 | Rev Charge power-up, with a placeholder charge/boost effect (Driving & Drift) | unblocks 2, value 4 | This is one of the four power-ups, and the board asked for its visible effect. | in-flight | T-460 |
| 7 | S7 | Jump power-up (Driving & Drift) | unblocks 1, value 4 | This is one of the four power-ups, and the board said its airtime counts towards the airtime and air-trick goals. | in-flight | T-461 |
| 8 | S8 | Bouncy Bumpers power-up (Driving & Drift) | unblocks 1, value 3 | This is one of the four power-ups: a longer bounce off obstacles. | in-flight | T-462 |
| 9 | S9 | Rusty Overcoat power-up (Enemy Behavior) | unblocks 1, value 3 | This is one of the four power-ups: the car damages enemies on contact. | in-flight | T-463 |
| 10 | S10 | Art: notebook page and power-up overlay (Asset Generation, style loop) | unblocks 0, value 4 | The board asked for a pixel-art notebook page, and the overlay must look clearly distinct. Both replace S4/S5's placeholders. | in-flight | T-464 |
| 11 | S11 | Art: four power-up icons (Asset Generation, style loop) | unblocks 0, value 4 | Each power-up must have an icon. | in-flight | T-465 |
| 12 | S13 | Integration check of a whole run (QA/Integration) | unblocks 0, value 4 | Confirms the missions, the overlay, the power-ups and the existing level-up gift work together in one run. | in-flight | T-467 |
| 13 | S12 | Art: Rev Charge charge and boost effect (Asset Generation, style loop) | unblocks 0, value 3 | The board asked for a visible charging and boost effect for Rev Charge. | in-flight | T-466 |

### S2: Mission and power-up data (Game Data, numbers proposed by Driving & Drift)

Needs: nothing.

- A missions data file holds the 5 fixed missions in the board's order, with their trick type and amount, and the generator's proposed rules: which tricks are allowed, how amounts grow from mission 6 to 30, and how many goals a mission has. Each rule has a reason note marked as a proposal for the playtest.
- A power-ups data file holds Rev Charge, Jump, Bouncy Bumpers and Rusty Overcoat, each with its tiers and per-tier numbers (marked as proposals) and an icon path.
- A data check test validates both files: 5 fixed missions, a total of 30, the four power-ups present, and at least 1 tier each.

### S3: Mission tracker and generator in the run (Game Loop)

Needs: S2.

- RunState (or a new mission node in the run) holds the run's 30 missions: the 5 fixed ones from data, then 25 generated from the data rules with a seed that changes per run. A new run (Start or Restart) resets to mission 1.
- Trick events (drift duration, ALT DRIFT, airtime, AIR 180, AIR 360, thread the needle and the others the data allows) advance the current mission's goals. A continuous-drift goal counts only one unbroken drift.
- It sends signals for goal progress, goal completed and mission completed. GUT tests complete missions 1 to 5 from simulated events, check that a run has 30 missions, and check that the first 5 are identical across seeds.

### S1: Text for missions and driving power-ups (Narrative Theme)

Needs: S2.

- A text entry exists, in the game's existing text data file and documented in HUD and menus, Content, for: the notebook page's header, a goal phrasing template for each trick or goal type the missions use (quantity goals with a {done}/{total} slot, duration goals with none), the power-up overlay's header and its take-button label, and the names of Rev Charge, Jump, Bouncy Bumpers and Rusty Overcoat.
- Each power-up has one description per tier it has in the S2 data (or a template that names the tier's number). None uses the 'Greenbull says ...' form.
- The data checks pass, with every key the new UI reads present and non-empty.

### S5: Driving power-up gift overlay (UI + Game Loop)

Needs: S1, S2, S3.

- The mission-completed signal pauses the run and opens a power-up overlay with exactly 2 cards, drawn from the power-ups the car doesn't have yet and the next tiers of the ones it has. A power-up at its last tier is no longer offered. What happens when nothing is left follows the answer to the open question; until then it is a documented proposal.
- Choosing works like the level-up screen (A/D or arrows, Enter/Space, mouse). Taking a card gives the power-up or tier and resumes the run. Pause and focus-loss rules match the level-up screen's.
- The overlay uses its own look, with a distinct header and frame from the Greenbull weapons gift screen, and shows the S1 names and tier descriptions with each power-up's icon (placeholder until S11). GUT tests cover the offer rules and the resume. Screenshots of both overlays side by side are saved.

### S4: Notebook mission page on the HUD, placeholder art (UI)

Needs: S1, S3.

- The run's HUD shows the current mission on the left side as a notebook page, using placeholder art until S10 replaces it, with the S1 text.
- Each goal has a checkbox. A quantity goal shows '{done}/{total}' and updates live; a duration or other goal shows no count. A completed goal shows a ticked box and is crossed off. When the mission completes, the next mission appears.
- The page is one of the HUD pieces the player can move (T-452/T-453), if that system is on master. A GUT test checks the label text and the tick/cross state after simulated progress. A screenshot is saved.

### S6: Rev Charge power-up, with a placeholder charge/boost effect (Driving & Drift)

Needs: S2.

- With Rev Charge owned, holding W and S together charges a boost, and releasing S fires it. The strength and the charge time come from the S2 tier numbers. Without the power-up, W+S behaves as before.
- While charging and while boosting, a visible effect plays (a placeholder until S12).
- GUT tests check charging, firing on S release, the tier scaling, and that nothing changes without the power-up.

### S7: Jump power-up (Driving & Drift)

Needs: S2, S3.

- With Jump owned, Space makes a small hop with the tier's numbers. It uses the existing airtime path (passing over obstacles, landing rules). Without it, Space keeps its current uses (for example leaving a grind).
- Airtime and air spins from a Jump hop advance the mission goals for airtime, AIR 180 and AIR 360. A GUT test simulates a hop and checks the tracker's progress.
- Tests check the hop height or duration for each tier, and that Space does nothing new without the power-up.

### S8: Bouncy Bumpers power-up (Driving & Drift)

Needs: S2.

- With Bouncy Bumpers owned, the wall bounce's distance (T-435) grows by the tier's factor from S2. Without it, the bounce is unchanged.
- GUT tests measure the bounce distance at no power-up and at each tier, and the distance grows tier by tier.

### S9: Rusty Overcoat power-up (Enemy Behavior)

Needs: S2.

- With Rusty Overcoat owned, a minion touched by the car takes the tier's damage (S2), with the usual red hit flash. Without it, contact deals no damage, as before.
- How contact damage repeats (cooldown per enemy) and whether it hits the kaiju follow the S2 data and the open question's answer.
- GUT tests check damage at each tier and none without the power-up.

### S10: Art: notebook page and power-up overlay (Asset Generation, style loop)

Needs: S4, S5.

- The PixelLab art for the notebook page (with checkbox and cross-off marks) and for the power-up overlay frame is in game/art/, has been through the style loop (a Style review section on the ticket), and the generation count is recorded in the result notes.
- S4 and S5 use the new art in place of their placeholders, and their tests still pass. Screenshots on a dark and a light background are saved.

### S11: Art: four power-up icons (Asset Generation, style loop)

Needs: S2, S5.

- Icons for Rev Charge, Jump, Bouncy Bumpers and Rusty Overcoat are in game/art/, made with PixelLab through the style loop, at the paths the S2 data names.
- The overlay cards show them. A screenshot shows all four icons.

### S13: Integration check of a whole run (QA/Integration)

Needs: S4, S5, S6, S7, S8, S9.

- A headless integration test runs the main game scene: it completes mission 1 from simulated input or events, sees the overlay pause the run, takes a power-up, sees the run resume and mission 2 shown, and then a weapon level-up still opens the weapons gift screen.
- The two overlays can't open at the same time (or they queue, following the documented proposal). Restart resets the missions and removes the power-ups.
- All three test sets pass on playtest/G-009.

### S12: Art: Rev Charge charge and boost effect (Asset Generation, style loop)

Needs: S6.

- The charge and boost effect frames are in game/art/ (PixelLab or a free script, through the style loop), and the S6 effect uses them in place of its placeholder.
- A recording or screenshot sequence of a charge and release is saved, and S6's tests still pass.

## Scoring

Ranked by code, not by Claude: first by how many other sub-goals wait on it (directly or further down the chain), then by value (Claude's estimate, 1 to 5), then by Claude's order. A sub-goal is therefore always ranked before every sub-goal that needs it. A dependency cycle is refused. Score column: unblocks N (sub-goals waiting on it), value V.

## Tickets

- T-455: Data: the run's missions (5 fixed, generator rules) and the four driving power-ups with their tiers (S2, written)
- T-456: Text: the mission notebook page, its goal phrasings, and the driving power-up overlay with the four power-ups' names and tier descriptions (S1, written)
- T-457: Missions in the run: 30 per run (5 fixed, 25 generated), progress from trick events, signals, and the car's owned power-ups (S3, written)
- T-458: HUD: the current mission as a notebook page on the left, with checkboxes, live counts and crossing off (placeholder art) (S4, written)
- T-459: The driving power-up overlay: a completed mission pauses the run and offers 2 power-ups (new or next tier) (S5, written)
- T-460: Rev Charge: hold W and S to charge a boost that fires when S is released, with a placeholder charge and boost effect (S6, written)
- T-461: Jump: Space makes a small hop on the car's real height, and its airtime counts for missions (S7, written)
- T-462: Bouncy Bumpers: the wall bounce goes further, tier by tier (S8, written)
- T-463: Rusty Overcoat: the car damages minions it touches, with the red hit flash (S9, written)
- T-464: Art: the mission notebook page (with checkbox, tick and cross-off marks) and the power-up overlay's frame (PixelLab) (S10, written)
- T-465: Art: the four driving power-up icons (PixelLab) (S11, written)
- T-466: Art: Rev Charge's charging and boost effect (S12, written)
- T-467: QA: missions and driving power-ups through a whole run (S13, written)

## Iteration log

- 2026-10-31, iteration 0: started: planning, by the session Greenbull.
- 2026-10-31, iteration 0: priority scoring: 13 sub-goals ranked, 7 goal criteria, 11 open questions.
- 2026-10-31, iteration 0: gap detection: 0 covered, 0 in flight, 13 missing; wrote 13 tickets.
- 2026-10-31, iteration 0: building.
- 2026-10-31, iteration 1: T-455 (S2, game-data, sonnet): passed (done, QA rounds 1), merged into playtest/G-009; art 0; agent: T-455 done and committed: missions.json, power_ups.json, MissionData/PowerUpData loaders, 5 GUT tests, and docs updated. GUT 2319/2319 and game/tools Python 767 pass. The tools/ unittest set wasn't finished (over 10 min, stopped); the ticket doesn't touch tools/, so QA should run it. No screenshots: nothing is on screen. Refused, got past and not blocking: game-data: {"tool_input": {"command": "tail -c 400 /c/Users/andre/.claude/projects/C--solid-carbide-worktrees-T-455/5e829cba-4f5c-4edc-8410-8fe664b072ec/tool-results/bp20wf3sw.txt"}, "tool_name": "Bash", "tool_use_id": "toolu_019QqsBxWwz7ktBBVWPrmJCN"} / game-data: {"tool_input": {"command": "f=\"/c/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-worktrees-T-455/5e829cba-4f5c-4edc-8410-8fe664b072ec/tasks/bwcginh4q.output\"; until grep -q -E \"^(OK|FAILED|Ran )\" \"$f\" 2>/dev/null; do sleep 5; done; grep -E \"^(OK|FAILED|Ran )\" \"$f\"", "description": "tools unittest set finishing", "timeout_ms": 600000}, "tool_name": "Monitor", "tool_use_id": "toolu_01Juw96wdZAFE1Swj3MR3sbM"} / game-data: Monitor with a grep/until loop to wait on the tools test output file: refused as a multi-part command; I did not work around it. / QA: {"tool_input": {"command": "python tools/qa_check.py T-455 --no-marks"}, "tool_name": "Bash", "tool_use_id": "toolu_017hQbVdY8PHkBGCKidnh1Bk"} / QA: python tools/qa_check.py T-455 --no-marks was refused (not in the pre-approved list). I skipped it and checked each criterion by hand; I did not run the final qa_check.py confirmation either.. Rescan: S2 covered, S1 in-flight, S3 in-flight, S5 in-flight, S4 in-flight, S6 in-flight, S7 in-flight, S8 in-flight, S9 in-flight, S10 in-flight, S11 in-flight, S13 in-flight, S12 in-flight.
- 2026-10-31, iteration 2: T-457 (S3, game-loop, opus): passed (done, QA rounds 1), merged into playtest/G-009; art 0; agent: T-457 done: the 30-mission tracker (5 fixed, 25 seeded per run, unbroken-drift goal) and the car's power-up tiers are in RunState with their signals, documented in the-run.md and Game loop architecture. All tests pass (GUT 2335/2335, game/tools 767, tools 614), full report in the result notes; ready for QA. Refused, got past and not blocking: QA: {"tool_input": {"command": "python tools/qa_check.py T-457 --no-marks"}, "tool_name": "Bash", "tool_use_id": "toolu_01DpcpjLo9Y4WJsXzDE5Y8ac"} / QA: python tools/qa_check.py T-457 --no-marks was refused (needs approval; not on the pre-approved list), so I checked each criterion by hand instead.. Rescan: S3 covered, S1 in-flight, S5 in-flight, S4 in-flight, S6 in-flight, S7 in-flight, S8 in-flight, S9 in-flight, S10 in-flight, S11 in-flight, S13 in-flight, S12 in-flight.

## Pauses

None yet.

