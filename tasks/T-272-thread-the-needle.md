---
id: T-272
title: "Thread the needle: pair two obstacles in the creator, and drive between them for a trick"
status: blocked
from: project-lead
to: level-challenge
lead:
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

The board's decision (Level design, Decisions, "Thread the needle", 2026-10-22).

**In the creator:** a way to mark two placed obstacles as a pair (any piece the car crashes into and that cuts the combo: boulders, barriers, cones, crates), with T-271's labels: pick the pair tool or key, click one obstacle, then another; a non-obstacle is refused with T-271's message. A paired obstacle shows its link in the editor (for example a dashed line between the two, your proposal), a pair can be removed (Unpair, or deleting either obstacle), an obstacle is in at most one pair, and pairs are saved in the level file and reopened. `check_level.py` checks every pair names two existing obstacles.

**In a run on that level:** when the car passes through the gap between a pair (crossing the line between them, without touching either), it is the **thread the needle** trick: it raises the combo like the other tricks, with T-271's popup word for word and its "+{amount}". Your proposals for the playtest, as tuning numbers in `game/data/combo.json` with their reasons in the result notes: what it is worth (compare with ALT DRIFT! and AIR 360!), whether it pays again on later passes through the same pair (for example after a cool-down, or once per lap), and whether it counts in the air (over a gap). Whether the pair shows in the run (a faint marker on the ground, or nothing) is your proposal too, drawn in code, never Redgull red. A crash into either obstacle cuts the combo as today and pays nothing. The game's own map has no pairs and is unchanged. Write the trick into Game loop architecture's list of tricks.

Built on T-262's branch once it passes QA (the Project Lead makes your folder), so it fits the regrouped panel. End with a screenshot of a pair in the editor and a short GIF of the car threading it in a run with the popup.

## Acceptance criteria

- [ ] Tests show two obstacles can be paired and unpaired, a non-obstacle is refused, pairs save and reopen, and `check_level.py` refuses a pair that names a missing obstacle (QA: pass / fail)
- [ ] Tests show crossing the gap between a pair pays the trick once with the data's amount and T-271's popup, touching either obstacle pays nothing and cuts the combo, and the repeat rule works as proposed (QA: pass / fail)
- [ ] The numbers live in `combo.json` with their reasons; Game loop architecture lists the trick; the game's own map is unchanged (QA: pass / fail)
- [ ] The screenshot and GIF are in `art-archive/T-272/screenshots/`; `game/README.md` describes it; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: pair two boulders in the creator and drive between them.
Board review files: the screenshot and GIF in `art-archive/T-272/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
