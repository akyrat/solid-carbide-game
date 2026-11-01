---
id: T-476
title: The browser build on itch.io plays no sound and no music
status: done
from: project-lead
to: sfx
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, docs/working-with-the-board.md, game/export_presets.cfg, game/scripts/run/run_sounds.gd, game/scripts/game/music_player.gd, tools/publish_itch.py]
files_expected_to_change: [game/scripts/run/run_sounds.gd, game/scripts/game/music_player.gd, game/export_presets.cfg, game/tests/unit/, docs/working-with-the-board.md]
model: sonnet
qa_rounds: 2
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

The board, 2026-11-01: the game on itch.io (the "Web" export preset, thread support off, Godot 4.6.2) plays no sound and no music at all; the desktop game has both.

Find the cause in a real browser: export the Web preset to a folder outside game/ (as `python tools/publish_itch.py --dry-run` does, never pushing), serve it locally over http (e.g. `python -m http.server`), open it in a browser (headless Chrome or Edge is fine), click into the game and start a run, and read the browser console for audio errors. Likely suspects to check, not conclusions: the browser's autoplay rule (audio only after a user gesture; does the game resume audio on the first click or key press?), Godot's web "sample" playback mode with threads off (what run_sounds.gd and music_player.gd do that it may not support: duplicated streams, looping, pitch, bus effects, mp3), the saved volume settings on a fresh browser, and whether the audio files are in the exported .pck.

Fix the cause so the browser build plays the music in the menus and the run's sound effects once the player has clicked or pressed a key, with no change to the desktop game's sound. Never push to itch.io (the Project Lead does it when the board asks). Never write, move or commit anything in game/data/levels/.

The board's review: after the Project Lead pushes the build, play it on itch.io and hear the music and the car.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes name the cause, with the browser console lines (or other evidence) that show it. (QA: pass)
- [ ] In a local browser run of the Web export, after one click, the menu music plays and a run's engine sound plays: shown by console or log lines the agent adds (or the Web Audio state), listed in the result notes. (QA: pass - agent's temp copy with sfx_enabled true showed the engine line; at HEAD the board's switch keeps the engine off, and my rerun showed music: contexts suspended then running, "[audio] music playing=true", buffer source 67.4 s)
- [ ] A test (or the agent's scripted browser check, saved in game/tools/) covers the fix so it can be rerun. (QA: pass - round 2: fresh export of the committed state, check prints RESULT: PASS, contexts suspended then running, music playing=true, engine line not required while sfx_enabled is false)
- [ ] The desktop game's sound is unchanged: the existing sound tests still pass. (QA: pass - layout routes SFX and Music to Master; 2396 GUT tests pass)
- [ ] docs/working-with-the-board.md ("Publishing to itch.io") notes anything about sound in the browser the board should know (for example, that sound starts after the first click). (QA: pass - line 66)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass - game/tools 777 OK (1 skipped), tools 633 OK, GUT 2396/2396)
- [ ] Nothing is pushed to itch.io, and nothing under game/data/levels/ is changed or committed. (QA: pass - nothing pushed, no change under game/data/levels/)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: the SFX Agent finds why the browser build is silent, in a local browser run.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Cause (found in a real run).** Exported the Web preset to a folder outside game/ (`godot --headless --export-release Web`), served it with node over http and drove headless Chrome through the DevTools protocol (`game/tools/web_audio_check.mjs`, no autoplay override). Not the autoplay rule: the AudioContext is `suspended` before the first click and `running` after it (Godot resumes it itself). Files are in the .pck, mp3 decodes and starts (probe: one buffer source, 67.4 s, peak 0.22) and the console had no audio errors. The real cause is the buses: `GameSettings.ensure_music_bus()` / `ensure_sfx_bus()` call `AudioServer.add_bus()` while the game runs, and in Godot's web "sample" playback (the web default) a bus added at runtime is not routed through Master. Evidence: with the old build, a tap on the Web Audio destination read output peak 0 while Godot reported `[audio] music playing=true`; the signal reached the Music bus nodes but not the destination. With the buses defined up front, the same run reads output peak 0.03 (music), 0.02 to 0.06 later.

