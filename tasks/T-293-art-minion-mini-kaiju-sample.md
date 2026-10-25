---
id: T-293
title: "Art: the minion redesigned as a car-sized mini kaiju, one sample direction through the style loop"
status: open
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-292]
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/enemies.md, game/README.md, agent-notes/asset-generation.md, art-archive/T-068/review_all8_directions_dark.png, game/art/car/car_iso.png]
files_expected_to_change: [art-archive/T-293/, docs/visual-style.md]
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

The board's redesign of the minion (Visual style, Decisions, "The minion, redesigned", 2026-10-25), in its words: bigger and more detailed, "slightly like a mini kaiju monster". It is still a lizard and walks on all fours, with a snapping jaw with teeth and a reptilian-looking face, and it is about as big as the car.

This task makes **one sample direction** (south-east, the car sheet's frame 0 direction), standing or mid-stride, as a single sprite for the board's review. It is the first real asset made through the style loop (`tasks/README.md`, "The style loop"), and its Style review is evidence for the course's Style Guide Agent assignment. The walk sheets for all directions and the minion's in-game size and hitbox come in later tasks, after the board approves the sample.

**The asset:**
- **Frame:** 128 x 128, like the car's frames. The minion is about the car's size: about 96 art pixels long at 32 art pixels per unit (Visual style, Content, "Rules", rule 3).
- **Look:** in the style guide (Visual style, Content, "Rules"): light green, not too bright, with darker scales; the pixel rules; a dark selective outline; a transparent background; at most 30 colours; no Redgull red.
- **Kaiju-like, not the kaiju:** it may echo the kaiju's Godzilla-style build, smaller, but it must not be a copy of Godzilla (rule 9).

**How:** through the style loop only, with the PixelLab go the board gave on 2026-10-25: at most 4 generations (the first version and up to 3 refines), free script fixes before a paid regeneration. Write the planned calls and their cost in the result notes before calling. The Project Lead starts the loop: `python tools/style_loop/run.py art --task T-293 --brief <brief> --out art-archive/T-293/minion_sample_se.png --size 128x128`. The kept sample stays in `art-archive/T-293/` until the board approves it; nothing goes into `game/art/` or the game yet.

The board's review: look at the kept sample next to the car and the current minion, on a dark and a light background, enlarged. Read the Style review to see how the loop got there.
Board review files: art-archive/T-293/review_sample_vs_car_dark.png, art-archive/T-293/review_sample_vs_car_light.png

## Acceptance criteria

- [ ] The task's `## Style review` section holds every round of the loop: each version's file, the script checks, the score, the reason and (from round 2) what changed, and a final "Kept" line. (QA: pass / fail)
- [ ] Every version is in `art-archive/T-293/style-loop/` with its PixelLab record, and the kept sample is `art-archive/T-293/minion_sample_se.png`. (QA: pass / fail)
- [ ] `python game/tools/style_rules.py art art-archive/T-293/minion_sample_se.png --size 128x128` passes, or its failures are named in the Style review. (QA: pass / fail)
- [ ] At most 4 PixelLab generations were used, as `game/art/pixellab-generation-log.jsonl` shows for T-293. (QA: pass / fail)
- [ ] The two review images exist: the sample next to a car frame and a current minion frame, enlarged with nearest-neighbour, on a dark and a light background. (QA: pass / fail)
- [ ] Nothing under `game/art/` changed except the PixelLab log. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
