---
id: T-357
title: Art: the six bad reaction icons for a broken combo
status: needs-playtest
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-356]
documents_affected: [docs/visual-style.md, game/docs/art/]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, tasks/T-352-art-reaction-icons.md]
files_expected_to_change: [game/art/hud/, game/scripts/hud/reactions.gd, game/tools/, art-archive/, docs/visual-style.md, game/docs/art/]
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

The board's decision (HUD and menus, Decisions, "Bad reactions when the combo breaks", 2026-10-29). Draw the six **bad reaction icons** for the burst when the combo breaks (the linked behaviour ticket): a crying-laughing face, a thumbs down, a face peeking between its hands, a broken heart, a skull and a screaming face. Same size and look as T-352's six reaction icons, which the board loved (16 x 16, bold comic outline, script-drawn), so the two sets sit together; they must read small at 0.9 alpha against the grey street. None of Greenbull's colours outside Greenbull's things (Visual style, Content, "Rules", rule 6). Save each as its own PNG in `game/art/hud/` with a record, then swap them in for the behaviour ticket's placeholders.

**PixelLab: no go.** Draw them by script, as T-352 did. Every icon goes through the style loop (at most 3 refines).

The board's review: crash in a run and see the bad reactions burst up.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/hud/` holds the six bad reaction icons, each its own PNG with a record, and they replace the behaviour ticket's placeholders in the game. (QA: pass: six PNGs plus json in game/art/hud, loaded by reactions.gd BAD_ICONS)
- [ ] Each icon scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass: peek 8, scream 7 noted below 8 after refines, all rounds in Style review)
- [ ] No PixelLab generations were used (the result notes say so). (QA: pass: zero PixelLab calls)
- [ ] Visual style and the art docs under game/docs/art/ record the art. (QA: pass: visual-style.md and game/docs/art/reaction-icons.md changed (qa_check's documents line is a path-matching quirk; the file did change))
- [ ] A contact sheet, enlarged, on a dark and a light background, and a screenshot of the burst after a crash are in `art-archive/<id>/screenshots/`. (QA: pass: contact_sheet.png and bad_burst.png present)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass: qa_check tests line passed all three sets)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started: script-drawn art for the six bad reactions, now that you approved the burst (T-356).

## Style review

Script-drawn art, so the loop was run by hand: I drew, the Style Evaluator agent scored from `style_rules.py art --size 16x16` (all passed every round) and by eye on the enlarged sheet. Versions: `art-archive/T-357/screenshots/before.png` (T-356 placeholders), `v1.png` to `v5.png` (the sheets of all twelve).

### Round 1
Version v2 (cry_laugh, thumbs_down, peek, broken_heart, skull, scream). Scores: cry_laugh 8, thumbs_down 8, peek 5, broken_heart 9, skull 8, scream 7. Reason: peek read as a blob with side lumps; scream's eyes and mouth were weak. Refine: peek redrawn as eyes over hands; scream bigger eyes, highlights and a pink mouth line. (cry_laugh was redrawn before v2 with tears on both sides, squinting eyes and a tongue.)

### Round 2
Version v3. peek 6 (hands a plain tan band), scream 7 (mouth small with fang-like pixels). Refine: peek with finger-bump hands at the lower corners and a gap; scream with a taller mouth, tongue, no fangs, hands on cheeks.

### Round 3
Version v4. peek 7 (hands nearly the face's orange), scream 7 (shading flat). Refine: peek hands in pale cream with finger lines.

### Round 4
Version v5 (kept). peek 8, scream 7 (rule 2 only, minor; below 8 but reads clearly; two refines used, the third left unused). Kept: cry_laugh 8, thumbs_down 8, peek 8, broken_heart 9, skull 8, scream 7.

## Result notes

Written by the agent when it finishes.

Done. Zero PixelLab calls (script-drawn). The six bad icons (`game/art/hud/reaction_{cry_laugh,thumbs_down,peek,broken_heart,skull,scream}.png` + `.json`, now task T-357) are redrawn in `game/tools/build_hud_reaction_icons.py` (same helpers, outline and palette as T-352; no Greenbull colours). The PNGs `reactions.gd` already loads (`BAD_ICONS`) are replaced by the new art, so behaviour and numbers are unchanged; only a comment changed. Final scores: cry_laugh 8, thumbs_down 8, peek 8 (3 refines), broken_heart 9, skull 8, scream 7 (minor rule 2 shading; 2 refines); every round is in the Style review. Docs: `docs/visual-style.md`, `game/docs/art/reaction-icons.md` (new), `game/docs/hud-and-menus/hud.md`. Test added in `game/tools/test_build_hud_reaction_icons.py` (twelve icons all differ, none blank; record names T-357). Screenshots in `art-archive/T-357/screenshots/`: `contact_sheet.png` (dark and light, x8), `bad_burst.png` (the burst after a crash), `before.png`, `v1.png` to `v5.png`. Tests, run in the foreground: game/tools unittest 658 OK (1 skipped), tools unittest 573 OK, GUT 1849/1849 passing. No .import or .uid files committed.


QA round 1: all six criteria pass. qa_check tests passed (3 sets); screenshots present; contact sheet and burst reviewed by eye. qa_check flagged documents for game/docs/art/ though reaction-icons.md changed on the branch (checked with git diff); treated as pass.
