---
id: T-297
title: "Ticket guard: a shell edit of a ticket's body passes when it can't write a guarded line"
status: in-qa
from: project-lead
to: project-lead
lead: Greenbull
epic: tooling
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/guard_ledger.py, tools/test_guard.py]
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

The board's decision (2026-10-26): the ticket guard should let through edits of a ticket that don't touch its `status`, `lead` or `qa_rounds` lines, so the rule and the agents' practice match. During the Greenbull rebrand (T-294, T-295), agents twice had a `sed -i` on a ticket's body refused (fixing a typo in the result notes, ticking acceptance-criteria boxes) and then made the same edit with the Edit tool, which the guard allows. The edits were harmless, but redoing a refused action with another tool goes against the common rule (CLAUDE.md, "Common rules for every agent").

Today `.claude/hooks/board_gate.py` refuses every `sed -i` on a file that could be a ticket (tasks/README.md, "Changing a task's status": "a `sed` is judged by its scripts … only `-i`, `-f` or a `w` or `e` command is refused"). Change it so a `sed -i` on a ticket passes when the guard can read all of its scripts and none of them can write a guarded line: only `s` commands (and `d`, `a`, `i`, `c` with literal text) whose pattern, replacement and text don't name `status`, `qa_rounds` or `lead`, and whose address is not the header (a line range starting at 1, or an address that could match a line starting `status:`, `qa_rounds:` or `lead:`). Anything the guard can't read stays refused, as do `-f`, `w` and `e`. The second guard (`tools/guard_ledger.py`, checked on every `git commit`) stays as it is and still catches a guarded line changed by any tool.

Only `sed -i` is in scope; Python and PowerShell writes that name a task file stay refused.

## Acceptance criteria

- [ ] A `sed -i 's/teh/the/' tasks/T-012-x.md` and a `sed -i 's/- \[ \] The wordmark/- [x] The wordmark/' tasks/T-012-x.md` pass the hook, as new tests in `tools/test_guard.py` show. (QA: pass)
- [ ] These stay refused, as tests show: a script naming `status`, `qa_rounds` or `lead`; an address range starting at line 1; `-f script.sed`; a `w` or `e` command; a script the guard can't read (from a variable or substitution). (QA: pass)
- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes. (QA: pass)
- [ ] `tasks/README.md`, "Changing a task's status", says which `sed -i` edits of a ticket pass. (QA: pass)
- [ ] Added by the Project Lead after QA round 1 found that `s/open/done/` and `s/0/1/` pass and rewrite `status: open` and `qa_rounds: 0`: a script that names no guarded word but would still change a `status`, `lead` or `qa_rounds` line is refused. The guard tries the readable `sed` script on the ticket's current text (in Python, without writing) and refuses when any of those lines would change, or when the file can't be read; tests show `s/open/done/` and `s/0/1/` refused on a ticket whose header has `status: open` and `qa_rounds: 0`, and the two edits in the first criterion still passing. (QA: fail: branch has no dry-run of the script on the ticket text; `sed_body_script_ok('s/open/done/')` and `'s/0/1/'` still return True, no tests for them)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-26, Open → In progress

Building it in this session, alongside T-296, so G-006 can finish.

### 2026-10-26, In progress → In QA

Built: a sed -i edit of a ticket's body now passes the guard when it can't write a guarded line; 23 new tests, 487 tools tests pass. Going to QA.

### 2026-10-26, In QA → In progress

Back to the builder: QA found that a script naming no guarded word can still rewrite a header line (s/open/done/ turns status: open into status: done). The guard will try the edit on the ticket's text and refuse it if any status, lead or qa_rounds line would change.

### 2026-10-26, In progress → In QA

Fixed: the guard now tries a sed edit on the ticket's text and refuses it if a status, lead or qa_rounds line would change; s/open/done/ and s/0/1/ are refused, the body edits still pass. 490 tools tests pass. QA round 2.

## Result notes

- `.claude/hooks/board_gate.py`: new `sed_body_script_ok` (and `_sed_delimited`); the sed branch of `why_risky` lets a `sed` on a ticket pass when every script is parsed in full and is only `s` (flags g p i I M and digits; no `w`/`e`), or `d`/`a`/`i`/`c` with a `/regex/` address, naming none of `status`, `qa_rounds`, `lead` (nor the fragments `stat`, `round`, `lead`, `qa`), no colon in a pattern or address, no numeric address below 2. Anything else (`-f`, `w`, `e`, `y`, unreadable variable/substitution scripts, `1,5s`, `1d`) stays refused. The old `SED_WRITES_RE` check is skipped for a script that passes this parse (it wrongly flagged text like " wordmark").
- Note: the hook only looks closely at a command that mentions status, qa_rounds or lead (even in a comment); the new tests add ` # status` to their commands so the sed rule is what decides.
- Limit left open: a numeric-free `s` pattern such as `s/0/1/` could still change `qa_rounds: 0`; the second guard (`guard_ledger.py`, on commit) catches that.
- `tasks/README.md`, "Changing a task's status": says which `sed -i` edits pass.
- Tests: new class `SedBodyEdits` in `tools/test_guard.py` (6 passing commands, 17 refused). Full run `python -m unittest discover -s tools -p "test_*.py"`: 487 tests, OK.
- QA round 1: all four criteria pass (SedBodyEdits tests show the passing and refused sets; full tools suite 487 tests OK; README updated). Open point for the Project Lead: the rule matches the ticket text literally (it checks only the words in the script), but a script naming none of the guarded words can still change a header line: `s/open/done/` turns `status: open` into `status: done`, and `s/0/1/` changes `qa_rounds: 0` (both verified accepted by `sed_body_script_ok`). Only the commit-time ledger guard catches these. This is wider than the builder's `s/0/1/` note; decide if acceptable or if `s` should be narrowed (e.g. anchor on body text, or refuse short patterns).
- QA round 1, criterion 5 (added later): fails, the branch is unchanged since my check, so `s/open/done/` and `s/0/1/` are still accepted and no test covers them.
- Round 2 (criterion 5): `board_gate.py` now parses the script into commands (`sed_body_parse`) and, for every target file that could be a ticket, runs them on the file's current text in Python without writing (`sed_changes_guarded_lines`, with `_bre` and `_replacement` translating basic regex and replacement exactly). It refuses when any line starting `status`, `qa_rounds` or `lead` would change, appear or vanish. It also refuses when the file can't be found or read (a glob, `$`, missing file), when an option other than `-i`/`-e` is given (`-n`, `-E`, `-z`...), or when the script can't be simulated exactly (brackets, groups, `\n`, back-references, flags other than g/i/I, regex ranges). Also fixed: `a`/`i`/`c` text now ends at the line end, and the next line is parsed as a command. Tests added to `SedBodyEdits` (sample ticket with `status: open`, `qa_rounds: 0`): `s/open/done/`, `s/0/1/` and 7 more header-changing scripts refused, 8 unreadable/inexact cases refused, nothing written, the two criterion-1 edits still pass. Note `s/a/b/g` is now refused too (it would turn `status` into `stbtus`).
