---
id: T-527
title: Polarized Steering Wheel: a cooldown between bursts, and a speed-stacking playtest bot
status: in-qa
from: project-lead
to: driving-drift
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [docs/drifting.md, game/docs/driving/drift.md, game/scripts/driving/polarized_steering_wheel.gd, game/data/power_ups.json, tasks/README.md]
files_expected_to_change: [game/scripts/driving/polarized_steering_wheel.gd, game/data/power_ups.json, game/tests/, game/tools/, game/docs/driving/drift.md, docs/drifting.md]
model: sonnet
qa_rounds: 0
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

Give the Polarized Steering Wheel a cooldown between bursts (game/scripts/driving/polarized_steering_wheel.gd; today "no cooldown: a new burst restarts a running one"). The cooldown starts when a burst fires; while it runs, the trigger (coast, steer, W again at 60 degrees or more) gives no burst. Its length per tier goes in game/data/power_ups.json as `cooldown_seconds` in each wheel tier (your proposal for the playtest, with a reason line like the other entries; tier 2 may be shorter than tier 1). Expose what the HUD needs to draw the reload: `cooldown_fraction_left()` (1 just after a burst, 0 when ready) and `is_ready()`, plus a signal when it becomes ready, so T-528 (UI) can draw the slot icon filling.

The playtest the board asked for: write a bot (a GUT test or a tool under game/tools/, your call, runnable headless in one command) that drives the real car with the wheel at tier 1 and at tier 2 and tries as hard as it can to reach extreme speeds for at least 60 simulated seconds: it chains the wheel's trigger as fast as the rules allow, combines it with the other speed sources a player has (the cruise boost, Rev Charge at tier 2, ramps/jumps if the test map has them, drifting), and records the peak and the average forward speed, against the car's normal top speed. Run it before your change (to measure today's runaway) and after. If with the cooldown the speed still keeps climbing over the minute (each burst ending faster than the last), do not invent a cap: report the numbers in the result notes and stop; the Project Lead brings it to the board. Document in game/docs/driving/drift.md and docs/drifting.md Content (Polarized Steering Wheel section). Screenshots: the bot's speed-over-time output before and after (a chart PNG or a table image).

The board, 2026-11-03: docs/drifting.md, Decisions, "A cooldown for the Polarized Steering Wheel", and docs/hud-and-menus.md, Decisions, "Weapon and power-up slots" (the cooldown on the slot icon). Today the wheel has no cooldown and each burst holds the car at burst_speed_multiplier x the speed it carried into the press, so chained bursts compound and the car ends up extremely fast. The board plays T-527 and T-528 together in one build (T-528's folder) before anything merges or reaches itch.io. No new player-facing text. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play the one combined build (T-527, T-528) from C:\solid-carbide-worktrees\T-528\game\project.godot before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] power_ups.json has cooldown_seconds for both wheel tiers, read by the wheel (unit test). (QA: pass)
- [ ] During the cooldown the trigger gives no burst; after it, the next trigger does (unit test). (QA: pass)
- [ ] cooldown_fraction_left() goes from 1 to 0 over the cooldown, is_ready() and the ready signal fire when it ends (unit test). (QA: pass)
- [ ] The speed bot runs in one command and its result notes give peak and average speed for tier 1 and 2, before and after the change. (QA: pass)
- [ ] After the change, the bot's peak speed over 60 s stays within a bounded figure stated in the result notes (it does not keep growing burst after burst); or the ticket's result notes say it still grows, with the numbers. (QA: pass)
- [ ] game/docs/driving/drift.md and docs/drifting.md Content describe the cooldown and the bot. (QA: pass)
- [ ] The Godot test set and the touched Python tests pass. (QA: pass)
- [ ] Screenshots: the before and after speed output in art-archive/T-527/screenshots/. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-03, Open → In progress

Driving & Drift agent: cooldown plus a speed bot that tries to reach extreme speeds.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

DONE. Cooldown: polarized_steering_wheel.gd (cooldown_seconds per tier in power_ups.json: proposals 3 s tier 1, 4 s tier 2; API cooldown_fraction_left(), is_ready(), signal ready_again; reset() clears it). Speed bot: bash game/tools/speed_bot.sh [--csv=f] [--seconds=60] (speed_bot.gd, speed_bot_plot.py); real car, open ground, wheel tier 1 and 2 with Rev Charge tier 2, grid of policies (chain trigger, drift, rev between), best by peak. Ramps/jumps not used (jump adds no speed). Top speed 16.5. BEFORE (no cooldown): runaway. Tier 1: 10x top after 2.1 s, 100x after 3.7 s, per-10s peaks 1.0e7 then 1.6e13, float overflow at 29.9 s. Tier 2: 10x after 1.9 s, 100x after 3.1 s, peaks 1.6e8 then 4.6e15, overflow at 24.9 s. AFTER (3 s / 4 s): bounded and flat. Tier 1 peak 88.2 avg 72.3 (20 bursts), every 10 s window 88.2. Tier 2 peak 90.5 avg 49.0 (15 bursts), windows 90.3 then 90.5. No growth burst after burst. What-if 8 s / 8 s: peaks 83.8 and 88.0 (avg 46, 41) so the cooldown length barely changes the peak. WHY ~5.4x top remains (for the board, I added no cap): a trace shows it is one Rev Charge boost or one wheel burst held while STEERING: the rule holds forward speed at least X along the turning nose every step while the sideways part stays, so speed is pumped into the side (Rev Charge tier 2 alone to about 81 units/s in 1.4 s of steering). Without steering a burst peaks at 19.8 (1.2 x 16.5). The board decides about that rule or a cap. Tests: test_polarized_steering_wheel.gd 16/16 (cooldown from data, trigger blocked then allowed, fraction 1 to 0 + ready_again once, reset, chained bursts do not grow); full Godot set 2741/2742 passing, 0 failing, 1 risky/pending (pre-existing); game/tools/test_speed_bot_plot.py OK. Docs: docs/drifting.md (Content, wheel section), game/docs/driving/drift.md. Screenshots: art-archive/T-527/screenshots/ speed_before.png, speed_after.png, speed_after_8s.png (+ _light), data: art-archive/T-527/speed_*.csv/.txt. Note: a first bot attempt outside the physics frame hung 2 headless Godot processes (started 18:31 and 18:52-18:59); they may still be running, not killed by me.
