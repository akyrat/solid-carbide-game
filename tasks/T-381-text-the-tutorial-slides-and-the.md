---
id: T-381
title: Text: the tutorial slides and the pause screen's trick list
status: in-progress
from: project-lead
to: narrative-theme
lead: Goal-G-007
epic: narrative
milestone: mvp
goal: G-007
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, game/docs/driving/tricks.md, game/data/recap_text.json, game/data/screen_texts.json]
files_expected_to_change: [game/data/tutorial_text.json, docs/hud-and-menus.md]
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

The last MVP round (board, 2026-10-29; HUD and menus, Decisions: 'Tutorial slides before the first run', 'A trick list in the pause screen') needs every text for the three tutorial slides and the pause screen's trick list, written before the UI tickets that show them. Write them into a new data file, game/data/tutorial_text.json (same shape as game/data/recap_text.json: one key per string, each with a comment saying where it appears). Texts: slide 1, the controls (W, A, S, D, and that accelerating while turning drifts the car). Slide 2: the seven trick names, one per trick id in game/docs/driving/tricks.md (extended_drift, three_sixty, alternate_drift, air_one_eighty, air_three_sixty, airtime, thread_the_needle), reusing the names the trick popups already show so each trick has one name; plus a short line on how tricks bring viewers, viewers bring subs, and sub goals bring gift packs with weapons that help survive and keep enemies away. Slide 3, the goal: chain tricks to get the most weapons and be strongest when the kaiju arrives with 1 minute left. Also: the Start button, the 'Don't show again' checkbox, the left and right arrows' accessible labels (tooltip text), the pause screen's trick list button and the trick list panel's back control. Keep slide text short enough for one 1152 x 648 screen. Every line goes through the style loop (tools/style_loop/run.py text, kind label for buttons, popup or card_desc for longer lines as fits). No line uses the form 'Greenbull says ...'. Add a section to HUD and menus, Content listing the texts and their keys.

The board's review: Read the slide and trick list texts in game/data/tutorial_text.json, then in the game once the slides are built.

## Acceptance criteria

- [ ] game/data/tutorial_text.json exists, is valid JSON and holds a key with a non-empty string and a comment saying where it appears for each of: slide 1 controls (naming W, A, S, D and that accelerating while turning drifts the car), the seven trick names (one per trick id in game/docs/driving/tricks.md), slide 2's tricks to viewers to subs to gift pack with weapons text, slide 3's goal text (chain tricks, most weapons, strongest when the kaiju arrives with 1 minute left), the Start button, the 'Don't show again' checkbox, the left and right arrows' accessible labels, the pause screen's trick list button and the panel's back control. (QA: pass / fail)
- [ ] The ticket's Style review records the style loop rounds for every new line, and each kept line scored 8 or more. (QA: pass / fail)
- [ ] No string in game/data/tutorial_text.json uses the form 'Greenbull says ...' (checked with a search of the file). (QA: pass / fail)
- [ ] docs/hud-and-menus.md, Content has a section listing the tutorial and trick list texts with their keys. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Goal runner (G-007): started, in C:\solid-carbide-worktrees\T-381.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
