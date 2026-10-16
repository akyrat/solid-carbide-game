---
id: T-142
title: Meteor boulders fade away 10 seconds after landing
status: needs-playtest
from: project-lead
to: enemy-behavior
lead: Playtest
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-046]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, tasks/T-046-kaiju-meteor-attack.md, game/README.md]
files_expected_to_change: [the meteor boulder script, tests, game/data/enemies.json, docs/enemies.md, game/README.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-046 (the meteor attack) is merged.**

The board played the meteor attack and liked it, with one change (board, 2026-10-15; Enemies, Decisions): a boulder left by a meteor stays for 10 seconds after it lands, then fades away and is gone. While it fades it is still drawn; once it is gone it no longer blocks the car or anything else. Put the 10 seconds and the fade's length in `game/data/enemies.json` with the other meteor numbers, so they can be tuned without code. The map's own boulders are not affected.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test lands a meteor and shows its boulder is still there, fully visible and blocking, just before 10 seconds (QA: pass)
- [ ] A test shows the boulder fades out after 10 seconds (its transparency goes down over the fade) and is then removed: it no longer blocks the car and is no longer in the scene (QA: pass)
- [ ] A test shows the map's own boulders are not removed (QA: pass)
- [ ] The 10 seconds and the fade length are read from `game/data/enemies.json` (QA: pass)
- [ ] `docs/enemies.md` Content and `game/README.md` describe the fade, without changing Summary, Decisions or Open questions (QA: pass)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Updates

### 2026-10-16, Open → In progress

Started: the Enemy Behavior Agent makes meteor boulders fade away after 10 seconds. You'll playtest it in C:\solid-carbide-worktrees\T-142.

## Result notes

Built (Enemy Behavior Agent). A meteor boulder stays 10 s after landing, fully visible and solid, then fades out over 2 s (sprite transparency in a straight line, still solid while fading) and is removed: body out of the physics world, sprite freed, entries gone from `meteor_boulders` / `all_boulders()`, spot free again. The map's own boulders are never touched (`remove_meteor_boulder` / `set_meteor_boulder_alpha` accept only bodies from `add_meteor_boulder`). Ageing runs in `kaiju_meteors.gd` `step()`, so it pauses with the game.

- Numbers: `boulder_lifetime_seconds` 10 (decided) and `boulder_fade_seconds` 2.0 (my proposal, tune freely) in `game/data/enemies.json`, `meteor_attack`.
- Code: `game/scripts/enemies/kaiju_meteors.gd`, `game/scripts/level/mvp_map.gd`. Also fixed meteor boulder naming to use a counter so names are not reused after removal.
- Tests: 5 new in `tests/unit/enemies/test_kaiju_meteors.gd` (fully visible and solid before 10 s; fades then removed from scene and physics; map's own boulders stay; numbers read from data, by changing them), `test_enemy_data.gd` key list updated. GUT 750/750 pass; pytest tools 180 passed; pytest game/tools 261 passed, 1 skipped. Game launched with `--quit-after 300`: no errors.
- Docs: `docs/enemies.md` Content ("Boulders fade") and `game/README.md` ("Boulders fade" paragraph and tests line). Summary, Decisions, Open questions untouched.
- Limitation: in the flat view the placeholder circles vanish at the end without fading; only the boulder art (isometric view) fades.

**How the board plays it:** open `C:\solid-carbide-worktrees\T-142\game\project.godot` (or Play on the ticket in the Builds tab). The playtest switch `kaiju_early_arrival.enabled` in `game/data/playtest.json` is ON in this branch: the kaiju arrives 30 s in, first meteors at about 35 s. Watch a boulder: after 10 s it fades over 2 s, then the car drives through the spot. **`kaiju_early_arrival.enabled` must be set back to false right before merging.**
- 2026-10-16, in-progress → in-qa: Built; GUT 750/750, pytest 180 + 261. Playtest switch kaiju_early_arrival is ON in this branch and must go back off right before merging. Play: C:\solid-carbide-worktrees\T-142\game\project.godot

### QA round 1 (QA/Integration Agent, 2026-10-16)
- Visible and blocking before 10 s: pass (test in test_kaiju_meteors.gd)
- Fades after 10 s then removed from scene and physics: pass
- Map's own boulders not removed: pass
- 10 s and fade length read from enemies.json: pass
- Docs: pass (enemies.md Content line only; game/README.md updated; Summary/Decisions/Open questions untouched)
- Tests: pass. GUT 750/750, pytest tools 180 passed, pytest game/tools 261 passed 1 skipped. Game launch --quit-after 300: no script errors.
- Note: kaiju_early_arrival.enabled is on for the playtest and must be set false before merging.
- 2026-10-16, in-qa → needs-playtest: QA round 1 all pass; GUT 750/750, pytest 180+261
