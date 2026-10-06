---
id: T-008
title: Short "boost" effect when W snaps the car to cruise speed
status: blocked
from: project-lead
to: driving-drift
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/drifting/unity-prototype-report.md]
files_expected_to_change: [the car's code and scene, and their tests]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until the Godot car exists.** The task that builds the car's driving in Godot is not written yet; when it is, it goes in `depends_on`.

When the player presses W and the car jumps instantly to cruise speed (Drifting, Decisions; the jump is described in the Unity prototype report, section 4, step 5), a short "boost" effect plays to emphasise that jump.

- **When it plays:** when W is newly pressed and that press makes the car jump up to cruise speed. Not on the jumps back to cruise that happen every physics step during a held drift, and not while W stays held.
- **What it looks like:** a placeholder for now (for example a brief flash or streak behind the car). The final animation is made by the **Asset Generation Agent** in the linked task T-009, from the board's description. This task does not wait for it: when the art arrives, it replaces the placeholder, hooked to the same signal.
- Make the trigger a clear signal the art, the SFX Agent and the UI can hook into later.
- Changes no driving behaviour.

## Acceptance criteria

- [ ] A test shows the boost signal fires once when W is pressed from standstill, and once when W is pressed while moving slower than cruise speed (QA: pass / fail)
- [ ] A test shows it does not fire while W stays held, including during a held drift where the car drops below cruise and jumps back every step (QA: pass / fail)
- [ ] A test shows it does not fire when W is pressed while already at or above cruise speed (QA: pass / fail)
- [ ] The car's speed values are identical with and without the effect, shown by a test (QA: pass / fail)
- [ ] A screenshot taken just after pressing W shows the placeholder effect (QA: pass / fail)
- [ ] The full test suite passes (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
