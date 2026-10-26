---
id: T-305
title: Art: the gift pack helicopter sheet in Greenbull's colours
status: blocked
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
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/game-loop-architecture.md, docs/working-with-the-board.md, game/README.md, tasks/T-144-gift-pack-drop.md, tasks/T-145-art-redgull-helicopter.md, game/tools/build_helicopter.py, game/tools/test_build_helicopter.py, game/scenes/run/gift_helicopter.tscn, game/art/gift_pack/, game/art/logo/]
files_expected_to_change: [game/art/gift_pack/helicopter_sheet.png, game/tools/build_helicopter.py, game/tools/test_build_helicopter.py, art-archive/, docs/visual-style.md, game/README.md]
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

The helicopter that drops the gift pack (T-145; T-144) is in Redgull's colours with its gull on the fuselage panel and the tail fin. Rebuild game/art/gift_pack/helicopter_sheet.png in Greenbull's colours (Visual style, Decisions, 'The rebrand', 'Greenbull's look', 'Red after the rebrand'; rule 6), with Greenbull's emblem from game/art/logo/ (D3) on its logo spots. build_helicopter.py first (a free recolour and restamp); PixelLab only where a recolour can't do it, each call listed with its reason and count in the result notes before calling, up to 12 generations within the goal's art cap. It goes through the style loop with --greenbull and --max-colors 30. Keep its frame count and size so gift_helicopter.tscn loads it unchanged. Keep the old sheet in art-archive/<this ticket>/. Update Visual style and game/README.md, 'The gift pack drop', where they describe the helicopter. An in-run screenshot of the helicopter carrying the package in art-archive/<this ticket>/screenshots/.

The board's review: play a run to a gift pack drop: the helicopter in Greenbull's colours with its emblem, carrying the package.

## Acceptance criteria

- [ ] game/art/gift_pack/helicopter_sheet.png is rebuilt in Greenbull's colours with Greenbull's emblem on its logo spots and no gull, with the same frame count and size as before (gift_helicopter.tscn unchanged). (QA: pass / fail)
- [ ] It has no pixel the Redgull red check (style_rules.is_redgull_red, or its renamed successor) flags (output in the result notes). (QA: pass / fail)
- [ ] build_helicopter.py rebuilds it by script; any PixelLab call is listed in the result notes with its reason and count, within 12 generations. (QA: pass / fail)
- [ ] It passes `python game/tools/style_rules.py art game/art/gift_pack/helicopter_sheet.png --greenbull --max-colors 30` and has a style loop record in the ticket's Style review. (QA: pass / fail)
- [ ] The old helicopter_sheet.png is in art-archive/<this ticket>/. (QA: pass / fail)
- [ ] test_build_helicopter.py and test_gift_drops.gd pass. (QA: pass / fail)
- [ ] An in-run screenshot of the helicopter carrying the package is in art-archive/<this ticket>/screenshots/, listed in the result notes. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
