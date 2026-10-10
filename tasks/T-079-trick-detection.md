---
id: T-079
title: Tricks: detect extended drifts, 360s and alternate drifts
status: open
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-029]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/drifting/unity-prototype-report.md, tasks/T-029-drift-defaults-after-playtest.md, game/README.md]
files_expected_to_change: [the car's code, the tuning panel, tests, docs/drifting.md, game/README.md]
model: opus
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

**Blocked until T-029 (the car's new defaults) is done.**

Drifting, Decisions defines the MVP's three tricks. Detect them from the car's own driving, without changing how it drives:
1. **Extended drift:** every full second of drifting is one trick. "Drifting" is the Unity definition the game already uses: W or S held together with A or D.
2. **360:** the car's heading turns a full 360 degrees in one direction during one unbroken drift. 720 degrees is two. A break in the drift, or turning back the other way, starts the count again.
3. **Alternate drift:** each switch between a forward drift and a backward drift while keeping the same steering direction is one trick. The board's description: drift forwards, release W while still steering, switch to S and drift backwards, then back to W, so the car draws semicircles. Propose the timing limits (for example how long the switch may take), and make them tuning panel sliders so the board can tune them.

Send one signal per trick, with the trick's id, so the combo (T-081) and the popups (T-083) can use it. Show the last trick in the drift prototype's readout, so the board can try them there.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test holds a drift for 3.5 seconds and shows exactly 3 extended-drift signals (QA: pass / fail)
- [ ] A test drifts the car through a full circle in one direction and shows one 360 signal; two circles give two; a drift that turns 300 degrees and then breaks gives none (QA: pass / fail)
- [ ] A test drives the forward-drift, release, backward-drift sequence with the same steering and shows one alternate-drift signal per switch; switching steering direction gives none (QA: pass / fail)
- [ ] The tuning panel has sliders for the alternate drift's timing limits, and its reset restores the proposed values (QA: pass / fail)
- [ ] A test shows the car's movement is exactly the same with trick detection on as before (T-012 and T-029's tests still pass) (QA: pass / fail)
- [ ] `game/README.md` documents the trick signal and the trick ids, and `docs/drifting.md` describes the detection in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: try the three tricks in the drift prototype (the readout shows the last trick) and tune the alternate drift's timing.

## Result notes

Written by the agent when it finishes.
