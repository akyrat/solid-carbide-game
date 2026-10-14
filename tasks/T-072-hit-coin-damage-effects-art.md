---
id: T-072
title: Art: enemy hits and deaths, coins, and car damage
status: needs-playtest
from: project-lead
to: asset-generation
lead: Enemies
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-044, T-036]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/enemies.md, tasks/T-044-minions.md, tasks/T-036-run-scene-and-state.md]
files_expected_to_change: [art files under game/art/ and their records, the scenes that used the placeholders, game/README.md]
model: sonnet
qa_rounds: 2
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

**Blocked until T-044 (minions and coins) and T-036 (the run, where the car takes damage) are done.**

Effects from Visual style, Decisions: an enemy being hit, an enemy dying, the coins enemies drop, and the car taking damage. Hook each to the moment it belongs to (T-044's hit, death and coin drop, the run's damage function) and swap in for any placeholders.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. Real-world things are inspiration only: no real logos, no copies of existing characters. Details the docs leave open (directions, frame counts, variants, sizes) are this agent's proposal, written in the result notes for the board to judge (Visual style, Decisions).

Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. The board judges the result.

This art task swaps its art in for the placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

Round 1's criteria (all passed on 2026-10-14) are superseded by the board's changes of 2026-10-15: the hit, death and car damage effects removed; enemies get only a brief slight red tint when damaged; the car shakes briefly when damaged. They are kept below, struck through, for the record.

- [x] A check script shows the coin sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass)
- [x] The record lists the one PixelLab call (the coin sample) with its prompt, settings and cost, and the balance before and after; the removed effects' art is kept in art-archive, not deleted (QA: pass)
- [x] A test shows a damaged minion and the kaiju get a brief red tint that returns to normal, and the tint is not Redgull red (QA: pass)
- [x] A test shows the car's sprite shakes briefly when the car takes damage, with no change to its physics, position or the camera, and it stands still while paused (QA: pass)
- [x] No hit, death or car damage effect from round 1 is left in the game; a screenshot shows a tinted minion next to normal ones (QA: pass)
- [x] T-044's, T-045's and T-036's tests still pass, and the full GUT suite and all Python tool tests pass (QA: pass)

Round 1 (superseded):

~~A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass)~~
~~The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass)~~
~~A screenshot sequence shows a minion being hit, dying and dropping a coin, and the car taking damage (QA: pass)~~
~~T-044's and T-036's tests still pass (QA: pass)~~
~~The full GUT suite and all Python tool tests pass (QA: pass)~~

The board's review: judge the look and play it. One round only, so problems are reported rather than regenerated.

## Result notes

Written by the agent when it finishes.

### Sample round (coin only; board's go for the sample, 2026-10-14)

**Proposal for the full set (not generated):**

