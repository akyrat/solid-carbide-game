---
id: T-306
title: Code comments, tests, tool names and game/README.md say Greenbull, behaviour unchanged
status: blocked
from: project-lead
to: qa-integration
lead: Goal-G-006
epic: tooling
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: no
depends_on: [T-298, T-299, T-302, T-303, T-304, T-305]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/tools/style_rules.py, game/scripts/hud/hud.gd, game/tools/make_logo_sizes.py]
files_expected_to_change: [game/scripts/, game/tests/, game/tools/, game/README.md]
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

After the rebrand tickets of this goal, code comments, tests, tool names and game/README.md still say Redgull in many places (for example 'never Redgull red' in game/scripts comments, REDGULL_RED and is_redgull_red in style_rules.py, HEART_COLOR's comment in hud.gd, make_logo_sizes.py, draw_gull_silhouette.py). Make them follow the new name and the docs (Visual style, Decisions, 'Red after the rebrand': red is no longer Greenbull's, the likes heart stays red), without changing behaviour:

- Rename constants, flags and functions named after Redgull to names that say what they are now (for example the heart's red, or the red check), with every caller; values and checks unchanged.
- Rewrite comments and test messages that say Redgull to what is true now; keep historical facts in art records as they are.
- Redgull-only tools (make_logo_sizes.py, draw_gull_silhouette.py, flatten_logo.py if Redgull-only) are renamed or marked as the old logo's history, never deleted.
- game/README.md says Greenbull where it describes the sponsor, and the old Redgull logo as history.

Show in the result notes that the diff touches only names, comments and strings. Nothing to picture: the result notes say so in one line.

## Acceptance criteria

- [ ] `git grep -i redgull game/scripts game/tests game/tools game/README.md` finds nothing except history in art records or in tools marked as the old logo's history, each match listed in the result notes. (QA: pass / fail)
- [ ] REDGULL_RED, is_redgull_red, the --redgull flag and any other name after Redgull are renamed, with every caller; the result notes show the diff touches only names, comments and strings, and the constants' values are unchanged. (QA: pass / fail)
- [ ] make_logo_sizes.py and any other Redgull-only tool is renamed or marked as the old logo's history; none is deleted (git log shows no deletion). (QA: pass / fail)
- [ ] The likes heart's colour (hud.gd HEART_COLOR) is unchanged. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
