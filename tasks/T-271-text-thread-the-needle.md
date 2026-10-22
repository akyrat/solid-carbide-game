---
id: T-271
title: "Text: the thread the needle trick's popup and its creator labels"
status: open
from: project-lead
to: narrative-theme
lead: Coursework
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/hud-and-menus.md, docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/level-design.md, game/data/level/creator_texts.json, tasks/T-241-text-airtime-trick-popup.md]
files_expected_to_change: [docs/hud-and-menus.md, docs/level-design.md, game/data/level/creator_texts.json]
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

The board's decision (Level design, Decisions, "Thread the needle", 2026-10-22): driving between two obstacles the board marked as a pair in the level creator is a trick the board named **thread the needle**. Write:

1. **Its popup** in the trick popups' voice (LONG DRIFT!, HANG TIME!, AIR 360!; HUD and menus, Content), keeping the board's name (for example THREAD THE NEEDLE!), followed by "+{amount}" like the others; into HUD and menus, Content, with this ticket's id, for T-272 to use word for word.
2. **The creator's labels**, plain like T-261's, into `game/data/level/creator_texts.json` (keep every existing key unchanged) and Level design, Content, "Level creator text": the tool or key hint for marking a pair (for example "Pair: click two obstacles", with its key), the top bar message once a pair is made and when a pick isn't an obstacle, and "Unpair" for removing a pair. Built on the level creator's build: the Project Lead makes your folder from `playtest/creator-set`.

## Acceptance criteria

- [ ] HUD and menus, Content, has the popup text with this ticket's id, keeping the board's name, in the trick popups' voice with "+{amount}" (QA: pass / fail)
- [ ] `creator_texts.json` is valid JSON with the pair labels (each with a "where it appears" note), every existing key unchanged, and they are listed in Level design, Content (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
