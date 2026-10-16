---
id: T-145
title: Art: the Redgull helicopter that drops the gift pack
status: blocked
from: project-lead
to: asset-generation
lead: Art
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-144]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/game-loop-architecture.md, tasks/T-144-gift-pack-drop.md, tasks/T-075-redgull-logo-art.md, game/README.md]
files_expected_to_change: [art files under game/art/ and their records, the T-144 scenes that use the placeholder, game/README.md]
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

The helicopter Redgull sends to drop each gift pack (Game loop architecture, Decisions, "Gift pack drop"; board, 2026-10-16). It flies over the screen and drops the package, as built in T-144. It is Redgull's helicopter, so it may carry the Redgull logo (`game/art/logo/`, T-075) and Redgull red where it fits.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. It belongs to Redgull, so Redgull's red is allowed where it fits (Visual style, Decisions, "Redgull's look"). No real brands. Details the docs leave open (directions, frame counts, size) are this agent's proposal, written in the result notes for the board to judge.

**PixelLab:** the board has not given its go for this task yet; don't call PixelLab until the Project Lead passes it on. Sample first (`docs/working-with-the-board.md`, "Art and money"): one sample for the board's review, then the full set from the approved sample. Write the planned calls and cost in the result notes before calling. Use `game/tools/pixellab_client.py` with a 600 s HTTP timeout, and record every call with its prompt, settings and cost, and the balance before and after. Never delete generated art: raw output in `art-archive/T-145/`.

This art task swaps its art in for T-144's placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after (QA: pass / fail)
- [ ] The helicopter sprite (and its frames, if animated) replaces T-144's placeholder, and T-144's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the sample, then the helicopter in a run.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

- 2026-10-16, open → blocked: Waits for T-144 (the placeholder drop flow).
