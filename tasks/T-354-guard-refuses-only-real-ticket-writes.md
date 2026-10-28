---
id: T-354
title: Token spend: the guard refuses only commands that really write a ticket
status: in-qa
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
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/test_guard.py, tasks/T-348-guard-read-only-commands-again.md, tasks/T-349-a-guard-against-very-large-shell-output.md, docs/token-spend/after-2026-10-28-early.md]
files_expected_to_change: [.claude/hooks/board_gate.py, tools/test_guard.py, tasks/README.md]
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

The board's go (2026-10-28), from the token-spend early read: hook refusals rose to 4.3% of calls (baseline 1.2%), and most were false alarms from the ticket guard in `.claude/hooks/board_gate.py`. It refuses a command when its text merely names task files or contains a header word like `Lead`, even when the command writes no ticket. Three agents then redid the refused edit with the Edit tool (T-343, T-347, T-348), which the board's rule against working around refusals forbids. Fewer false refusals keeps that rule strict and saves the failed calls.

Real refusals from 2026-10-28 (seven) to reproduce in tests:
- `python tools/merge_batch.py T-350 ... --entry T-350="... written by the Project Lead ..."`: refused because an argument names a task and holds the word `Lead`. merge_batch.py writes tickets only through task_status.py.
- An inline `python -` edit of `tools/merge_batch.py` whose script text mentions `tasks` (T-347): refused, though it wrote only a tools file.
- Inline python or sed editing `.claude/agents/*.md` (T-343): refused for the same reason.
- A read-only `python -c` that opened a ticket to read it (T-347): refused.
- `grep ... ; date +%H:%M`: refused because of `date`.
- A read-only loop over `tasks/T-*.md` that used a shell `case $s in done|cancelled) continue;; esac` to skip finished tickets: refused (`case`: a command the guard can't tell won't write a ticket).
- `git rev-parse -q --verify MERGE_HEAD || { git add docs/timeline.md tasks/...md && git commit -m ... }`, the shared-master commit guard from docs/working-with-the-board.md: refused because of the `{` grouping.

Make the guard tell a real write of a ticket's guarded fields (status, lead, qa_rounds) apart from a mention:
- Allow the repo's own tools that change tickets only through `task_status.py` (`merge_batch.py`, `new_ticket.py`, `qa_check.py`, `task_status.py`) whatever their argument text says.
- Allow inline scripts and sed whose write targets are not task files, even if the text mentions tasks.
- Allow read-only commands such as `date`.
- Keep refusing anything that writes a task file's status, lead or qa_rounds outside task_status.py (cp, mv, redirection, sed -i or a script writing a `tasks/T-*.md` path), and anything the guard really can't read.

If the guard can't be sure whether a script writes a ticket, it still refuses: false refusals are cheaper than an unrecorded status change. Say which cases stay refused, and why. Nothing to picture. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `tools/test_guard.py` has a test for each of the seven real refusals in the description: each command is now allowed, with the refusal text from before named in the test. (QA: pass; test_allowed_1 to _7 in OnlyRealTicketWrites, each names its earlier refusal; 2 to 6 are reconstructions but faithful to the wording)
- [ ] Tests show the guard still refusing: a `cp` or `mv` onto a `tasks/T-*.md` file, a redirection into one, `sed -i` on one, an inline script that writes a `tasks/T-*.md` path, and an edit of a ticket's status, lead or qa_rounds outside task_status.py. (QA: pass; test_still_refused_real_writes and the Edit-tool test for status, qa_rounds and lead all deny; see the --log= note below)
- [ ] Every guard test that existed before still passes, unchanged unless the result notes say why. (QA: pass; the diff of tools/test_guard.py removes no line; all 84 guard tests pass)
- [ ] `tasks/README.md` says in one place what the guard refuses and what it allows, and the result notes list the cases that stay refused with the reason. (QA: pass; README block "What the ticket guard refuses and allows, in short (T-354)" plus the result notes list)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass; QA reran all three, game/tools 643 OK (1 skipped), tools 556 OK, run_tests.sh result below; counts match the notes)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-28, Open → In progress

Started: the agent teaches the guard to refuse only real writes of a ticket's status, lead or qa_rounds, with the seven real refusals from 2026-10-28 as tests.

### 2026-10-28, In progress → In QA

