---
id: T-276
title: A bigger health bar with the heart under it, and the car's weapons as icons beside it
status: open
from: project-lead
to: ui
lead:
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/weapons.md, game/README.md, game/scripts/hud/, game/scenes/hud/, game/art/hud/likes_heart.png, game/art/level_up/, tasks/T-113-hud-vertical-health-and-likes-bars.md, tasks/T-174-art-one-level-up-card-image.md, tasks/T-243-airtime-counter-hud.md]
files_expected_to_change: [game/scripts/hud/, game/scenes/hud/, game/tests/unit/, docs/hud-and-menus.md, game/README.md, art-archive/T-276/screenshots/]
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

The board's decision (HUD and menus, Decisions, "A bigger health bar with the heart, and the weapons beside it", 2026-10-22), for the top left of the HUD:

1. **Health bar:** still upright and filling from the bottom up (green), but 3 times wider and twice as tall: from 24 x 160 to **72 x 320 pixels** at the default 1152 x 648 window. The "Car Health" label goes. The likes bar's red heart (`game/art/hud/likes_heart.png`, the same picture, board-approved red) sits centred under the bar.
2. **Weapon icons:** to the right of the bar, a column of small square icons, one per weapon the car has (the starting gun included, proposal; say if you leave it out), in the order taken, each a small version of its level-up card picture (T-174, `game/art/level_up/weapon_*.png`, nearest filtering, no new art). A weapon taken more than once shows its count next to its icon as "x2", "x3" ... (its tier), in the HUD's comic font (Bangers with a black outline, as the combo counter and the airtime counter; this is the combo counter's "x{n}" form, no new words). The column fits the space beside the bar (icon size your proposal so eight-tier counts and all five weapons fit) and updates the moment a gift pack's weapon is taken or upgraded.

Nothing overlaps the run timer, the counters or the screen edge at the default window and zoom; the HUD scales with the window as today.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. T-273 is changing the likes bar at the bottom on its own branch in parallel; keep to the top-left elements. End with screenshots of the top left with no weapon but the gun, and with all five weapons at mixed tiers.

## Acceptance criteria

- [ ] The health bar is upright, 72 x 320 at the default window, filling from the bottom; the "Car Health" label is gone; the likes heart sits under it (screenshot, layout test) (QA: pass / fail)
- [ ] Tests show an icon appears for each weapon the car has, in the order taken, with "x{n}" for tiers above 1, updating when a weapon is taken or upgraded, in the comic font (QA: pass / fail)
- [ ] Nothing overlaps at the default window; no new art; no Redgull red besides the approved heart (screenshot) (QA: pass / fail)
- [ ] Screenshots are in `art-archive/T-276/screenshots/`; HUD and menus, Content, and `game/README.md` describe the new top left; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: take a few weapons from gift packs and look at the top left.
Board review files: the screenshots in `art-archive/T-276/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
