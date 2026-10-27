---
id: T-272
title: "Thread the needle: pair two obstacles in the creator, and drive between them for a trick"
status: done
from: project-lead
to: level-challenge
lead: Coursework
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-271]
documents_affected: [docs/level-design.md, docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, game/README.md, game/scripts/level_creator/, game/data/level/props.json, game/data/combo.json, game/scripts/run/run.gd, game/scripts/run/run_state.gd, tasks/T-242-airtime-trick.md, tasks/T-253-placeable-props.md, tasks/T-262-creator-panel-grouped.md]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/scripts/run/, game/data/combo.json, game/tools/check_level.py, game/tests/, game/README.md, docs/level-design.md, docs/game-loop-architecture.md, art-archive/T-272/screenshots/]
model: opus
qa_rounds: 1
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

The board's decision (Level design, Decisions, "Thread the needle", 2026-10-22).

**In the creator:** a way to mark two placed obstacles as a pair (any piece the car crashes into and that cuts the combo: boulders, barriers, cones, crates), with T-271's labels: pick the pair tool or key, click one obstacle, then another; a non-obstacle is refused with T-271's message. A paired obstacle shows its link in the editor (for example a dashed line between the two, your proposal), a pair can be removed (Unpair, or deleting either obstacle), an obstacle is in at most one pair, and pairs are saved in the level file and reopened. `check_level.py` checks every pair names two existing obstacles.

**In a run on that level:** when the car passes through the gap between a pair (crossing the line between them, without touching either), it is the **thread the needle** trick: it raises the combo like the other tricks, with T-271's popup word for word and its "+{amount}". Your proposals for the playtest, as tuning numbers in `game/data/combo.json` with their reasons in the result notes: what it is worth (compare with ALT DRIFT! and AIR 360!), whether it pays again on later passes through the same pair (for example after a cool-down, or once per lap), and whether it counts in the air (over a gap). Whether the pair shows in the run (a faint marker on the ground, or nothing) is your proposal too, drawn in code, never Redgull red. A crash into either obstacle cuts the combo as today and pays nothing. The game's own map has no pairs and is unchanged. Write the trick into Game loop architecture's list of tricks.

Built on T-262's branch once it passes QA (the Project Lead makes your folder), so it fits the regrouped panel. End with a screenshot of a pair in the editor and a short GIF of the car threading it in a run with the popup.

## Acceptance criteria

- [ ] Tests show two obstacles can be paired and unpaired, a non-obstacle is refused, pairs save and reopen, and `check_level.py` refuses a pair that names a missing obstacle (QA: pass; GUT creator_pairs (16) cover pair/unpair, refusal, save/reopen; TestCheckPairs covers missing obstacle; all green)
- [ ] Tests show crossing the gap between a pair pays the trick once with the data's amount and T-271's popup, touching either obstacle pays nothing and cuts the combo, and the repeat rule works as proposed (QA: pass; GUT thread_the_needle (16) cover pay once, touch cancels, repeat_seconds; popup is THREAD THE NEEDLE! +0.5, matching T-271 in hud-and-menus.md)
- [ ] The numbers live in `combo.json` with their reasons; Game loop architecture lists the trick; the game's own map is unchanged (QA: pass; combo.json has numbers and reasons, game-loop-architecture lists the trick, mvp_ground.json unchanged by T-272 commits and has no pairs)
- [ ] The screenshot and GIF are in `art-archive/T-272/screenshots/`; `game/README.md` describes it; the full GUT suite and all Python tool tests pass (QA: pass; screenshots and GIF checked, GIF shows the car crossing and popup; README updated; GUT 1593 pass (first run segfaulted 139 in an unrelated popup test, rerun clean), game/tools 496 OK, tools 451 OK)