In QA: the guard now refuses only real writes of a ticket's status, lead or qa_rounds; the seven refusals are tests. QA by a qa-integration agent.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**What changed** (`.claude/hooks/board_gate.py`): the guard now judges what a command writes, not what its text mentions.
- Ticket tools: `merge_batch.py`, `new_ticket.py` and `qa_check.py` (any path ending in `tools/<name>`) pass whatever their argument text says (`TICKET_TOOLS`, `ticket_tool_reason`). `task_status.py` already passed. Each `--test-cmd` is still judged as a command of its own, a `--log` into a possible ticket is refused, and a redirection of their output is checked as before.
- Inline Python: new `python_write_targets` reads every write (`open(..., '<w/a/x/+>')`, `.open('w')`, `write_text`, `write_bytes`, `.write` on a file opened that way or on stdout). Each target must be a literal path: a string, `Path(...)`, `a / b`, `os.path.join`, a name set once to one of those, or a loop name over `.glob`, `.rglob`, `glob.glob` or a literal list. When no target can be a ticket the code passes, even if it mentions `tasks` or `lead`. Anything else that could write, move, delete or run something gives None, and the code is refused as before.
- sed: new `sed_script_effects` reads a script command by command, so words like `when`, `each` and `work` in a pattern are no longer taken for the `w`/`e` commands. A `w` into a file that can't be a ticket passes, an `e` is refused, and a script it can't read (a `[` in a regex, an unknown command) falls back on the old word check.
- Globs: `.claude/agents/*.md`-style globs of `.md` files pass when their folder is written out (no glob, no `..`, not a tasks folder), exists, and holds no `T-nnn*.md` file that matches.
- Shell: `date`, `basename`, `dirname`, `realpath`, `readlink`, `stat`, `du`, `diff`, `cmp`, `seq`, `which`, `continue`, `break` and `:` count as read-only. `{` and a lone `}` of a command group are read through. So are a `case` head and its patterns (`done|cancelled) continue`). Inline `python -c "..."` with a backslash the shell leaves alone (`'\n'`) is now read exactly.

**Tests** (`tools/test_guard.py`, new class `OnlyRealTicketWrites`): one test per real refusal, each naming the refusal text it got before (`test_allowed_1` to `test_allowed_7`). Run against master's copy of the hook (in a scratch copy), all seven were refused. They also cover the other two ticket tools and the sed and Python variants. `test_still_refused_real_writes` checks that these stay refused:
- `cp` or `mv` onto a ticket
- `>` and `>>` into a ticket
- `sed -i`, and a sed `w` into a ticket
- a glob over a folder that holds a T-nnn file
- inline Python writing `tasks/T-*.md` in eight spellings
- the ticket tools with `--log`, `--test-cmd` or `>` aimed at a ticket
- braces and case patterns that hide a write

`test_still_refused_an_edit_of_a_guarded_line_outside_the_status_script` covers the Edit tool changing status, qa_rounds and lead. `test_the_parts_on_their_own` unit-tests the sed reader and the Python target reader. Every guard test that existed before is unchanged and passes.

