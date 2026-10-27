---
id: T-313
title: No Redgull left in the level creator's code, tools and notes, behaviour unchanged
status: in-qa
from: project-lead
to: level-challenge
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, tasks/T-312-no-redgull-left-in-game-outside.md, docs/visual-style.md, game/README.md, game/tools/style_rules.py]
files_expected_to_change: [game/scripts/level/thread_the_needle.gd, game/scripts/level_creator/editor.gd, game/tools/build_creator_buildings.py, game/tools/build_prop_art.py, game/tools/build_prop_final_art.py, game/tools/test_build_prop_art.py, game/README.md]
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

The sponsor was renamed from Redgull to Greenbull (Visual style, Decisions, "The rebrand: Redgull becomes Greenbull"), and goal G-006 cleared the old name from the game (T-306, T-312). The level creator was built on a branch made before the rebrand and merged into master after it (2026-10-28), so its code still names the old sponsor. The board asked to clean up the remaining instances (2026-10-28). Nothing here is seen by the player, and nothing the game or a tool does may change.

`git grep -i redgull -- game/scripts game/tools game/README.md` on master finds:

1. **Code comments** in `game/scripts/level/thread_the_needle.gd` (the gap's drawing, "Never Redgull red") and `game/scripts/level_creator/editor.gd` (the pair rings' colour, the spawn marker's colours). Reword them the T-306 way, for example "none of Greenbull's colours" where the comment states the colour rule (Visual style, Content, "Rules", rule 6), or "not the old sponsor's red" where it describes a red the code avoids. Colours and code stay the same.
2. **Prop and creator building tools** (`game/tools/build_creator_buildings.py`, `build_prop_art.py`, `build_prop_final_art.py`, `test_build_prop_art.py`): their docstrings, comments and the check labels "no Redgull red" / "Redgull red". Rename the labels (for example "no old-brand red") and every test that reads them, and build any remaining use of the old name from `style_rules.OLD_BRAND` (T-312) or reuse `style_rules.is_old_brand_red` where it is the same test. **Keep every check's pass or fail exactly as it is today** (the same pixels count as red; only names and messages change).
3. **game/README.md** (the spawn point, the creator textures and the placeholder props paragraphs): say "the old sponsor's red" or "Greenbull's colours" as fits each sentence, without the name.

Leave the docs in `docs/` alone: their mentions are the rebrand's history and stay. Leave every file under `game/art/` and `art-archive/` alone (records of how old art was made).

In the result notes, show that the diff changes only comments, docstrings, labels, messages and names, and paste the output of each tool's check (`build_prop_art.py check`, `build_prop_final_art.py check` and `build_creator_buildings.py`'s check, whichever exist) before and after. Nothing to picture: the result notes say so in one line.

## Acceptance criteria

- [ ] `git grep -i -l redgull -- game/scripts game/scenes game/data game/tools game/README.md` prints only files under game/tools that build the name from `OLD_BRAND` without spelling it (it prints nothing if none spell it), and none of the seven files in "files expected to change" contains the word "Redgull" in any case. (QA: PASS, grep prints nothing; none of the seven files has the word.)
- [ ] `git diff master -- game/scripts` changes only lines that start with `#` or `##` (comments): no code line in thread_the_needle.gd or editor.gd changes. (QA: PASS, diff of game/scripts is three `##` comment lines only.)
- [ ] Each prop and creator building tool's check gives the same pass or fail per asset before and after the change (the result notes show both outputs, and QA reruns the "after" one), with only the labels' wording different. (QA: PASS, build_prop_art check OK, build_prop_final_art check OK, build_creator_buildings Drew 6 textures; only labels reworded, thresholds untouched.)
- [ ] `git diff master --stat -- game/art art-archive docs` prints nothing: no art, archive or docs file changes. (QA: PASS, `git diff master...HEAD` on game/art, art-archive, docs is empty (the two-dot diff only shows master's newer commits).)
- [ ] game/README.md's three paragraphs no longer name the old sponsor and still describe the same behaviour. (QA: PASS, the three README paragraphs say old sponsor's red / old-brand red, behaviour text unchanged.)
- [ ] All three test sets pass: `python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"` and the GUT suite (`bash game/tools/run_tests.sh`). Their counts are in the result notes. (QA: PASS, game/tools 620 OK (1 skipped); tools 501 OK; GUT 142 scripts, 1688 of 1688 passing.)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started: the Level/Challenge Design Agent is renaming the old sponsor in the creator's code, tools and notes, behaviour unchanged.

### 2026-10-27, In progress → In QA

The agent is done: the old sponsor's name is gone from the creator's code, tools and notes, checks unchanged, all tests pass. QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Done. Nothing to picture (no art or visuals changed).

**What changed** (20 lines in 7 files, comments, docstrings, labels, messages and names only; no code line in thread_the_needle.gd or editor.gd changed):
- thread_the_needle.gd, editor.gd: three `##` comments now say "None of Greenbull's colours" / "none of Greenbull's colours".
- build_creator_buildings.py, build_prop_art.py, build_prop_final_art.py: docstrings, comments, and the labels "Redgull red" / "no Redgull red" became "old-brand red" / "no old-brand red". The pixel tests (thresholds) are untouched, so the same pixels count as red; I did not swap them for style_rules.is_old_brand_red because the thresholds differ and that would change results. No file spells the old name any more, so none needed OLD_BRAND.
- test_build_prop_art.py: the expected label is "no old-brand red".
- game/README.md: the spawn point paragraph says "never the old sponsor's red"; the creator textures and placeholder props paragraphs say "no old-brand red".
- `git grep -i redgull -- game/scripts game/scenes game/data game/tools game/README.md` prints nothing.

**Checks, before and after** (identical output): `build_prop_art.py check` OK; `build_prop_final_art.py check` OK; `build_creator_buildings.py` (no check mode, it draws and runs its own check): "Drew 6 textures". Before and after outputs diff clean.

**Tests:** `unittest discover -s game/tools`: 620 tests, OK (1 skipped). `unittest discover -s tools`: 501 tests, OK. GUT (`bash game/tools/run_tests.sh`): 142 scripts, 1688 tests, 1688 passing, TESTS PASSED.

**Housekeeping:** Godot's line-ending-only .import changes were reverted and not committed. Untracked .import files Godot created (creator_final, nobanner, road_pieces) were left uncommitted; a hook refused deleting them with xargs rm, so they are still in the folder.
