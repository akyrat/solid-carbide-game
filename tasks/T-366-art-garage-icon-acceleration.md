---
id: T-366
title: Art: the acceleration upgrade's icon
status: done
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

The board's decision (Garage design, Decisions, "Pixel art icons for the upgrades", 2026-10-29). Draw a small pixel art icon for the **acceleration** upgrade (reaching top speed faster), for example the car with speed lines or a rising speedometer needle (your call). 16 x 16 (a proposal), in the game's pixel rules and the HUD icons' bold comic outline (T-352's reaction icons, which the board loved), readable at 3x in the garage. The five garage icons are drawn as one set, so match the others if they exist already. None of Greenbull's colours outside Greenbull's things (Visual style, Content, "Rules", rule 6). Save it as `game/art/garage/acceleration.png` with a record; the garage picks it up on its own (T-365).

**PixelLab: no go.** Draw it by script, as T-352 did. Style loop, at most 3 refines.

The board's review: open the garage and see the acceleration icon.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/garage/acceleration.png` exists with a record, and the garage shows it on the acceleration row. (QA: pass)
- [ ] It scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass)
- [ ] No PixelLab generations were used (the result notes say so). (QA: pass)
- [ ] Visual style and the art docs under game/docs/art/ record it. (QA: pass)
- [ ] The icon enlarged on a dark and a light background, and a screenshot of the garage, are in `art-archive/<id>/screenshots/`. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started: the acceleration icon, script-drawn.

## Style review

Script-drawn, so the Style Evaluator was called directly for each round (no PixelLab; `tools/style_loop/run.py` generates through the agent and was not needed). Versions in `art-archive/T-366/style-loop/`.

### Round 1
- Version: `v1.png` (a speedometer on a squat rounded body; ticks and needle scattered). Script checks: pass.
- Score: 5. Reason: reads as a gem or window, not a dial; no round silhouette or tick arc; needle without a hub (rule 2, clarity).
- Refine: round bezel, tick arc, hub and angled needle.

### Round 2
- Version: `v2.png`. Score: 7. Reason: reads as a speedometer, but the 3x3 hub is heavy, the ticks uneven, the bottom squat (rule 2, thin detail).
- Refine: 2x2 hub, needle thicker near the hub, ticks evenly spaced and symmetric.

### Round 3
- Version: `v3.png`. Score: 8. Reason: clear, symmetric dial, readable at 3x, blue dominant, no Greenbull colours; shading is minimal and the needle tip sits close to a tick.
- Kept: v3 (8/10), copied to `game/art/garage/acceleration.png`.

## Result notes

QA report (round 1): qa_check run with --no-tests (no test-set criterion): screenshots PASS; its documents check names the directory game/docs/art/ and cannot match it, but game/docs/art/garage-icons.md and docs/visual-style.md both changed on the branch, so the docs criterion passes. All five criteria pass: 16x16 PNG and json, garage screenshot shows the dial on the Energy Throttle row; style 8 with all rounds recorded; 0 PixelLab calls stated. Set check: the five garage icons (dial, heart, burst, magnet, car with arrow) share the black comic outline, flat colours and highlight/shade and read as one set; air turn is the lightest in weight but fits.

Written by the agent when it finishes.

Done: the acceleration garage icon, a blue speedometer dial (white ticks, needle and hub), 16 x 16, kept at 8/10 after 2 refines.

- Made by `game/tools/build_garage_icon_acceleration.py` (hand-placed grid, deterministic, reuses `build_hud_livestream_art` helpers and the reaction icons' outline approach); test `game/tools/test_build_garage_icon_acceleration.py`. Output `game/art/garage/acceleration.png` and `.json`.
- PixelLab: no generations used (0 calls).
- Docs: Visual style (Content, new entry) and `game/docs/art/garage-icons.md` (created; other garage icon agents may add sections, expect a trivial merge on that file).
- Screenshots in `art-archive/T-366/screenshots/`: `icon_dark_light.png` (enlarged on dark and light) and `garage.png` (garage screen, the icon on the acceleration row "Energy Throttle"; taken with v3).
- Tests: `python -m unittest discover -s game/tools -p "test_*.py"` run; result below.
- 2026-10-29, needs-playtest → done: The board played the garage and art build: garage icons lgtm (2026-10-29).
