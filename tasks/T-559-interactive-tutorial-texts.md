---
id: T-559
title: Texts for the interactive tutorial slides
status: in-progress
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
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/extended-narrative.md, game/data/tutorial_text.json, game/data/mission_text.json]
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
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Write, through the style loop, the texts of HUD and menus, Decisions, "Interactive tutorial slides", into game/data/tutorial_text.json (or the data file the notebook reads its goals from), each with a key and a _comment saying where it appears: (1) slide 1, the loop: a title and the short words of the chain do tricks, gain subs, get weapons, repeat, with the point that by the 4-minute mark the player is strong enough to take on the kaiju; (2) for each trick slide (drift, alt drift, air spins, grind): a title and a one-line instruction with the keys, in the voice of today's trick list recipes; (3) the notebook goal line for each ("x/3" style, like the missions' goals); (4) the success message shown over the practice window after the third success (one, or one per slide); (5) any hint the grind slide needs about the Jump gift offered at its start. Reuse today's last slide texts. Mark texts of the old slides 1 to 3 that are no longer shown as unused in their _comment, deleting nothing. List every key in the result notes for T-562.

The board's review: play the tutorial in the combined build (playtest/interactive-tutorial): press Start from the main menu.

Part of the interactive tutorial (board, 2026-11-07; HUD and menus, Decisions, "Interactive tutorial slides" and "A trick falls into the notebook"; Level design, Decisions, "The practice playground"; tickets T-559 to T-563). The board plays all of it at the end in one combined build (branch playtest/interactive-tutorial), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --append <file>` (write the file with the Write tool) or `--text`, and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each text listed in the description exists with a key and a _comment, listed in the result notes with what it is for. (QA: pass / fail)
- [ ] Each text has a style loop score of 8 or more in the Style review, or is noted for the playtest. (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content lists the new texts. (QA: pass / fail)
- [ ] The tests for the changed data pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: texts for the loop slide, the four trick slides, their notebook goals and the success message.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "title: The content loop / step1: Do tricks / step2: Gain subs / step3: Unbox new weapons / step4: Repeat for content / point: By the 4-minute mark, you're strong enough to take on the kaiju. Huge for engagement."
- Script checks: 2 of 4 pass; failed: rule 4, label: one line ("title: The content loop\nstep1: Do tricks\nstep2: Gain subs\nstep3: Unbox new weapons\nstep4: Repeat for content\npoint: By the 4-minute mark, you're strong enough to take on the kaiju. Huge for engagement."); rule 4, label: sentence case (capitalised: ['The', 'Do', 'Gain', 'Unbox', 'Repeat', 'By', 'Huge'])
- Score: 8/10
- Reason: The text fits the brief and the voice. Rule 1: the satire is light and corporate ("Repeat for content", "Huge for engagement"), and it never mocks the city's people. Rule 2: no banned words, and "subs" is used correctly. Rule 3: no "Greenbull says" line. Length limits hold: the title is 3 words, steps 1 to 4 are 2 to 3 words each, and the point is one line saying the player can take on the kaiju by the 4-minute mark.

Rule 4 (labels: one line, sentence case) is the only failure, and it is marked failed in the script output. Both failures look like artefacts of checking the whole 6-line block as one label. Judged line by line, every line is in sentence case, because only its first word is capitalised ("The content loop", "Do tricks", "Gain subs", "Unbox new weapons", "Repeat for content"). The capitalised list the script reports is just those first words. Two things are still worth fixing:
- The point line is two sentences. "By the 4-minute mark, you're strong enough to take on the kaiju. Huge for engagement." is not one short plain line. Make it one sentence, for example "By minute 4 you can take on the kaiju", or fold the aside in without a second sentence.
- If the checker is meant to pass 6-line label blocks, it should split on lines before checking. If it is not, this output format will always fail the script.
- Rules broken: 4

**Kept:** version 1, score 8/10 ("title: The content loop / step1: Do tricks / step2: Gain subs / step3: Unbox new weapons / step4: Repeat for content / point: By the 4-minute mark, you're strong enough to take on the kaiju. Huge for engagement.", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/o1.txt`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "drift_title: Drift / altdrift_title: Alt drift / airspin_title: Air spins / grind_title: Grind style / drift: Hold W and a turn key, A or D, to drift. Let go to cash it in. / altdrift: Drift forward, then swap W for S while holding the same turn key. / airspin: Hit a ramp holding W, then hold A or D in the air: AIR 180! or AIR 360! both count. / grind: In the air, hold Space and touch a rail to grind it. Let go to launch the way you face."
- Script checks: 2 of 4 pass; failed: rule 4, label: one line ('drift_title: Drift\naltdrift_title: Alt drift\nairspin_title: Air spins\ngrind_title: Grind style\ndrift: Hold W and a turn key, A or D, to drift. Let go to cash it in.\naltdrift: Drift forward, then swap W for S while holding the same turn key.\nairspin: Hit a ramp holding W, then hold A or D in the air: AIR 180! or AIR 360! both count.\ngrind: In the air, hold Space and touch a rail to grind it. Let go to launch the way you face.'); rule 4, label: sentence case (capitalised: ['Drift', 'Alt', 'Air', 'Grind', 'Hold', 'W', 'A', 'D,', 'Let', 'Drift', 'W', 'S', 'Hit', 'W,', 'A', 'D', 'AIR', 'AIR', 'In', 'Space', 'Let'])
- Score: 9/10
- Reason: No Text rules are broken. The two failed script checks (rule 4, "one line" and "sentence case") are artifacts of scoring all eight labelled lines as one block, so I'm not counting them. The "one line" check fires because the text holds eight lines. The "sentence case" check fires on key letters (W, A, D, S, Space) and the popup name AIR 180!/AIR 360!, which the brief wants as written. Checked line by line: the titles are 3 words or fewer, with only the first word capitalised ("Drift", "Alt drift", "Air spins", "Grind style"). The longest instruction, grind at about 88 characters, is within the 90 limit. Rule 2 and rule 3 pass (the script's no-banned-words and no-"Greenbull says" checks are both ok). The wording reuses the existing trick_rule lines: altdrift and grind match alternate_drift and rail_grind almost word for word, with W and S named instead of "gas" and "brake". The lines are plain and instructional. That is fine for tutorial text, since rule 1's satire applies to Greenbull's voice and these slides are not Greenbull's. The one weak spot is that the lines have no wit. If a refine is wanted, a single dry aside could go on one slide, such as the drift cash-in, as long as the line stays within 90 characters.
- Rules broken: none
- Refused: {"tool_input": {"command": "python - <<'EOF'\nlines={\"drift_title\":\"Drift\",\"altdrift_title\":\"Alt drift\",\"airspin_title\":\"Air spins\",\"grind_title\":\"Grind style\",\n\"drift\":\"Hold W and a turn key, A or D, to drift. Let go to cash it in.\",\n\"altdrift\":\"Drift forward, then swap W for S while holding the same turn key.\",\n\"airspin\":\"Hit a ramp holding W, then hold A or D in the air: AIR 180! or AIR 360! both count.\",\n\"grind\":\"In the air, hold Space and touch a rail to grind it. Let go to launch the way you face.\"}\nfor k,v in lines.items(): print(k,len(v))\nEOF", "description": "Count characters of each text line"}, "tool_name": "Bash", "tool_use_id": "toolu_01KpNRiMtyqXbmrcPHdCxPAA"}

