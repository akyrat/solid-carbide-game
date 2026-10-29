---
id: T-316
title: "Text: the time's up failure screen"
status: in-progress
from: project-lead
to: narrative-theme
lead: Greenbull
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, docs/extended-narrative.md]
files_expected_to_change: [game/data/, docs/hud-and-menus.md, art-archive/T-316/]
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

The board's decision (Game loop architecture, Decisions, "Time's up screen", 2026-10-28): when the 8-minute timer runs out and the kaiju has survived it (a loss), a 3-second animated failure screen plays before the run ends. T-317 builds it and waits for this text.

Write the screen's text: a short headline in the trick popups' style (capitals, ending in "!"; Extended narrative, Content, "Text rules"), for example about the stream's time running out while the kaiju is still standing, and at most one short second line if it helps, in Greenbull's out-of-touch voice where it fits (never "Greenbull says ..."). It is on screen for 3 seconds, so it must read at a glance. Every line goes through the style loop. Put the approved text where T-317 will read it (with the game's other screen texts; say where in the result notes) and in HUD and menus, Content, under a new "Time's up screen" heading.

The board's review: read the time's up text in HUD and menus, Content.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The headline (and any second line) are in a data file the game reads, named in the result notes, and in HUD and menus, Content, "Time's up screen". (QA: pass / fail)
- [ ] Each line scored at least 8 in the style loop, with every round in the Style review. (QA: pass / fail)
- [ ] The headline follows Text rules: capitals, ends in "!", no banned word. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started overnight (build B, End of a run): the Narrative Theme Agent is writing the time's up screen's text.

## Style review

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind popup, brief `art-archive/T-316/brief.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "STREAM OVER, KAIJU STILL TRENDING!"
- Script checks: 5 of 5 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4: one line, capitals, ends in "!" (script facts). Rule 2: it says "stream" and "kaiju" and uses no banned words. Rule 3: Greenbull is not quoted. Rule 1: "KAIJU STILL TRENDING" is a satirical social-media aside, and it turns the failure into engagement-bait without joking about the city's people or their fear. It fits the brief: the stream's time is over and the kaiju is still standing. The one small point is length. At 34 characters it is longer than LONG DRIFT! or COMBO BROKEN!, so it is a bit less instant at a glance. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("STREAM OVER, KAIJU STILL TRENDING!", copied to `art-archive/T-316/headline.txt`): it reached 8 or more.

## Result notes

Headline (no second line, so it reads in 3 seconds): **STREAM OVER, KAIJU STILL TRENDING!** Style loop: round 1, score 9/10, 5 of 5 script checks pass (see Style review).
- Data file: `game/data/screen_texts.json`, key `time_up.headline` (T-317 reads it there).
- Docs: `docs/hud-and-menus.md`, Content, "Time's up screen".
- Brief: `art-archive/T-316/brief.md`.
- Tests: the ticket has no test criterion and changes no code, so the three test sets were not run (the JSON loads).
