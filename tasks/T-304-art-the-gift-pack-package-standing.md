---
id: T-304
title: Art: the gift pack package, standing and falling, in Greenbull's colours
status: open
from: project-lead
to: asset-generation
lead: Goal-G-006
epic: art
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: yes
depends_on: [T-144, T-300, T-299]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/game-loop-architecture.md, docs/working-with-the-board.md, game/README.md, tasks/T-144-gift-pack-drop.md, tasks/T-146-art-redgull-gift-pack-package.md, game/tools/build_gift_package.py, game/tools/test_build_gift_package.py, game/art/gift_pack/, game/art/logo/]
files_expected_to_change: [game/art/gift_pack/package.png, game/art/gift_pack/package_falling.png, game/tools/build_gift_package.py, game/tools/test_build_gift_package.py, art-archive/, docs/visual-style.md, game/README.md]
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

The gift pack package (T-146; dropped by T-144's helicopter) is in Redgull's colours with its gull logo. Rebuild game/art/gift_pack/package.png and package_falling.png in Greenbull's colours (Visual style, Decisions, 'The rebrand', 'Greenbull's look', 'Red after the rebrand'; rule 6), with Greenbull's emblem from game/art/logo/ (D3) in place of the gull. build_gift_package.py first (a free recolour and restamp); PixelLab only where a recolour can't do it, each call listed with its reason and count in the result notes before calling, up to 12 generations per asset within the goal's art cap. Both go through the style loop with --greenbull. Keep file names and sizes so gift_package.tscn loads them unchanged. Keep the old versions in art-archive/<this ticket>/. Update Visual style and game/README.md, 'The gift pack drop', where they describe the package. In-run screenshots of the package falling and landed in art-archive/<this ticket>/screenshots/.

The board's review: play a run to a gift pack drop: the package, falling and landed, in Greenbull's colours with its emblem.

## Acceptance criteria

- [ ] game/art/gift_pack/package.png and package_falling.png are rebuilt in Greenbull's colours with Greenbull's emblem from game/art/logo/ and no gull, keeping their file names and sizes. (QA: pass / fail)
- [ ] Neither has a pixel the Redgull red check (style_rules.is_redgull_red, or its renamed successor) flags (output in the result notes). (QA: pass / fail)
- [ ] build_gift_package.py rebuilds them by script; any PixelLab call is listed in the result notes with its reason and count, within 12 generations per asset. (QA: pass / fail)
- [ ] Both pass `python game/tools/style_rules.py art <file> --greenbull` and have a style loop record in the ticket's Style review. (QA: pass / fail)
- [ ] The old package.png and package_falling.png are in art-archive/<this ticket>/. (QA: pass / fail)
- [ ] test_build_gift_package.py (and test_build_gift_placeholders.py, if it covers the package) pass, as does test_gift_drops.gd. (QA: pass / fail)
- [ ] In-run screenshots of the package falling and landed are in art-archive/<this ticket>/screenshots/, listed in the result notes. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