| Effect | Frames and size | How | Cost |
|---|---|---|---|
| Coin | 1 still, 32x32 (opaque about 16x21); the placeholder's bob stays in code | PixelLab, the sample below | 1 generation (spent) |
| Enemy hit | 4 frames, 16x16 each, one row: white-hot flash, cyan/pink spark burst, spreading shards, gone. Pop or shrink, no fade | Free script (same method as T-074's particles) | 0 |
| Enemy death | 6 frames, 32x32 each: puff of dust and sparks growing then breaking up into pixels, with a small flash | Free script first; if the board finds it too plain, 1 PixelLab call (pixflux) for a 32x32 key frame, 1 generation | 0 (or 1) |
| Car damage | 4 frames, 48x48 each, over the car: red-free cyan/white spark burst plus a few debris pixels (no Redgull red) | Free script | 0 |

Why script: these are short, abstract shapes with a few colours, and a script keeps the exact palette, no anti-aliasing and no semi-transparent pixels, as with the heart, drift smoke and level-up particles. PixelLab is best at objects with detail (the coin). Full-set estimate: 1 generation spent, 0 more planned (at most 1 more for the death key frame). Nothing hooked into the game yet.

**Planned call for the sample (written before calling):** one `/create-image-pixflux`, 32x32, no background, selective outline, detailed shading, seed 7207, view "high top-down", isometric true, direction south. Cost 1 generation. The balance before was 4919.

**Sample call made (T-072):**
- Prompt: "single gold coin standing upright on its edge seen from a 3/4 isometric angle, round gold disc with a thick dark outline, bright pale yellow shine pixels and darker amber rim, small stepped warm glow, simple pixel art game pickup, no text, no symbols"
- Negative: "text, letters, red, ground, shadow, hand, stack, background". Request: `art-archive/T-072/coin_request.json`.
- Result: `art-archive/T-072/sample/coin_sample.png` and `.json`. Logged in `game/art/pixellab-generation-log.jsonl`.
- Cost: 1 generation. Balance before 4919, after 4918. One call only, no regeneration.
- Check (`game/tools/check_sprite_rules.py ... --size 32`): all PASS: transparent corners, 0 semi-transparent pixels, 23 colours, opaque bounding box (8,6)-(23,26).
- Review image: `art-archive/T-072/coin_review_dark_light_placeholder_left_sample_right.png` (12x, nearest, dark and light backgrounds, placeholder left, sample right).

**Problems seen (not regenerated):**
- No dark outline: the rim is brown/amber, so it will be weaker against the grey asphalt than the placeholder.
- The coin is tilted diagonally and is about 16x21 px, roughly twice the placeholder's size (about 9x11); it needs scaling in the game, or a smaller 16x16 redraw.
- A few grey pixel fragments at the bottom (a stray shadow remnant) that do not belong to the coin. A free script could remove them.
- It is not a clear upright edge-on coin; it reads as a tilted disc, acceptable but not the standing coin the placeholder shows.
- Free fixes before any more paid calls: delete the grey fragments, add a dark outline pass, and downscale or redraw by script.

Status stays in-progress; nothing swapped into the game.

### Final round (board agreed: no more PixelLab calls)

- Total PixelLab use for T-072: the one coin sample call above (1 generation; balance 4919 to 4918). No other call.
- Coin: the sample was fixed by redrawing, not downscaling (a tilted 16x21 coin shrunk to 8x10 turned to mush). `game/art/effects/coin.png`, 10x12, an 8x10 hand-drawn fill in the sample's gold palette plus a dark outline, no grey strays. The old sample stays in `art-archive/T-072/sample/`. Note: art at the game's 32 px per unit is drawn at 0.5, so the sample's 16x21 was in fact close to the placeholder's on-screen size. The 10x12 coin is drawn at scale 1, like the placeholder, so its pixels look chunkier than the world's. If the board wants it consistent, redraw it at about 16x20 and draw it at 0.5.
- Hit (4 frames, 16x16), death (6 frames, 32x32, the minion's light green puff with a white core), car damage (4 frames, 48x48, white/cyan flash, cyan and pink sparks, yellow debris): scripted by `game/tools/build_hit_coin_damage_effects.py`. No red at all (the amber and brown of the coin were nudged until the Redgull-red check passed).
- Hooks (small changes): `Minion.hurt` signal (emitted when a hit leaves it alive); `MinionSpawner` plays the hit and death effects (`play_effect`); `RunState.car_damaged` signal, and `run.gd` plays the car damage effect in the view over the car; `coin_sprite.gd` draws the art. New `scripts/enemies/effect_flipbook.gd`. Behaviour unchanged: effects are visual only and pause with the tree.
- Checks: `python game/tools/build_hit_coin_damage_effects.py check` passes every frame (size, transparent corners, 0 semi-transparent pixels, colours under 30, no Redgull red). GUT: 583 of 583 pass; Python tool tests: 246 OK (1 skipped, pre-existing).
- Review images (enlarged, dark and light): `art-archive/T-072/coin_dark_light_x16.png`, `enemy_hit_dark_light_x10.png`, `enemy_death_dark_light_x6.png`, `car_damage_dark_light_x4.png`. Screenshot sequence (hit, death and coin drop, car damage): `art-archive/T-072/screenshot_sequence_hit_death_coin_damage.png`, frames in `art-archive/T-072/screenshots/`.
- Things to judge: the hit is small (16 px at scale 1, about one unit across) and quick; the death puff is the biggest effect; the car damage flash is big and cyan, covering the car's roof for about 0.1 s.

### QA round 1 (qa-integration, 2026-10-14): all criteria pass

1. **Check script: pass.** `python game/tools/build_hit_coin_damage_effects.py check` exits 0, `ALL RULES PASS`: coin (10x12, 5 colours), enemy_hit (4 frames, 2-5 colours), enemy_death (6 frames, 1-9 colours), car_damage (4 frames, 2-6 colours). Every frame: right size, transparent corners, 0 semi-transparent pixels, some opaque pixels, no Redgull red (the shared `is_redgull_red` from `build_level_up_particles.py`).
2. **PixelLab record, one round: pass.** Exactly one call for T-072 in `game/art/pixellab-generation-log.jsonl` (`/create-image-pixflux`, coin_sample, 1 generation). The result notes give the prompt, negative prompt, settings (32x32, no background, selective outline, detailed shading, seed 7207, high top-down, isometric, south; request in `art-archive/T-072/coin_request.json`), cost 1 generation, balance 4919 before and 4918 after. The hit, death, car damage and the final coin are script art (board-approved); no regeneration.
3. **Screenshot sequence: pass.** `art-archive/T-072/screenshot_sequence_hit_death_coin_damage.png` (16 frames from `screenshots/`) shows in the real game the minion beside the car, the hit flash on it (4 frames), the death puff breaking up with two coins dropping, the coins on the ground, then the cyan car damage flash and sparks over the car. Review images (dark and light) also looked at; no red seen in any of them.
4. **T-044's and T-036's tests: pass.** `test_minions.gd` and `test_run_state.gd` pass in the full run. The diff against master only adds tests (four T-072 tests at the end of `test_minions.gd`); no test line removed or changed, so nothing weakened.
5. **Full GUT suite and Python tool tests: pass.** GUT 583 of 583 (exit 0). Python: `game/tools` 246 OK (1 skipped, pre-existing), `tools` 130 OK. Note: my first two GUT runs failed 1 and 4 tests in camera/zoom settings, the car sheet byte check and pause camera controls, while another worktree (T-042, T-045) ran GUT at the same time; these tests share `user://` files across worktrees. Each passes alone, and the full suite passed 583/583 when no other GUT run was active. Not caused by T-072.

Extra checks asked for:
- **No Redgull red:** check script and review images, pass.
- **Hooks change no behaviour:** `Minion.hurt` is emitted only in the `else` branch of `take_damage` (alive after a hit); `RunState.car_damaged` is emitted after `health_changed` in `damage_car`, with the health and loss logic untouched. No file in `game/data/` or `game/scenes/` changed, and no damage, drop chance or coin number changed in the scripts. `coin_sprite.gd` only swaps the ellipse drawing for the texture (same bob and shadow).
- **Effects free themselves and pause:** `effect_flipbook.gd` advances in `_process` and calls `queue_free()` after its last frame (tested in `test_effect_frees_itself_after_its_last_frame`); it keeps the default inherited process mode under the run's pausable tree (no `PROCESS_MODE_ALWAYS` on its parents), so it pauses with the game.
- 2026-10-14, in-qa → needs-playtest: QA round 1: all five criteria pass (qa-integration).
- 2026-10-15, needs-playtest → in-progress: Board (2026-10-15): remove the effects; enemies only get a slight brief red hue when damaged; car animation to be clarified

### Round 3: the board played it and sent it back (2026-10-15)

The board's words: "regarding the effects, uh, I want you to remove the effects that you put. And the only effect that I want is that the enemies get like a slight red hue very briefly when they take damage. And the uh, also the car uh, has some like animation." Then, on the car: "a short shake or wobble of the car".

- Removed: the hit, death and car damage flipbook effects and all their hooks (`effect_flipbook.gd`, the spawner's `play_effect`, `Minion.hurt`). The drawn sheets were moved, not deleted, to `art-archive/T-072/unused_effects/` (the build script now writes them there). The first-version screenshots are in `art-archive/T-072/first_version_sequence/`. The coin art stays (the board did not mention it). Total PixelLab use is still the one coin sample call.
- Enemy hit tint (proposal): `scripts/enemies/hit_tint.gd`: tint `Color(1, 0.62, 0.62)` (a pale, slight red; multiplies the sprite, so the green minion turns olive), for 0.12 s, then back to normal. Only for a hit the enemy survives (a killing hit removes the sprite). Not Redgull red: the tint is about 0.5 away from Redgull's (0.86, 0.1, 0.16) in colour distance and only 38% saturated (a test checks both). The sprite's screenshot: `art-archive/T-072/screenshots/hit_tint_before_hit_after.png` (before, hit, 0.15 s after).
- Reuse by the kaiju: `HitTint.attach(self)` once in `_ready()` (needs a `sprite` property) and `hit_tint.flash()` in `take_damage()` when still alive. Details in game/README.md.
- With T-042's flamethrower orange flash (on master): it hits first (red) and then starts the orange burn; the tint never starts on a sprite that already has a tint, and only restores white if the sprite still has its own red. So orange wins and is never cut short; during a burn, further hits show no red.
- Car shake (proposal): when `RunState.damage_car` runs it emits `car_damaged`; `run.gd` calls `car_sprite.shake()`. 0.2 s, about 3 screen pixels at the start, 20 Hz, dying down. It only changes the sprite's `offset` (not its position, the car's physics, collisions, popups or the camera) and pauses with the game. Constants in `car_sprite.gd` (`SHAKE_SECONDS`, `SHAKE_PIXELS`, `SHAKE_HZ`) if the board wants it bigger or longer.
- Master was merged into this branch first (gun, flamethrower, combo spawning). A merge conflict on the task file's `lead:` line was resolved keeping `lead: Enemies`.
- Tests: GUT 631 of 631 pass (new: tint then back to normal, no clash with another tint, no tint on the kill hit and not Redgull red, coin art has no red, car shake moves only the drawing and settles); Python tool tests 246 OK (1 skipped, as before).

### Round 4: kaiju and the animated minion (merged master again)

- Merged master (kaiju T-045, animated minion T-068): the only conflict was the append-only PixelLab log (kept both sides). T-068's `minion_sprite.gd` needed no change: the tint is a `modulate` on the sprite node, which tints everything it draws.
- Kaiju: `kaiju.gd` now does `HitTint.attach(self)` in `_ready()` and `hit_tint.flash()` in `take_damage()` while alive. Test: `test_a_damaged_kaiju_is_tinted_briefly_then_back_to_normal` in `tests/unit/enemies/test_kaiju.gd`; the minion's is in `test_minions.gd`.
- Screenshot: `art-archive/T-072/screenshots/hit_tint_before_hit_after.png`: in a run, one minion tinted next to three normal ones (before, just hit, 1 s later). Fixture `tests/fixtures/effects_demo.tscn`.
- Tests: GUT 661 of 661 pass; Python tool tests 251 OK (1 skipped). A cleanup `rm` of the old screenshots was refused by the safety check; it was not needed (the new shots overwrite the same names) and nothing was deleted.

### QA round 2 (qa-integration, 2026-10-15): all six current criteria pass

1. **Coin check script: pass.** `python game/tools/build_hit_coin_damage_effects.py check` exits 0, `ALL RULES PASS`: coin 10x12, transparent corners, 0 semi-transparent pixels, 5 colours, 109 opaque pixels, no Redgull red. (It also still checks the archived sheets in `art-archive/T-072/unused_effects/`; all pass.)
2. **PixelLab record and archive: pass.** `game/art/pixellab-generation-log.jsonl` has exactly one T-072 entry (`/create-image-pixflux`, `coin_sample`); the result notes give its prompt, negative prompt, settings, cost (1 generation) and balance 4919 before, 4918 after. The removed hit, death and car damage sheets are in `art-archive/T-072/unused_effects/` (png + json each), their review images and the first-version screenshots in `art-archive/T-072/`; nothing deleted. Nothing in `game/` loads them: no `.gd`, `.tscn`, `.tres` or `.json` refers to `enemy_hit`/`enemy_death`/`car_damage` art, `effect_flipbook`, `play_effect` or a `hurt` signal (the only `enemy_hit` match is the flamethrower's own unrelated signal), and `game/art/effects/` holds only coin, drift and level-up art.
3. **Hit tint test, not Redgull red: pass.** `test_a_damaged_minion_is_tinted_briefly_then_back_to_normal` (`test_minions.gd`) and `test_a_damaged_kaiju_is_tinted_briefly_then_back_to_normal` (`test_kaiju.gd`): tinted at once, still tinted halfway through 0.12 s, white again after. `test_the_kill_hit_does_not_tint_and_the_tint_is_not_redgull_red`: `TINT` `Color(1, 0.62, 0.62)` is more than 0.5 from Redgull (0.86, 0.1, 0.16) and under 40% saturated. **Flamethrower:** `exhaust_flamethrower.gd` calls `take_damage` (red tint) then `_start_burn` (orange `modulate`); `HitTint` restores white only if the sprite still shows its own tint, and never starts on a sprite already tinted, so the orange is never replaced or cut short, and the burn's own end sets white as before. `test_hit_tint_leaves_another_tint_alone` covers both orders.
4. **Car shake: pass.** `test_car_damage_shakes_only_the_drawn_car_then_settles`: `damage_car` starts the shake, the sprite's `offset` moves while its `position` and the car body's position stay, and it settles back to the base offset. Code read: `car_sprite.gd` changes only `offset` (`_base_offset` + shake); `run.gd` only calls `car_sprite.shake()` from `RunState.car_damaged`; the camera and popups read `car_sprite.position`, never `offset`; `run_state.gd` only adds the signal emit after `health_changed`, with health and loss logic untouched. **Gap:** the agent's test does not check pause or the camera. I checked both with a temporary GUT test (not committed, removed after): with the tree paused, `car_sprite.can_process()` and the minion's `hit_tint.can_process()` are false (both inherit the run's pausable mode; no `PROCESS_MODE_ALWAYS` above them), and the camera's and car body's global positions are unchanged during a shake. 2 of 2 passed. Suggest adding a pause assertion to the shake test in a later change.
5. **Round 1 effects gone, screenshot: pass.** See 2 for no leftover effects or hooks (the spawner and `minion.gd` have no T-072 change beyond the tint). `art-archive/T-072/screenshots/hit_tint_before_hit_after.png`: in the real run, three panels; the middle one shows one minion turned olive/brown next to normal green ones, and before and 1 s after all are green. The tint reads as olive on the green minion rather than red (a multiply); the board judges whether that is red enough.
6. **Earlier tests, full GUT, Python: pass.** Full GUT suite: 661 of 661 pass (includes `test_minions.gd` for T-044, `test_kaiju.gd` for T-045, `test_run_state.gd` for T-036); no camera or settings test failed this time. Python: `game/tools` 251 OK (1 skipped, pre-existing), `tools` 171 OK. The diff against master only adds test functions; none removed or weakened.

Extra checks:
- **No data numbers changed:** `git diff master HEAD -- game/data` is empty; no `game/scenes` change either.
- **Merge from master:** no conflict markers in the tree (`git grep` for `<<<<<<<`, `=======`, `>>>>>>>` lines: none; `git diff --check master HEAD` clean). The generation log keeps all 65 of master's lines and adds the one T-072 line (66).
- **Process note:** a first temporary pause test used `await` with the tree paused, which also paused GUT's own wait; that headless Godot run in this folder (started by QA) hung, and stopping it was refused by the permission check, so it may still be running. It does not touch the repo; it holds no files other runs need beyond GUT's `user://` settings.
- 2026-10-15, in-qa → needs-playtest: QA round 2: all six current criteria pass (qa-integration)
