---
id: T-037
title: Likes (XP) and levels: from challenges and drifts, level-up pauses the run
status: in-progress
from: project-lead
to: game-loop
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-036, T-038]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/drifting.md, docs/drifting/unity-prototype-report.md, docs/extended-narrative.md, tasks/T-036-run-scene-and-state.md, tasks/T-038-run-and-likes-data.md, game/README.md]
files_expected_to_change: [the run's scripts, their tests, game/README.md, docs/game-loop-architecture.md]
model: opus
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

**Blocked until T-036 (the run) and T-038 (the numbers) are done.**

XP is shown to players as **likes** (Extended narrative, Decisions); in code and docs it may stay "XP". Add XP and levels to the run, as Game loop architecture, Decisions describes:

1. **From challenges:**
   - When the map's "challenge completed" signal fires (T-019), add that level's XP for a challenge, from T-038's data.
   - Send a "score" signal with the amount gained. The challenge popup from the car (T-092) will show it (the score is the likes gained).
   - Game loop architecture says completed challenges give XP, with no exception, so the kaiju's meteor challenges (T-035's signal) give XP the same way.
2. **From drifting:**
   - "Drifting" uses the Unity prototype's definition: W or S held together with A or D (report, section 3). The car from T-012 already knows its drift state.
   - A drift that lasts longer than 1 second gives XP for every second it lasts, the first second included.
   - Each second is worth a fixed amount, from T-038's data.
3. **Levels:**
   - When XP reaches the current level's threshold, the player levels up.
   - Leftover XP and how thresholds grow follow T-038's data.
   - Send a "level up" signal with the new level.
4. **Level-up and the weapon choice:** in the end a level-up pauses the run until the player has made the weapon choice. That screen (T-052) doesn't exist yet, and the board wants to playtest likes and levels before it (2026-10-10). So:
   - Provide the pause: a switch, off for now, that makes a level-up stop the clock and freeze the car until a public "choice made" function is called. If two level-ups happen at once, the second waits for the first choice. T-052 turns the switch on.
   - While the switch is off, a level-up just raises the level and the run carries on.
5. **Values for the HUD:** current XP, the current level's threshold and the level, readable at any time, with a signal when they change.
6. **Reset** with every new run (T-036).

Document the new signals and functions in `game/README.md`, "The run".

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test fires the map's "challenge completed" signal at level 1 and shows the XP bar fills, the level becomes 2, the "level up" signal fires once and the "score" signal carries the XP gained (QA: pass / fail)
- [ ] A test holds a drift for 0.9 seconds and shows no XP, then holds one for 3 seconds and shows exactly 3 seconds' worth of XP (QA: pass / fail)
- [ ] A test with the pause switch off shows a level-up raises the level and the clock keeps running (QA: pass / fail)
- [ ] A test with the switch on shows the run is paused after a level-up and resumes after the choice-made function is called, and two level-ups at once wait one after the other (QA: pass / fail)
- [ ] A test shows a completed meteor challenge (T-035's signal, simulated) gives the same XP as a preset challenge (QA: pass / fail)
- [ ] A test shows XP and level reset when a new run starts (QA: pass / fail)
- [ ] `game/README.md` documents the new signals and functions. `docs/game-loop-architecture.md` describes them in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
