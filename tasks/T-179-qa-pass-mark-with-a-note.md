---
id: T-179
title: The status script accepts a QA pass mark with a note
status: in-qa
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, tools/task_status.py, tools/test_task_status.py, tools/goal_agent/build.py]
files_expected_to_change: [tools/task_status.py, tools/test_task_status.py, tools/goal_agent/build.py, tools/goal_agent/test_build.py]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

Twice today a QA agent marked every criterion as passed but put a note inside the mark, `(QA: pass; full suite 850/850)` or `(QA: pass: ...)`. The status script only counts `(QA: pass)` exactly (`QA_PASS_RE` in `tools/task_status.py`), so it refused the move (T-164) and G-002 paused on T-166 with "QA left 3 criteria unmarked" (`goals/G-002-add-an-image-of-the.md`, "Pauses"). A fail mark already allows a note (`(QA: fail ...`). The board gave the Project Lead the decisions a run needs (2026-10-18).

1. `QA_PASS_RE` also accepts a note after `pass`, separated by `;`, `:`, `,` or ` -` (for example `(QA: pass; 850/850)`), but not another word straight after it: `(QA: passed)` or `(QA: pass/fail)` (the template's placeholder `(QA: pass / fail)`) still count as unmarked.
2. The QA prompt in `tools/goal_agent/build.py` shows the exact forms: `(QA: pass)` or `(QA: fail: <reason>)`.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, including every existing `tools/test_task_status.py` test (QA: pass)
- [ ] A test shows `(QA: pass)`, `(QA: pass; a note)`, `(QA: pass: a note)` and `(QA: PASS, note)` count as passed, and `(QA: pass / fail)`, `(QA: passed)` and an unmarked line count as unmarked (QA: pass)
- [ ] A test shows the goal runner's QA prompt names the exact forms `(QA: pass)` and `(QA: fail: <reason>)` (QA: pass)

## Updates

### 2026-10-18, Open → In progress

Quick fix started: QA pass marks may carry a note, and the runner's QA prompt shows the exact forms. Then G-002 resumes, with T-166 already passed by QA.

### 2026-10-18, In progress → In QA

Built: a QA pass mark may carry a note; the runner's QA prompt shows the exact forms. 312 tools tests pass. QA checks it now.

## Result notes

- `tools/task_status.py`: `QA_PASS_RE` is now `\(QA:\s*pass(?:\)|\s*[;:,]|\s-)` (case-insensitive): `(QA: pass)` or a note after `pass` separated by `;`, `:`, `,` or ` -`. `(QA: passed)`, `(QA: pass / fail)` and `(QA: pass/fail)` stay unmarked.
- `tools/goal_agent/build.py`: the QA prompt now shows `(QA: pass)` or `(QA: fail: <reason>)`.
- Criterion 2: `test_task_status.QaMarks.test_a_pass_mark_may_carry_a_note` (pass forms) and `test_other_words_after_pass_stay_unmarked` (unmarked forms); also `test_a_fail_mark_still_wins_over_a_pass_note`.
- Criterion 3: `goal_agent/test_build.py` existing prompt test, assertion changed to the new exact forms.
- Criterion 1: full suite run, `python -m unittest discover -s tools -p "test_*.py"`: 312 tests, OK.
- Docs: `tasks/README.md` may want one line saying a pass mark may carry a note (not edited by me).
