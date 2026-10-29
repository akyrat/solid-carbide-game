---
id: T-368
title: Art: the damage bonus upgrade's icon
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

The board's decision (Garage design, Decisions, "Pixel art icons for the upgrades", 2026-10-29). Draw a small pixel art icon for the **damage bonus** upgrade (more damage for the car's weapons, in percent), for example a burst or crossed weapons with an up arrow (your call). 16 x 16 (a proposal), in the game's pixel rules and the HUD icons' bold comic outline (T-352's reaction icons, which the board loved), readable at 3x in the garage. The five garage icons are drawn as one set, so match the others if they exist already. None of Greenbull's colours outside Greenbull's things (Visual style, Content, "Rules", rule 6). Save it as `game/art/garage/damage_bonus.png` with a record; the garage picks it up on its own (T-365).

**PixelLab: no go.** Draw it by script, as T-352 did. Style loop, at most 3 refines.

The board's review: open the garage and see the damage bonus icon.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/garage/damage_bonus.png` exists with a record, and the garage shows it on the damage bonus row. (QA: pass / fail)
- [ ] It scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass / fail)
- [ ] No PixelLab generations were used (the result notes say so). (QA: pass / fail)
- [ ] Visual style and the art docs under game/docs/art/ record it. (QA: pass / fail)
- [ ] The icon enlarged on a dark and a light background, and a screenshot of the garage, are in `art-archive/<id>/screenshots/`. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started: the damage bonus icon, script-drawn.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

Script-drawn, so the loop was run by hand: I drew, `style_rules.py art --size 16x16` passed every round, and the Style Evaluator agent scored the enlarged sheet. Versions: `art-archive/T-368/screenshots/v1.png`, `v2.png`.

### Round 1
Version v1. Not sent to the evaluator: by eye the outline was clipped at the canvas edge (grid 15 wide) and the white arrow read as a cross or dagger in a blobby burst. Refine: a 13 x 13 grid with clear spikes, an arrow with a 5 wide head and 3 wide shaft.

### Round 2
Version v2 (kept). Score 8. Reason: all rules pass; the arrow reads at 3x, red and white only; minor: the corner outline looks thicker than 1px, the arrow is a little stubby and low and right of centre, uneven spikes. Kept at 8, no further refine.

Kept version v2, score 8.

## Result notes

Written by the agent when it finishes.

Done. Zero PixelLab calls (script-drawn). `game/art/garage/damage_bonus.png` + `.json`: a red comic burst with a white up arrow, built by `game/tools/build_garage_icon_damage_bonus.py` (reuses `build_hud_livestream_art` helpers and the 1 pixel outline), test `game/tools/test_build_garage_icon_damage_bonus.py`. Style loop: v1 redone, v2 scored 8 (two rounds in the Style review). The garage shows it on the "Brand Impact" (damage bonus) row. Docs: `docs/visual-style.md`, `game/docs/art/garage-icons.md` (new; other garage ticket branches may add their own sections, expect a trivial merge). Screenshots in `art-archive/T-368/screenshots/`: `icon_enlarged.png` (dark and light, x16), `garage.png`, `v1.png`, `v2.png`. Tests: `python -m unittest discover -s game/tools -p "test_*.py"` run in the foreground, result below. No .import or .uid files committed.
