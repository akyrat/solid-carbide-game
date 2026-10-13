---
id: T-118
title: Art: the drift marks' tyre texture, drawn by script
status: blocked
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-117]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, game/README.md, tasks/T-117-drift-marks.md, tasks/T-074-challenge-and-level-up-effects-art.md]
files_expected_to_change: [a drift mark drawing script and its test, the mark sprite(s) under game/art/ and their record, T-117's drift marks scene, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The final look of the drift marks (Visual style, Decisions, "Drift marks", 2026-10-13). T-117 builds the working marks with a plain placeholder line; this task draws the real texture and swaps it in.

**Branch:** create your branch `task/T-118-drift-marks-art` from T-117's branch (not from master), in your own folder `C:\solid-carbide-worktrees\T-118`, so the board playtests both from your folder. T-117 merges first, then this task.

**No PixelLab** (like the level-up particles, T-074): write a script that draws the mark texture: dark rubber tyre marks with a visible tread pattern, readable on both the dark asphalt and the dusty gravel, within Visual style, Decisions (no anti-aliasing, no semi-transparent pixels, transparent background, about 30 colours or fewer, night palette, not Redgull red). Make it tile cleanly along the length of a mark. Propose the colours, width and tread pattern, and any retuning of T-117's lifetime and fade, in the result notes.

Swap it into T-117's drift marks scene without changing when or how the marks are laid. Keep the script and its output: game-ready art under `game/art/`, with a short record; anything unused in `art-archive/T-118/`.

## Acceptance criteria

- [ ] A check script shows the new sprite(s) have a transparent background, no semi-transparent pixels, about 30 colours or fewer, and no Redgull red (QA: pass / fail)
- [ ] The sprites are made by a committed script, with a test, and no PixelLab calls were made (QA: pass / fail)
- [ ] Screenshots of the car drifting on asphalt and on gravel show the marks with the new texture, tiling without visible seams (QA: pass / fail)
- [ ] T-117's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest drifting in a run and judge the marks (together with T-117).

## Result notes

- 2026-10-13, open → blocked: waits for T-117
