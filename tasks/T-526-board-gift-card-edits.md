---
id: T-526
title: The board's gift pack card edits: weapon and power-up cards
status: done
from: project-lead
to: narrative-theme
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [docs/hud-and-menus.md, game/scripts/ui/level_up_texts.gd, game/data/screen_texts.json, game/scripts/ui/power_up_screen.gd, tasks/README.md]
files_expected_to_change: [game/scripts/ui/level_up_texts.gd, game/data/screen_texts.json, game/tests/, game/tools/, docs/hud-and-menus.md, docs/weapons.md, docs/drifting.md]
model: sonnet
qa_rounds: 2
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

Set these texts to the board's words (file | key: old -> new). {braces} are slots the game fills from power_ups.json; where the board removed a slot, the card simply no longer shows that number.

- game/data/screen_texts.json | power_ups.overlay_header: "Mission done: soup up the car" -> "Mission done: pimp your ride"
- game/data/screen_texts.json | power_ups.descriptions.bouncy_bumpers -> "Bounce {bounce_multiplier}x farther off walls and obstacles."
- game/data/screen_texts.json | power_ups.descriptions.jump -> "Press Space to Jump."
- game/data/screen_texts.json | power_ups.descriptions.polarized_steering_wheel -> "(while coasting) Steer, then Accelerate: +{burst_percent}% speed burst."
- game/data/screen_texts.json | power_ups.descriptions.rev_charge -> "Hold Gas+Brake then release the Brake: speed boost."
- game/data/screen_texts.json | power_ups.descriptions.rusty_overcoat -> "The car deals damage to minions it touches. Rust: now a feature."
- game/data/screen_texts.json | power_ups.descriptions_last_tier.bouncy_bumpers -> "Bounce {bounce_multiplier}x farther off walls and obstacles."
- game/data/screen_texts.json | power_ups.descriptions_last_tier.jump -> "Press Space to Jump higher."
- game/data/screen_texts.json | power_ups.descriptions_last_tier.polarized_steering_wheel -> "+{burst_percent}% speed, shock hits and shoves minions."
- game/data/screen_texts.json | power_ups.descriptions_last_tier.rev_charge -> "Faster charge, bigger boost."
- game/data/screen_texts.json | power_ups.descriptions_last_tier.rusty_overcoat -> "Deals {contact_damage} damage to kaijus now too. Tetanus is content." (the board, 2026-11-03: added the missing "to")
- game/scripts/ui/level_up_texts.gd | get_bricks.desc -> "Make the car heavier, sending impact waves after each jump landing."
- game/scripts/ui/level_up_texts.gd | get_flamethrower.desc -> "Tailpipe flames while you drift."
- game/scripts/ui/level_up_texts.gd | get_molotov.desc -> "Throws a molotov every 3 seconds."
- game/scripts/ui/level_up_texts.gd | get_underglow.desc -> "Damages nearby enemies each second."
- game/scripts/ui/level_up_texts.gd | get_wiper.desc -> "Sweeps in front of the car, shoving minions back."
- game/scripts/ui/level_up_texts.gd | upgrade_bricks.tier3.title -> "Harder Landing"
- game/scripts/ui/level_up_texts.gd | upgrade_bricks.tier3.desc -> "Damage x2.25."
- game/scripts/ui/level_up_texts.gd | upgrade_bricks.tier4.title -> "Shove Factor"
- game/scripts/ui/level_up_texts.gd | upgrade_bricks.tier4.desc -> "Knockback x2.25."
- game/scripts/ui/level_up_texts.gd | upgrade_flamethrower.tier3.desc -> "+20% Damage, +30% flame area."
- game/scripts/ui/level_up_texts.gd | upgrade_flamethrower.tier4.title -> "Hot Stuff"
- game/scripts/ui/level_up_texts.gd | upgrade_flamethrower.tier4.desc -> "Enemies burn 2 seconds longer."
- game/scripts/ui/level_up_texts.gd | upgrade_gun.tier2.desc -> "+2 bullets per volley."
- game/scripts/ui/level_up_texts.gd | upgrade_gun.tier3.desc -> "Fire rate x1.44."
- game/scripts/ui/level_up_texts.gd | upgrade_gun.tier4.desc -> "+1 bullet per volley, fire rate x1.2."
- game/scripts/ui/level_up_texts.gd | upgrade_gun.tier5.title -> "Rated E for Everyone"
- game/scripts/ui/level_up_texts.gd | upgrade_gun.tier5.desc -> "Fire rate x4. Everyone gets a bullet."
- game/scripts/ui/level_up_texts.gd | upgrade_molotov.tier3.desc -> "+2 molotovs per throw."
- game/scripts/ui/level_up_texts.gd | upgrade_molotov.tier4.title -> "Quick Throw"
- game/scripts/ui/level_up_texts.gd | upgrade_molotov.tier4.desc -> "+50% attack speed."
- game/scripts/ui/level_up_texts.gd | upgrade_molotov.tier5.desc -> "+1 Molotov per throw."
- game/scripts/ui/level_up_texts.gd | upgrade_underglow.tier3.title -> "Hotter Glow"
- game/scripts/ui/level_up_texts.gd | upgrade_underglow.tier3.desc -> "Glow damage x2.25."
- game/scripts/ui/level_up_texts.gd | upgrade_underglow.tier4.title -> "Faster Pulse"
- game/scripts/ui/level_up_texts.gd | upgrade_underglow.tier4.desc -> "Glow hits come twice as fast."
- game/scripts/ui/level_up_texts.gd | upgrade_underglow.tier5.desc -> "+30% Glow radius. Sunglasses recommended."
- game/scripts/ui/level_up_texts.gd | upgrade_wiper.tier3.title -> "Faster Sweep"
- game/scripts/ui/level_up_texts.gd | upgrade_wiper.tier3.desc -> "Sweep speed x1.6."
- game/scripts/ui/level_up_texts.gd | upgrade_wiper.tier4.desc -> "Minion knockback x1.5. Blades x1.3 longer."
- game/scripts/ui/level_up_texts.gd | upgrade_wiper.tier5.desc -> "A copy of your front wiper sweeps behind. Maximum visibility."

