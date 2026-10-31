---
id: T-459
title: The driving power-up overlay: a completed mission pauses the run and offers 2 power-ups (new or next tier)
status: in-qa
from: project-lead
to: ui
lead: Goal-G-009
epic: hud-menus
milestone: mvp
goal: G-009
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: [T-456, T-455, T-457]
documents_affected: [docs/hud-and-menus.md, docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/level-up-screen.md, game/scripts/ui/level_up_screen.gd, game/scripts/weapons/level_up_offers.gd, game/scripts/run/run.gd, game/scripts/run/run_state.gd, game/scripts/run/missions.gd, game/data/power_ups.json, game/data/screen_texts.json]
files_expected_to_change: [game/scripts/ui/power_up_screen.gd, game/scripts/run/power_up_offers.gd, game/scripts/run/run.gd, game/tests/unit/test_power_up_screen.gd, game/tests/unit/run/test_power_up_offers.gd, game/tests/fixtures/power_up_screen_demo.gd, game/tests/fixtures/power_up_screen_demo.tscn, game/docs/hud-and-menus/level-up-screen.md, docs/hud-and-menus.md, docs/game-loop-architecture.md]
model: opus
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

Game loop architecture, Decisions, 'Mission packs': a completed mission gives a driving power-up gift. Like the level-up gift pack screen, it pauses the run and offers 2 choices, on an overlay similar to the weapons' gift menu but clearly distinct (driving power-ups, not weapons).

- The tracker's mission_completed opens the overlay and pauses the run. Exactly 2 cards, drawn from power-ups the car doesn't own and the next tiers of those it owns (RunState.power_up_tier); a power-up at its last tier is not offered. With only one choice left, show one card (proposal); with none, follow power_ups.json's `offer_when_exhausted` proposal. Document both.
- Choosing works like the level-up screen: A/D or arrows, Enter/Space, mouse. Taking a card calls RunState.grant_power_up and resumes the run. Pause and window-focus-loss rules match the level-up screen's (Escape doesn't open the pause screen over it, focus loss doesn't).
- If the level-up screen is open or a gift pack is picked up while the overlay is open (or the other way round), they don't show at once: the second waits until the first closes (proposal; document it).
- Its own look: a header and frame distinct from the Greenbull weapons gift screen (placeholder frame drawn in code, not Greenbull's green or emblem), with D1's header, button label, names and tier descriptions exactly, and each power-up's icon from its power_ups.json path (a placeholder square with the power-up's initial until the icon art exists).

Screenshots: the power-up overlay and the weapons gift screen side by side.

The board's review: complete a mission in a run and check the power-up overlay: that it reads clearly as driving power-ups rather than weapons, the controls, and the run resuming.

## Acceptance criteria

- [ ] After a simulated mission_completed in a run, the run is paused and the power-up overlay shows exactly 2 cards (GUT test). (QA: pass)
- [ ] GUT tests of the offer rules: offers come only from unowned power-ups and next tiers, a power-up at its last tier is never offered, and the one-left and none-left cases follow the documented proposals. (QA: pass)
- [ ] Choosing with A/D, arrows, Enter/Space and the mouse works as on the level-up screen; taking a card raises that power-up's tier in RunState and resumes the run; Escape and focus loss behave as on the level-up screen (GUT tests). (QA: pass)
- [ ] The overlay and the level-up screen never show at the same time; the second waits for the first (GUT test), and the rule is documented in HUD and menus. (QA: pass)
- [ ] The overlay shows D1's header, button label, names and tier descriptions exactly, with each power-up's icon or a placeholder, and its header and frame differ from the weapons gift screen; screenshots of both screens side by side are in art-archive/<id>/screenshots/. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Blocked → In progress

Goal runner (G-009): started, in C:\solid-carbide-worktrees\T-459.

### 2026-10-31, In progress → In QA

Goal runner (G-009): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**UI Agent, 2026-10-31: done, ready for QA.** PixelLab: 0 generations. Style loop: not run. No new player-facing text: every word comes from T-456's texts, which have already passed the style loop (`screen_texts.json`, `power_ups`). The look is a placeholder drawn in code, with no generated asset.

