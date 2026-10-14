---
id: T-051
title: Text: the level-up (gift pack) screen
status: open
from: project-lead
to: narrative-theme
lead:
epic: narrative
milestone: mvp
user_facing_text: yes
changes_visuals: no
depends_on: [T-040, T-043]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, .claude/agents/narrative-theme.md, docs/weapons.md, tasks/T-040-weapon-data.md, tasks/T-043-level-up-weapon-choices.md, tasks/T-052-level-up-screen.md]
files_expected_to_change: [tasks/T-051-text-level-up-screen.md (result notes only)]
model: sonnet
qa_rounds: 0
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

**Blocked until T-040 (what each upgrade tier changes) and T-043 (the choice ids) are done,** so the text describes what the weapons actually do.

Text for the level-up screen (HUD and menus, Decisions), where Redgull's gift pack offers 2 choices (Weapons, Decisions):
- **levelup.title:** the screen's heading. Up to 30 characters.
- For every choice id in T-043, a **title** (up to 30 characters) and a **description** (up to 90 characters). The weapons need names (Extended narrative, Decisions: this agent writes them): the starting gun and the exhaust flamethrower. Each upgrade tier's description says what that tier changes, from T-040's data.
- **levelup.take:** the label of the button that takes a choice. Up to 15 characters.


Write the final text in this task's result notes, as a table: key, where it appears, the text, and its length in characters. The building task uses exactly this text (`tasks/README.md`, "User-facing text and visuals"). Write in Extended narrative's voice: satirical, Redgull out of touch, the player's fun slightly unethical. Players see "likes", never "XP". Don't describe anything the game doesn't do.

## Acceptance criteria

- [ ] The result notes have levelup.title, levelup.take, and a title and description for every choice id in T-043 (QA: pass / fail)
- [ ] Each upgrade description matches what that tier changes in T-040's data (QA: pass / fail)
- [ ] Every text in the table fits the length limit given for it (QA: pass / fail)
- [ ] No text contains "XP" or "experience" (QA: pass / fail)

The board's review: read the text and judge whether it has the right voice.

## Result notes

Written by the agent when it finishes.
