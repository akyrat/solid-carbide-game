---
id: T-174
title: Art: one level-up card image per weapon, all five (PixelLab)
status: in-progress
from: project-lead
to: asset-generation
lead: Goal-G-002
epic: art
milestone: mvp
goal: G-002
user_facing_text: no
changes_visuals: yes
depends_on: [T-173]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/weapons.md, docs/hud-and-menus.md, docs/working-with-the-board.md, game/scripts/ui/level_up_screen.gd, tools/pixellab_client.py, tools/check_sprite_rules.py]
files_expected_to_change: [game/art/level_up/, art-archive/, game/scripts/ui/level_up_screen.gd, game/tests/unit/test_pixellab_assets.gd, docs/visual-style.md, game/README.md]
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

Every level-up card shows an image of its weapon (docs/hud-and-menus.md, Decisions, 2026-10-18). Generate one card image per weapon with PixelLab: the starting gun (a small pixel-art gun, board, 2026-10-18), the exhaust flamethrower, the neon underglow, the molotovs and the windshield wiper, sized for the card slot D8 made. This is a goal run: the goal is the board's go for PixelLab up to its art cap (40 generations, shared with D10), no sample review, one generation round only (weak art is noted, not regenerated). Write the planned calls and cost in the result notes before calling, with a 600 s timeout. Follow the Visual style pixel rules (hard edges, no semi-transparent pixels, transparent background); red only where it fits Redgull's gift packs. Game-ready images go in `game/art/level_up/` with their records; every other generation in `art-archive/<task id>/`. Swap them in for D8's placeholders.

The board's review: Look at the five card images in game/art/level_up/ and the level-up screen screenshot; judged in the goal's final playtest.

## Acceptance criteria

- [ ] The result notes list the planned calls and their cost before any call, and the total stays within the goal's art cap with D10; only one generation round was made. (QA: pass / fail)
- [ ] Five images (gun, flamethrower, underglow, molotovs, wiper) are in `game/art/level_up/` with records, and `tools/check_sprite_rules.py` passes on each (hard edges, no semi-transparent pixels, transparent background). (QA: pass / fail)
- [ ] The level-up screen loads these images instead of the placeholders, and the screenshot fixture shows two cards with the final images. (QA: pass / fail)
- [ ] Every other generation is in `art-archive/<task id>/`; `docs/visual-style.md` records any art decision made; the game's test set passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Blocked → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-174.

## Result notes

Written by the agent when it finishes.
