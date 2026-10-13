---
id: T-112
title: Level-up particles from the car (placeholder squares)
status: in-progress
from: project-lead
to: game-loop
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-037]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/game-loop-architecture.md, tasks/T-037-likes-and-levels.md, tasks/T-074-challenge-and-level-up-effects-art.md, game/README.md]
files_expected_to_change: [the run's scripts and scenes, a new level-up effect scene, their tests, game/README.md, docs/game-loop-architecture.md]
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

The functional side of the level-up effect (Visual style, Decisions, "Level-up effect"): when the player levels up, the car gives off a burst of pixel-art particles. T-074 then swaps in the final particle art and tunes the look; this task only builds the working effect with placeholder particles.

1. Make one level-up effect scene (a Godot particle node, `CPUParticles2D` or `GPUParticles2D`, your choice) that plays a single burst around the car when started. Keep it easy to retune: the particle texture(s), count, speed, spread and lifetime are set in the scene, not hard-coded in scripts, so T-074 can change them without touching code.
2. Play it on T-037's "level up" signal, on the car, following the car while it plays. Several level-ups at once may play it once per level-up or once in total; write which in the result notes.
3. It must play before the level-up screen (T-052) once that exists; for now the run carries on, so it just plays while driving. Make sure it still plays (is not frozen) if the run is paused for the level-up screen later: set its process mode accordingly and say so in the result notes.
4. Placeholder particles: small plain squares (2 to 4 pixels) drawn by a script or built in code, in one light colour, **not Redgull red**. Nearest-neighbour filtering, no smoothing.
5. Pixel rules for the effect itself: no semi-transparent pixels and no anti-aliasing, so particles do not fade by alpha; they pop out or shrink instead (Visual style, Decisions, "See-through rule").

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. No playtest for this task: the board playtests once T-074's final particles are in.

## Acceptance criteria

- [ ] A GUT test shows that emitting T-037's "level up" signal starts the level-up effect on the car, and that it is not playing before (QA: pass / fail)
- [ ] A GUT test or a check on the scene shows the particles use nearest-neighbour filtering, have no alpha fade (colour ramp / modulate alpha stays 1) and are not Redgull red (QA: pass / fail)
- [ ] A screenshot shows the placeholder burst around the car at a level-up in the run scene (QA: pass / fail)
- [ ] game/README.md says how the effect is triggered and which scene and settings T-074 changes to swap the art; Game loop architecture says the run plays it on a level-up (QA: pass / fail)
- [ ] T-037's tests, the full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
