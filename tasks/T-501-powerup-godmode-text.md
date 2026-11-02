---
id: T-501
title: Text for the Polarized Steering Wheel, Rusty Paintjob and God mode
status: open
from: project-lead
to: narrative-theme
lead: Greenbull
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/hud-and-menus.md, game/data/screen_texts.json, game/data/power_ups.json]
files_expected_to_change: [game/data/screen_texts.json, game/tests/unit/, game/tools/]
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

Three sets of player-facing text, written first so the tasks that show them never use placeholders (docs/drifting.md, Decisions, "Rusty Paintjob and the Polarized Steering Wheel"; docs/hud-and-menus.md, Decisions, "A secret God mode").

1. **Polarized Steering Wheel** (a new driving power-up; the name is the board's and stays exactly as written): every text the other power-ups have, written the same way and in the same files: its name, its card text in the power-up overlay (with {field} numbers where the others use them), and its per-tier lines if the other power-ups have them. What it does: let go of accelerate, steer, then accelerate again in a different direction from the one the car is moving in, and the car gets a short speed burst; tiers 1 to 3 make the burst bigger; tier 4 makes it a little bigger again and also sets off an impact shock that damages and pushes back minions. T-502 builds it and reads these texts.
2. **Rusty Paintjob**: the board renamed Rusty Overcoat to Rusty Paintjob. Change the player-facing name everywhere the player can read it (screen texts, the trick list or tutorial if it appears there, the power-up overlay); the card text stays as it is ("The car deals {contact_damage} damage to minions it touches. Rust: now a feature.") unless it names the overcoat. The internal id stays rusty_overcoat.
3. **God mode** (a secret page, T-504 and T-505): the label of the hidden settings entry that opens it, the page's title, a short line under the title saying what it does (set each weapon's and power-up's tier for this run), the two group headings (weapons, driving power-ups), how a tier reads next to a name (for example "Tier 3 / 8" or "Not owned"), and the button that goes back. Put them in game/data/screen_texts.json (or wherever the pause screen's settings texts live), with keys T-505 can use, and list the keys in the result notes.

Run the style loop on every new or changed text. List every final text with its key in the result notes. This task's branch is built on T-497's branch, which already holds the board's new weapon trees (T-495 to T-499) and the playtest tier switch (T-500), so the board can play everything in one build. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py <id> --append <file>`, never with Edit or Bash on the ticket. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build with the weapon trees (T-495 to T-499), the power-up changes and God mode (T-501 to T-505), from the Project Lead's combined folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Polarized Steering Wheel has a name (exactly the board's), a card text and the same kinds of per-tier texts as the other power-ups, in the same files, under keys the result notes list. (QA: pass / fail)
- [ ] No text the player can read still says Rusty Overcoat (a search of game/data and game/scripts for "Overcoat" in player-facing strings finds none); the name reads Rusty Paintjob; the internal id rusty_overcoat is unchanged. (QA: pass / fail)
- [ ] The God mode texts (entry label, title, line under the title, two group headings, the tier format, the back button) exist under keys listed in the result notes. (QA: pass / fail)
- [ ] The style loop's scores for every new or changed text are in the ticket's Style review and result notes. (QA: pass / fail)
- [ ] The test files that cover screen texts and power-up texts pass (-gselect, and the python text checks if any cover them). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
