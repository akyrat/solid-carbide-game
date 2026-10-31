---
id: T-456
title: Text: the mission notebook page, its goal phrasings, and the driving power-up overlay with the four power-ups' names and tier descriptions
status: in-progress
from: project-lead
to: narrative-theme
lead: Goal-G-009
epic: narrative
milestone: mvp
goal: G-009
user_facing_text: yes
changes_visuals: no
board_approved_art: no
depends_on: [T-455]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/drifting.md, game/data/missions.json, game/data/power_ups.json, game/data/screen_texts.json, game/tools/style_rules.py]
files_expected_to_change: [game/data/screen_texts.json, docs/hud-and-menus.md, game/tests/unit/test_mission_texts.gd]
model: sonnet
qa_rounds: 0
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

Text for goal G-009 (Game loop architecture, Decisions, 'Mission packs'; Drifting, Decisions, 'Driving power-ups'). Every piece goes through the style loop (`python tools/style_loop/run.py text ...`, kind `label`, `card_title` or `card_desc` as fits).

Write, into a new `missions` and `power_ups` section of the game's existing text data file `game/data/screen_texts.json` (or the file the HUD's texts already live in, say which in the result notes), and list in HUD and menus, Content:
- The notebook page's header (left side of the HUD, a pixel-art notebook page showing the current mission; short, it sits on a small page).
- One goal phrasing template per trick or goal type the missions use (every trick type in `game/data/missions.json`, fixed missions and generator rules): a quantity goal has a `{done}/{total}` slot (the board's example: '2/4 Alt drifts'); a duration goal (the continuous drift, airtime seconds) has no count, only the amount (for example a `{seconds}` slot).
- The power-up overlay's header (opened when a mission completes; it offers driving power-ups, not weapons, and must read clearly differently from the Greenbull weapons gift screen) and its take-button label.
- The names Rev Charge, Jump, Bouncy Bumpers and Rusty Overcoat (the board's names; keep them unless the style loop finds a rule they break, then say so).
- One description per tier each power-up has in `game/data/power_ups.json` (or one template per power-up that names the tier's number). What each does: Rev Charge, hold W and S together to charge a boost that fires when S is released; Jump, Space makes a small hop; Bouncy Bumpers, a bigger bounce off walls and obstacles; Rusty Overcoat, the car damages enemies it touches. None uses the 'Greenbull says ...' form (these are not Greenbull's gifts).

Add a GUT test that every key the new UI reads is present and non-empty.

The board's review: read the notebook page's header, the goal phrasings, the overlay's header and button, and the power-ups' names and tier descriptions.

## Acceptance criteria

- [ ] screen_texts.json (or the named HUD text file) holds non-empty entries for: the notebook header, a goal template for every trick type in missions.json (quantity ones contain `{done}/{total}`, duration ones do not), the overlay header, the take-button label, and the four power-up names. (QA: pass / fail)
- [ ] Each power-up has one description per tier in power_ups.json, or one template naming the tier's number; none contains 'Greenbull says'. (QA: pass / fail)
- [ ] HUD and menus, Content lists every new text with where it appears. (QA: pass / fail)
- [ ] The ticket's Style review records the style loop rounds for the texts. (QA: pass / fail)
- [ ] A GUT test checks every new key is present and non-empty, and it passes; all three test sets pass, with the counts in the result notes. No screenshots: the result notes say there is nothing to picture. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Blocked → In progress

Goal runner (G-009): started, in C:\solid-carbide-worktrees\T-456.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