The board's review: pair two boulders in the creator and drive between them.
Board review files: the screenshot and GIF in `art-archive/T-272/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-23, Blocked → In progress

Started on the creator line: pair two obstacles, drive between them for THREAD THE NEEDLE!.

### 2026-10-23, In progress → In QA

Built: P pairs two obstacles in the creator; driving between them pays THREAD THE NEEDLE! +0.5, again after 3 s. Sent to QA.

### 2026-10-23, In QA → Needs playtest

QA passed all 4. Ready to play in the creator build: pair two boulders with P and drive between them. T-280 starts on it.

## Result notes

Written by the agent when it finishes.

**Level/Challenge Design Agent, 2026-10-23.** Built on the branch as given (T-262 to T-265, T-271's and T-279's labels). Commits `d6dd4b0` to `a968e59`.

**In the creator.**
- Obstacles are the boulders plus the Obstacles group's props (barrier, cones, crates). The list is read from the catalogue's `obstacles` group in `creator_assets.json`, so there is only one list.
- The pair tool is the top bar's "Pair obstacles", or **P** (`KEY_ACTIONS`). Click one obstacle, then a second one. Anything else gets `pair_not_obstacle` and the first click is kept. Clicking the same obstacle again lets it go. The tool stays on until P, Esc, a right-click or picking a piece.
- Unpair appears when a paired obstacle is selected. Deleting either obstacle also removes the pair.
- The hint line is now `controls_hint_pairs`. T-279's `controls_hint_spawn` is left for T-280, which builds the spawn point.
- Pairs are saved as `pairs: [{id, a, b}]` and reopen with the level.
- A ref is a boulder's copy id, or `<copy>/<index>` for copies that hold several boulders (the game's own map has those), or a prop's id. The shared code is `scripts/level/obstacle_pairs.gd`.
- `check_level.py` (`check_pairs`) checks that each pair names two different obstacles that exist, and that no obstacle is in two pairs.

**Proposals for the playtest.** The numbers are in `combo.json` with their reasons.
- **Worth: 0.5.** That is the same as ALT DRIFT! and AIR 360!, and twice a FULL 360!. You have to aim a line through a gap the board placed.
- **Repeat rule:** a pair pays again in either direction once 3.0 s have passed since it last paid (`repeat_seconds`). So weaving back and forth over the line doesn't pay on every crossing.
- **Air: it counts** (`counts_in_air: true`), so a jump through the gap pays. The car can't fly over the obstacles themselves, because a car in the air still crashes into them.
- **Touching:** a touch of either obstacle from 0.5 s before the crossing to 0.25 s after it cancels the pass (`touch_window_seconds`, `clear_seconds`). The crash cuts the combo as usual. The popup appears 0.25 s after the crossing.
- **Last-made pair wins:** pairing an obstacle that is already in a pair replaces its old pair.
- **Editor look:** a mint-green dashed line from one obstacle's edge to the other's, and a ring round each. The obstacle being held for a new pair gets a thicker ring.
- **Look in the run:** a faint dashed chalk-white line on the ground across the gap (alpha 0.35), drawn in code. It is never red.

**In the run.**
- `scripts/level/thread_the_needle.gd` reads the map's pairs. `run.gd` feeds it the car's centre after every step and every `hit_obstacle`.
- `RunState.add_needle_trick()` raises the combo by `trick_add.thread_the_needle`. The popup reads **THREAD THE NEEDLE!** plus "+{amount}", for example "THREAD THE NEEDLE! +0.5".
- The game's own map has no pairs, so there are no gates and no marker.
- Game loop architecture's combo section now lists the tricks, thread the needle included.

**Tests.**
- New GUT tests: `tests/unit/level_creator/test_creator_pairs.gd` (16) and `tests/unit/run/test_thread_the_needle.gd` (16).
- New Python tests: `TestCheckPairs` in `tools/test_check_level.py`.
- Three hint assertions changed from `controls_hint_rework` to `controls_hint_pairs`.
- Full GUT suite: 1593 passing, TESTS PASSED. Python: `game/tools` 496 OK (1 skipped), `tools` 451 OK.

**Screenshots** (`art-archive/T-272/screenshots/`):
- `pair_in_editor.png`: two pairs, plus a crate held as the first of a new pair.
- `thread_the_needle.gif`: the car drives through a boulder pair across a road, and the popup shows.
- `popup.png`: the frame with the popup.
- `drive_end.png`: the last frame.

I looked at all of them. One thing to note for the playtest: the game's boulder sprites are drawn larger than their collision circles (3 across), so on screen the gap looks narrower than it really is. That was already true before this ticket.

**Documents affected:** `docs/level-design.md` (Content, "Level creator: thread the needle"), `docs/game-loop-architecture.md` (The combo, the list of tricks), `game/README.md` ("Level creator", "Thread the needle (T-272)"; Tricks; the validator line).

No refusals.
- 2026-10-27, needs-playtest → done: The board's playtest of the creator build (playtest/creator-set, 2026-10-28): every check ticked on the playtest page, everything works fine.
