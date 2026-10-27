---
id: T-345
title: Token spend: one script writes a new ticket's paperwork
status: open
from: project-lead
to: project-lead
lead: Tokens
epic: token-spend
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, tasks/_TEMPLATE.md, tools/task_status.py]
files_expected_to_change: [tools/new_ticket.py, tools/test_new_ticket.py, tasks/README.md]
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

Writing tickets and doc edits by hand was 16 to 24% of the long sessions' weighted cost; each ticket takes the Project Lead about five steps (next free number, the template, the timeline entry, regenerating the GDDs, the commit). Write `tools/new_ticket.py` that takes a short JSON or YAML file (title, slug, agent, epic, model, the header lists, description, criteria, timeline text, and the decision docs the Project Lead already edited) and: picks the next free number from `tasks/` and `git log` on `master`, writes the ticket from `tasks/_TEMPLATE.md` (the shared comment and sections copied, not retyped), claims it for a given lead, appends the timeline entry, regenerates the long GDD and the short GDD's fingerprint when a game area doc changed, and commits only those files after checking no merge is in progress. It prints one line per ticket. Several tickets in one file make one commit.

The decisions themselves stay the Project Lead's (it still writes the Decisions line in the game area doc, and the criteria). Describe the script in `tasks/README.md`.

Part of the token-spend epic (board, 2026-10-28; `tasks/README.md`, "Epics and milestones"). The evidence behind it is the Tokens session's recon of 2026-10-28 (summarised in `docs/timeline.md`, "2026-10-28: The token-spend epic"). Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Tests on a throwaway repo show two tickets from one input file written with the next free numbers, the template's sections intact, the header parseable by `tools/task_status.py`, the lead claimed, one timeline entry each, and a single commit with only those files. (QA: pass / fail)
- [ ] A test shows the script refusing to commit while a merge is in progress. (QA: pass / fail)
- [ ] `tasks/README.md` describes the script and its input. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
