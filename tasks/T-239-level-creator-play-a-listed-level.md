---
id: T-239
title: Level creator: play a listed level as a full run, and come back to the creator
status: in-qa
from: project-lead
to: game-loop
lead: Goal-G-005
epic: game-loop
milestone: mvp
goal: G-005
user_facing_text: yes
changes_visuals: yes
depends_on: [T-233, T-230, T-234, T-238]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/data/level/creator_texts.json, game/scripts/run/run.gd, game/scripts/game/game_flow.gd, game/scripts/level_creator/level_creator.gd, game/scripts/level_creator/level_list_screen.gd, game/scripts/enemies/enemy_navigation.gd]
files_expected_to_change: [game/scripts/level_creator/level_creator.gd, game/tests/unit/level_creator/test_play_level.gd, game/README.md]
model: opus
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

Custom levels are played only from the creator, as a full run: the same 8 minutes, enemies and kaiju as the game (Level design, Decisions, 'Level creator', board 2026-10-21). Pressing play on a listed level (the play label from creator_texts.json) starts a run on that level's file, using the run's layout path (the 'run can play any map file' ticket), with the pause screen, weapons and the garage upgrades as the game's own run sets them up (see game_flow.gd's start_run). The game's own flow and its map stay unchanged. When the run ends, win or loss, the creator shows its level list again (the docs don't say; this is a proposal for the board, written in the result notes). Tests use a level saved into a temporary levels folder that has at least one ramp. Add playing to game/README.md, 'Level creator'. Screenshot of a run on a custom level in art-archive/<this task's id>/screenshots/.

The board's review: In the level creator, press play on a level you made and play the run to its end.

## Acceptance criteria

- [ ] A unit test presses play on a listed level: a run starts on that file (the run's layout path is the level's path), the timer reads 8:00 and minions spawn; fast-forwarding the run state to the kaiju's time makes the kaiju appear; the run's map holds the level's buildings, platforms and ramps. (QA: pass / fail)
- [ ] A unit test on that custom level: enemy navigation built for the run's map returns a path from the street to a rooftop that passes over its ramp. (QA: pass / fail)
- [ ] A unit test: when the run ends (win and loss), the creator's level list is shown again. (QA: pass / fail)
- [ ] A run started from the game's main menu still uses res://data/level/elevation_sample_map.json (test). (QA: pass / fail)
- [ ] The test that scans the creator's scripts for hard-coded label strings still passes. (QA: pass / fail)
- [ ] game/README.md, 'Level creator', says how to play a level and where the run returns. (QA: pass / fail)
- [ ] A screenshot of a run on a custom level is in art-archive/<this task's id>/screenshots/ and listed in the result notes. (QA: pass / fail)
- [ ] The full GUT suite passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Goal runner (G-005): started, in C:\solid-carbide-worktrees\T-239.

### 2026-10-22, In progress → In QA

Goal runner (G-005): the agent is done; QA is checking it.

## Result notes

Game Loop Agent, 2026-10-22.

**What was built**
- `game/scripts/game/game_flow.gd`: the run's setup moved out of `start_run()` into a static `GameFlow.add_run(parent, progress, layout_path = "")`. It does the same steps in the same order: garage upgrades (health, acceleration, damage bonus), saved zoom and camera options, the pause screen (child `PauseScreenLayer`), and the coins banked into the save. `start_run()` calls it with no path, so the main menu's run is unchanged and still plays `res://data/level/elevation_sample_map.json`.
- `game/scripts/level_creator/level_creator.gd`: Play on a listed level (`play_level(path)`) clears the list and adds a full run on that file through `GameFlow.add_run(self, progress, path)`. When the run ends, win or loss, `show_list()` is called deferred, the same way the game goes back to its menu. Clearing a screen also unpauses the tree, so a run that ends while paused comes back unpaused. `play_requested(path)` is still emitted, and `run_shown` and `list_shown` were added. The creator keeps its own `PlayerProgress`.
- `game/README.md`, Level creator: a new "Playing a level (T-239)" bullet, and the Opening bullet now points to it.

**Proposals for the board** (the docs don't settle these)
- When a run on a custom level ends, win or loss, the creator shows its level list again, with no message. Play starts the level again.
- A custom-level run is exactly the game's run. That includes banking its coins into the real save and applying the garage upgrades. If coins earned on custom levels shouldn't count, that is a one-line change: leave out `connect_run` for the creator.

**Tests** (all run, all pass)
- `game/tests/unit/level_creator/test_play_level.gd`, 13 tests. They use a level saved only into a temporary folder (`RunPaths`): the elevation sample map with its first building and roof-se-6 (with its ramp) removed, so it keeps roof-nw-3 and its ramp. What they check:
  - Play starts a run whose `layout_path` is the level's path; the timer reads 8:00; minions spawn; advancing the state to boss time makes the kaiju appear.
  - The map holds the level's buildings, rooftop ids and ramp ids.
  - Navigation finds a path from the street (-60, -48) to roof-nw-3 (-80, -80) over a ramp.
  - The level list is shown again after a win, after a loss on health, after a loss on the clock, and after a run that ends while paused.
  - Play after a run starts a fresh run.
  - A main-menu run still plays the sample map.
- `test_level_list.gd`: the Play signal test now saves a whole map file, because Play now really starts a run on it.
- The test that scans the creator for hard-coded labels passes. The new code adds no text, and the Play label is still `play_action`.
- Full GUT suite: 1386/1386 passed.

**Screenshots** (`art-archive/T-239/screenshots/`, from `game/tests/fixtures/level_creator_play_demo*.tscn`; the fixture builds the level in the editor and saves it into a temporary folder)
- `run_on_custom_level.png`: a run on the custom level "Rooftop corner", with its ramp up to the 3 (top right), a boulder and a minion.
- `back_to_list_after_run.png`: the creator's level list after the run ended as a win.
- In both run shots the clock still read 8:00 when the picture was taken. The screenshot tool takes few real frames; the unit tests check the clock.

**Documents affected:** none (documents_affected is empty). The return-to-list proposal is written here and in game/README.md for the board to settle.

**PixelLab:** 0 generations. **Refusals:** none.

**Uncommitted:** Godot's line-ending-only `.import` noise in the working tree was not committed.
