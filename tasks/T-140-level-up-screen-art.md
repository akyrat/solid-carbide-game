---
id: T-140
title: "Art: the level-up screen, red and gold, Redgull-themed"
status: open
from: project-lead
to: asset-generation
lead: Enemies
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-052]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/weapons.md, tasks/T-052-level-up-screen.md, tasks/T-003-pixellab-test-generation.md, game/README.md]
files_expected_to_change: [art files under game/art/ and their records, art-archive/T-140/, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-052 (the level-up screen, with its comic-look cards) is done.**

The board (2026-10-15): the level-up screen gets "nice art", "more red gold colored and themed". HUD and menus and Visual style, Decisions: the level-up screen's art is red and gold, themed on Redgull, since the weapons it offers arrive as Redgull gift packs (Visual style, Decisions: red is used on Redgull's own things). It is the art T-141's animation of the screen showing up uses.

Propose, in the result notes, which pieces the screen needs (for example a card frame or card back in red and gold, a header banner or ribbon, a backdrop or burst behind the cards, a highlight for the chosen card), how each fits T-052's layout and comic look, and whether each is drawn by script (free) or generated with PixelLab, with the planned calls and their cost.

**Money:** no PixelLab call without the board's go for this task. Sample first: one piece, for the board's review, then the rest only with its go. Use `game/tools/pixellab_client.py` with a 600 s HTTP timeout, one call at a time, and record every call (prompt, settings, cost, balance before and after). Report problems rather than regenerating.

Follow Visual style, Decisions (hard-edged pixel art, a selective dark outline, about 30 colours per sprite, no semi-transparent pixels, a transparent background where the piece needs one). Real-world things are inspiration only: no real logos or brands. Put the approved art into `game/art/`; swapping it into the screen and animating it is T-141.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a hard pixel edge, no semi-transparent pixels, and about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after, each round matching a board go written in this task file (QA: pass / fail)
- [ ] A mock-up image puts the art together as the level-up screen over a dimmed run, as T-141 would show it (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the look, sample first.

## Result notes

Written by the agent when it finishes.
