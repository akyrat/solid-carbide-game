---
id: T-616
title: Molotov fires show on raised platforms
status: open
from: project-lead
to: weapon-behavior
lead: Weapons
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/weapons/molotovs.md, game/scripts/weapons/molotov_fire.gd, game/scripts/weapons/molotovs.gd, game/scripts/weapons/weapons.gd, game/scripts/weapons/neon_underglow.gd, game/scripts/enemies/enemy_depth.gd, game/docs/setup/screenshots.md]
files_expected_to_change: [game/scripts/weapons/molotov_fire.gd, game/scripts/weapons/molotovs.gd, game/tests/unit/weapons/test_molotovs.gd, game/docs/weapons/molotovs.md, docs/weapons.md]
model: opus
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

The board's bug report (2026-11-10): "the molotov fires are not showing correctly on any raised platform". The decision is in Weapons, Decisions, "Molotov fires show on raised ground".

What the Project Lead found reading the code (a lead, not a verified cause; reproduce it first and say in the result notes what the cause really was): a fire area (molotov_fire.gd) is added to the node MolotovFires in the map's drawing just after the drift marks (molotovs.gd, fire_root()), at `centre * PX_PER_UNIT` with no height, so it is always drawn flat at street height and under the buildings. Since T-414 a bottle may land on a short building (a platform), and the fire already knows its level (`level = rack.level_at(centre)`, T-326), but that height is never used for drawing. The bottle (MolotovBottle) also flies down to height 0 and its shadow is drawn at street height, whatever it lands on. T-225 lifted the underglow and the wiper to the car's height and left the fire on the ground on purpose; that was before bottles could land on raised ground.

What to build: a fire is drawn on the surface its bottle landed on. On every kind of raised ground the car can stand on in the game's maps (a rooftop, a short building used as a platform, a ramp, and any other the map code knows) the fire shows on top of that surface at its height, sorted in depth so the surface does not hide it and things in front of it (taller buildings, enemies and the car standing on it) are still drawn over it as on the street. The bottle lands on that surface and its shadow falls on it, not on the street below. On the street nothing changes: same place, same size, same drawing order. Damage, levels, numbers and data are not to change. No new art: use the existing fire art.

Reproduce first, on the game's own map (game/data/level/kaiju_city_map.json) and on a test fixture with a platform, with a before screenshot. Check each kind of raised ground and list in the result notes which kinds there are and what each looked like before and after. If the fix for one kind needs a choice the docs do not make (for example how a fire lying across a platform's edge or on a ramp's slope is drawn), make the simplest one, and write it in the result notes and in Weapons as a proposal for the playtest.

Update Weapons (Content, "The molotovs": where the fire is drawn) and game/docs/weapons/molotovs.md.

The board's review: play a run with the molotovs (playtest switch `molotov_at_start` in game/data/playtest.json, or God mode) on a map with rooftops, short buildings and ramps, and see the fires on top of them.
Board review files: art-archive/T-616/screenshots/

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes say what caused the bug, found by reproducing it, with a before screenshot of a fire on raised ground showing wrongly. (QA: pass / fail)
- [ ] A fire whose bottle landed on raised ground is drawn at that ground's height: a test places a fire on a platform of known height and checks its drawn position is lifted by that height (in screen pixels, as the car's sprite is), and that a fire on the street is drawn where it was before this ticket. (QA: pass / fail)
- [ ] A fire on a platform is not hidden by that platform: a test checks its drawing order against the platform's top, and a screenshot shows the whole fire on top of a rooftop, a short building and a ramp (one screenshot each, or one showing all). (QA: pass / fail)
- [ ] A car and a minion standing in a fire on a platform are drawn over the fire, as on the street (a test or a screenshot). (QA: pass / fail)
- [ ] A bottle thrown onto raised ground ends its flight at that ground's height, and its shadow is on that surface (a test on the bottle's final height, and a screenshot or short recording of a bottle landing on a platform). (QA: pass / fail)
- [ ] The fire's damage is unchanged: the existing molotov tests and the level tests (T-326) pass without their expectations being changed, and no value in game/data/weapons.json changes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-616/screenshots/ show: before and after for a fire on raised ground, and a fire on the street after the change, looking as before. (QA: pass / fail)
- [ ] docs/weapons.md (Content, "The molotovs") and game/docs/weapons/molotovs.md say where the fire and the bottle are drawn on raised ground. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
