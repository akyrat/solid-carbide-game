---
id: T-528
title: The steering wheel's cooldown on its HUD slot icon, like loading
status: needs-playtest
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [docs/hud-and-menus.md, docs/drifting.md, tasks/T-523-weapon-power-up-slots.md, tasks/README.md]
files_expected_to_change: [game/scripts/hud/, game/tests/, game/docs/, docs/hud-and-menus.md]
model: sonnet
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

In the HUD's power-up slots (T-523), the Polarized Steering Wheel's icon shows its cooldown as it reloads, like a loading bar: right after a burst it looks spent and it fills back up over the cooldown (read cooldown_fraction_left() / is_ready() / the ready signal from T-527's wheel), and when ready it looks normal, with a short, small cue that it is ready (your proposal). How it fills (a radial sweep, a rising fill, a dimmed icon brightening) is your proposal for the playtest, drawn in code in the pixel look, no PixelLab. Make it generic enough that another power-up with a cooldown (Jump has one) could use it later, but only the wheel uses it now. Document in game/docs/hud-and-menus (the slots section) and docs/hud-and-menus.md Content.

The board, 2026-11-03: docs/drifting.md, Decisions, "A cooldown for the Polarized Steering Wheel", and docs/hud-and-menus.md, Decisions, "Weapon and power-up slots" (the cooldown on the slot icon). Today the wheel has no cooldown and each burst holds the car at burst_speed_multiplier x the speed it carried into the press, so chained bursts compound and the car ends up extremely fast. The board plays T-527 and T-528 together in one build (T-528's folder) before anything merges or reaches itch.io. No new player-facing text. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play the one combined build (T-527, T-528) from C:\solid-carbide-worktrees\T-528\game\project.godot before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The wheel's slot icon is drawn as spent right after a burst and full again when the cooldown ends, following cooldown_fraction_left() (unit test on the slot's draw state at 0, 0.5 and 1). (QA: pass)
- [ ] Other power-up slots are unchanged (test). (QA: pass)
- [ ] docs/hud-and-menus.md Content and the HUD doc describe it. (QA: pass)
- [ ] The Godot test set passes. (QA: pass; run on the branch with the real wheel from T-527, Hud.bind_car binds car.polarized, HUD tests that bind a real car pass)
- [ ] Screenshots: the slot at about full cooldown, half and ready, in art-archive/T-528/screenshots/. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-03, Open → In progress

UI agent: the loading fill on the wheel's slot icon, built against T-527's cooldown API in parallel.

### 2026-11-03, In progress → In QA

UI agent: the wheel's slot icon fills like loading (veil shrinking top-down, white flash when ready), built against T-527's API; ready for QA and the combined playtest.

### 2026-11-03, In QA → Needs playtest

QA passed 5/5 with T-527's real wheel merged in. Ready to play.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. New SlotCooldown (game/scripts/hud/slot_cooldown.gd): a loading veil over the power-up icon, 1 = spent (whole slot veiled), shrinking top-down in 2 px steps with a light edge line, 0 = normal; a 0.3 s white flash on ready_again as the ready cue. Generic: WeaponIcons.bind_cooldown(id, source) takes any object with cooldown_fraction_left() (missing method = always ready, so it runs on today's wheel); Hud.bind_car binds car.polarized to the wheel. Other slots get a veil that draws nothing (tested). Tests: game/tests/unit/hud/test_hud_slot_cooldown.gd (0, 0.5, 1, clamp, no-method, flash, wheel slot vs stub, other slots); the test_hud set passes (205 tests). Not yet run against T-527's real wheel (stub only). Screenshots (stub, full/half/ready, Jump beside it unchanged): art-archive/T-528/screenshots/cooldown_full.png, cooldown_half.png, cooldown_ready.png, cooldown_strip_full_half_ready.png. Docs: docs/hud-and-menus.md (Content, slots), game/docs/hud-and-menus/hud.md. Fill style is a proposal for the playtest.

Sample video (the board asked): scripted demo game/tests/fixtures/wheel_cooldown_demo.tscn/.gd (real run, car and HUD; wheel tier 1 for 10 s then tier 2 for 10 s; bot coasts, steers 62+ degrees and presses W as soon as is_ready(); 4 minions; car put back near the start when it strays) and game/tools/record_wheel_cooldown_video.sh (--write-movie AVI, 30 fps). Output, outside the repo: scratchpad videos/wheel_cooldown.avi, 20 s, 600 frames, 104 MB, 1152x648 (the --resolution 1280x720 flag did not change the size). The slot icon is seen going dark, the veil shrinking and the icon filling back up (checked on stills).

Sample GIF for phones (scratchpad videos/wheel_cooldown.gif): the same demo recorded as PNG frames with record_wheel_cooldown_video.sh (output path ending in f.png), then every 4th frame, 640x360 (box downscale), 8 fps, 150 frames, 64-colour octree palette per frame, 14.5 MB. frames_to_gif.py at skip 2 was 38 MB and its median-cut palette lost the HUD colours, so the GIF was made by a short one-off script (not committed).

Merge of master into the branch (2026-11-06): one conflict, game/docs/hud-and-menus/hud.md, kept both sections (T-528 slot cooldown, T-534 subs flight). Tests run in the foreground: tests/unit/hud 27 scripts, 245/245 passing (includes test_hud_slot_cooldown and test_hud_slot_grids); test_polarized_steering_wheel 16/16 passing. No .import/.uid files added.
