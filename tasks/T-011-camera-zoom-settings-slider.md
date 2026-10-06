---
id: T-011
title: Camera zoom slider in the settings menu
status: blocked
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
depends_on: [T-010]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/drifting/unity-prototype-report.md, tasks/T-010-decide-default-camera-zoom.md]
files_expected_to_change: [the settings menu scene and script, and their tests]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until the board has chosen the default zoom (T-010) and the game has a settings menu** (not planned yet; that task will be added to `depends_on`).

The camera zoom is a player setting (Drifting, Decisions). Add a zoom slider to the settings menu. It starts at the default from T-010 and keeps the player's choice between sessions. As in the Unity prototype, the slider covers 6 to 20 (half the visible height, in car lengths), unless the board decides otherwise.

The UI Agent builds the slider and collects the input only (its role). The camera belongs to the Driving & Drift Agent: the slider sets the camera's zoom through whatever the camera exposes, without changing camera code. How the setting is saved follows the game's save system (Game Data Agent), once it exists.

## Acceptance criteria

To be finalised when this task is unblocked. They will cover: the slider's range and default, the camera zoom changing with it, the choice surviving a restart, and the full test suite passing.

## Result notes

Written by the agent when it finishes.
