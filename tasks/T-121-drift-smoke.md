---
id: T-121
title: Drift smoke: the rear tyres puff smoke while drifting (placeholder)
status: in-progress
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/drifting.md, game/README.md, tasks/T-117-drift-marks.md, tasks/T-112-level-up-particles-placeholder.md]
files_expected_to_change: [a new drift smoke scene and script, the run scene and the drift prototype scene, their tests, game/README.md]
model: opus
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

The board wants drift smoke (Visual style, Decisions, "Drift smoke", 2026-10-13): while the car drifts, puffs of smoke come off its two rear tyres. This task builds the working effect with a placeholder look; T-073 draws the final smoke sprites by script and swaps them in, built on this task's branch. The board playtests both together from T-073's folder (no separate sample review).

1. **When:** smoke only while the car is drifting (the car's own drift state, as the drift marks use, T-117). None while driving straight or standing still.
2. **Where:** from each rear tyre's position (reuse T-117's tyre positions). Puffs are left behind in the world (they don't move with the car), drift up or outward a little, grow, then shrink and pop out. Drawn above the ground, the drift marks and the boulders, below the HUD; in the depth order T-034 set up, so a building covering the car also covers the smoke near the car.
3. **No semi-transparent pixels in the sprites** (Visual style, Decisions); puffs shrink and pop out rather than fading per pixel. Whether whole puffs may also fade as objects (allowed by the "See-through rule") is your proposal.
4. **Placeholder look:** small plain light grey-violet squares or circles, not Redgull red, nearest filtering. Keep the texture(s), amount, lifetime, speed, size curve and colour in one scene, so T-073 can swap the art and retune without touching code.
5. Keep it cheap: a capped number of puffs at once.
6. Works in the run (including from the main menu) and in the drift prototype.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Do not merge.

## Acceptance criteria

- [ ] GUT tests show smoke is emitted from both rear tyres while the car drifts and not while it drives straight or stands still (QA: pass / fail)
- [ ] GUT tests show puffs stay where they were left in the world, end within their lifetime, and never exceed the cap during a long drift (QA: pass / fail)
- [ ] A GUT test or a check on the scene shows the depth order (above ground, marks and boulders; below the HUD; covered by a building that covers the car), nearest filtering, no semi-transparent pixels in the placeholder and no Redgull red (QA: pass / fail)
- [ ] A screenshot of the car drifting in a run shows smoke behind the rear tyres, and one of driving straight shows none (QA: pass / fail)
- [ ] game/README.md says how the smoke works and which scene and settings T-073 changes (QA: pass / fail)
- [ ] The drift, drift marks and car tests, the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest drifting in a run (from T-073's folder, together with the final smoke) and judge the smoke.

## Result notes

Written by the agent when it finishes.
