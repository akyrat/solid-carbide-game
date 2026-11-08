---
id: T-598
title: Text: the trick popups setting's label
status: done
from: project-lead
to: narrative-theme
lead: Rails
epic: hud
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/data/pause_text.json]
files_expected_to_change: [game/data/pause_text.json, docs/hud-and-menus.md]
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

Write the label for HUD and menus, Decisions, "A setting to turn off the trick popups": one checkbox label in the settings, in the voice and length of the other settings checkboxes (look at the pause screen's settings texts, e.g. the Drift Guide and jump arrow checkboxes, wherever they live). Suggested starting point: "Trick popups". Put it next to the other settings labels with a _comment saying where it shows (both the pause screen's settings and the main menu's Settings screen), list it in the result notes for T-599 and in hud-and-menus.md Content. Make sure the key is one the main menu's Settings screen can read too (check how T-571 shares labels).

The board's review: in T-599's build.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The label exists with a key and _comment next to the other settings labels, listed in the result notes with where it shows. (QA: pass)
- [ ] docs/hud-and-menus.md Content lists it. (QA: pass)
- [ ] QA's full run passes, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: the label for the trick popups setting.

### 2026-11-08, In progress → In QA

Label: Trick popups. You'll see it in T-599's build.

### 2026-11-08, In QA → Needs playtest

QA passed all 3 criteria. The label shows in T-599's build (playtest-b).

## Style review

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/brief.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Trick popups"
- Script checks: 4 of 4 pass
- Score: 10/10
- Reason: "Trick popups" is a short, plain, sentence-case noun phrase on one line, matching the settings label format in rule 4 and the sibling labels ("Drift Guide", "Rain"). It has no on/off words and no banned words. It uses no Greenbull voice, so rules 2 and 3 hold. No real brands. Rule 1 (tone) doesn't call for satire in a bare settings label. All script checks pass. Nothing to fix.
- Rules broken: none

**Kept:** version 1, score 10/10 ("Trick popups"): it reached 8 or more.

## Result notes

Narrative Theme, 2026-11-08. Key trick_popups_label = "Trick popups" in game/data/pause_text.json (after jump_arrow_label, _comment extended). Style loop: 1 round, 10/10. Shows in the pause screen settings and the main menu Settings screen (both reuse the pause labels). Listed in docs/hud-and-menus.md Content (Trick popups checkbox). For T-599: read trick_popups_label. Tests: GUT 285 scripts, 3251 tests, 3250 pass, 0 fail, 1 risky; game/tools pytest 1232 passed, 4 skipped.
- 2026-11-08, needs-playtest → done: The board played it in playtest-b: lgtm (2026-11-08).
