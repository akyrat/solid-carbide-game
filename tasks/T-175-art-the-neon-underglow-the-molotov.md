---
id: T-175
title: Art: the neon underglow, the molotov and its fire area, and the windshield wiper in the world (PixelLab)
status: open
from: project-lead
to: asset-generation
lead: Goal-G-002
epic: art
milestone: mvp
goal: G-002
user_facing_text: no
changes_visuals: yes
depends_on: [T-168, T-169, T-170]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/weapons.md, docs/working-with-the-board.md, game/scripts/weapons/neon_underglow.gd, game/scripts/weapons/molotovs.gd, game/scripts/weapons/molotov_fire.gd, game/scripts/weapons/windshield_wiper.gd, tools/pixellab_client.py, tools/check_sprite_rules.py]
files_expected_to_change: [game/art/weapons/, art-archive/, game/scripts/weapons/neon_underglow.gd, game/scripts/weapons/molotovs.gd, game/scripts/weapons/molotov_fire.gd, game/scripts/weapons/windshield_wiper.gd, game/tests/unit/test_pixellab_assets.gd, docs/visual-style.md, game/README.md]
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

The three new weapons were built with placeholders drawn in code (D3, D4, D5). Generate their in-world art with PixelLab and swap it in: the underglow effect under the car, the molotov bottle in flight and its fire area (animated if you propose it), and the wiper. This is a goal run: the goal is the board's go for PixelLab up to its art cap (40 generations, shared with D9), no sample review, one generation round only. Write the planned calls and cost in the result notes before calling, with a 600 s timeout. Follow the Visual style pixel rules (32 art pixels per unit, drawn at scale 0.5, hard edges, no semi-transparent pixels); the placeholders' rule holds for the art too: no Redgull red. Game-ready art in `game/art/` with records; every other generation in `art-archive/<task id>/`.

The board's review: Look at the in-world weapon art in a run with the three weapons owned; judged in the goal's final playtest.

## Acceptance criteria

- [ ] The result notes list the planned calls and their cost before any call, and the total with D9 stays within the goal's art cap; only one generation round was made. (QA: pass / fail)
- [ ] The underglow, the molotov bottle, the fire area and the wiper are in `game/art/` with records, at 32 art pixels per unit, and `tools/check_sprite_rules.py` passes on each. (QA: pass / fail)
- [ ] In a run with the three weapons owned (the `all_weapons_at_start` switch or a fixture), the scripts draw the art at scale 0.5 instead of the placeholders, shown in a screenshot fixture. (QA: pass / fail)
- [ ] The weapon behaviour tests still pass, and every other generation is in `art-archive/<task id>/`; `docs/visual-style.md` records any art decision made. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
