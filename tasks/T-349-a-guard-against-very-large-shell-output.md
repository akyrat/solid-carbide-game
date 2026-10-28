---
id: T-349
title: Token spend: a guard against very large shell output
status: done
from: project-lead
to: project-lead
lead: Tokens
epic: token-spend
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/test_guard.py, .claude/settings.json]
files_expected_to_change: [.claude/hooks/board_gate.py, tools/test_guard.py, tasks/README.md]
model: sonnet
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

Shell output was about 33 MB across the sessions, and whole docs printed with `cat` or `sed` were among the largest results; whatever lands in a conversation is re-sent on every later call. The board's idea (2026-10-28): when a command would print too much, don't let it into the conversation as is.

First find out, from the Claude Code hooks documentation, what a hook can do here: refuse a command before it runs (PreToolUse) and say why, or also shorten its output after it ran (PostToolUse). Write the answer in the result notes with the source.

Then build the cheap part: a PreToolUse check (in the existing guard or beside it) that refuses a shell command printing a whole file over a size limit (for example `cat`, `type`, `Get-Content`, or `sed -n` over more than a few hundred lines, of a file over 20 KB), and tells the agent to use a line range, a search, or the Read tool with an offset and limit. Small files and commands already capped (`head`, `tail`, `| head`) pass. Propose the limit in the result notes.

The board's further idea, a Haiku agent summarising large output for the agent to double-check, is a later step: describe in the result notes whether hooks allow it and what it would cost, and don't build it.

Part of the token-spend epic (board, 2026-10-28; `tasks/README.md`, "Epics and milestones"). The evidence behind it is the Tokens session's recon of 2026-10-28 (summarised in `docs/timeline.md`, "2026-10-28: The token-spend epic"). Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes say what PreToolUse and PostToolUse hooks can do with shell output, citing the documentation. (QA: pass)
- [ ] `cat` of a file over the limit is refused with a message naming the alternatives; `cat` of a small file, `head -50` of a big one and `grep` on a big one pass (a guard test each). (QA: pass)
- [ ] The result notes cover the Haiku-summary idea (possible or not, cost) without building it. (QA: pass)
- [ ] Every existing guard test still passes unchanged. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-28, Open → In progress

Started: the agent is adding the guard against very large shell output.

### 2026-10-28, In QA

Built: the guard now refuses printing whole files over 20 KB and names the cheaper ways to read them. All three test sets pass. QA is checking it now.

**QA (round 1): pass on all five criteria.** Counts: tools 532 OK, game/tools 620 OK (1 skipped), GUT 1735/1735. BigOutput tests cover cat big/small, head, grep; hooks doc cited; Haiku idea documented, not built; existing guard tests unchanged and passing.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Built (agent).** Nothing to picture (no visuals).

1. What hooks can do (source: Claude Code hooks reference, https://code.claude.com/docs/en/hooks). PreToolUse runs before the command: it can refuse it (`hookSpecificOutput.permissionDecision: "deny"` plus `permissionDecisionReason`, which Claude sees), or rewrite the input (`updatedInput`, replaces the whole input object, so a hook could wrap a command in `| head -n 300`). PostToolUse runs after the command and cannot undo it, but can replace what Claude sees: `updatedToolOutput` "replaces the tool's output ... before it is sent to Claude" and works for built-in tools; for Bash the value must match the output shape `{stdout, stderr, interrupted, isImage}`, otherwise it is ignored. It can also add `additionalContext` (max 10,000 chars). So both refusing before and shortening after are possible; I built only the refusal, as asked.
2. Built: `big_read_reason()` in `.claude/hooks/board_gate.py`, called first in `pre_shell`. Refuses `cat`, `type`, `Get-Content`/`gc`, `more`, `bat` on a file over 20 KB, and `sed -n` with a range over 300 lines (or plain `p`) on such a file. The message names the Read tool with offset and limit, grep/Grep, and a line range of at most 300 lines. Passes: small files, a printer followed by a pipe (`| head`, `| grep`), output redirected to a file, `Get-Content -TotalCount/-Tail/-Head`, `head`, `tail`, `grep`, `sed -n '10,60p'`, missing files. Files are looked up in the working folder and any `cd` target.
3. Proposed limits: file over 20 KB (about 5,000 tokens); sed ranges over 300 lines. Constants `BIG_FILE_BYTES` and `BIG_SED_LINES`. Known gaps (cheap guard only): output of other commands (test runs, `git merge` warnings, `git diff`) is not limited; `cat a b` of many small files, and `python -c` printing a file, pass.
4. Haiku-summary idea (not built). Possible: a PostToolUse command hook can run `claude -p --model haiku` on the stdout and return `updatedToolOutput` with the summary (plus the saved full output's path), or a `prompt`/`agent` hook type could do it. Cost: each large output is paid once more as Haiku input (cheap per token, but a call adds seconds of latency), and the main agent sees a summary it cannot trust to be complete, so it must re-read parts. Risks: hiding error lines, and the original output is gone from the conversation unless the hook saves it to a file. Worth trying only for a threshold such as output over 20 KB, after the refusal guard has shown how often large output remains. The better first step is likely a PostToolUse truncation (head and tail with a pointer to a saved file) with no model call.
5. Tests: `BigOutput` class in `tools/test_guard.py` (3 tests: big cat refused with alternatives named; type/Get-Content/gc/sed wide/multi-file/cd refused; small cat, head -50, tail, grep, piped, sed range, TotalCount, redirect, missing file, git log pass). All earlier guard tests unchanged and pass (74 in test_guard). Docs: `tasks/README.md` gets one paragraph before the second-guard paragraph.
6. Test sets: `game/tools` 620 tests OK (1 skipped); `tools` 532 tests OK; `bash game/tools/run_tests.sh` TESTS PASSED (Godot leak warnings at exit are pre-existing).
- 2026-10-28, in-qa → done: QA pass