**What was built**
- `game/scripts/run/power_up_offers.gd` (`PowerUpOffers`, child `PowerUpOffers` of the run). It listens for `RunMissions.mission_completed`, pauses the run and emits `offers_ready(mission_index, ids)`. The choices are power-ups the car doesn't own (offered at tier 1) and the next tier of power-ups it owns (`RunState.power_up_tier`). A power-up at its last tier is never offered. A gift gives 2 cards drawn at random in power_ups.json's order. **Proposal: when only one choice is left, it shows one card.** When nothing is left, power_ups.json's `offer_when_exhausted` "skip_gift" applies: no overlay, no pause, `gift_skipped`. `choose(id)` calls `RunState.grant_power_up(id)` and resumes the run.
- `game/scripts/ui/power_up_screen.gd` (`PowerUpScreen`, layer 15). It has the level-up screen's controls: A/D, arrows, Enter/Space and the card's button. A key held when the overlay opens does nothing until it is let go, and nothing counts during the short stepped build-up (0.36 s). Texts are T-456's word for word. Each description is filled with the offered tier's numbers ("Next hop in 2 s"). Each card shows the icon from power_ups.json's path, or an amber placeholder square with the name's initial until the art exists. **Tier pips** (no text) show the tiers owned, the tier offered and the rest.
- **Its own look** (placeholder drawn in code): an amber and black hazard-striped header bar with a dark steel plate, dark steel cards with amber frames, a white frame on the highlighted card and amber "Take power-up" plates. It uses no Greenbull green, emblem, ribbon or sunburst.
- **Escape and focus loss:** `pause_screen.gd` `_choice_open()` also counts the overlay, so Escape doesn't open the pause screen over it. When the window loses focus nothing happens, because the tree is paused (test added to `test_close_and_focus.gd`).
- **Never at once with the level-up screen (proposal, documented):**
  - A weapon choice that starts while the overlay is open is held (`LevelUpScreen.hold` / `show_held()`) and shows when a power-up is taken. The run stays paused in between.
  - A mission completed during the weapon choice waits. It opens at the start of the next frame (the tree's `process_frame`/`physics_frame` signals, before anything moves), because RunState unpauses right after `level_up_choice_made`.
  - The same check re-pauses the run if a weapon choice with nothing to offer resumes the tree while the overlay is open.
  - Two missions completed together open one overlay after the other.
  - A new run closes the overlay and drops any waiting gift.
- `run.gd` wires all of this up. Small changes in `level_up_screen.gd` (the hold) and `pause_screen.gd`. RunState is unchanged.

**Tests**
- New: `tests/unit/run/test_power_up_offers.gd` (11) and `tests/unit/test_power_up_screen.gd` (18), plus 1 in `tests/unit/game/test_close_and_focus.gd`.
- Godot GUT, full suite: **2369/2369 passed** (195 scripts, 880 s).
- Python `game/tools`: **767 tests OK** (1 skipped).
- Python `tools`: **614 tests OK**.

**Documents affected**
- `docs/hud-and-menus.md`: new Content section, "Power-up overlay", with the rules, the one-left and none-left cases, the waiting rule and the look.
- `docs/game-loop-architecture.md`: "Missions in the run" now has "The gift's pause (T-459)".
- `game/docs/hud-and-menus/level-up-screen.md`: new "Power-up overlay (T-459)" section on how it is built.

**Screenshots** (`art-archive/T-459/screenshots/`)
- `side_by_side_power_ups_vs_weapons_gift.png`: the power-up overlay next to the weapons gift screen.
- `power_up_overlay.png`: a fresh car, Rev Charge and Jump at tier 1.
- `power_up_overlay_next_tier.png`: owned tiers, Bouncy Bumpers offered at tier 3, highlight on the second card.
- `weapons_gift_screen.png`: the weapons gift screen, for comparison.
- Fixtures: `game/tests/fixtures/power_up_screen_demo.tscn`, `power_up_screen_next_tier.tscn` and `power_up_screen_weapons_gift.tscn`.

**QA round 1 (2026-10-31): all 6 criteria pass.** Re-ran: Godot GUT full suite TESTS PASSED (exit 0; the new power-up offer, screen and focus tests are listed and passed), Python game/tools 767 OK (1 skipped), Python tools 614 OK. Screenshots exist (4 files) and the side-by-side shows the amber/black power-up overlay clearly distinct from the green Greenbull gift screen; the docs carry the waiting rule. Refusal: `python tools/qa_check.py T-459 --no-marks` was refused (not on the pre-approved list), so the script's checks were done by hand.

**Refusals:** one. A first `cd ...; git log` command was refused. It wasn't needed, and I used plain `git log` instead.
