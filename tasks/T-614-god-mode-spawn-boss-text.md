---
id: T-614
title: Text for God mode's spawn the boss button
status: open
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

- [ ] `game/data/pause_text.json` holds `god_mode_spawn_boss` and `god_mode_spawn_boss_used`, each 16 characters or fewer, and the file still parses (the text tests pass, the text inventory test included). (QA: pass / fail)
- [ ] Each of the two texts has an entry in the ticket's Style review with a score of 8 or more, or is listed in the result notes as below 8 after its refines. (QA: pass / fail)
- [ ] HUD and menus, Content, lists both texts with what each is for and where it shows. (QA: pass / fail)
- [ ] Nothing to picture: the result notes say so in one line (the texts are shown in T-612's screenshots). (QA: pass / fail)
- [ ] The tests for the changed files pass (the agent) and QA's run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Every document in documents_affected is updated. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
