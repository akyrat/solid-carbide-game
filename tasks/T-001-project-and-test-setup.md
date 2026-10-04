---
id: T-001
title: Set up the Godot project, headless runner and test suite
status: open
from: project-lead
to: qa-integration
depends_on: []
documents_affected: [game/README.md, README.md]
files_to_read_first: [CLAUDE.md, README.md, game/README.md, tasks/_TEMPLATE.md, docs/game-loop-architecture.md]
files_expected_to_change: [game/project.godot, game/README.md, .gitignore, .env.example, the runner and test scripts this task creates]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

`game/` has no Godot project yet. Every code agent must write and run tests, and QA/Integration must run the full suite before each playtest, so the project, a headless way to run Godot and a test framework must exist before any game work starts. The board decided QA/Integration owns this setup.

This task is technical scaffolding only. It adds no game content: no scenes, mechanics, art or sounds beyond what a sample test needs.

1. Create a Godot 4.6.2 project in `game/` with a folder layout for scenes, scripts, data (JSON), art and audio.
2. Godot is not on the PATH. The console executable on the board's machine is `C:\Tools\Godot\Godot_v4.6.2-stable_win64_console.exe`. Read its location from a `GODOT_BIN` variable in `.env` at the repo root, so the path is not hard-coded in scripts.
3. Add `.gitignore` at the repo root. It must ignore `.env`, the `.secrets/` folder, Godot's `.godot/` cache and other generated files. Add `.env.example` listing every expected variable with no real values: `GODOT_BIN`, `FREESOUND_CLIENT_ID`, `FREESOUND_API_KEY`, `FREESOUND_REDIRECT_URI`, `PIXELLAB_API_KEY`. The root `README.md` section "Secrets and API keys" describes these; add `GODOT_BIN` there.
   `.env` does not exist yet. Create `.gitignore` **first**, confirm `git check-ignore .env` prints `.env`, and only then create `.env` containing `GODOT_BIN` alone. Never write any other value into `.env`: the board adds its own credentials there after this task is done. If `.env` already exists when you start, do not overwrite it; only add `GODOT_BIN` if it is missing.
4. Install a GDScript test framework (GUT or gdUnit4, your choice; give the reason in the result notes) inside the project.
5. Provide one command, run from the repo root, that runs the whole test suite headless and exits with a non-zero code when any test fails.
6. Provide one script that runs a given scene for a set number of frames and saves a screenshot to a given path, so later visual criteria can be checked from an image.
7. Add one sample test that passes, to prove the pipeline works.
8. Document in `game/README.md` how to run the tests and take a screenshot, in a form other agents can follow without asking. For `.env` setup, link to the root README's "Secrets and API keys" section instead of repeating it.

## Acceptance criteria

QA/Integration checks its own setup in this task. Every criterion is mechanical, so the result is the same whoever runs it.

- [ ] `game/project.godot` exists and reports Godot 4.6 as its engine version (QA: pass / fail)
- [ ] `.gitignore` exists at the repo root, and `git check-ignore .env .secrets/x` prints both paths (QA: pass / fail)
- [ ] `.env.example` exists and lists `GODOT_BIN`, `FREESOUND_CLIENT_ID`, `FREESOUND_API_KEY`, `FREESOUND_REDIRECT_URI` and `PIXELLAB_API_KEY` with no real values (QA: pass / fail)
- [ ] `.env` exists, is not tracked by git, and contains `GODOT_BIN` pointing to a file that exists (QA: pass / fail)
- [ ] No script contains the Godot path as a literal; it is read from `GODOT_BIN` (QA: pass / fail)
- [ ] The documented test command exits 0 with the sample test in place (QA: pass / fail)
- [ ] After a deliberately failing test is added temporarily, the same command exits non-zero; the failing test is then removed (QA: pass / fail)
- [ ] The screenshot script, run on a minimal scene, writes a non-empty PNG to the given path (QA: pass / fail)
- [ ] `game/README.md` documents the test command and the screenshot script, and links to the root README for `.env` setup (QA: pass / fail)
- [ ] The root README's "Secrets and API keys" section describes `GODOT_BIN` (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
