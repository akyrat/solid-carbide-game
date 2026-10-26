---
id: T-299
title: Style loop: Greenbull's flag and the new rule 6 in the evaluator's style guide
status: blocked
from: project-lead
to: project-lead
lead: Goal-G-006
epic: tooling
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: no
depends_on: [T-298, T-296]
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, tools/style_loop/loop.py, tools/style_loop/run.py, tools/style_loop/test_loop.py, game/tools/style_rules.py, tasks/T-291-style-loop-tool.md, tasks/T-296-style-loop-keeps-earlier-runs.md]
files_expected_to_change: [tools/style_loop/loop.py, tools/style_loop/run.py, tools/style_loop/test_loop.py, tasks/README.md]
model: sonnet
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

The style loop tool (T-291) still speaks of Redgull: run.py has a --redgull option and loop.py an ArtSpec.redgull field that it passes to style_rules.art_checks. After D1 renames the flag to --greenbull, rename the loop's option and field the same way, so an asset marked as one of Greenbull's own things is checked with style_rules.py's Greenbull flag. Check that the style guide text the loop gives the Style Evaluator for art is the current Visual style, Content, Rules, rule 6 included ('Greenbull's colours'), read from docs/visual-style.md and not copied into the tool. Update the tests that expect the old rule 6 message ('no Redgull red'). Update the loop command in tasks/README.md, 'The style loop' ([--redgull] becomes [--greenbull]). Depends on T-296 because both change loop.py and test_loop.py. Tooling only: nothing to picture, the result notes say so in one line.

## Acceptance criteria

- [ ] `git grep -i redgull tools/style_loop` finds nothing. (QA: pass / fail)
- [ ] A test runs the loop (with --fake) on an art asset marked --greenbull and checks that style_rules.art_checks was called with the Greenbull flag set; a second test checks it is not set without the option. (QA: pass / fail)
- [ ] A test reads the style guide text the loop extracts for the Style Evaluator and finds "Greenbull's colours" in it and no 'Redgull'. (QA: pass / fail)
- [ ] tasks/README.md, 'The style loop', shows --greenbull in the art command and no --redgull. (QA: pass / fail)
- [ ] tools/style_loop/test_loop.py passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
