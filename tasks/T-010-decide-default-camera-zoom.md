---
id: T-010
title: Board decides the camera zoom
status: done
from: project-lead
to: board
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-012]
documents_affected: [docs/drifting.md]
files_to_read_first: [docs/drifting.md, docs/drifting/unity-prototype-report.md, docs/extended-narrative.md, docs/visual-style.md]
files_expected_to_change: [docs/drifting.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**A decision for the board, not work for an agent.** Blocked until the Godot car exists with its camera zoom slider (built by the Driving & Drift Agent in T-012).

The camera zoom is fixed: players cannot change it (Drifting, Decisions). The board playtests the Godot car, tries zoom levels on the prototype's zoom slider, and picks the value the game uses. The Unity prototype's default was 14.4 (half the screen height, in car lengths: about 29 car lengths top to bottom), on a slider from 6 to 20; the board's own saved value there could not be read exactly (Unity prototype report, section 7).

The agents involved:
- **Driving & Drift Agent:** owns the camera and gives the prototype its zoom slider for this playtest.

When the board has decided, the Project Lead records the value in Drifting, Decisions, and marks this task done.

## Acceptance criteria

- [x] The board's chosen zoom is recorded in `docs/drifting.md`, Decisions, with the date (Project Lead checks)
- [x] The timeline records the decision (Project Lead checks)

## Result notes

After playtesting T-012 (2026-10-08), the board decided the zoom is not fixed after all: it is a player setting, a slider in the pause menu (built in T-015, MVP), with the Unity default of 14.4 and range 6 to 20, saved between sessions. Recorded in Drifting and HUD and menus, Decisions.