Tests that check numbers or slots in these texts (for example game/tools/test_four_minute_run_texts.py, game/tools/test_check_level_up_texts.py, the level-up and power-up screen tests) are updated to the board's words, keeping what they check about structure (every key present, every slot a known one). Update docs/hud-and-menus.md Content, and docs/weapons.md / docs/drifting.md where they quote card texts.

The board, 2026-11-03, wrote these words itself on the gift pack cards page (every weapon and power-up card drawn on the game's card art). Use the board's words exactly; only trim trailing spaces. The style loop does not change them (if it finds a real problem, say so in the result notes and keep the board's words). Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it from the ticket's folder (C:\solid-carbide-worktrees\T-526\game\project.godot), which also holds T-525's edits, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every text listed has exactly the board's words, trailing spaces trimmed (a test reads them from their files). (QA: pass; file texts match the list incl. the updated Rusty Paintjob line)
- [ ] The power-up cards still fill their remaining {slots} with the tier's numbers, and a text without slots shows as written (test). (QA: pass)
- [ ] Screenshots: a weapon gift pack and a power-up gift pack showing edited cards. (QA: pass; round 2: level_up_gift_pack.png and power_up_overlay.png present)
- [ ] docs/hud-and-menus.md Content (and Weapons/Drifting where they quote card texts) match the new texts. (QA: pass)
- [ ] The text inventory, level-up and power-up screen tests and the Python text checks pass. (QA: pass; round 2: qa_check tests all pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-03, Open → In progress

Narrative agent applying the board's 41 card edits, on top of T-525.

### 2026-11-03, In QA → In progress

QA round 1: one Godot test still pins old card texts, and the two screenshots are missing. Back to the Narrative agent.

### 2026-11-03, In QA → Needs playtest

QA round 2 passed. The board asked to push these text changes once in.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Applied the board's 41 texts exactly (11 in game/data/screen_texts.json, 30 in game/scripts/ui/level_up_texts.gd; no style-loop rewrites). Updated tests: game/tools/test_check_level_up_texts.py and test_four_minute_run_texts.py (new words; structure kept), game/tests/unit/test_power_up_screen.gd, test_level_up_screen.gd, test_mission_texts.gd (slot test now checks every slot left is a known one; bouncy_bumpers keeps {bounce_multiplier}). Docs: docs/hud-and-menus.md Content (card table, header, power-up descriptions); weapons.md and drifting.md only quote older/historical card texts, left as is. Python text tests pass (41 passed, 3 skipped). NOT RUN: Godot unit tests (test_power_up_screen, test_level_up_screen, test_mission_texts) and the screenshots, because GODOT_BIN is not set in this worktree; QA to run them and take a weapon gift pack and a power-up gift pack shot. Real problems noted, board's words kept: (1) Wiper tier 3 says 'Sweep speed x1.6' while data is x1.625 (rounding). (2) Gun tier 2 no longer says '3 in all'; Molotov tier 4 '+50% attack speed' vs data interval x0.56 (about +79% rate). (3) Rusty Paintjob tier 1 card shows no damage number; tier 2 'Deals {contact_damage} damage kaijus now too' reads oddly (missing 'to'). (4) Jump/Rev Charge cards no longer show cooldown or charge numbers. (5) game/tools/check_level_up_texts.py already reported mismatches against the old T-171 table before this ticket (not part of the tests).

Follow-up (Project Lead, board): rusty_overcoat last-tier text now 'Deals {contact_damage} damage to kaijus now too. Tetanus is content.' (screen_texts.json, test_power_up_screen.gd, hud-and-menus.md). Python text tests pass.

QA round 1 fixes: test_t171s_texts_word_for_word in game/tests/unit/test_level_up_screen.gd now pins the board's words. Screenshots taken with screen_gallery.py: art-archive/T-526/screenshots/level_up_gift_pack.png and power_up_overlay.png (tutorial_slide_2.png copied into T-525's art-archive, not committed there). Godot test run NOT finished: my gut run (test_level_up_screen, test_power_up_screen, test_mission_texts) hung (Godot pid 45400, started 17:23, in the main checkout's game folder path form) and a hook refused me stopping it; QA must run these tests.
- 2026-11-03, needs-playtest → done: The board asked to push these text changes once QA passed (2026-11-03)

Correction: the Godot run was not hung, it ran the whole suite (the .gutconfig dirs, 239 scripts) in 1352 s: 2738 tests, 2737 passing, 1 pending/risky, 0 failures, so the level-up, power-up and mission-text tests pass.
