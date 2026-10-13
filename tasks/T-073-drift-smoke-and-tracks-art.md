---
id: T-073
title: Art: drift smoke
status: open
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, game/README.md, tasks/T-121-drift-smoke.md, tasks/T-118-drift-marks-art.md, tasks/T-074-challenge-and-level-up-effects-art.md]
files_expected_to_change: [a smoke drawing script and its test, smoke sprites under game/art/ and their record, T-121's smoke scene, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The final look of the drift smoke (Visual style, Decisions, "Drift smoke", 2026-10-13). T-121 builds the working smoke with a placeholder; this task draws the real smoke sprites and swaps them in. The tyre tracks moved to T-117 and T-118 (done).

**Branch:** create your branch `task/T-073-drift-smoke-art` from T-121's branch (not from master), in your own folder `C:\solid-carbide-worktrees\T-073`, so the board playtests both from your folder. T-121 merges first, then this task.

**No PixelLab** (board, 2026-10-13: no sample review, straight to the playtest): write a script that draws the smoke puff sprites, a few sizes or frames (for example a puff that grows, then breaks up in pixel steps), within Visual style, Decisions: pixel art, no anti-aliasing, no semi-transparent pixels (use dithering or stepped shapes for softness), a transparent background, about 30 colours or fewer, the night palette (cool grey-violet smoke, perhaps a faint neon tint from the city), not Redgull red. It must read on both the dark asphalt and the dusty gravel. Propose the shapes, colours, sizes and any retuning of T-121's settings in the result notes, and judge honestly how it reads.

Swap the sprites into T-121's smoke scene without changing when or how smoke is emitted. Keep the script and its output: game-ready art under `game/art/`, with a short record; anything unused in `art-archive/T-073/`.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, about 30 colours or fewer, and no Redgull red (QA: pass / fail)
- [ ] The sprites are made by a committed script, with a test, and no PixelLab calls were made (QA: pass / fail)
- [ ] Screenshots of the car drifting on asphalt and on gravel show the new smoke behind the rear tyres (QA: pass / fail)
- [ ] T-121's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest drifting in a run and judge the smoke (together with T-121).

## Result notes

Written by the agent when it finishes.
