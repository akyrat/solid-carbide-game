---
id: T-602
title: Text: the Polarized Steering Wheel's new descriptions
status: in-progress
from: project-lead
to: narrative-theme
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/hud-and-menus.md, game/data/power_ups.json]
files_expected_to_change: [game/data/, docs/hud-and-menus.md]
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

Drifting, Decisions, "The Polarized Steering Wheel bursts after an alternate drift" changes how the wheel triggers, so its two card descriptions (HUD and menus, Content, "Power-up descriptions": tier 1 "(while coasting) Steer, then Accelerate: +{burst_percent}% speed burst.", tier 2 "+{burst_percent}% speed, shock hits and shoves minions.") must say the new trigger. Rewrite them in the same voice and length as the other power-up descriptions, keeping the {burst_percent} slot (it will read 10 and 22.5 from the data; say in the result notes how 22.5 shows, and whether the data should round it). The tier 1 text names the trigger, the alternate drift, with the trick name the player sees (ALT DRIFT!), and the burst; the tier 2 text keeps the shock. Check whether any other player-facing text describes the old lift-steer-gas trigger (the tutorial's missions slide, the tutorial demos, the garage) and rewrite it too. Go through the style loop. List every text with its key and where it shows in the result notes and in hud-and-menus.md Content.

The board's review: in T-603's build.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The tier 1 and tier 2 descriptions name the new trigger and keep {burst_percent}, with their keys and where they show listed in the result notes. (QA: pass / fail)
- [ ] Every other text that described the old trigger is found and rewritten, or the result notes say there is none and where it was checked. (QA: pass / fail)
- [ ] The style loop's scores are in the Style review. (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content lists the new texts. (QA: pass / fail)
- [ ] QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: the wheel's two descriptions for the new trigger, through the style loop.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Pull an ALT DRIFT: +{burst_percent}% speed burst."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rules broken. Rules 2, 3 and 4 pass by script (no banned words, no "Greenbull says", 49 of 90 characters). It says first what the card does and names the trigger exactly as the popup does (ALT DRIFT). It keeps the {burst_percent} slot. It is plain and short like the other power-up descriptions. Rule 1 allows at most one satirical aside and the brief asked for none, so the missing aside is fine. The only small nit is that "Pull an ALT DRIFT" is a slightly unusual verb, but it is clear and needs no fix.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Pull an ALT DRIFT: +{burst_percent}% speed burst.", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/o1.txt`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "+{burst_percent}% burst after each ALT DRIFT!, and a shock shoves minions. Brand safety."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is broken. The script checks pass (88 characters, no banned words, no "Greenbull says"). The text states what the card does first (burst after each ALT DRIFT!, shock shoves minions) and then adds one short aside, as rule 4 asks. The deadpan corporate aside "Brand safety." fits the tone of rule 1. It uses no real brand, and the slot {burst_percent} is kept. Two small things the author could polish: "% burst" doesn't say what is bursting (the brief says speed), and the aside doesn't tie closely to the effect. Something like "+{burst_percent}% speed burst after each ALT DRIFT!, and a shock shoves minions. Brand safety." would be clearer, but it would pass 90 characters only if trimmed elsewhere.
- Rules broken: none

**Kept:** version 1, score 8/10 ("+{burst_percent}% burst after each ALT DRIFT!, and a shock shoves minions. Brand safety.", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/o2.txt`): it reached 8 or more.

## Result notes

Texts (game/data/screen_texts.json): tier 1 power_ups.descriptions.polarized_steering_wheel = 'Pull an ALT DRIFT: +{burst_percent}% speed burst.' (style 9); tier 2 power_ups.descriptions_last_tier.polarized_steering_wheel = '+{burst_percent}% burst after each ALT DRIFT!, and a shock shoves minions. Brand safety.' (style 8). Both show on the Polarized Steering Wheel's gift/level-up card (tier 1 when offered, tier 2 as the next-tier offer). 22.5: power_up_screen.gd rounds with roundi, so tier 2 reads 23% (tier 1 reads 10%); recommend leaving the data as is (a 23% label for a 22.5% burst is fine), or set 1.225 -> 1.23 in T-603 if exact wanted. In this branch the data is still 1.2/1.45 (20/45) until T-603 halves it. Other texts: checked tutorial_text.json, screen_texts.json, garage.json, missions.json, recap_text.json; no other text describes the lift-steer-gas trigger (only the tutorial's generic 'Gas' labels and the alt drift slide, which describe the trick, not the wheel). Test updated: game/tests/unit/test_power_up_screen.gd now expects the new texts with the percent read from data. docs/hud-and-menus.md Content updated. Tests: Godot 3250 run, 3249 pass, 0 fail, 1 risky (pre-existing); Python tools 643 OK, game/tools 1193 OK (4 skipped).
