---
id: T-605
title: Stop Godot's generated .import and .uid files showing as changes
status: open
from: project-lead
to: qa-integration
lead: Rails
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, .gitignore, tools/merge_batch.py, .gitattributes]
files_expected_to_change: [.gitignore, .gitattributes, tools/, tasks/README.md]
model: sonnet
qa_rounds: 0
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

The board's request (2026-11-08): the main checkout keeps filling with Godot's generated files: about 240 untracked *.import and 340 untracked *.uid files (from art and scripts added on branches, which merge_batch.py leaves out of merges, T-347), and tracked *.import files and game/project.godot that Godot rewrites with only line-ending changes (218 at once on 2026-11-08). Find the right fix and make it: (1) for untracked generated files, decide with reasons whether they should be committed (Godot 4.4+ uses .uid files to find resources by uid, and .import files carry import settings; ignoring them can break a fresh checkout or the Web export) or ignored, and check what a fresh clone and `python tools/publish_itch.py --dry-run` need; (2) for line-ending-only rewrites, a .gitattributes rule (eol) or similar so Godot's rewrites stop showing as changes. Change merge_batch.py's handling if the decision changes what it should leave out. Never run commands that reset or discard the board's own changes; the generated files' state in the main checkout is for the Project Lead to apply after the merge, with the exact commands in the result notes.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes give the decision for untracked .import and .uid files with reasons, including what a fresh clone and the Web export need. (QA: pass / fail)
- [ ] After the change, a Godot import in the task's folder leaves no line-ending-only changes in git status (shown in the result notes). (QA: pass / fail)
- [ ] merge_batch.py's tests pass, updated if its handling changed. (QA: pass / fail)
- [ ] tasks/README.md describes the rule. (QA: pass / fail)
- [ ] The tools test set passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
