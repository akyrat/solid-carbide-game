---
id: T-405
title: Short buildings (low-rise, small, long) become connectable platforms at height 3, and everything on platforms works at its height
status: open
from: project-lead
to: level-challenge
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/level-design.md, docs/visual-style.md, game/docs/level/]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/drifting.md, docs/visual-style.md, tasks/T-393-creator-objects-ignore-heights.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/docs/level/elevation-sample-map.md, game/scripts/level_creator/, game/scripts/level/, game/data/level/]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/scripts/run/, game/data/level/, game/art/buildings/, game/tools/, game/tests/unit/, game/docs/level/, docs/level-design.md, docs/visual-style.md, art-archive/]
model: opus
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

The board's decision (Level design, Decisions, "Short buildings become platforms", 2026-10-30). The board: "when I'm on platforms, a lot of stuff seems to not be working ... If I have a low-rise building directly placed on top of a platform, I hit the invisible building, which is correctly rendered under the platform, but I still hit it and I can't reach the end of the platform. And we don't define what happens when the player jumps off a platform and can he go over a building. So I'm deciding that the low-rise buildings no longer exist and they're just like better platforms. Keep the same asset but make it a platform, treat it as a platform, make the assets so that they can connect, and fix any bugs with altitude." The board's answers: height **3** (the art's walls trimmed by script), and the **small and long buildings too**; only skyscrapers stay solid buildings.

1. **Platforms:** the low-rise, small and long pieces become platforms at height 3 with their own art (walls trimmed by script from today's art; no PixelLab; keep the originals in `art-archive/<id>/`). The car drives on their roofs like a rooftop, reaches them by today's 0-to-3 ramps, falls off their edges, and enemies treat them as rooftops (today's navigation). Rooftop decorations (AC units, water tanks, vents, signs) still go on them, at their height. Whether they keep the see-through rule when the car is behind them is your proposal.
2. **Connecting:** two of them placed side by side (or a low-rise next to a 3-high rooftop) join into one surface: no walls or roof edges drawn between them, no seam the car bumps on. Script work on the art (edge and corner pieces cut from the existing art) where needed.
3. **Altitude audit:** list in the result notes every collider in the level (building bodies, platform and ramp walls, props, obstacles, the spawn point) and check each works at its height: nothing below a platform stops the car on top of it; the car that jumps off a platform falls to the ground or a lower platform; a skyscraper blocks it at any height. Fix what doesn't, with a test each. Pickups (gift packs and the others) are T-402's: don't change their code.
4. **Saved levels and the game's own map:** short buildings in them load as these platforms; `check_level.py` and the drivability check accept them. The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): copy them into your worktree to test (uncommitted), never write or commit them.

This ticket's worktree is branched from T-393's branch (its depth rule for objects on rooftops, waiting for the board's playtest), so it merges after T-393. Other agents work on the creator at the same time (T-394 pairs, T-400 small ramp, T-402 gift packs): keep to the buildings, platforms and colliders.

The board's review: in the creator, place short buildings side by side and next to rooftops, connect them with ramps, put props on them, press Play, drive across them, jump off them and try to reach every edge; open the board's own levels.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The low-rise, small and long pieces are platforms at height 3: the car drives on them, reaches them by a 0-to-3 ramp and falls off their edges; enemies follow it there (tests). (QA: pass / fail)
- [ ] Two placed side by side, or one next to a 3-high rooftop, join with no wall or roof edge drawn between them and no bump crossing the join (tests, screenshots). (QA: pass / fail)
- [ ] The result notes list every collider and how it works at height; nothing below a platform stops the car on top of it, a jump off a platform lands on the ground or a lower platform, and a skyscraper blocks at any height (a test each). (QA: pass / fail)
- [ ] Saved levels with short buildings and the game's own map load them as platforms; check_level.py and the drivability check accept them (tests); the board's level files are unchanged and uncommitted. (QA: pass / fail)
- [ ] Level design (Content), Visual style and game/docs/level/ describe the platforms, the joins and the audit; the original art is kept in `art-archive/<id>/`. (QA: pass / fail)
- [ ] Screenshots of joined short platforms in the editor and the run, and a GIF of driving across them and jumping off, are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
