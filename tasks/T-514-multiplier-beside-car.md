---
id: T-514
title: The combo multiplier beside the car, viewers counter gone
status: in-progress
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [docs/hud-and-menus.md, docs/game-loop-architecture.md, game/scripts/hud/hud.gd, tasks/README.md]
files_expected_to_change: [game/scripts/hud/, game/scripts/menu/, game/data/, game/tests/unit/, docs/hud-and-menus.md]
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

Remove the live viewers counter (T-336) from the HUD and show the combo as its multiplier number beside the car, following it on screen (docs/hud-and-menus.md, Decisions, "The multiplier beside the car"), using T-512's texts. Trick popups show the multiplier they added, flying into the multiplier by the car, which bumps on arrival. The subs a trick pays (T-513, built in parallel; take its signal once it lands, or read the XP change) visibly go into the sub goal. Re-point what used the viewers: the reactions' heat steps and the fire look become multiplier steps (ComboHeat thresholds), the bad reactions rise from the multiplier (or a place you propose), a crash shows on the multiplier, the recap shows the peak multiplier (peak_viewers becomes or sits beside a peak multiplier; keep old saves loading), and the tutorial slide 2 panel with the eye icon shows the multiplier. Remove the viewers code you replace (ViewersData, viewers.json) only if nothing else reads it; say what you removed. Proposals for the playtest: the multiplier's place relative to the car, size, colour and heat look. Update docs/hud-and-menus.md Content (the counter, popups, reactions, recap, tutorial) and the HUD layout notes. When T-513 is done, merge its branch into yours so the board plays one build (the Project Lead may do this step with the QA agent).

The board, 2026-11-02: the live viewers are confusing; back to the combo multiplier number, shown beside the car; tricks also pay subs. Decisions: docs/game-loop-architecture.md, "Back to the combo multiplier; tricks pay subs", and docs/hud-and-menus.md, "The multiplier beside the car". The board plays T-512..T-514 together in one playtest build before anything merges. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The HUD has no live viewers counter; the multiplier shows beside the car and follows it as it drives (test and screenshot). (QA: pass / fail)
- [ ] A trick popup shows its multiplier add with T-512's text, and the multiplier bumps when it arrives (test). (QA: pass / fail)
- [ ] The reactions, bad reactions, recap peak and tutorial slide 2 work from the multiplier, and an old save with peak_viewers still loads (tests). (QA: pass / fail)
- [ ] Every text shown comes from T-512's keys, none hard-coded (test or grep in the result notes). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content no longer describes a viewers counter as current. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] Screenshots of a run with the multiplier by the car, a trick popup, the recap and tutorial slide 2, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started on top of T-512's texts (T-512 is in QA).

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
