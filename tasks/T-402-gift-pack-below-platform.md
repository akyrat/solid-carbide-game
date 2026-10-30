---
id: T-402
title: Bug: a gift pack that falls on a platform is drawn below the platform
status: open
from: project-lead
to: game-loop
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/level-design.md, docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/game-loop-architecture.md, tasks/T-393-creator-objects-ignore-heights.md, game/scripts/run/, game/scripts/level/]
files_expected_to_change: [game/scripts/run/, game/scripts/level/, game/tests/unit/, docs/level-design.md, docs/game-loop-architecture.md, art-archive/]
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

The board's decision (Level design, Decisions, "A gift pack that falls on a platform shows on it", 2026-10-30; a bug the board wants fixed at once): "fix a bug where the gift, when it falls on a platform, it shows below the platform." Today's rule (Level design, Content, "Elevation sample map") says gift packs pick only street-level spots, so either the drop spot picker misses platforms (for example on levels made in the creator) or the pack's depth or height ignores the platform. Find the root cause and fix it. Write in the result notes, as a proposal for the board's playtest, which way it goes: the pack keeps to street spots (the rule as written), or it can land on a platform, drawn at the platform's height and picked up there. Either way it is never drawn below a platform.

T-393 (in review, its own worktree `C:\solid-carbide-worktrees\T-393`) fixed the depth rule for placed objects on maps with rooftops; read its result notes and reuse its rule where it fits rather than writing a second one, and keep your changes to the gift pack's code so the merges stay clean. The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): copy one into your worktree to reproduce (uncommitted), never write or commit them.

The board's review: play a level with platforms until a gift pack drops near one, and see where it lands and how it is drawn.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The root cause is written in the result notes, with a test that fails before the fix (named). (QA: pass / fail)
- [ ] A gift pack is never drawn below a platform: it lands on a street spot or on the platform as the result notes propose, drawn at the height of what it lands on (tests). (QA: pass / fail)
- [ ] If it can land on a platform, the car picks it up there (test). (QA: pass / fail)
- [ ] Level design (Content) and Game loop architecture describe the behaviour. (QA: pass / fail)
- [ ] Screenshots of a gift pack by a platform before and after are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
