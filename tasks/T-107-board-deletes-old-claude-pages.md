---
id: T-107
title: Board deletes the three old claude.ai task board pages
status: done
from: project-lead
to: board
lead:
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [docs/README.md]
files_expected_to_change: []
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Work for the board:** the pages belong to the board's first Claude account, which the Project Lead can't reach.

The local task board (`docs/README.md`, "The task board") replaced the published pages on 2026-10-12. From the first account, delete:

- the old task board: https://claude.ai/artifact/3MeqfoLeaSWXxWbCb5A7op
- the prototype board: https://claude.ai/artifact/5sFYFTXCXLnAKk3PvwYxUZ
- the test board: https://claude.ai/artifact/99XwBYjzFbktMxNTr7b8uk

The links stay in `docs/timeline.md` and T-032 as history.

## Acceptance criteria

- [x] None of the three links opens any more (QA: pass) Checked by the Project Lead: the Artifact service confirmed each deletion ("its link no longer works for anyone"); no game code, so no QA agent run.

## Result notes

Done by the Project Lead on the board's go (2026-10-14): the three pages turned out to be owned by the account this session uses, so the Project Lead could reach them after all. Each was read first (titles: Solid Carbide Task Board, Solid Carbide Board Prototype, Solid Carbide Test Board, all owned and private) and then deleted with the Artifact tool, which confirmed for each that the link no longer works for anyone. The links stay in docs/timeline.md and T-032 as history.
