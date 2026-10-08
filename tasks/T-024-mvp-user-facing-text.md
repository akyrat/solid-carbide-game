---
id: T-024
title: Write all of the MVP's user-facing text
status: blocked
from: project-lead
to: narrative-theme
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: no
depends_on: [T-022]
documents_affected: [docs/extended-narrative.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/weapons.md, docs/weapons/unity-weapons-report.md, docs/garage-design.md, .claude/agents/narrative-theme.md]
files_expected_to_change: [game/data/text/mvp-text.json, docs/extended-narrative.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-022 is done:** the weapon text must describe the weapons as they actually behave (the Unity prototype weapons report).

The board asked the Narrative Theme Agent to write the game's user-facing text, using Extended narrative to get the tone (Extended narrative, Decisions). This task writes every piece of text the MVP shows the player, in one data file the UI and other code will read. Write in the tone Extended narrative sets: satirical, tongue-in-cheek, Redgull out of touch, the player's fun slightly unethical. Players only ever see "likes", never "XP".

Write `game/data/text/mvp-text.json`, with one clearly named key per string, covering at least:

- **Main menu:** the title "SOLID CARBIDE" (as decided) and the "(work in progress)" line under it, as decided in HUD and menus; the Start, Garage and Quit buttons.
- **HUD:** the labels the HUD shows (HP, timer, likes and level, coins, kaiju health), including how likes are shown: the word, a heart icon, or both (this agent's choice; Extended narrative, Decisions). If you choose an icon, describe it in the file for the UI Agent and the Asset Generation Agent.
- **Level-up (gift pack) screen:** its heading, and a title and a description for each option: the starting gun, the exhaust flamethrower, and their upgrades as the T-022 report describes them.
- **Garage:** its heading, and a name and a description for each of the 3 upgrades (acceleration, car HP, weapon damage bonus), plus the labels for level, price, buy and back.
- **Pause screen:** "Paused" and the hint that Escape resumes (HUD and menus, Decisions; wording may follow the tone).
- **End of run:** a win message and a loss message.
- **Challenges:** any short message shown when a challenge is completed (the likes gained).

Keep each string short enough for a game screen, and note any that must fit a tight space. Do not invent game mechanics: describe only what the documents decide. Where the documents don't give enough to write a string, list it as an open question in the result notes rather than guessing what the game does.

In `docs/extended-narrative.md`, add a short `### MVP text` subsection under Content: where the file is, and the voice choices you made (for example how Redgull speaks, how likes are shown). Do not change Summary, Decisions or Open questions. Follow `docs/README.md`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] `game/data/text/mvp-text.json` is valid JSON and has strings for every screen listed above: main menu, HUD, level-up, garage, pause, end of run and challenge completion (QA: pass / fail)
- [ ] The main menu strings include "SOLID CARBIDE" and "(work in progress)" (QA: pass / fail)
- [ ] There is a title and a description for both MVP weapons and their upgrades, and for all 3 garage upgrades (QA: pass / fail)
- [ ] No player-facing string contains "XP" or "experience"; the likes bar is called likes (or shown by the chosen icon) (QA: pass / fail)
- [ ] The file says how likes are shown (word, icon or both), with an icon description if one is used (QA: pass / fail)
- [ ] `docs/extended-narrative.md` has the `### MVP text` subsection, still follows the five-section structure, and its Summary, Decisions and Open questions are unchanged (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: read the text and judge whether it has the right voice.

## Result notes

Written by the agent when it finishes.
