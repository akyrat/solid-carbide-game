---
id: T-291
title: "The style loop: generate, evaluate with a score and a reason, refine below 8"
status: open
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

- [ ] `python tools/style_loop/run.py art --task T-NNN --brief <file> --out <png>` and `python tools/style_loop/run.py text --task T-NNN --brief <file>` exist and run the four steps above; the generator and refiner are the same agent session (resumed), and the evaluator is the `style-evaluator` agent. (QA: pass / fail)
- [ ] The tool calls Claude only through `tools/goal_agent/claude_call.py` (`grep -rn "claude -p\|subprocess" tools/style_loop/` shows no other call to Claude). (QA: pass / fail)
- [ ] With a fake fixture where versions score 4, 6 and 9, the run stops after the third version, keeps it, and the task's `## Style review` section has three rounds, each with the version, the script checks, the score, the reason, and (rounds 2 and 3) what changed. Shown by a unit test on a temporary copy of a task file. (QA: pass / fail)
- [ ] With a fake fixture that never reaches 8, the run stops after 3 refines (4 versions), keeps the best-scoring one, and the task is set to `flagged-for-review` through `task_status.py`. Shown by a unit test. (QA: pass / fail)
- [ ] Every art version of a run is saved in `art-archive/<task id>/style-loop/`, none deleted. Shown by a unit test. (QA: pass / fail)
- [ ] `python tools/style_loop/run.py text --task T-NNN --brief <file> --fake <fixture>` runs end to end without Claude, and the fixture is committed. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)
- [ ] `tasks/README.md`, "The style loop", gives the commands, and `docs/README.md` lists the tool with the other tools. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
