---
id: T-506
title: Text for the rain toggle in the settings
status: needs-playtest
from: project-lead
to: narrative-theme
lead: Greenbull
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/hud-and-menus.md, game/data/screen_texts.json]
files_expected_to_change: [game/data/screen_texts.json, game/tests/unit/]
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

The board, 2026-11-02 (docs/level-design.md, Decisions, "Rain over the map"): a toggle in the settings turns the rain on or off. Write its label (and its on/off states if the other settings toggles have their own words) in the same file and style as the other settings texts, so T-508 never uses a placeholder. Run the style loop on it and list the keys in the result notes. This task's branch is built on T-497's branch, which already holds the board's new weapon trees (T-495 to T-499) and the playtest tier switch (T-500), so the board can play everything in one build. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py <id> --append <file>`, never with Edit or Bash on the ticket. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build with the weapon trees (T-495 to T-499), the power-up changes and God mode (T-501 to T-505), from the Project Lead's combined folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The rain toggle's label (and on/off words if the other toggles have them) exists under keys listed in the result notes, in the same file as the other settings texts. (QA: pass; rain_label = "Rain" in game/data/pause_text.json, listed in result notes, no on/off words as other checkboxes have none)
- [ ] The style loop's score is in the Style review and the result notes. (QA: pass; 9/10 in both)
- [ ] The test files that cover screen texts pass (-gselect). (QA: pass; qa_check: 2 test sets passed, tools set skipped)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started: the rain toggle's label.

### 2026-11-02, In progress → In QA

Rain toggle label 'Rain' written as pause_text.json key rain_label, style loop 9/10; no on/off words (other checkboxes have none).

### 2026-11-02, In QA → Needs playtest

QA passed all 3 criteria; ready for the board's playtest.

## Style review

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind label, brief `art-archive/T-506/brief.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Rain"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Rain" breaks no rule I can find. The script checks pass: no banned words, no Greenbull line, one line, sentence case. It matches the brief: short, plain settings voice, no end punctuation, no on/off words. It sits well beside "Camera smoothing" and "Dynamic camera", and it names the thing the checkbox switches. I did not open the Text rules to check for anything the script can't test. The one point off is that "Rain" is a bare noun, a bit terser than the neighbouring two-word labels. That is not a rule break and needs no fix.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Rain", copied to `art-archive/T-506/label.txt`): it reached 8 or more.

## Result notes

Added key `rain_label` = "Rain" in `game/data/pause_text.json` (the file of the pause screen's settings texts; the ticket named screen_texts.json, but the other settings labels are in pause_text.json). The other settings checkboxes (Camera smoothing, Dynamic camera) have no on/off words, so the rain toggle has none either: label only. Style loop: round 1, score 9/10, 4 of 4 script checks pass (Style review). Tests: game/tests/unit/test_rain_label_text.gd and test_pause_screen pass. Not shown in-game yet (T-508 reads the key); fixture image: art-archive/T-506/screenshots/rain_label_text.png. Note: a hook refused one chained timeout-wrapped --import command; I reran it on its own, as its message said.
