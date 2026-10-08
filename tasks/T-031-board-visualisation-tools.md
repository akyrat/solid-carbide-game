---
id: T-031
title: The board's own visualisation tools (HTML)
status: open
from: project-lead
to: board
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/README.md]
files_to_read_first: [tasks/README.md, tasks/_TEMPLATE.md, docs/README.md]
files_expected_to_change: [the visualisation tools (location chosen by the board), docs/README.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Work for the board, not for an agent.** The board plans to build visualisation tools for its own use at some point, probably as HTML pages, to see parts of the project at a glance (board, 2026-10-09). What they show and how they look is up to the board. It does not block the MVP.

Things they could read, all in the repo:
- the task files' headers in `tasks/`, which are parseable by design (`tasks/README.md`)
- the agent definitions in `.claude/agents/`
- the game area docs' front matter and sections (`docs/README.md`)
- the timeline in `docs/timeline.md`

When a tool exists, the Project Lead lists it in `docs/README.md` (what it shows and how to open it), and adds any follow-up tasks the board asks for.

## Acceptance criteria

- [ ] Each tool the board builds under this task is listed in `docs/README.md`, with what it shows and how to open it (Project Lead checks)
- [ ] The timeline records it (Project Lead checks)

## Result notes

Written when the board has built a tool.
