---
id: T-339
title: "Art: the livestream HUD (clock, live viewers counter and its fire, sub goal, hearts, icons)"
status: open
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/hud-and-menus.md, docs/extended-narrative.md, docs/working-with-the-board.md, game/README.md, game/art/gift_pack/package.png]
files_expected_to_change: [game/art/hud/, art-archive/T-339/, docs/visual-style.md, game/README.md]
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

The board's decision (HUD and menus, Decisions, "The HUD looks like a livestream", 2026-10-28). Make the pixel art for the new HUD pieces, in the game's pixel rules and comic HUD look (Visual style, Content, "Rules"; none of Greenbull's colours outside Greenbull's things, rule 6):

1. **The digital clock:** a dark panel and segment-style digits 0 to 9 and the colon, drawn so the game can tint them green, yellow, orange and red (white or greyscale digits), plus a soft glow.
2. **The live viewers counter:** its panel, a **LIVE** badge (red, like a stream's), a small **eye icon** for the viewers (also used on trick popups), and a **fire animation** for the counter over a million (looping pixel flames around the panel, 8 to 12 frames, in the burning likes bar's fire colours).
3. **The sub goal:** the square's frame (black inside, an outline that reads over the street), and a **subs icon** (the board's mock uses a star; propose better).
4. **Hearts:** a **full heart** and an **empty heart**, at the HUD's size, in the comic HUD style.

**Not tied to the HUD tickets:** this ticket doesn't wait for T-335 to T-338. The board will **place the finished art on its HUD layout page** (https://claude.ai/artifact/U33QPUELxgZCZBjYDpBszQ; the Project Lead uploads it there), so save each asset as its own PNG in `game/art/hud/` with a record. The HUD tickets use the art if it has landed in their branch; otherwise the Project Lead writes a short ticket to swap it in.

**PixelLab: the board's go** ("please don't be stingy"), **up to 40 generations** for this ticket, through the style loop (at most 3 refines per asset). Free script work first where it is as good (the digits may be best drawn by script). Write the planned calls and cost in the result notes before calling, with a long HTTP timeout (600 s). Every asset goes through the style loop. No sample review: the board judges the art on the layout page and in the playtest.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/hud/` holds: the clock panel and digits 0 to 9 and the colon; the viewers panel, the LIVE badge, the eye icon and the fire animation frames; the sub goal frame and the subs icon; a full and an empty heart; each with a record (how it was made). (QA: pass / fail)
- [ ] Each asset scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass / fail)
- [ ] The PixelLab generations used are 40 or fewer, listed in the result notes with the planned calls written before calling. (QA: pass / fail)
- [ ] Visual style and game/README.md record the art. (QA: pass / fail)
- [ ] A contact sheet of every asset, enlarged, on a dark and a light background, is in `art-archive/T-339/`. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
