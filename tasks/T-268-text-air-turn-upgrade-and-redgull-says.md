---
id: T-268
title: "Text: the air turn upgrade, and two level-up lines without \"Redgull says\""
status: in-progress
from: project-lead
to: narrative-theme
lead: Coursework
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/garage-design.md, docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/hud-and-menus.md, docs/extended-narrative.md, game/scripts/ui/level_up_texts.gd, tasks/T-223-text-magnet-upgrade.md]
files_expected_to_change: [docs/garage-design.md, docs/hud-and-menus.md, game/scripts/ui/level_up_texts.gd]
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

Two pieces of text (board, 2026-10-22):

1. **The air turn upgrade** (Garage design, Decisions, "Air turn upgrade"): its name and description in the garage, in the form of the other four (name up to 25 characters, description up to 80, naming no number, since the Game Data Agent proposes the levels), with the key `air_turn`, written into Garage design, Content, as T-223 did for the magnet, for T-270 to use word for word.
2. **No "Redgull says ..." lines** (HUD and menus, Decisions): rewrite the two level-up card descriptions that use that form, keeping what each says the tier does: `upgrade_flamethrower.tier6.desc` ("The flame area grows 30%. Redgull says think bigger.") and `upgrade_underglow.tier2.desc` ("Glow radius up 20%. Redgull says be seen."). Same length limits as the other card descriptions; no "Redgull says" form. Change them in `game/scripts/ui/level_up_texts.gd` (the text only) and wherever HUD and menus, Content lists them. Check no other player-facing text uses "Redgull says"; list any you find in the result notes without changing them.
3. **Brand Magnet too** (board, 2026-10-22, added after the ticket started): rewrite the magnet's garage description, `garage.pickup_magnet.desc` ("Pickups reach you from further per level. Redgull calls it engagement."), without the "Redgull calls it" quip, still saying what the upgrade does, within 80 characters; in Garage design, Content, and wherever the game reads it (find the garage's text source).

## Acceptance criteria

- [ ] Garage design, Content, has the air turn upgrade's name and description with this ticket's id, within 25 and 80 characters, naming no number (QA: pass / fail)
- [ ] The two level-up descriptions are rewritten without "Redgull says", still say what the tier does, and fit the cards' limits; no player-facing text says "Redgull says" (a search) (QA: pass / fail)
- [ ] The level-up text tests (`game/tools/check_level_up_texts.py` and the GUT text tests) pass (QA: pass / fail)

The board's review: read the new texts.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's request: the air turn upgrade's text, and the two Redgull says lines rewritten.

## Result notes

Written by the agent when it finishes.
