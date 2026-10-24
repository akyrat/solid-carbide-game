---
id: T-283
title: "Level creator: a \"+\" button that asks for a new piece, and the panel picking it up"
status: blocked
from: project-lead
to: level-challenge
lead: Coursework
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-282, T-284, T-285]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/README.md, docs/README.md, game/scripts/level_creator/, game/data/level/creator_texts.json, tasks/T-262-creator-panel-grouped.md, tasks/T-284-creator-request-inbox.md, tasks/T-285-add-generated-creator-piece.md]
files_expected_to_change: [game/scripts/level_creator/, game/scenes/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-283/screenshots/]
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

The board's decision (Level design, Decisions, "Asking for a new piece from the creator", 2026-10-24). The board asks for a new piece from inside the level creator:

- **The "+" button:** at the top of the side panel, it opens a small tab.
- **The tab:** has the piece's kind (building, obstacle or decoration), a description box for the board's own words, an optional footprint size, and Send and Cancel. All labels come from T-282.
- **Send:** writes a request into T-284's inbox, in the format `docs/README.md` gives. An empty description is refused with T-282's message.
- **Requests in the panel:** each sent request has its own line with T-282's state labels (waiting, being made, ready, failed), read back from the inbox while the creator is open.
- **A ready piece:** when the request is ready, the piece T-285's script added appears in its group with a button like the others, with no restart and without losing the level being edited. It can be placed, saved and played like any other piece.
- **Unchanged:** nothing in the creator changes when no request is sent.

The creator only writes requests and reads their status and the catalogue. It never calls PixelLab or any outside service.

Built on the level creator's build after T-282, T-284 and T-285: the Project Lead makes your folder. End with screenshots of the tab filled in, a request waiting, and the panel with a ready piece. Make the ready piece in a test fixture with T-285's script and an existing PNG; no PixelLab calls.

## Acceptance criteria

- [ ] Tests show Send writes a request in T-284's format with the kind, the description word for word and the footprint, that an empty description is refused, and that Cancel writes nothing (QA: pass / fail)
- [ ] Tests show each request's line follows its status in the inbox, and that a piece added by T-285's script appears in its group while the creator is open, can be placed, saves and plays, with the open level kept (QA: pass / fail)
- [ ] Labels from `creator_texts.json`; no Redgull red; the creator makes no network calls (QA: pass / fail)
- [ ] Screenshots are in `art-archive/T-283/screenshots/`; `game/README.md` describes it; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: press "+", send a request for a piece, and see it arrive in the panel.
Board review files: the screenshots in `art-archive/T-283/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
