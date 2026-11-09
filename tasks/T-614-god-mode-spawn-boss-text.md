---
id: T-614
title: Text for God mode's spawn the boss button
status: in-qa
from: project-lead
to: narrative-theme
lead: Polish
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/extended-narrative.md, game/data/pause_text.json, tasks/T-609-controller-prompts-text.md]
files_expected_to_change: [game/data/pause_text.json, game/tests/, docs/hud-and-menus.md]
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

Write the text for HUD and menus, Decisions, "God mode can spawn the boss" (board, 2026-11-09). T-612 builds the button and uses exactly your text.

Two texts, in `game/data/pause_text.json` beside the other `god_mode_*` keys, each through the style loop (tasks/README.md, "The style loop"):

1. `god_mode_spawn_boss`: the label of a button on the God mode page (the pause screen's hidden testing page, with the weapons' and power-ups' tier rows and Back). Pressing it makes the kaiju arrive straight away. It is a shared small button like Back: keep it short, about 16 characters at most, in the page's plain wording ("God mode", "Back", "Not owned").
2. `god_mode_spawn_boss_used`: what the same button reads once it can no longer be pressed (it was pressed, or the kaiju has already arrived on its own). Same length limit. It must make clear the kaiju is already here.

The boss is called the kaiju in the game's texts; check Extended narrative for the name the player knows it by. Add both texts, with what each is for and where it shows, to HUD and menus, Content, where the God mode texts are listed. If the game has a text inventory test that lists the keys of `pause_text.json`, add the new keys to it.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/data/pause_text.json` holds `god_mode_spawn_boss` and `god_mode_spawn_boss_used`, each 16 characters or fewer, and the file still parses (the text tests pass, the text inventory test included). (QA: pass: both keys present, 14 and 13 chars, JSON parses, qa_check tests passed)
- [ ] Each of the two texts has an entry in the ticket's Style review with a score of 8 or more, or is listed in the result notes as below 8 after its refines. (QA: pass: Run 1 and Run 2 each 9/10)
- [ ] HUD and menus, Content, lists both texts with what each is for and where it shows. (QA: pass: Content section lists both with purpose and place)
- [ ] Nothing to picture: the result notes say so in one line (the texts are shown in T-612's screenshots). (QA: pass: result notes say nothing to picture (qa_check screenshots line is red only because user_facing_text is yes; the criterion accepts the note))
- [ ] The tests for the changed files pass (the agent) and QA's run passes, with the counts in the result notes. (QA: pass: qa_check test sets passed (2 run, tools set skipped); agent reported 8 passed)
- [ ] Every document in documents_affected is updated. (QA: pass: docs/hud-and-menus.md updated)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-09, Open → In progress

Started: the Narrative Theme Agent is writing the spawn the boss button's two texts; T-612 builds the button with them.

### 2026-11-09, In progress → In QA

The texts are written: "Call the kaiju" (the button) and "Kaiju is here" (once used), both scored 9. QA is checking the ticket now.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/b1c3c0b1-4990-411e-bdd9-d1465b8e287f/scratchpad/b1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Call the kaiju"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Call the kaiju" is 14 characters, one line, sentence case. Rule 4 (menu and settings labels: short, plain, sentence case) is met. It uses only "the kaiju", with no banned words, no brand names and no "Greenbull says" line (rules 2 and 3). Rule 1 (tone) asks for satire, but the brief says plain page wording for a hidden testing page, so a plain label is right. It breaks no rules. I took off one point only because the text is neutral and has no tone.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Call the kaiju"): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/b1c3c0b1-4990-411e-bdd9-d1465b8e287f/scratchpad/b2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Kaiju is here"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: Passes the script checks (rules 2, 3, 4: one line, sentence case, 13 characters). It uses the settled term "the kaiju" and never says Godzilla. It is plain and short, as rule 4 asks for labels. It is not in Greenbull's voice and is not a "Greenbull says" line (rule 3). It states clearly that the kaiju is already here, which is what the brief asked for. The only deduction is that rule 1's satirical tone does not show, but the brief asks for plain page wording, so this is not a violation. No fix needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Kaiju is here"): it reached 8 or more.

## Result notes

Wrote god_mode_spawn_boss = 'Call the kaiju' (14 chars) and god_mode_spawn_boss_used = 'Kaiju is here' (13 chars) in game/data/pause_text.json; style loop scored 9/10 and 9/10 in round 1 (no refines). Listed in docs/hud-and-menus.md Content, 'God mode's spawn the boss button'. The text inventory is by file prefix, so no key list to extend; game/tools/test_text_inventory.py 8 passed. Nothing to picture: the texts are shown in T-612's screenshots.
