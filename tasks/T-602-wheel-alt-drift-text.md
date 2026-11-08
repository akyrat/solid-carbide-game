---
id: T-602
title: Text: the Polarized Steering Wheel's new descriptions
status: open
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

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
