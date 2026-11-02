---
id: T-516
title: Drift Guide checkbox label
status: in-qa
from: project-lead
to: narrative-theme
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [docs/hud-and-menus.md, tasks/T-506-rain-toggle-text.md, tasks/README.md]
files_expected_to_change: [game/data/pause_text.json, game/tools/text_inventory.py, game/tests/, docs/hud-and-menus.md]
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

Write the pause screen's checkbox label for the Drift Guide, in pause_text.json next to rain_label (key drift_guide_label). The board named it "Drift Guide": use exactly that text unless the style loop finds a real problem (then say so, keep the board's words as the value). List it in docs/hud-and-menus.md Content with where it appears.

The board, 2026-11-02: docs/drifting.md, Decisions, "The Drift Guide", and docs/hud-and-menus.md, Decisions, "A Drift Guide checkbox". The board plays T-516..T-518 together in one playtest build before anything merges or reaches itch.io. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build (T-516, T-517, T-518) from the Project Lead's combined folder (C:\solid-carbide-worktrees\T-518\game\project.godot), before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] pause_text.json has drift_guide_label with the value "Drift Guide" (test). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content lists it with where it appears. (QA: pass / fail)
- [ ] The text inventory and the tests that read pause_text.json pass (the agent runs the ones it touched). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started: the Drift Guide label.

### 2026-11-02, In progress → In QA

Drift Guide label added to pause_text.json (the board's words, style 8/10), documented, test passes.

## Style review

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind label, brief `art-archive/T-516/brief.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Drift Guide"
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['Guide'])
- Score: 8/10
- Reason: "Drift Guide" meets every text rule I can judge. It is one short line with no end punctuation and no on/off words, and none of the banned words or a "Greenbull says" line appear. Its plain settings voice fits "Rain", "Camera smoothing" and "Dynamic camera". The only failed script check is rule 4 sentence case, because of the capital G. I don't count that as a real break. "Drift Guide" is the board's own name for a named feature, and docs/hud-and-menus.md (lines 73 and 197) fixes it as the exact label. The brief says to keep the board's words unless there is a real rule break. Lowercasing it to "Drift guide" would change the board's name, so I would not do that. The one point off is for the script's failed sentence-case check. If the board wants strict sentence case like "Dynamic camera", that is a board decision.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Drift Guide"): it reached 8 or more.

## Result notes

Added drift_guide_label = "Drift Guide" (the board's words) to game/data/pause_text.json; the text inventory reads pause_text.json by key, so it lists it with no code change. Style loop: round 1, score 8/10; the script flagged rule 4 sentence case (capital G), kept because they are the board's own words and a proper feature name. Docs: hud-and-menus.md Content entry (appears only on the pause screen, after Rain, built in T-518). Test: game/tests/unit/test_drift_guide_label_text.gd, 1 test passing. Brief: art-archive/T-516/brief.md.
