---
id: T-028
title: Explore a "livestream combo" (viewers multiplier on likes)
status: open
from: project-lead
to: project-lead
epic: driving
milestone: final-release
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md, docs/hud-and-menus.md, docs/extended-narrative.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, docs/extended-narrative.md]
files_expected_to_change: [docs/game-loop-architecture.md, docs/hud-and-menus.md, docs/extended-narrative.md, new task files for the build]
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

**An exploration for the board, not a build yet.** The board explores the idea with the Project Lead; once it is settled, the Project Lead records the decisions in the game area docs and splits the build into task files per agent.

**The idea (board, 2026-10-08):** a **livestream combo**.
- The more tricks the player does in a row without colliding with anything, the higher a combo multiplier grows. The multiplier multiplies the rate at which likes (XP) are earned.
- On the HUD the combo is a **vertical bar next to the likes bar**. What the bar holds is the stream's **current viewers**.
- Colliding with anything cuts the combo by **80%**.
- If the player stops doing tricks for longer than the **chain interval** (2 seconds to start with), the combo, and so the viewers, starts dropping at an **exponential** rate.

**Why: a counterbalance.** Extended narrative (Open questions) has the after-MVP idea of people in need of help, where rewards for "ethical" actions are balanced by likes dropping when the player isn't doing enough tricks. The combo is that counterbalance: stopping to help costs viewers.

**Questions to settle while exploring:**
1. What counts as a trick: completed challenges, drifts over 1 second, both, or something new?
2. How much the multiplier grows per trick, whether it has a maximum, and whether viewers and the multiplier are the same number.
3. Does "anything" include enemies, or only walls, buildings and boulders? Enemy contact is also an open question in Drifting (does the car bounce off enemies?).
4. The exponential drop: how fast, and does the multiplier ever drop below 1x?
5. Does the combo apply to all likes, including challenge likes, or only to drift likes?
6. Is the combo kept or reset across the level-up pause and the kaiju's arrival?
7. Is it MVP or after the MVP? This ticket assumes after the MVP (`final-release`), like the helping-people idea it balances.
8. How to try it: on paper with numbers, or as a quick prototype in the drift prototype (that would be a separate task for the Driving & Drift Agent).

## Acceptance criteria

- [ ] The board's answers are recorded as decisions in the game area doc that owns likes (Game loop architecture), with the bar in HUD and menus, and anything still open listed under Open questions (QA: pass / fail)
- [ ] Extended narrative's helping-people idea points to the combo as its counterbalance, without repeating the details (QA: pass / fail)
- [ ] The long GDD is regenerated and `python tools/generate_long_gdd.py --check` exits 0 (QA: pass / fail)
- [ ] The build is split into task files, one per agent, linked through `depends_on`, each with its own acceptance criteria (QA: pass / fail)
- [ ] A timeline entry lists the documents touched (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
