---
id: T-426
title: Text: the HUD size slider's label
status: in-qa
from: project-lead
to: narrative-theme
lead: Goal-G-008
epic: narrative
milestone: mvp
goal: G-008
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/pause-screen.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, game/docs/hud-and-menus/pause-screen.md, game/scripts/ui/pause_screen.gd]
files_expected_to_change: [game/data/pause_text.json, docs/hud-and-menus.md, game/docs/hud-and-menus/pause-screen.md]
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

The board's goal G-008 adds a HUD size slider to the pause screen (HUD and menus, Decisions, 'The HUD scales with the window, and a HUD size slider'). Write its label, and how its value reads if the slider shows one, through the style loop (kind label). It sits on the pause strip next to the other slider labels, 'Camera zoom level' and 'Music volume', and must have the same form (a short noun phrase, sentence case, no punctuation). Today the pause screen's texts are constants in game/scripts/ui/pause_screen.gd; put the new label in a new data file game/data/pause_text.json (key hud_size_label, plus hud_size_value if a value reads), which the UI ticket for the slider will make the pause screen read. Also write the text into HUD and menus, Content, 'Pause screen', and game/docs/hud-and-menus/pause-screen.md. Write no other text.

The board's review: Read the HUD size slider's label in game/data/pause_text.json; you meet it in the pause screen once the slider's ticket is in.

## Acceptance criteria

- [ ] game/data/pause_text.json exists, is valid JSON and holds the HUD size slider's label (and its value format, if any); the file is named in the result notes. (QA: pass)
- [ ] The same text is in docs/hud-and-menus.md, Content, 'Pause screen', and in game/docs/hud-and-menus/pause-screen.md. (QA: pass)
- [ ] Each new line scored at least 8 in the style loop (or is noted below 8 after 3 refines in a goal run), with every round in the ticket's Style review. (QA: pass)
- [ ] The label follows Extended narrative's Text rules and has the same form as 'Camera zoom level' and 'Music volume' (short noun phrase, sentence case, no end punctuation). (QA: pass)
- [ ] python -m unittest discover -s game/tools -p "test_*.py" passes, with the count in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Goal runner (G-008): started, in C:\solid-carbide-worktrees\T-426.

### 2026-10-30, In progress → In QA

Goal runner (G-008): the agent is done; QA is checking it.

## Style review

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind label, brief `art-archive/T-426/brief.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "HUD size"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "HUD size" follows rule 4 for menu and settings labels. It is short, plain and in sentence case ("HUD" is the board's own word, so the capitals are fine). It has no end punctuation and no story flavour, so rule 1 doesn't apply to it. It uses no banned or old vocabulary (rule 2) and has no "Greenbull says" line or brand (rule 3). It reads as a sibling of "Camera zoom level", "Music volume" and "SFX volume". It is one point short of 10 because "size" names the control but not the thing it sizes. That is fine for a label on the pause strip, so no fix is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("HUD size", copied to `art-archive/T-426/label.txt`): it reached 8 or more.

## Result notes

Label: "HUD size", scored 9/10 in round 1 of the style loop (see Style review; brief in art-archive/T-426/brief.md, kept text in art-archive/T-426/label.txt). Same form as "Camera zoom level" and "Music volume".

- File: `game/data/pause_text.json` (valid JSON, key `hud_size_label`). No `hud_size_value`: the slider's value reads as a bare number at the right end like the other sliders, so no value text exists.
- Docs: docs/hud-and-menus.md (Content, Pause screen, "HUD size slider" entry) and game/docs/hud-and-menus/pause-screen.md.
- Tests: `python -m unittest discover -s game/tools -p "test_*.py"`: 736 tests, OK (1 skipped).
- Screenshots: none, text-only work (nothing on screen until the slider's UI ticket).
- PixelLab generations: 0. Refusals: none.

QA round 1: all 5 criteria pass. JSON valid with hud_size_label "HUD size"; text present in both docs; style loop 9/10 round 1 recorded; form matches siblings; unittest 736 OK (1 skipped), re-run by QA. No screenshots needed (text only). `python tools/qa_check.py` was refused (not pre-approved), so checks were done by hand.
