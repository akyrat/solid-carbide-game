---
id: T-139
title: The likes bar animates when the player levels up
status: open
from: project-lead
to: ui
lead: Level-up
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/game-loop-architecture.md, tasks/T-131-combo-heat-levels.md, tasks/T-113-hud-vertical-health-and-likes-bars.md, game/README.md]
files_expected_to_change: [the HUD scene and scripts, tests, docs/hud-and-menus.md, game/README.md]
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

The board (2026-10-15): "add an animation to the level up bar when the player levels up". The likes bar at the bottom of the HUD (with "Likes" and "Hype Lv {level}") plays a short animation at the moment the player levels up, before or as the level-up screen opens.

What the animation looks like is your proposal, written in the result notes for the board to judge in its playtest. Keep it in the HUD's comic look (the combo counter's and the trick popups' style: hard pixel edges, pulses in pixel-art frames, T-131), drawn in code, never Redgull red. For example: the bar flashes white-hot as it fills to the end, "Hype Lv" pops with the new number, a few pixel sparks burst off the bar. It must play even though the level-up pauses the run (it runs while paused, or plays just before the pause), stay clear of the combo counter and the other HUD parts at the HUD's window sizes, and not hide the new level number for long. No new player-facing text.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test levels the player up in a run and shows the animation starts at the level-up, ends within its proposed length, and leaves the bar and texts as they were (the new level shown, the bar starting again) (QA: pass / fail)
- [ ] A test shows the animation still plays when the level-up pauses the run, and that it doesn't play on other changes to the bar (likes going up, the drain) (QA: pass / fail)
- [ ] A screenshot sequence of a run shows the animation's key frames, clear of the other HUD parts, with no Redgull red (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes it in Content, without changing Summary, Decisions or Open questions, and `game/README.md` says how it's built (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

Written by the agent when it finishes.
