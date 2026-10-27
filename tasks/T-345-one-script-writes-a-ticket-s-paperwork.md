---
id: T-345
title: Token spend: one script writes a new ticket's paperwork
status: in-progress
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
files_to_read_first: [tasks/README.md, tasks/_TEMPLATE.md, tools/task_status.py]
files_expected_to_change: [tools/new_ticket.py, tools/test_new_ticket.py, tasks/README.md]
model: sonnet
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

Writing tickets and doc edits by hand was 16 to 24% of the long sessions' weighted cost; each ticket takes the Project Lead about five steps (next free number, the template, the timeline entry, regenerating the GDDs, the commit). Write `tools/new_ticket.py` that takes a short JSON or YAML file (title, slug, agent, epic, model, the header lists, description, criteria, timeline text, and the decision docs the Project Lead already edited) and: picks the next free number from `tasks/` and `git log` on `master`, writes the ticket from `tasks/_TEMPLATE.md` (the shared comment and sections copied, not retyped), claims it for a given lead, appends the timeline entry, regenerates the long GDD and the short GDD's fingerprint when a game area doc changed, and commits only those files after checking no merge is in progress. It prints one line per ticket. Several tickets in one file make one commit.

The decisions themselves stay the Project Lead's (it still writes the Decisions line in the game area doc, and the criteria). Describe the script in `tasks/README.md`.

Part of the token-spend epic (board, 2026-10-28; `tasks/README.md`, "Epics and milestones"). The evidence behind it is the Tokens session's recon of 2026-10-28 (summarised in `docs/timeline.md`, "2026-10-28: The token-spend epic"). Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Tests on a throwaway repo show two tickets from one input file written with the next free numbers, the template's sections intact, the header parseable by `tools/task_status.py`, the lead claimed, one timeline entry each, and a single commit with only those files. (QA: pass / fail)
- [ ] A test shows the script refusing to commit while a merge is in progress. (QA: pass / fail)
- [ ] `tasks/README.md` describes the script and its input. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started in parallel: the ticket-paperwork script.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built `tools/new_ticket.py` (tests: `tools/test_new_ticket.py`; described in `tasks/README.md`, "Writing new tickets with a script"). Nothing to picture (a command-line tool).

What it does: `python tools/new_ticket.py tickets.json [--dry-run]`, run from the main checkout on master. It checks that no merge is in progress (MERGE_HEAD) and validates the input before writing anything. Next number = highest T-NNN in `tasks/`, `git log` on master (or HEAD) and `task/T-NNN` branches, plus one; zero-padded to 3 digits. It writes each ticket from `tasks/_TEMPLATE.md` (header lines filled in; the comment, acceptance-criteria intro, Updates, Style review and Result notes copied from the template), claims it through `task_status.py --lead` (so the guard ledger stays happy), appends one timeline entry per ticket (heading, "Decision or change", "Documents touched", "Tasks"), and when `decision_docs` is given regenerates the long GDD and the short GDD fingerprint. It then commits only those files with `git commit -- <files>` (unrelated staged files stay out) in one commit. One output line per ticket; exit 1 on refusal, 2 on usage or input error.

Input format (JSON; YAML not supported, JSON needs no dependency). Example:
```
{"lead": "Tokens", "commit_message": "T-360: ticket", "decision_docs": ["docs/weapons.md"], "date": "2026-10-28",
 "common_criteria": ["All three test sets pass, with the counts in the result notes."],
 "tickets": [{"title": "Short title", "slug": "short-title", "to": "weapon-behavior", "epic": "weapons", "model": "sonnet",
   "depends_on": [], "documents_affected": ["docs/weapons.md"], "files_to_read_first": ["tasks/README.md"],
   "files_expected_to_change": ["game/x.gd"], "description": "What and why.", "criteria": ["Something QA can check."],
   "timeline": {"title": "Entry title", "decision": "What the board decided.", "documents": ["docs/weapons.md"]}}]}
```
Optional: `common_description` (appended to every description), per-ticket `lead`, `milestone`, `user_facing_text`, `changes_visuals`.

Tests (throwaway repos in temp folders only; the real repo's tasks were never touched, no real ticket created): 8 new tests in `tools/test_new_ticket.py`: two tickets from one file with next free numbers, template sections intact, header parsed by `tb.parse_header` and readable by `task_status.py`, lead claimed, one timeline entry each, one commit with only those files; numbers from git log and branches; refusal while a merge is in progress (library and command line, nothing written); bad input writes nothing; dry run; unrelated staged files stay out of the commit; command-line one-line-per-ticket; decision doc edit regenerates the long GDD and fingerprint, which join the commit and pass `generate_long_gdd.py --check`.

Test counts: `python -m unittest discover -s tools -p "test_*.py"`: 509 tests OK (includes the 8 new). `python -m unittest discover -s game/tools -p "test_*.py"`: 620 tests OK (1 skipped). `bash game/tools/run_tests.sh`: 1735 of 1735 passing, TESTS PASSED.

Unsure or notes: (1) the commit message has no attribution line unless the Project Lead puts it in `commit_message`. (2) Timeline entries go at the end of `docs/timeline.md` with the given date; each ticket gets its own entry as the ticket asked, so a batch from one decision repeats the entry text unless the lead varies it. (3) The script does not write the Decisions line or criteria: those stay the Project Lead's. (4) Linked Narrative/art tasks are not generated; list them as separate tickets in the same file.