**Fix.** New `game/default_bus_layout.tres` with the SFX and Music buses (both send to Master), so the web audio graph builds them at start; `ensure_*_bus()` find them and add nothing (desktop behaviour is unchanged: same names, same volumes, same code path). New `game/scripts/game/web_audio_log.gd` (`WebAudioLog.say`, prints `[audio] ...` on the web only), called from `music_player.gd` (`[audio] music playing=true`) and `run_sounds.gd` (`[audio] engine playing=true`).

**Browser run after one click** (`node game/tools/web_audio_check.mjs <export> --start 632,315`): `before click, contexts: ["suspended"]`, `after click: ["running"]`, console `[audio] music playing=true`, then in a run `[audio] engine playing=true`, final output peak 0.056, RESULT: PASS. To see the engine I exported a temporary copy with `sfx_enabled` true and SFX volume 100 and reverted both (nothing of that is committed).

**Board should know.** At HEAD the sound effects are off for the MVP by the board's own switch (`sfx_enabled: false` in `game/data/sfx.json`, T-388) and the SFX volume defaults to 0, so the desktop game also plays only music until that switch is turned on; I did not change it. Documented in docs/working-with-the-board.md ("Publishing to itch.io"): sound starts after the first click.

**Tests.** `game/tests/unit/test_web_audio_buses.gd` (GUT) and `game/tools/test_web_audio_check.py`. Counts: see the last line below.

**Test counts:** game/tools unittest 777 OK (1 skipped); tools unittest 633 OK; GUT 2396 of 2396 passing (199 scripts, includes the 4 new tests), TESTS PASSED. Nothing pushed; nothing under game/data/levels/ touched.
- 2026-11-01, in-progress → in-qa: Web build silent: runtime-added buses not routed in web sample mode; fixed with default_bus_layout.tres; browser check passes
- 2026-11-01, in-qa → in-progress: QA fail (code): web_audio_check.mjs prints RESULT: FAIL on the committed state because sfx_enabled is false so no engine line appears; require the engine line only when SFX are on. All else passes.

### QA round 1 fix (criterion 3)

The check no longer requires the engine line when the sound effects are off. `game/tools/web_audio_rules.mjs` holds the pass rule (`verdict`) and reads `sfx_enabled` from `game/data/sfx.json` (`sfxEnabledFrom`); `--sfx on|off` overrides. Music line plus a running context always; the engine line only when `sfx_enabled` is true. The switch and the SFX default volume are untouched (the board confirmed on 2026-11-01 that sound effects stay off). Master merged into the branch (the only snag was an untracked .uid file; no conflicts). Python tests added for both cases (`game/tools/test_web_audio_check.py`).

Browser check on the committed, merged state (fresh Web export):
```
before click, contexts: ["suspended"]
after click, contexts: ["running"]
final contexts: ["running"] buffer sources started: 1 worklet nodes: 2 output taps: 2 output peak: 0.048
log: [audio] music playing=true
sfxOn: false | SFX are off by the board's switch (sfx_enabled false in data/sfx.json, T-388): the engine line is not required
RESULT: PASS
```
(Earlier, with the switch temporarily on, the engine line `[audio] engine playing=true` appeared in a run.)

Test counts after the merge: game/tools unittest 865 OK (1 skipped); tools unittest 633 OK; GUT 2516 of 2516 passing (212 scripts), TESTS PASSED (GUT_TIME_LIMIT=1800).
- 2026-11-01, in-progress → in-qa: Browser check now requires the engine line only when sfx_enabled; passes on the merged build; all three test sets green
- 2026-11-01, in-qa → needs-playtest: QA round 2 passed: web check RESULT: PASS on a fresh export, 3 test sets green
- 2026-11-01, needs-playtest → done: Merge and push
