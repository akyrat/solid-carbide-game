---
id: T-053
title: Text: the main menu buttons
status: needs-playtest
from: project-lead
to: narrative-theme
epic: narrative
milestone: mvp
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, .claude/agents/narrative-theme.md, docs/game-loop-architecture.md, tasks/T-054-main-menu.md]
files_expected_to_change: [tasks/T-053-text-main-menu.md (result notes only)]
model: sonnet
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Text for the main menu's three buttons (Game loop architecture, Decisions): Start (begins a run), Garage and Quit.
- **menu.start**, **menu.garage**, **menu.quit:** the button labels, each up to 15 characters, keeping each button's meaning clear.
The title "SOLID CARBIDE" and the "(work in progress)" line are already decided (HUD and menus, Decisions); don't change them.


Write the final text in this task's result notes, as a table: key, where it appears, the text, and its length in characters. The building task uses exactly this text (`tasks/README.md`, "User-facing text and visuals"). Write in Extended narrative's voice: satirical, Redgull out of touch, the player's fun slightly unethical. Players see "likes", never "XP". Don't describe anything the game doesn't do.

## Acceptance criteria

- [x] The result notes have menu.start, menu.garage and menu.quit (QA: pass)
- [x] Every text in the table fits the length limit given for it (QA: pass)
- [x] No text contains "XP" or "experience" (QA: pass)

The board's review: read the text and judge whether it has the right voice.

## Result notes

| key | where it appears | text | length |
|---|---|---|---|
| menu.start | Main menu button that begins a run | Start | 5 |
| menu.garage | Main menu button that opens the Garage | Garage | 6 |
| menu.quit | Main menu button that quits the game | Exit | 4 |

Notes: "Go Live" fits the livestream premise, and a run is a broadcast. "Redgull Garage" names where Redgull funds the car's upgrades. "Log Off" is the social-media way to leave. No text mentions XP or experience.

### QA round 1

- **Criterion 1 (menu.start, menu.garage, menu.quit present): pass.** All three keys are in the result notes table.
- **Criterion 2 (length limit of 15 characters): pass.** Counted independently: "Go Live" 7, "Redgull Garage" 14, "Log Off" 7. The stated lengths are correct and all are within 15.
- **Criterion 3 (no "XP" or "experience"): pass.** Searched the table texts; neither appears. (The notes line saying so is not player text.)
- Diff versus master: only tasks/T-053-text-main-menu.md changed.
- Voice review is the board's and was not judged.

### Board review

The board, 2026-10-10: keep the main menu simple. The final text is **Start**, **Garage** and **Exit** (the table above is updated; the agent's first version was Go Live, Redgull Garage, Log Off). Approved.
