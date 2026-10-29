---
id: T-370
title: Art: the air turn upgrade's icon
status: in-qa
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

The board's decision (Garage design, Decisions, "Pixel art icons for the upgrades", 2026-10-29). Draw a small pixel art icon for the **air turn** upgrade (the car spins faster in the air), for example the car in the air with a curved spin arrow (your call). 16 x 16 (a proposal), in the game's pixel rules and the HUD icons' bold comic outline (T-352's reaction icons, which the board loved), readable at 3x in the garage. The five garage icons are drawn as one set, so match the others if they exist already. None of Greenbull's colours outside Greenbull's things (Visual style, Content, "Rules", rule 6). Save it as `game/art/garage/air_turn.png` with a record; the garage picks it up on its own (T-365).

**PixelLab: no go.** Draw it by script, as T-352 did. Style loop, at most 3 refines.

The board's review: open the garage and see the air turn icon.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/garage/air_turn.png` exists with a record, and the garage shows it on the air turn row. (QA: pass / fail)
- [ ] It scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass / fail)
- [ ] No PixelLab generations were used (the result notes say so). (QA: pass / fail)
- [ ] Visual style and the art docs under game/docs/art/ record it. (QA: pass / fail)
- [ ] The icon enlarged on a dark and a light background, and a screenshot of the garage, are in `art-archive/<id>/screenshots/`. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started: the air turn icon, script-drawn.

## Style review

Script-drawn 16 x 16, 0 PixelLab generations; the script checks (style_rules.py art) passed every round. The Style Evaluator was run per round on the enlarged sheets (art-archive/T-370/screenshots/vN_sheet.png, versions in art-archive/T-370/vN/).

### Round 1 (v1)
5. Blocky white arch for an arrow that reads as a cloud or handle, no air feel, dark wheels merge with the outline. Refine: thin 1 px arrow with a head, lighter wheels.

### Round 2 (v2)
6. Arrow still a flat bar reading as a handle, blocky head, muddy gap. Refine: a big loop over the car with an open tail and pointed head.

### Round 3 (v3)
7. Reads as an air turn icon; outline heavy round the arrow, arch a little flat, car near the bottom edge. Refine: gap between arrow and car, car lifted, shade pixels.

### Round 4 (v4)
7. Arrow reads as a bridge, head a flat block. No refines left.

Kept: v3 (7, the earliest of the tied best; its arrowhead reads better than v4's). Below 8 after 3 refines, noted for the board's playtest (game/art/garage/air_turn.png).

## Result notes

Built `game/art/garage/air_turn.png` (+ `.json`), 16 x 16, a blue car under a white curved spin arrow, by `game/tools/build_garage_icon_air_turn.py` (hand-placed grid, 1 px dark outline via the HUD helpers, deterministic; test `game/tools/test_build_garage_icon_air_turn.py`). PixelLab: none, 0 generations. Style loop: 5, 6, 7, 7 over 3 refines; kept v3 at 7 (below 8: the arrow is a little flat and the outline heavy round it). The garage shows it on the Spin Doctor row (T-365's loader, no code change).
Docs: Visual style, `game/docs/art/garage-icons.md` (new; other agents may add sections on their branches, expect a trivial merge).
Screenshots: `art-archive/T-370/screenshots/` (`air_turn_enlarged.png` dark and light, `garage_screen.png`, `v1..v4_sheet.png`).
Tests: game/tools unittest 660 OK (1 skipped); GUT not run, per the brief.
