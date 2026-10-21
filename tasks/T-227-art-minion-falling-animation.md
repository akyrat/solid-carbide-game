---
id: T-227
title: "Art: the minion's falling animation (PixelLab)"
status: blocked
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-226]
documents_affected: [art-archive/README.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/enemies.md, tasks/T-226-enemies-jump-down-off-ledges.md, art-archive/README.md, game/README.md]
files_expected_to_change: [game/art/minion/, game/scripts/enemies/, game/tests/unit/, art-archive/T-227/, art-archive/README.md, game/README.md, game/art/pixellab-generation-log.jsonl]
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

The final art for the falling minion (Enemies, Decisions, "Enemies jump down off ledges": a falling enemy plays a falling animation from the edge until it lands, board, 2026-10-21). T-226 builds the fall with a placeholder animation made by script and leaves a hook for real frames; this task makes those frames from the approved minion art in `game/art/minion/` (the same character, palette and size), in its directions, and swaps them in through T-226's hook without changing behaviour.

The board's go for PixelLab on this task needs asking first: plan the calls and cost in the result notes and stop for the Project Lead before calling. Then sample first (`docs/working-with-the-board.md`, "Art and money"): one direction's falling frames, shown to the board as a GIF, then the rest after approval. One round; problems are reported, not regenerated; free script fixes first. Follow Visual style's technical rules.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a GIF of minions falling off a rooftop in a run.

## Acceptance criteria

- [ ] A check script shows every new frame follows Visual style's technical rules and matches the minion's palette (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after (QA: pass / fail)
- [ ] In a run, a falling minion plays the new frames from the edge until it lands, behaving as before (GIF; T-226's tests pass) (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: first the one-direction sample as a GIF, then minions falling in a run.
Board review files: the GIFs in `art-archive/T-227/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