**Kept:** version 1, score 9/10 ("drift_title: Drift / altdrift_title: Alt drift / airspin_title: Air spins / grind_title: Grind style / drift: Hold W and a turn key, A or D, to drift. Let go to cash it in. / altdrift: Drift forward, then swap W for S while holding the same turn key. / airspin: Hit a ramp holding W, then hold A or D in the air: AIR 180! or AIR 360! both count. / grind: In the air, hold Space and touch a rail to grind it. Let go to launch the way you face.", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/o2.txt`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "goal_drift: Drifts {done}/{total} / goal_altdrift: Alt drifts {done}/{total} / goal_airspin: Air spins {done}/{total} / goal_grind: Rail grinds {done}/{total} / success: Content secured! / grind_hint: One power-up on the house: Jump. Take it, jump, then hold Space over a rail."
- Script checks: 2 of 4 pass; failed: rule 4, label: one line ('goal_drift: Drifts {done}/{total}\ngoal_altdrift: Alt drifts {done}/{total}\ngoal_airspin: Air spins {done}/{total}\ngoal_grind: Rail grinds {done}/{total}\nsuccess: Content secured!\ngrind_hint: One power-up on the house: Jump. Take it, jump, then hold Space over a rail.'); rule 4, label: sentence case (capitalised: ['Drifts', 'Alt', 'Air', 'Rail', 'Content', 'One', 'Jump.', 'Take', 'Space'])
- Score: 9/10
- Reason: The two failed rule 4 checks come from how the script reads this batch, not from the text. It treats the six labelled lines as one label, so "one line" fails. It also flags the first word of each line and the key and item names "Jump" and "Space" as capitalised. Each line is a single line, and the capitals are sentence-initial or proper names, which sentence case allows.

Each line meets the brief:
- The four goal lines keep {done}/{total} exactly and use at most 3 words plus the counter, mirroring "Alt drifts {done}/{total}".
- "Content secured!" is 2 words plus "!", in the satirical-stream voice.
- grind_hint is about 76 characters, under the 80 limit. It names the one power-up gift, Jump, and gives the order: take it, jump, hold Space over a rail.
- There is no "Greenbull says" and no banned words.

The only small point is that "One power-up on the house" is a mild flourish. It fits the tone, so no fix is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("goal_drift: Drifts {done}/{total} / goal_altdrift: Alt drifts {done}/{total} / goal_airspin: Air spins {done}/{total} / goal_grind: Rail grinds {done}/{total} / success: Content secured! / grind_hint: One power-up on the house: Jump. Take it, jump, then hold Space over a rail.", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/o3.txt`): it reached 8 or more.

