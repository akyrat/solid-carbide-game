---
id: T-291
title: "The style loop: generate, evaluate with a score and a reason, refine below 8"
status: in-qa
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-290]
documents_affected: [tasks/README.md, docs/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/visual-style.md, docs/extended-narrative.md, .claude/agents/style-evaluator.md, tools/goal_agent/claude_call.py, tools/goal_agent/try_fixture.py, tools/task_status.py, game/tools/pixellab_client.py, game/tools/style_rules.py]
files_expected_to_change: [tools/style_loop/, tasks/README.md, docs/README.md]
model: opus
qa_rounds: 0
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

Second of three tickets for the style loop. The loop's rules are in `tasks/README.md`, "The style loop"; this ticket builds the tool that runs them, with no one stepping in:

1. **Generate:** the task's agent makes the asset or text from a brief: the Asset Generation Agent for art (a PNG, through PixelLab or a script), the Narrative Theme Agent for text.
2. **Evaluate:** `style_rules.py` (T-290) runs its script checks, then the Style Evaluator agent (`.claude/agents/style-evaluator.md`) scores the version from 1 to 10 against Visual style, Content, "Rules" or Extended narrative, Content, "Text rules", and gives the reason: which rules it breaks and how. For art it looks at the image itself.
3. **Refine:** below 8, the same agent, resumed in the same session so it remembers what it made, gets the reason and makes a new version. Art: free script fixes before a paid regeneration.
4. **Stop:** at 8 or more; or after 3 refines, keep the best-scoring version and flag the task for review (`task_status.py <id> flagged-for-review`).

**Keep it small and reuse what exists:**
- Every Claude call goes through `tools/goal_agent/claude_call.py` (`RealClaude` with `agent=`, `FakeClaude` for tests). No second way of calling Claude.
- The evaluator answers in a JSON schema: `score` (1 to 10), `reason`, and the rule numbers broken.

**The record.** The tool writes each round into the task's `## Style review` section, the evidence for the board and for the course:
- the round, the version (the text itself, or the file path),
- the script checks, the score and the reason,
- for a refine, what changed;
- a last line saying which version was kept and its score.

Every art version is kept in `art-archive/<task id>/style-loop/` (never deleted). The kept version goes where the brief says.

**A fake mode** (`--fake <fixture>`, like `tools/goal_agent/try_fixture.py`) runs a whole loop with `FakeClaude` and no PixelLab, so the loop can be shown and tested for free.

## Acceptance criteria

