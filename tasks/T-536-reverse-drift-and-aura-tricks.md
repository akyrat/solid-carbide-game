---
id: T-536
title: Two new tricks: the reverse drift and the aura
status: needs-playtest
from: project-lead
to: driving-drift
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: [T-533]
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/driving/tricks.md]
files_expected_to_change: [game/scripts/driving/trick_detector.gd, game/data/combo.json, game/tests/, game/docs/driving/tricks.md, docs/drifting.md]
model: opus
qa_rounds: 1
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

Build Drifting, Decisions, "A reverse drift trick" and "An aura trick", in the trick detector like the other tricks (paid with a popup, adds to the combo, pays subs, counts for the recap's tricks). Use exactly T-533's popup texts. Reverse drift: propose what counts (for example a drift while the car's velocity points backwards relative to its nose, for at least a minimum time) and its worth next to the existing tricks. Aura: the car stationary (propose a speed threshold) for 5 s, then one aura trick paid every full second while it stays still; moving resets the count; it doesn't pay during pause, the level-up screen, a wreck or the time-up screen. Both numbers live in game/data/combo.json. The trick list and tutorial are not changed in this ticket.

The board's review: play the combined build from C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot before merging.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A reverse drift that meets the proposed rule pays the reverse drift trick once with T-533's popup text; a forward drift doesn't (tests). (QA: pass)
- [ ] Staying still pays nothing for the first 5 s, then one aura trick each second; moving above the threshold resets it; nothing pays while paused or wrecked (tests). (QA: pass)
- [ ] Both tricks add to the combo and pay subs like the other tricks, with their numbers in game/data/combo.json (test). (QA: pass)
- [ ] docs/drifting.md Content and game/docs/driving/tricks.md describe both, with each proposed number and its reason. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] Screenshots or GIFs in art-archive/T-536/screenshots/ show each popup in a run. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-05, Open → In progress

Started: the agent is working in C:\solid-carbide-worktrees\T-536.

### 2026-11-06, In progress → In QA

Built: REVERSE DRIFT! and AURA FARMING! (still 5 s, first pay at 6 s, then every second). QA is checking it.

### 2026-11-06, In QA → Needs playtest

QA passed. In the combined playtest build: C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### Driving & Drift Agent, 2026-11-05

Done. Both tricks are built in the trick detector like the other tricks: popup with its amount, combo add, subs (T-513), and a count in the recap's tricks. T-533's texts are used exactly: REVERSE DRIFT! and AURA FARMING!, normal popup size.

**What counts (proposals for the playtest):**
- **Reverse drift:** a drift on S without W (the model's own is_drifting with reverse) while the velocity points backwards relative to the nose (`forward_speed() < 0`), unbroken for `reverse_drift.min_seconds`. Paid once per unbroken reverse drift, at the step it reaches that time; any other step resets and re-arms it. Braking with S + A while still rolling forward does not count until the car moves backwards. It still counts as a drift for LONG DRIFT! and as the backward half of ALT DRIFT!.
- **Aura:** on the ground with speed (any direction) at most `aura.still_speed`. After `aura.wait_seconds` (5 s, the board's) one aura every `aura.every_seconds` (1 s, the board's): first at 6 s, then 7 s, 8 s... Moving faster or leaving the ground resets the count. Only observed physics steps count, so pause, level-up and the time's up hold (all pause the tree) add nothing and the count resumes after them; the wreck already turns detection off and resets it (run.gd, T-413); `RunState.add_trick` ignores tricks when the run is not going.

**Numbers and reasons (all in game/data/combo.json):**
- `reverse_drift.min_seconds` 1.0: same as the shortest drift that pays (drift_pay.min_seconds), so a tap of S + A/D doesn't pay.
- `trick_add.reverse_drift` 0.25, `trick_subs.reverse_drift` 5: as FULL 360! and AIR 180!, half ALT DRIFT!, since it needs one held pair of keys and no timing.
- `aura.still_speed` 0.5 units/s: under 5% of cruise (11); with no keys the car coasts to 0 in about 1 s, so a stopped car counts and a rolling one doesn't.
- `aura.wait_seconds` 5.0 and `aura.every_seconds` 1.0: the board's. Reading: the first aura at 6 s (5 s still, then the first full second). If the board meant the first at 5 s, set wait_seconds to 4.0.
- `trick_add.aura` 0.1, `trick_subs.aura` 2: small, since it repeats every second with no skill. 2 subs is a fifth of a drift second; 0.1/s keeps the combo from draining and climbs it slowly (about 50 s still from x1 to x6) while enemies close in.

**Files changed:** game/scripts/driving/trick_detector.gd (TRICK_REVERSE_DRIFT, TRICK_AURA in TRICK_IDS, `_observe_reverse_drift`, `_observe_aura`), game/scripts/data/combo_data.gd (4 getters), game/data/combo.json, game/scripts/hud/trick_popups.gd (TEXTS, SIZES), game/data/recap_text.json (recap names), game/tests/unit/test_reverse_and_aura_tricks.gd (new), game/tests/unit/test_tricks.gd (TRICK_IDS list; the car-signal test's 1 s backward drift now also pays reverse_drift), game/tests/fixtures/reverse_aura_popups.tscn + reverse_aura_popups_demo.gd (screenshot fixture), game/docs/driving/tricks.md, docs/drifting.md.

**Documents affected:** docs/drifting.md (Content, new section "Reverse drift and aura (task T-536)" with each number and its reason); game/docs/driving/tricks.md (trick table and "How each trick is found").

**Merge with T-541 (rail grind):** my changes are inserted mid-list (after alternate_drift) in TRICK_IDS, combo.json's trick_add/trick_subs, trick_popups TEXTS/SIZES and recap_text.json, with new code in its own functions. The one likely touch point is the `TRICK_IDS` constant (I added a line between its two lines) and `test_tricks.gd`'s `test_ids` list: if T-541 also edits those lines, the conflict is a one-line union of both lists.

**Not changed (per the ticket):** the trick list, the tutorial, missions' known tricks.

**Tests run (foreground, -gselect each):** test_reverse_and_aura_tricks 18/18 (65 asserts), test_tricks 27/27, test_air_tricks 36/36, test_airtime_trick 14/14, test_combo_data 6/6, test_run_combo 20/20, test_trick_subs 4/4 (covers the new trick_add keys automatically), test_crash_pays_trick 17/17, test_trick_popups (all trick_popups_* files) 35/35, test_trick_popup_prebuild 10/10, test_run_recap 12/12, test_recap_screen 18/18, test_wreck 37/37, test_missions 20/20, test_pickups_combo_base 11/11, test_run_likes_drain 19/19, test_hud_combo_heat 13/13, test_thread_the_needle 22/22. All pass. Full sets not run (QA's).

**Screenshots** (art-archive/T-536/screenshots/, from a run started from the main menu, fixture `res://tests/fixtures/reverse_aura_popups.tscn`, `REVERSE_AURA_MODE=reverse|aura`, `REVERSE_AURA_PNG=<abs png>`):
- reverse_drift: art-archive/T-536/screenshots/reverse_popup.png (S + A from the start, REVERSE DRIFT! +x0.25 after 1 s)
- aura: art-archive/T-536/screenshots/aura_popup.png (car left still at the start, AURA FARMING! +x0.1 at 6 s, clock 3:54)

Note: the older fixture base `tests/fixtures/run_elevation_demo.gd` no longer reaches a run (the main menu's Start now shows the tutorial slides first, so `game.run` is null); my fixture sets `tutorial_enabled = false`. Not fixed here (outside this ticket).

QA (Sonnet): all 6 criteria pass. qa_check: tests 2 sets pass, documents changed, 2 screenshots. Popup texts REVERSE DRIFT!/AURA FARMING! confirmed in trick_popups.gd; numbers in combo.json; docs mention both; aura screenshot viewed.
