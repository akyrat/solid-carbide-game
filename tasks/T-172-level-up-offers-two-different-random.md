---
id: T-172
title: Level-up offers: two different random choices from all five weapons
status: needs-playtest
from: project-lead
to: weapon-behavior
lead: Goal-G-002
epic: weapons
milestone: mvp
goal: G-002
user_facing_text: no
changes_visuals: yes
depends_on: [T-168, T-169, T-170]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/visual-style.md, docs/extended-narrative.md, game/scripts/weapons/level_up_offers.gd, game/scripts/weapons/weapons.gd, game/scripts/weapons/flamethrower/exhaust_flamethrower.gd, game/data/playtest.json, game/tests/unit/weapons/test_level_up_offers.gd, game/README.md]
files_expected_to_change: [game/scripts/weapons/level_up_offers.gd, game/scripts/weapons/weapons.gd, game/data/playtest.json, game/tests/unit/weapons/test_level_up_offers.gd, docs/weapons.md, game/README.md]
model: opus
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

With five weapons each level-up still offers 2 choices, now two different ones drawn at random from every choice available: getting a weapon the car doesn't have, or the next tier of one it has (docs/weapons.md, Decisions, 2026-10-18). The first level-up of a normal run still offers exactly 'upgrade the gun' and 'get the flamethrower'. Extend `level_up_offers.gd` with ids `get_underglow`/`upgrade_underglow`, `get_molotov`/`upgrade_molotov`, `get_wiper`/`upgrade_wiper` next to the existing ones, draw the two at random with a generator tests can seed, never offer a weapon at tier 8, show one choice when only one is left and skip the choice when none is left (as today). `choose(id)` applies the new ids through the rack. Keep the `flamethrower_at_start` playtest switch working. Add one playtest switch in `data/playtest.json`, `all_weapons_at_start` (false by default, never visible to players, docs/hud-and-menus.md, Decisions, the dev flag), that gives all five weapons at the start of a run, for the integration check and the board's playtest.

The board's review: Level up several times in a run from the task folder and see two different random weapon choices each time.

## Acceptance criteria

- [ ] A test shows the first level-up of a normal run offers exactly `upgrade_gun` and `get_flamethrower`. (QA: pass)
- [ ] Seeded tests over many later level-ups show: two different ids each time, every id drawn is available (a get for a weapon not owned, an upgrade for one owned below tier 8), and over the seeds every available id is offered at least once. (QA: pass)
- [ ] Tests show one choice when only one is left, the choice skipped (run resumes, no offers_ready) when none is left, and the `flamethrower_at_start` switch still gives the flamethrower and leads to its upgrades being offered. (QA: pass)
- [ ] Tests show taking each of the six new ids applies the weapon or its next tier and resumes the run, and `all_weapons_at_start` (false in the committed playtest.json) gives all five weapons at tier 1 when set to true. (QA: pass)
- [ ] `docs/weapons.md` Content 'The level-up offers' and `game/README.md` 'The level-up offers' describe the random draw, the new ids and the switch; the game's test set passes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Blocked → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-172.

### 2026-10-18, In progress → In QA

Goal runner (G-002): the agent is done; QA is checking it.

### 2026-10-18, In QA → Needs playtest

Goal runner (G-002): QA passed; merged into playtest/G-002.

## Result notes

Weapon Behavior Agent, 2026-10-18.

**What was built**
- `game/scripts/weapons/level_up_offers.gd`: the 9 choice ids (`upgrade_gun`, `get_`/`upgrade_` for flamethrower, underglow, molotov, wiper; `ALL_IDS`), built from the rack per weapon: `get_<w>` while not owned, `upgrade_<w>` while owned below tier 8 (`available_offers()`). Each choice draws 2 different ids uniformly from the available ones with the script's own seedable `rng`, shown in `ALL_IDS` order; 1 id when only one is left; the choice is skipped (no `offers_ready`, `choice_made()` at once) when none is left. The first choice of a normal run (no choice taken yet this run, the car owns only the gun) is always `upgrade_gun` + `get_flamethrower`. `compute_offers()` still changes nothing: it returns the next draw and puts the generator's state back. `choose(id)` applies any id through `rack.upgrade(weapon_of(id))`.
- `game/scripts/weapons/weapons.gd`: playtest switch `all_weapons_at_start` (static `all_weapons_switch_on()`, test override `all_weapons_override`): gives every weapon not yet owned at tier 1 in `reset_for_run()`, after the per-weapon switches, so nothing is given twice.
- `game/data/playtest.json`: `"all_weapons_at_start": false` and its line in `_comment`.

**Tests** (`tests/unit/weapons/test_level_up_offers.gd`, rewritten, 24 tests, ~9,800 asserts): first offer over 40 seeds; 40 seeded runs taken from level 1 until nothing is left (39 choices each), each offer two different available ids, all 9 ids seen; same seed same offers; `compute_offers()`; order; tier 8 never offered; one left; none left; each of the six new ids applied and the run resumed; `flamethrower_at_start` leading to `upgrade_flamethrower`; `all_weapons_at_start` on/off and false in the committed file.
- `tests/unit/test_level_up_screen.gd` (UI Agent's): two tests assumed a fixed later offer. `test_flamethrower_upgrade_card_shows_its_next_tier` now maxes the three new weapons first; `test_keyboard_and_mouse_work_after_the_animation` presses whichever card is first on the second level-up and checks that weapon's tier went up.
- Full GUT suite: 946/946 passed (`bash game/tools/run_tests.sh`). Python tool tests (`game/tools`): 278 OK.

**Choices made where the docs are silent (for the board's playtest)**
- "First level-up of a normal run" = no choice taken yet this run and the car has only the gun. So with `flamethrower_at_start` (or any other `*_at_start` switch) the first level-up is drawn.
- The two drawn ids are shown in a fixed order (gun, flamethrower, underglow, molotovs, wiper), not the drawn order, so the gun's card stays first as before.

**Open for other agents**
- The level-up screen has no card text for the six new ids yet: `card_text()` returns empty title and description for them (and `upgrade_<new weapon>` needs per-tier keys as the gun's and flamethrower's do). That is a Narrative Theme text task plus a UI task; this task has `user_facing_text: no`.
- The level-up screen's test runs leave many queued card nodes reported as GUT "orphans" in the big seeded loops; harmless, the tests pass.

**Board's review:** in the task folder, open `game/project.godot` and play (F5); level up several times: from the second level-up on, the two cards are random among the five weapons (new weapons' cards show no text yet, see above). Set `all_weapons_at_start` to `true` in `game/data/playtest.json` to start with all five.

**Documents affected:** `docs/weapons.md` (Content, "The level-up offers (built in tasks T-043 and T-172)", and the three new weapons' "Owning it" lines), `game/README.md` (Weapons, "The level-up offers", and the three new weapons' "How it plugs in" lines).

**PixelLab:** none used. **Refusals:** one: redirecting the test log to `/tmp` (outside the folder) was refused; I wrote it to an ignored `game/*.tmp` file in the task folder instead (not essential, nothing committed).
- 2026-10-18, in-qa → needs-playtest: QA passed every criterion (goal G-002).
