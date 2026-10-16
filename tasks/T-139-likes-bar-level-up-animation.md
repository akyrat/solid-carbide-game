---
id: T-139
title: The likes bar animates when the player levels up
status: in-qa
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
qa_rounds: 1
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

**Note (Project Lead, 2026-10-16):** T-144 (built at the same time) changes the level-up: the level-up screen no longer opens at once, a helicopter drops a package and the screen opens when the car drives over it; the run keeps going until then. The animation plays at the moment of the level-up (when the bar fills), not when the screen opens, so it must work whether the run is running or paused. The board plays T-139 and T-144 together in one build.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test levels the player up in a run and shows the animation starts at the level-up, ends within its proposed length, and leaves the bar and texts as they were (the new level shown, the bar starting again) (QA: pass)
- [ ] A test shows the animation still plays when the level-up pauses the run, and that it doesn't play on other changes to the bar (likes going up, the drain) (QA: pass)
- [ ] A screenshot sequence of a run shows the animation's key frames, clear of the other HUD parts, with no Redgull red (QA: pass)
- [ ] `docs/hud-and-menus.md` describes it in Content, without changing Summary, Decisions or Open questions, and `game/README.md` says how it's built (QA: pass)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Updates

### 2026-10-16, Open → In progress

Started: agent launched in C:\solid-carbide-worktrees$t. Part of the one level-up playtest build.

### 2026-10-16, In QA

Built: a 0.75 s white-hot flash on the likes bar with pixel sparks and a Hype Lv pop; plays paused or not. In QA now; you'll play it in the one level-up build.

## Result notes

Built by the UI Agent. Proposal for the board to judge in playtest:

- **The animation (0.75 s, 9 pixel-art frames at 12 a second):** the moment the bar fills, a white-hot cover sweeps across the likes bar from the left in 3 frames (the bar fills to the end), stays white-hot 2 frames, goes yellow, then flickers away in yellow and orange stripes while the bar is back at its new start. A burst of 16 square pixel sparks (white, yellow, orange) flies up off the bar (at most 24 px high) and fades. "Hype Lv {n}" pops to 1.3x from its bottom right corner (up and left, never down onto the bar), white-hot, then yellow, then settles. The new level number shows the whole time. Hard pixel edges, drawn in code, no Redgull red, no new text, no sound.
- **Where it lives:** `game/scripts/hud/level_up_flash.gd` (`LevelUpFlash`, `hud.level_up_flash`); the Hud connects the run state's existing `level_up` signal in `bind()` (`_on_level_up`). It is PROCESS_MODE_ALWAYS, so it plays the same whether the run is paused at that moment (today) or keeps going (T-144). Level-up timing and the level-up screen are untouched, so it should merge cleanly with T-144 (only hud.gd, small additions in `_build_bottom`, `_layout_bottom`, `bind` and one new handler).
- **Tests:** new `tests/unit/hud/test_hud_level_up_flash.gd` (10 tests: start/end/length, bar and texts as before, paused with real timers while the tree is paused, run keeps going, other bar changes and combo drain ignored, restart, bind stops it, no red and pixel grid, clear of the combo counter at its biggest step and inside the bar at 1152x648, 1280x720, 1920x1080, 1024x576) and `tools/test_level_up_flash_strip.py`. `test_hud_layout.gd` got two lines that stop the animation before measuring (the label's rectangle grows during the pop). Full GUT suite: 787/787 pass. Python: game/tools 266 passed, tools/ 182 passed.
- **Screenshots (key frames before, 0, 1, 2, 4, 5, 6):** `C:\solid-carbide-worktrees\T-139\screenshots\level_up_flash_frames.png` (all stacked, 2x) and the single frames beside it; copies in `C:\solid-carbide-worktrees\T-139rt-archive\T-139\screenshots\`. Made by `bash game/tools/level_up_flash_shots.sh screenshots`.
- **Honest view:** the sparks are small and fairly sparse; the stripes in the last frames are a busy look. Cheapest tweaks if the board finds it weak: bigger or more sparks, a shorter or longer length (`FRAME_COUNT`).
- Documents updated: docs/hud-and-menus.md (Content only), game/README.md.
- 2026-10-16, in-progress → in-qa: Likes bar level-up animation (0.75 s flash, sparks, Hype Lv pop) built, tests and screenshots in place
