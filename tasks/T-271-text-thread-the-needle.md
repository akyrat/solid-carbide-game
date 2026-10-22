---
id: T-271
title: "Text: the thread the needle trick's popup and its creator labels"
status: in-qa
from: project-lead
to: narrative-theme
lead: Coursework
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/hud-and-menus.md, docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/level-design.md, game/data/level/creator_texts.json, tasks/T-241-text-airtime-trick-popup.md]
files_expected_to_change: [docs/hud-and-menus.md, docs/level-design.md, game/data/level/creator_texts.json]
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

The board's decision (Level design, Decisions, "Thread the needle", 2026-10-22): driving between two obstacles the board marked as a pair in the level creator is a trick the board named **thread the needle**. Write:

1. **Its popup** in the trick popups' voice (LONG DRIFT!, HANG TIME!, AIR 360!; HUD and menus, Content), keeping the board's name (for example THREAD THE NEEDLE!), followed by "+{amount}" like the others; into HUD and menus, Content, with this ticket's id, for T-272 to use word for word.
2. **The creator's labels**, plain like T-261's, into `game/data/level/creator_texts.json` (keep every existing key unchanged) and Level design, Content, "Level creator text": the tool or key hint for marking a pair (for example "Pair: click two obstacles", with its key), the top bar message once a pair is made and when a pick isn't an obstacle, and "Unpair" for removing a pair. Built on the level creator's build: the Project Lead makes your folder from `playtest/creator-set`.

## Acceptance criteria

- [ ] HUD and menus, Content, has the popup text with this ticket's id, keeping the board's name, in the trick popups' voice with "+{amount}" (QA: pass; hud-and-menus.md Content has THREAD THE NEEDLE! with T-271 and "+{amount}", same voice as the others)
- [ ] `creator_texts.json` is valid JSON with the pair labels (each with a "where it appears" note), every existing key unchanged, and they are listed in Level design, Content (QA: pass; JSON valid, 6 new keys each with a where note, no T-261 key changed, labels listed in level-design.md Content)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's request: the thread the needle popup and its creator labels.

### 2026-10-22, In progress → In QA

Text written: THREAD THE NEEDLE! and the pairing labels (P to pair). Sent to QA.

## Result notes

Written by the agent when it finishes.

- Popup: **THREAD THE NEEDLE!** followed by "+{amount}", in HUD and menus, Content, "Trick popups", for T-272 to use word for word.
- Creator labels added to `game/data/level/creator_texts.json` (every existing key unchanged, each with a where note) and listed in Level design, Content, "Level creator text": `pair_tool` "Pair obstacles", `pair_hint` "Pair: click two obstacles", `pair_made` "Pair made. Drive between them.", `pair_not_obstacle` "Not an obstacle. Pick a boulder, barrier, cones or crates.", `unpair_label` "Unpair", `controls_hint_pairs` (the rework hint with "P: pair." added; P is the text's proposal, the creator must use the same key).
- Documents affected: docs/hud-and-menus.md, docs/level-design.md.