## Result notes

Texts written through the style loop (3 runs, one per group, each kept at round 1: scores 8, 9, 9; the script checks for "one line" and "sentence case" flagged only because each run holds several labelled lines, the evaluator passed them). All in game/data/tutorial_text.json, block `tutorial` (each entry has a `_comment`), documented in docs/hud-and-menus.md ("The interactive tutorial's texts (T-559)"). Slides 1 to 3 keys (slide1.*, slide2.*, slide3.*, kicker.controls/loop/missions) marked UNUSED in their comments, nothing deleted. Last slide's keys reused as they are. game/tools/text_inventory.py got the entry "tutorial_text:tutorial".

Keys for T-562 (text, then where):
- tutorial.loop.title "The content loop": loop slide headline
- tutorial.loop.step1 "Do tricks", step2 "Gain subs", step3 "Unbox new weapons", step4 "Repeat for content": chain labels
- tutorial.loop.point "By the 4-minute mark, you're strong enough to take on the kaiju. Huge for engagement.": closing line
- tutorial.trick.drift.title "Drift" / .instruction "Hold W and a turn key, A or D, to drift. Let go to cash it in."
- tutorial.trick.altdrift.title "Alt drift" / .instruction "Drift forward, then swap W for S while holding the same turn key."
- tutorial.trick.airspin.title "Air spins" / .instruction "Hit a ramp holding W, then hold A or D in the air: AIR 180! or AIR 360! both count."
- tutorial.trick.grind.title "Grind style" / .instruction "In the air, hold Space and touch a rail to grind it. Let go to launch the way you face."
- tutorial.goal.drift "Drifts {done}/{total}", .altdrift "Alt drifts {done}/{total}", .airspin "Air spins {done}/{total}", .grind "Rail grinds {done}/{total}": notebook goal lines
- tutorial.success "Content secured!": one message, all slides, over the practice window after the third success
- tutorial.grind_hint "One power-up on the house: Jump. Take it, jump, then hold Space over a rail."
Reused: trick.* names, trick_rule.*, slide4.title/kaiju, kicker.goal, kicker.pattern, button.start/skip, checkbox.dont_show, arrow.*.

Tests: game/tools/test_text_inventory.py + test_style_rules.py 35 passed; GUT test_tutorial_slides all passed (306 asserts), test_trick_list 18/18. Full GUT run left to QA/merge.
