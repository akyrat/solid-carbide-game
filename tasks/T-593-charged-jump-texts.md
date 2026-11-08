---
id: T-593
title: Texts: describe the charged jump wherever the game explains jumping
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
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/hud-and-menus.md, tasks/T-590-charged-jump-playtest.md, game/data/screen_texts.json, game/data/tutorial_text.json]
files_expected_to_change: [game/data/, game/tests/, docs/hud-and-menus.md]
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

The board approved T-590's charged jump (2026-11-08) and asked that every text describing how the player jumps be updated before it merges. This branch starts from T-590's. Find every player-facing text that explains the jump or how to catch a rail from a jump (the Jump power-up's name lines and tier descriptions in screen_texts.json, the tutorial's slides and practice notes in tutorial_text.json, the trick list, the pause screen's controls, any hint or popup; search game/data/ for jump, Space and hop) and rewrite the ones that are now wrong: on the ground with Jump, hold Space to charge (up to 3 s, a higher jump), release to jump; a tap still hops; to catch a rail from a jump, tap to jump, then hold Space in the air. Keep each text's voice and length; style loop only where those texts went through it before. Change only what is wrong; list every text changed (key, old, new, where it shows) in the result notes and in hud-and-menus.md Content. Update tests that pin the old wording.

The board's review: the board approved the jump; it asked for these texts and then a merge, so the Project Lead checks them and merges with T-590.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every player-facing text about jumping or catching a rail from a jump matches the charged jump; the result notes list each one changed with its key, old and new text and where it shows, and say where the search looked. (QA: pass / fail)
- [ ] No other text changed. (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content lists the changed texts. (QA: pass / fail)
- [ ] Tests that pin the wording are updated; QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A screenshot in art-archive/T-593/screenshots/ shows at least the Jump power-up card and the tutorial text with the new wording. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
