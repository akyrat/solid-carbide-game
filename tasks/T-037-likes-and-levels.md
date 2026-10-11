---
id: T-037
title: Likes (XP) and levels: from challenges and drifts, level-up pauses the run
status: in-qa
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

Written by the Game Loop Agent.

**Built:** likes (XP) and levels in the run's state, `game/scripts/run/run_state.gd` (`RunState`), wired up in `game/scripts/run/run.gd`; tests in `game/tests/unit/run/test_run_likes.gd` (15 tests). Full GUT suite: 249 of 249 pass. Python tool tests: 67, OK.

- **Challenges:** the run scene connects the map's `challenge_completed` and `meteor_challenge_completed` to `state.challenge_completed(id)`, which sends `score(amount, challenge_id)` with the current level's `challenge_xp` and adds it as XP. Meteor challenges give the same XP as preset ones.
- **Drifting:** after every car physics step the run calls `state.drift_step(car.model.is_drifting, car.model.dt)` (the model's `is_drifting` is the Unity definition). An unbroken drift gives `drift_xp_per_second` when it reaches 1 s, then at each further full second, so the bar fills while the player drifts. 0.9 s gives nothing, 3 s gives 3 seconds' worth. Reading of the decision worth the board knowing: only full seconds count, so 3.5 s gives 3 seconds' worth, not 3.5. This XP is tracked by the run itself, not from the car's `extended_drift` trick, which stays separate (Decisions, Combo).
- **Levels:** `add_xp` levels up each time XP reaches `xp_needed(level)`, with leftover XP carried over as `run.json` says; `level_up(new_level)` fires once per level. At `max_level` the bar stops (XP stays 0; challenges still send their score).
- **The pause switch:** `pause_on_level_up`, off. On, each level-up pauses the scene tree (clock and car stop) and sends `level_up_choice_started(level)`; `choice_made()` sends `level_up_choice_made(level)` and starts the next waiting choice or resumes. Two level-ups at once wait one after the other.
- **For the HUD (T-049):** `xp`, `xp_needed()`, `level`, and `xp_changed(xp, xp_needed, level)` on every change and on start.
- **Reset:** `start_run()` resets XP, level, the drift in progress and any waiting choice (unpausing if it was waiting). Nothing is added after the run ends.
- **For T-052:** the pause uses `get_tree().paused`, the same as the Escape pause screen. Pressing Escape twice during a level-up choice would currently resume the run, so T-052 should keep the pause screen from resuming while `state.is_waiting_for_choice()` is true.

**Documents updated:** `game/README.md` ("The run": the new functions, values and signals, and the tests), `docs/game-loop-architecture.md` (a new "Likes and levels" part in Content; Summary, Decisions and Open questions unchanged).
