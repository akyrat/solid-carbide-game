---
id: T-180
title: Goal runner: the goal check gets the pre-approved list and blocked field, and the runner syncs the docs first
status: in-progress
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, tools/goal_agent/loop.py, tools/goal_agent/build.py, tools/goal_agent/test_loop.py, tools/generate_long_gdd.py, tools/update_short_gdd_fingerprint.py, goals/G-002-add-an-image-of-the.md]
files_expected_to_change: [tools/goal_agent/loop.py, tools/goal_agent/build.py, tools/goal_agent/fake_team.py, tools/goal_agent/fixtures/, tools/goal_agent/test_*.py]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

G-002 built all 11 tickets, then paused in the goal check (`goals/G-002-add-an-image-of-the.md`, "Pauses"): the QA session that checks the goal's own criteria ran chained commands that aren't pre-approved, and its prompt and schema missed what T-177 and T-178 gave the ticket sessions (the pre-approved list, and `blocked`), so any refusal paused the goal. One goal criterion also needs the docs staleness check, which only the Project Lead runs (`python tools/generate_long_gdd.py --check`, not on the agents' list; T-176 hit the same). The board wants runs to finish on their own (2026-10-18).

1. **The goal check like the ticket sessions.** `goal_check` in `loop.py` gives its QA session the same pre-approved-commands note as the agent and QA prompts (`build.pre_approved_note`), and its schema a required boolean `blocked` with the same meaning; its refusals go through the same rule (logged when not blocked, pause when blocked or missing).
2. **The runner syncs the docs before the goal check.** In the goal's build folder the runner (its own process, through `Shell`) runs `python tools/generate_long_gdd.py --check`; if anything is stale it runs `python tools/generate_long_gdd.py` and `python tools/update_short_gdd_fingerprint.py`, commits the changed docs on the goal's build branch (staging only those files), and checks again. The result (the check's output) goes into the goal check's prompt, which tells QA to use it for any criterion about the docs being in sync instead of running the scripts. A failing or refused command still pauses, as for any `Shell` command.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with no Claude or network calls (QA: pass / fail)
- [ ] A test shows the goal check's prompt holds the pre-approved note and the docs check result, and its schema requires `blocked`; a goal check reporting a refusal with `blocked` false still ends the goal `ready-to-play` when every criterion passes, and one with `blocked` true pauses it (QA: pass / fail)
- [ ] A test (temporary repo, the two docs scripts faked or real) shows stale docs are regenerated and committed on the goal's build branch before the goal check, and docs already in sync are left alone with nothing committed (QA: pass / fail)

## Updates

### 2026-10-18, Open → In progress

Quick fix started: the goal check gets the pre-approved list and the blocked field, and the runner syncs the docs before it. Then G-002 resumes at its goal check.

## Result notes

What changed:
- `loop.py`: `CHECK_SCHEMA` requires a boolean `blocked`; `check_prompt` carries the pre-approved note (`build.pre_approved_note`), the skip-if-not-essential and `blocked` wording, and the docs check result with an instruction to use it instead of running the docs scripts; `goal_check` logs refusals QA got past (`build.check_refusals`: pause when blocked or missing). New `sync_docs`: runs `generate_long_gdd.py --check` in the goal's build folder through `Shell.run(check=False)` (exit 1 = stale is the only non-zero exit allowed; any other exit pauses as a `command` pause; `Shell` is unchanged), if stale runs `generate_long_gdd.py` and `update_short_gdd_fingerprint.py`, commits only the changed `docs/` files on the goal's build branch, checks again.
- `build.py`: `check_refusals` docstring corrected.
- `temp_repo.py`: the temporary repo now holds the two docs scripts and a small in-sync sample doc, long GDD and short GDD fingerprint. `fixtures/whole-goal.json` and the `check()` helper in `test_loop.py` give the goal check answer `blocked`. `fake_team.py` needed no change.

Tests (all in `tools/goal_agent/test_loop.py`, class `GoalCheck`):
- Criterion 1: full suite, 319 tests, all pass, no Claude or network.
- Criterion 2: `test_the_prompt_holds_the_pre_approved_note_and_the_docs_result_and_the_schema_requires_blocked`, `test_a_refusal_the_goal_check_got_past_is_logged_and_the_goal_is_ready`, `test_a_blocked_goal_check_pauses`, `test_a_goal_check_refusal_without_blocked_pauses`.
- Criterion 3: `test_stale_docs_are_regenerated_and_committed_on_the_build_branch_before_the_check`, `test_docs_already_in_sync_are_left_alone`, `test_a_docs_check_that_fails_for_another_reason_pauses`.

Docs: nothing changed. `docs/working-with-the-board.md` is listed as affected; the Project Lead may want a line there that the runner syncs the docs before the goal check.
