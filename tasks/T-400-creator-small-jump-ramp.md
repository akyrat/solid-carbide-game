---
id: T-400
title: Level creator: a small jump ramp, one tile long and about 2 units high
status: open
from: project-lead
to: level-challenge
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/level-design.md, game/docs/level/]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/drifting.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/scripts/level_creator/, game/scripts/level/, game/tests/unit/level_creator/test_creator_ramps.gd]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/data/level/, game/tools/check_level.py, game/tests/unit/, game/docs/level/, docs/level-design.md, art-archive/]
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

The board's decision (Level design, Decisions, "A small jump ramp", 2026-10-30). The board: "now we have from level 0 to 3, 3 to 6, and 0 to 6 ... a ramp spans 3 blocks in length. I want a ramp that is only 1 square, and that goes up to, let's say, 2 units high, so I can do small jumps, like a small ramp."

Add it as another ramp height step (or ramp kind, whichever fits the creator's keys better; say which), placed, turned in all four directions and put on the ground or on a rooftop like the other ramps, drawn with the ramps' existing textures (no new art). Proposals for the playtest, written in the result notes: one tile long, rising 2 units; its tall end open, so the car drives up and flies off (a closed wall there would stop it) and the jump counts for airtime and the air tricks like a ramp hop; how it shows its slope (today's arrows). Enemies path round or over it as the drivability check decides. Saved levels keep it, earlier levels open unchanged, `check_level.py` accepts it, and the game's own map is unchanged.

Other agents are changing the creator at the same time (T-393 object heights, T-394 obstacle pairs): keep your changes to the ramp code. The strip label for the new step follows the existing ramps' format (numbers only, for example 0 to 2); if it needs a new word, stop and tell the Project Lead (a text ticket comes first). The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): read copies only, never write or commit them.

The board's review: place the small ramp on the ground and on a rooftop in each direction, press Play and jump off it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The creator places the small ramp in all four directions, on the ground and on a rooftop, one tile long and 2 units high, or as the result notes propose (tests). (QA: pass / fail)
- [ ] In a run the car drives up it and leaves the ground off its top, and a jump long enough counts for airtime as a ramp hop does (tests). (QA: pass / fail)
- [ ] The small ramp saves and reopens, an earlier level opens unchanged, check_level.py accepts it, and the game's own map builds as before (tests). (QA: pass / fail)
- [ ] Level design, Content and game/docs/level/ describe the piece, its keys and the proposals. (QA: pass / fail)
- [ ] Screenshots of the small ramp in each direction in the editor, and a GIF of jumping off it in a run, are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
