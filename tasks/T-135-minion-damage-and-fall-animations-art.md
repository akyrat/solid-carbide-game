---
id: T-135
title: "Art: the minion's damage, fall-down and get-up animations"
status: blocked
from: project-lead
to: asset-generation
lead: Enemies
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-068, T-134]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/enemies.md, tasks/T-068-minion-art.md, tasks/T-134-minions-knock-each-other-down.md, game/README.md]
files_expected_to_change: [art files under game/art/ and their records, the minion's scenes and scripts that show the animations, game/README.md]
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

**Polish, built once the MVP is playable end to end (board, 2026-10-14).** Visual style, Decisions: the animated minion from T-068 gets three more animations, built from the same approved lizard:
1. **Damage:** a short reaction when it is hit (T-044's `take_damage`).
2. **Fall down:** when it bumps into another minion (T-134's "fell" signal).
3. **Get up:** before it runs at the car again (T-134's "got up" signal).

Propose the directions and frame counts, and the PixelLab calls and their cost, in the result notes before calling. Sample first: one animation in one direction for the board's review, then the rest only with the board's go. Use `game/tools/pixellab_client.py` with a 600 s HTTP timeout and record every call (prompt, settings, cost, balance before and after). Report problems rather than regenerating.

Follow Visual style, Decisions (pixel art at about 40 pixels per unit, selective dark outline, about 30 colours, no semi-transparent pixels, transparent background, night neon palette). Swap the animations in for T-134's placeholder and hook the damage one to the hit, without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new frame has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after (QA: pass / fail)
- [ ] A screenshot sequence of a run shows a minion's damage reaction, a fall and a get-up, facing the way it moved (QA: pass / fail)
- [ ] T-044's and T-134's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the look, sample first.

## Result notes

Written by the agent when it finishes.
