---
id: T-594
title: Texts: Replay, Skip and "your turn" for the tutorial's demos
status: done
from: project-lead
to: narrative-theme
lead: Rails
epic: tutorial
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/data/tutorial_text.json, game/docs/hud-and-menus/tutorial-slides.md]
files_expected_to_change: [game/data/tutorial_text.json, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Write the three texts of HUD and menus, Decisions, "The tutorial's recorded demos", in tutorial_text.json, in the voice and length of the tutorial's other texts: the button that replays the slide's recording (the board's word: "replay"), the button that skips it and goes to the player's turn (the board's word: "skip"; check the slides' existing Skip button so the two don't read the same or clash), and the label that shows for 2 seconds when the player's turn starts (the board's words: "your turn"). The board named them, so start from its words and keep them unless a clash forces a change; no style loop for the board's own words. Use keys next to the tutorial's other texts, with a _comment saying where each shows; list them in the result notes for T-574's build and in hud-and-menus.md Content. This branch starts from T-574's.

The board's review: in T-574's build.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The three texts exist in tutorial_text.json with keys and _comment, listed in the result notes with where each shows. (QA: pass)
- [ ] docs/hud-and-menus.md Content lists them. (QA: pass)
- [ ] QA's full run passes, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: Replay, Skip and your turn texts for the tutorial demos.

### 2026-11-08, In progress → In QA

Texts in: Replay, Skip demo, Your turn. They show in T-574's build; checked together with it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Narrative Theme Agent (relayed by the Project Lead): three texts in game/data/tutorial_text.json block demo, each with _comment: demo.replay 'Replay' (trick slide button, replays the recording); demo.skip 'Skip demo' (button while the recording plays; 'demo' added so it does not clash with button.skip 'Skip', the slides' top-right control); demo.your_turn 'Your turn' (label over the practice window for 2 s when the recording ends or is skipped, then fades). Listed in docs/hud-and-menus.md Content. Commit 5989696b. The agent ran no tests: a hook refused its raw Godot --import, and it stopped. Project Lead: qa_check's one Python failure (test_text_inventory, tutorial_text.json) already fails on T-574's branch, not from these texts; T-574 tweak 12 fixes it. Screenshots come with T-574's build, where the texts first show.
- 2026-11-08, needs-playtest → done: Board: T-574 lgtm, merge (2026-11-08); texts seen in its build
