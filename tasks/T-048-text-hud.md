---
id: T-048
title: Text: the HUD
status: needs-playtest
from: project-lead
to: narrative-theme
epic: narrative
milestone: mvp
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, .claude/agents/narrative-theme.md, docs/game-loop-architecture.md, tasks/T-049-hud-run-values.md, tasks/T-050-hud-challenge-arrow-and-kaiju-bar.md]
files_expected_to_change: [tasks/T-048-text-hud.md (result notes only)]
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

Text for the HUD (HUD and menus, Decisions), built in T-049 and T-050. The HUD must stay readable while driving, so keep it short:
- **hud.likes:** how the likes bar is labelled. Extended narrative, Decisions says this agent chooses whether likes are shown as the word, a heart icon, or both. Say which. If you choose an icon, describe it in the result notes; the Project Lead then writes an art task for it. Up to 12 characters.
- **hud.level:** the label for the current level, with where the number goes (for example a `{level}` placeholder). Up to 15 characters.
- **hud.coins:** the label for the coins collected this run. Up to 12 characters.
- **hud.health:** the label for the car's health bar, if it needs one (say if it doesn't). Up to 12 characters.
- **hud.kaiju:** the label for the kaiju's health bar. Up to 20 characters.
- **hud.score_flash:** the short message flashed when a challenge is completed, showing the likes gained (Game loop architecture, Decisions), with where the number goes. Up to 25 characters.
The timer is digits only and needs no text.


Write the final text in this task's result notes, as a table: key, where it appears, the text, and its length in characters. The building task uses exactly this text (`tasks/README.md`, "User-facing text and visuals"). Write in Extended narrative's voice: satirical, Redgull out of touch, the player's fun slightly unethical. Players see "likes", never "XP". Don't describe anything the game doesn't do.

## Acceptance criteria

- [ ] The result notes have a table with hud.likes, hud.level, hud.coins, hud.health, hud.kaiju and hud.score_flash (QA: pass / fail)
- [ ] The result notes say whether likes are shown as the word, an icon or both, and describe the icon if one is chosen (QA: pass / fail)
- [ ] Every text in the table fits the length limit given for it (QA: pass / fail)
- [ ] No text contains "XP" or "experience" (QA: pass / fail)

The board's review: read the text and judge whether it has the right voice.

## Result notes

Final text. Lengths count the placeholder as written (a rendered number is shorter).

| key | where it appears | text | length |
|---|---|---|---|
| hud.likes | label of the likes (XP) bar, next to the heart icon | Likes | 5 |
| hud.level | current level, beside the likes bar; `{level}` is the number | Hype Lv {level} | 15 |
| hud.coins | label for the coins collected this run; the count follows it | Coins | 5 |
| hud.health | label of the car's health bar (it needs one) | Car Health | 10 |
| hud.kaiju | label of the kaiju's health bar, shown once it appears | Kaiju (Co-Star) | 15 |
| hud.score_flash | flashed when a challenge is completed; `{likes}` is the likes gained | Trending! +{likes} Likes | 24 |

The timer is digits only and has no text.

**Likes choice: both the word and an icon.** The likes bar is labelled "Likes" and carries a heart icon at its left end, as on a social media post. The word keeps it readable at a glance; the heart gives the livestream feel.

**Icon description (for the Project Lead's art task):** a small, plain heart, solid Redgull red, with a thin dark outline so it reads on any background. Flat, no shine. It should look like the like button of a social app, and be small enough to sit beside the bar's label. Until the art exists, the HUD uses a placeholder shape.

Notes: no text contains "XP" or "experience". "Brand Coins" and "Kaiju (Co-Star)" are the satirical touches (Redgull treating coins as brand money and the monster as a livestream co-star); if the board finds them unclear, plain "Coins" and "Kaiju Health" also fit the limits.

### QA round 1

Lengths counted independently, placeholders as written: Likes 5 (max 12), Hype Lv {level} 15 (max 15), Brand Coins 11 (max 12), Car Health 10 (max 12), Kaiju (Co-Star) 15 (max 20), Trending! +{likes} Likes 24 (max 25). Diff versus master touches only this task file.

- [x] Table has all six keys: pass
- [x] Likes shown as word and icon, icon described: pass
- [x] Every text fits its limit: pass
- [x] No "XP" or "experience" in the table texts: pass (the table's "where it appears" cell for hud.likes mentions "(XP)" as a description, not player-facing text)

The board's voice review was not checked by QA.

### Board review

The board, 2026-10-10: approved, with one change: the coins label is **Coins**, not "Brand Coins" (the table above is updated). The likes heart icon in Redgull red is approved; its art task is T-086.