- [x] `python tools/style_loop/run.py art --task T-NNN --brief <file> --out <png>` and `python tools/style_loop/run.py text --task T-NNN --brief <file>` exist and run the four steps above; the generator and refiner are the same agent session (resumed), and the evaluator is the `style-evaluator` agent. (QA: pass; run.py art/text exist, loop resumes the same generator session, evaluator is style-evaluator (test_the_generator_is_one_session_resumed_and_the_evaluator_is_the_style_evaluator))
- [x] The tool calls Claude only through `tools/goal_agent/claude_call.py` (`grep -rn "claude -p\|subprocess" tools/style_loop/` shows no other call to Claude). (QA: pass; grep for claude -p / subprocess in tools/style_loop finds nothing, calls go through claude_call)
- [x] With a fake fixture where versions score 4, 6 and 9, the run stops after the third version, keeps it, and the task's `## Style review` section has three rounds, each with the version, the script checks, the score, the reason, and (rounds 2 and 3) what changed. Shown by a unit test on a temporary copy of a task file. (QA: pass; test_scores_4_6_9 and test_the_style_review_has_every_round_with_its_parts pass on a sandbox copy)
- [x] With a fake fixture that never reaches 8, the run stops after 3 refines (4 versions), keeps the best-scoring one, and the task is set to `flagged-for-review` through `task_status.py`. Shown by a unit test. (QA: pass; test_never_reaching_8_keeps_the_best_of_4_versions_and_flags_the_task passes)
- [x] Every art version of a run is saved in `art-archive/<task id>/style-loop/`, none deleted. Shown by a unit test. (QA: pass; test_every_art_version_is_saved_in_the_archive_and_the_kept_one_goes_to_out and test_an_earlier_run_is_never_overwritten pass)
- [x] `python tools/style_loop/run.py text --task T-NNN --brief <file> --fake <fixture>` runs end to end without Claude, and the fixture is committed. (QA: pass; fake command ran end to end (4, 6, 9, kept version 3), fixtures committed, real ticket's Style review stays empty)
- [x] All three test sets pass. (QA: pass; tools 478 OK, game/tools 409 OK (1 skipped), GUT 1419/1419)
- [x] `tasks/README.md`, "The style loop", gives the commands, and `docs/README.md` lists the tool with the other tools. (QA: pass; tasks/README.md 'The style loop' lists the commands and docs/README.md lists the tool)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-25, Open → In progress

Started: the style loop tool (generate, evaluate with a score and reason, refine below 8, at most 3 refines, every round written in the ticket). Opus agent in C:\solid-carbide-worktrees\T-291.

### 2026-10-25, In progress → In QA

Built and reworked: the loop runs end to end in fake mode from the shell; it writes the ticket only through the status script, and the guard is unchanged. Tests 478 / 409 / GUT 1419 pass. Now with QA.

## Result notes

**Built** (all in `tools/style_loop/`, plus two small additions to shared code):
- `loop.py`: the four steps. Generate (asset-generation for art, narrative-theme for text, `session_id=<new uuid>`), script checks (`style_rules.text_checks` / `art_checks`, imported, no subprocess), evaluate (`style-evaluator`, tools `Read,Glob,Grep`, JSON schema `score` 1-10, `reason`, `rules_broken`), refine below 8 by resuming the same generator session (`resume=<uuid>`) with the score, reason, rules and failed script checks; at most 3 refines; keeps the best (earliest on a tie). Each round is written into `## Style review` as it ends (version text or archived file, what changed for rounds 2+, script checks, score, reason, rules broken, any refusals), then a `**Kept:**` line. Art: the agent is asked to save at `art-archive/<task>/style-loop/v<N>.png`; a file saved elsewhere is copied there; an earlier run's file is never overwritten (`v1-2.png`); the kept PNG is copied to `--out`.
- `run.py`: the command line (`art` / `text`, see `tasks/README.md`, "The style loop"). `--fake <fixture>` uses `FakeClaude` and runs in `task_status.sandbox`: a copy of the task file in a new temporary folder, with the status script's paths pointed there, so a fake run never changes the real task; archive and `--out` go into that folder too.
- `fixtures/text-4-6-9.json` (keeps version 3), `fixtures/text-never-8.json` (scores 5, 7, 6, 4: keeps version 2, flags), `fixtures/sample-brief.md`.
- `tools/goal_agent/claude_call.py`: `RealClaude.ask(..., resume=<session id>)` adds `--resume`; the only way to carry on a session, so refines remember what was made (test added in `test_claude_call.py`).
- `tools/task_status.py`: `set_section(text, heading, body)` (replaces a section, or adds `## Style review` before `## Result notes`, keeps CRLF and the header); `write_section(task_id, heading, body)` (finds the ticket by id where it lives and writes the section); `task_checkout(task_id)`; `sandbox(task_id | text=..., keep=True)`; and `move(..., by="style-loop")` allows `in-progress` → `flagged-for-review`, which the loop uses to flag (board approved, 2026-10-25; status rules in `tasks/README.md` updated).

**Rework (board, 2026-10-25):** the first version's `run.py` was refused by the guard ("its code names task files and writes files"). The board kept the guard unchanged; now no module in `tools/style_loop/` names the tasks folder or a ticket path or writes a ticket: finding the ticket, writing `## Style review`, the fake sandbox and the flag all go through `task_status.py` (`write_section`, `task_checkout`, `sandbox`, `move`). The tests also use `task_status.sandbox`. Helper tests added in `tools/test_task_status.py` (`StyleLoopHelpers`, 6 tests; the `set_section` tests moved there from `test_loop.py`). No hook or settings changed.

**Run:** `python tools/style_loop/run.py text --task T-NNN --brief tools/style_loop/fixtures/sample-brief.md --kind popup --fake tools/style_loop/fixtures/text-4-6-9.json`.

**Fake demo** (from the shell, exactly that command with T-291; the guard let it run): it printed "Fake run on a copy of T-291: C:\Users\andre\AppData\Local\Temp\task-sandbox-f6b7wody", then Round 1 4/10 (3 of 5 script checks pass: rule 4 capitals and "!" fail), Round 2 6/10 (4 of 5: "!" fails), Round 3 9/10 (5 of 5), "Kept version 3, score 9/10: \"SAMPLE COMBO!\"", exit 0. The copy's `## Style review` holds the three rounds (version, what changed for 2 and 3, script checks, score, reason, rules broken) and the `**Kept:**` line; this ticket was not changed.

**Tests:** 20 in `tools/style_loop/test_loop.py`, 6 in `tools/test_task_status.py` (`StyleLoopHelpers`), 1 in `tools/goal_agent/test_claude_call.py`, all discovered by the tools set. `tools`: 478 OK; `game/tools`: 409 OK (1 skipped); GUT: 1419/1419 passing. `grep -rn "claude -p\|subprocess" tools/style_loop/` finds nothing.

**Screenshots:** none, tooling.
