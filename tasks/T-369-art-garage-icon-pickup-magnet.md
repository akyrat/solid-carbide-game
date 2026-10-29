---
id: T-369
title: Art: the pickup magnet upgrade's icon
status: needs-playtest
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-365]
documents_affected: [docs/visual-style.md, game/docs/art/]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/garage-design.md, tasks/T-352-art-reaction-icons.md]
files_expected_to_change: [game/art/garage/, game/tools/, art-archive/, docs/visual-style.md, game/docs/art/]
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

The board's decision (Garage design, Decisions, "Pixel art icons for the upgrades", 2026-10-29). Draw a small pixel art icon for the **pickup magnet** upgrade (coins, gift packs and health drops are pulled to the car from further away), for example a horseshoe magnet pulling a coin (your call). 16 x 16 (a proposal), in the game's pixel rules and the HUD icons' bold comic outline (T-352's reaction icons, which the board loved), readable at 3x in the garage. The five garage icons are drawn as one set, so match the others if they exist already. None of Greenbull's colours outside Greenbull's things (Visual style, Content, "Rules", rule 6). Save it as `game/art/garage/pickup_magnet.png` with a record; the garage picks it up on its own (T-365).

**PixelLab: no go.** Draw it by script, as T-352 did. Style loop, at most 3 refines.

The board's review: open the garage and see the pickup magnet icon.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/garage/pickup_magnet.png` exists with a record, and the garage shows it on the pickup magnet row. (QA: pass)
- [ ] It scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass)
- [ ] No PixelLab generations were used (the result notes say so). (QA: pass)
- [ ] Visual style and the art docs under game/docs/art/ record it. (QA: pass)
- [ ] The icon enlarged on a dark and a light background, and a screenshot of the garage, are in `art-archive/<id>/screenshots/`. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started: the pickup magnet icon, script-drawn.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

Script-drawn 16 x 16 (0 PixelLab generations); every script check (style_rules.py art) passed.

### Round 1 (game/art/garage/pickup_magnet.png)
Score 8 (Style Evaluator). Reason: a clear horseshoe magnet, thick dark outline, white tips, blue body with highlight and shade, readable on dark and light, no Greenbull colours. Minor: the outline is a closed ring (rule 2 wants it broken by highlights), the grey band under the tips is a flat stripe. Kept at 8, no refine.

## Result notes

QA report (round 1): qa_check run with --no-tests (no test-set criterion): screenshots PASS; its documents check names the directory game/docs/art/ and cannot match it, but game/docs/art/garage-icons.md and docs/visual-style.md both changed on the branch, so the docs criterion passes. All five criteria pass: 16x16 PNG and json; style 8 in round 1, recorded; 0 PixelLab calls stated; screenshots present. Set check: the five garage icons share the black comic outline, flat colours and highlight/shade and read as one set; air turn is the lightest in weight but fits.

Done: `game/art/garage/pickup_magnet.png` (16 x 16, a blue horseshoe magnet with white pole tips and the HUD's dark outline) and `pickup_magnet.json`, drawn by `game/tools/build_garage_icon_pickup_magnet.py` (reuses the HUD outline helpers; deterministic) with `test_build_garage_icon_pickup_magnet.py`. 0 PixelLab generations. Style loop: one round, score 8, kept (Style review). Docs: Visual style and `game/docs/art/garage-icons.md`. Screenshots in `art-archive/T-369/screenshots/`: `icon_dark_light.png` and `garage.png` (garage demo scene, after Godot's import). Tests: `python -m unittest discover -s game/tools -p "test_*.py"` run in the foreground (660 tests, OK). No .uid/.import files committed.