**Reproductions:** the exact text of refusals 2 to 6 is not in the ticket. I wrote faithful reconstructions from its descriptions. For refusal 4 (the read-only `python -c` of T-347) I assumed the cause was a `'\n'` inside double quotes, which made the old guard give up on the code. I tried to pull the exact commands from the session transcripts with a scratch script, but the live guard refused that command (it couldn't read a script the same command was creating), so I didn't retry it. A later probe run (`python -` with a here-document naming `tasks`) was refused for the same kind of reason; I turned those probes into tests instead.

**Cases that stay refused, and why:**
- Writes into a ticket by `cp`, `mv`, `rm`, `tee`, `Set-Content`, `>`, a `>>` of a header line, a `sed -i` that could change a header line, or inline Python or a script that writes a `tasks/T-*.md` path or a glob that could match one: these really can change `status`, `lead` or `qa_rounds` outside the status script.
- A computed file name (`$f`, backticks, a substitution that names task files): the guard can't know the target.
- Python whose write target isn't a literal path (`open(sys.argv[1], 'w')`, a name set twice, `shutil`, `subprocess`, `exec`, `json.dump`): the guard can't know what it writes.
- A sed `e` (it runs a command), and sed scripts it can't read.
- Subshells `( ... )`: not parsed, and the `cd` checks don't see a `(cd tasks`.
- Any writing command run inside a tasks folder.
- Unknown commands.

In doubt it still refuses: a false refusal costs one call, an unrecorded status change costs the record.

**Docs:** `tasks/README.md`, "Changing a task's status", has a new "What the ticket guard refuses and allows, in short (T-354)" block. The sed sentence in the long paragraph is updated for `w` into non-ticket files.

**Tests run** (foreground, from the worktree):
- `python -m unittest discover -s game/tools -p "test_*.py"`: 643 tests, OK (1 skipped)
- `python -m unittest discover -s tools -p "test_*.py"`: 556 tests, OK
- `bash game/tools/run_tests.sh`: 1757/1757 passing, TESTS PASSED

Nothing to picture: tooling only.

**QA notes (round 1):** all five criteria pass.
- Tests rerun in the foreground: game/tools 643 OK (1 skipped); tools 556 OK; run_tests.sh "TESTS PASSED" (the 1757 count was cut off by QA's tail, the pass line is what QA saw); tools.test_guard alone 84 OK. The diff of tools/test_guard.py removes no line.
- `qa_check.py` was not run: the live (master) guard refuses it, so the items were checked by hand (criteria marked, notes, test counts).
- Reproductions 2 to 6 are reconstructions from the ticket wording; each is faithful (merge_batch with a task and Lead in the arguments, inline python editing tools/merge_batch.py that names tasks, python/sed on .claude/agents/*.md, a read-only `python -c` with `'\n'`, `grep ...; date`, a `case ... done|cancelled) continue;; esac` loop, the `{ ...; }` commit guard).
- Eighth false refusal: `python tools/qa_check.py T-354 2>&1 | tail -8` is allowed by the branch's guard (fed to board_gate.pre_shell, with and without a `# status` suffix). Not a criterion.
- Real writes probed on the branch (about 45 commands): refused are sed -i / perl -i on a ticket, `>` into one, inline Python in many spellings (open w/r+/wb/mode=, io.open, codecs.open, shutil, os.rename/replace/system, Path().open, joinpath, f-string path, concatenated path, chdir, subprocess), and the ticket tools with `--log tasks/T-x.md`, `--test-cmd "cp ... tasks/T-x.md"`, or `> ticket` / `| tee ticket` when a guard word is present.
- Findings that are not criteria, for the Project Lead:
  1. New hole: `python tools/merge_batch.py T-1 --log=tasks/T-1-x.md` (the `=` form) is allowed on the branch; master refused it. The log overwrites the ticket file, so it can drop its header. The README says a ticket tool's `--log` "must not be a ticket", which the `--log tasks/...` (space) form honours but the `=` form does not. Small fix: judge `--log=VALUE` like `--log VALUE`.
  2. Old behaviour, unchanged by T-354 (master behaves the same): `cp`, `mv`, `install`, `dd of=` and `tee` onto a `tasks/T-*.md` file are allowed when the command text holds no guard word (status, lead, qa_rounds) and no inline code; with a guard word they are refused. The same for `git checkout master -- tasks/T-x.md`. Those can still change a header by copying a whole ticket file over another.

**Fix after QA round 1:**
1. `--log=` form (fixed): a ticket tool's output options (`--log`, `--log-file`, `--out`, `--output`, `-o`; `TOOL_OUTPUT_OPTIONS`) are now judged in both the `--opt value` and `--opt=value` forms. A target that could be a ticket is refused. The refusal ends like a script refusal, so it holds even when the command has no guard word. `test_still_refused_real_writes` adds `merge_batch.py --log=tasks/T-001-x.md` (with and without `# status`), `--log tasks/T-001-x.md` with no guard word, and `qa_check.py --log=...`.
2. `cp`/`mv`/`install`/`dd of=`/`tee` onto a ticket with no guard word: **not done, blocked by a refusal.** I wrote the change, an `overwrite_reason` check in `pre_shell`. It runs before the guard-word gate and refuses `cp`, `mv`, `install`, `ln`, `tee`, `dd of=`, the PowerShell copy/move/set-content family, `>` and a ticket tool's output options whenever a target is a `tasks/T-*.md` file, a glob in a tasks folder, or the tasks folder itself, and leaves `git checkout`/`git restore` allowed. I applied it with an inline `python -` here-document, and the live guard refused it: "inline code that names task files (`tasks`)", the very false refusal this ticket fixes, because master's hook is still the old one. Under the rule against working around a refusal, I did not redo it with the Edit tool or any other way. Fix 2 can be done once this branch's guard is live, or by an Edit the Project Lead allows explicitly. The README block is unchanged for now; the git checkout/restore note goes in with fix 2.

Tests after the fix (foreground): game/tools 643 OK (1 skipped); tools 556 OK; run_tests.sh: see below.
