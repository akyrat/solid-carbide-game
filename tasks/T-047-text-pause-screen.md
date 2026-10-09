---
id: T-047
title: Text: the pause screen
status: needs-playtest
from: project-lead
to: narrative-theme
epic: narrative
milestone: mvp
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, .claude/agents/narrative-theme.md, tasks/T-015-pause-on-escape.md]
files_expected_to_change: [tasks/T-047-text-pause-screen.md (result notes only)]
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

Text for the MVP pause screen built in T-015 (HUD and menus, Decisions):
- **paused.title:** the word the screen shows when the game is paused (HUD and menus says "Paused"; keep that meaning). Up to 20 characters.
- **paused.hint:** a hint that Escape resumes the game. Up to 50 characters. It must name the Escape key.
- **paused.zoom_label:** the label next to the camera zoom slider. Up to 25 characters.


Write the final text in this task's result notes, as a table: key, where it appears, the text, and its length in characters. The building task uses exactly this text (`tasks/README.md`, "User-facing text and visuals"). Write in Extended narrative's voice: satirical, Redgull out of touch, the player's fun slightly unethical. Players see "likes", never "XP". Don't describe anything the game doesn't do.

## Acceptance criteria

- [ ] The result notes have a table with paused.title, paused.hint and paused.zoom_label (QA: pass / fail)
- [ ] paused.hint names the Escape key (QA: pass / fail)
- [ ] Every text in the table fits the length limit given for it (QA: pass / fail)
- [ ] No text contains "XP" or "experience" (QA: pass / fail)

The board's review: read the text and judge whether it has the right voice.

## Result notes

| Key | Where it appears | Text | Length (chars) |
|---|---|---|---|
| paused.title | Pause screen, large title shown while the game is paused | Paused | 6 |
| paused.hint | Pause screen, under the title, tells the player how to resume | Press Escape to get back to the stream. | 39 |
| paused.zoom_label | Pause screen, label next to the camera zoom slider | Camera zoom, for the fans | 25 |

Limits: title 20, hint 50, zoom label 25. The title keeps HUD and menus' meaning ("Paused"). The hint names Escape and nods to the livestream audience waiting; the zoom label nods to the viewers. No "XP" or "experience".

### QA round 1

Lengths counted independently (wc -m): title 6 of 20, hint 39 of 50, zoom label 25 of 25.

- [x] The result notes have a table with paused.title, paused.hint and paused.zoom_label: PASS
- [x] paused.hint names the Escape key: PASS ("Press Escape to get back to the stream.")
- [x] Every text in the table fits the length limit given for it: PASS (stated lengths match the real counts)
- [x] No text contains "XP" or "experience": PASS

Branch diff versus master changes only this task file. The board's voice review is still pending.
