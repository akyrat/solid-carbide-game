---
id: T-570
title: Texts: the main menu's Settings button and the Settings screen
status: needs-playtest
from: project-lead
to: narrative-theme
lead: Rails
epic: ui
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/data/pause_text.json, game/scripts/menu/main_menu.gd]
files_expected_to_change: [game/data/, docs/hud-and-menus.md]
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

Write the texts for HUD and menus, Decisions, "A Settings screen from the main menu", through the style loop: (1) the main menu button that opens it (for example "Settings"), in the voice of the other main menu buttons; (2) the screen's title, if it needs one; (3) its Back button, if the existing Back text does not fit. The settings' own labels are reused from game/data/pause_text.json as they are. Keys and _comment in the file the main menu already reads, or in pause_text.json; list them in the result notes for T-571.

The board's review: in T-571's build, open Settings from the main menu.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. No PixelLab calls. Never run a real itch.io push (butler push) and never print .env values. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each text exists with a key and a _comment, listed in the result notes. (QA: pass)
- [ ] Each scores 8 or more in the style loop, or is noted for the playtest. (QA: pass)
- [ ] docs/hud-and-menus.md Content lists them. (QA: pass)
- [ ] The tests for the changed data pass and QA's full run passes, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: Narrative Theme writes the Settings texts.

### 2026-11-07, In progress → In QA

Texts written: Settings button, title and Back. QA now.

### 2026-11-07, In QA → Needs playtest

QA passed (4/4). You'll see the texts in T-571's Settings screen.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Settings"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Settings" is one plain word in sentence case on a single line. It matches the brief and the voice of the sibling buttons (Start, Garage, Cosmetics, Exit). The script checks pass: no banned words, no "Greenbull says" line, one line, sentence case. It has no in-world flourish, but the brief asks for a plain button, so nothing needs fixing. I did not re-read the full Text rules, so I judged only against the brief and the script results.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Settings", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/o1.txt`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Settings"
- Script checks: 4 of 4 pass
- Score: 10/10
- Reason: "Settings" matches the brief exactly: one plain word in sentence case, the suggested title. All script checks pass (no banned words, no "Greenbull says" line, one line, sentence case). It has no punctuation, no jargon and no off-story content, and I found no text rule it breaks. A plain label like this is what the rules ask for.
- Rules broken: none

**Kept:** version 1, score 10/10 ("Settings", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/o2.txt`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Back"
- Script checks: 4 of 4 pass
- Score: 10/10
- Reason: "Back" matches the brief exactly. It is one plain word on one line, in sentence case. The script checks for rules 2 and 4 all pass. It has no banned words and no "Greenbull says" line. As a plain navigation label it carries no in-world voice and makes no claim that could break a narrative rule. I found nothing to fix.
- Rules broken: none

**Kept:** version 1, score 10/10 ("Back", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/o3.txt`): it reached 8 or more.

## Result notes

Added to game/data/pause_text.json (with _comment): settings_button 'Settings' (9), settings_title 'Settings' (10), settings_back 'Back' (10; same word as god_mode_back, own key). Settings labels reused from pause_text.json as-is. T-571 reads these 3 keys. docs/hud-and-menus.md Content: 'Texts for the Settings screen (T-570)'; long GDD regenerated. Tests: new game/tests/unit/test_settings_screen_text.gd 1/1 passed (2 asserts group), test_hud_size_slider 8/8, test_drift_guide_label_text passed, tools/test_generate_long_gdd.py 13 passed. Style review rounds recorded.

Screenshots (art-archive/T-570/screenshots/): main_menu_settings_button.png (Settings button before Exit in the real main menu) and settings_title_and_back.png (title and Back in the menu's styles), made by the fixture game/tools/shots/settings_texts_shots.tscn.
