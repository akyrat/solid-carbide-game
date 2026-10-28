---
id: T-352
title: "Art: the reaction icons (likes, thumbs up, hearts) for the livestream bursts"
status: in-qa
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-351]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/hud-and-menus.md, docs/working-with-the-board.md, game/docs/hud-and-menus/hud.md, game/docs/art/pixellab.md, tasks/T-351-reaction-bursts-on-a-sub-goal-and-at-high-viewers.md]
files_expected_to_change: [game/art/hud/, art-archive/T-352/, docs/visual-style.md, game/README.md]
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

The board's decision (HUD and menus, Decisions, "The HUD looks like a livestream", 2026-10-28). Make the pixel art for the **reaction icons** that burst from the sub goal and float up the screen at high viewer counts (T-351): a small set, about **6 icons**, such as a heart, a thumbs up, a fire, a clapping hands, a star and a smiling face, each small (about 16 x 16 or 24 x 24, a proposal), in the game's pixel rules and comic HUD look (Visual style, Content, "Rules"; none of Greenbull's colours outside Greenbull's things, rule 6). They must read when partly transparent and small, against the street and rooftops. Save each as its own PNG in `game/art/hud/` with a record, then swap them in for T-351's placeholders.

**PixelLab: no go yet.** Free script work first (small pixel icons can be drawn by script). If PixelLab is needed, write the planned calls and their cost in the result notes and wait for the board's go (docs/working-with-the-board.md, "Art and money"). Every asset goes through the style loop (at most 3 refines).

The board's review: see the icons in the burst and floating up in a run.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/hud/` holds the reaction icons (about 6), each its own PNG with a record, and they replace T-351's placeholders in the game. (QA: pass / fail)
- [ ] Each icon scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass / fail)
- [ ] The PixelLab generations used are within the board's go and listed in the result notes (or none, if all script work). (QA: pass / fail)
- [ ] Visual style and game/README.md record the art. (QA: pass / fail)
- [ ] A contact sheet, enlarged, on a dark and a light background, and a screenshot of the burst in a run are in `art-archive/T-352/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-28, Open → In progress

Started: script-drawn reaction icons (no PixelLab go), to replace T-351's placeholders.

## Style review

All six icons are script-drawn 16 x 16 (0 PixelLab generations); every script check (style_rules.py art) passed each round.

### Round 1 (v2, art-archive/T-352/v2/)
heart 9, thumbs up 8, fire 9, star 8, smile 7, clapping 5 (reads as a bunny or bow, blob). Refine: clapping redrawn, smile thicker features.

### Round 2 (v4, art-archive/T-352/v4/)
clapping 7 (A-shaped pressed palms with sparks, flat interior), smile 8. Refine: highlight pixels on the clapping palm.

### Round 3 (v5, art-archive/T-352/v5/)
clapping 8 (a little tent-like). Kept.

Kept: heart 9, thumbs up 8, fire 9, clapping 8, star 8, smile 8 (game/art/hud/).

## Result notes

Six script-drawn 16 x 16 reaction icons (heart, thumbs up, fire, clapping, star, smile) in game/art/hud/reaction_*.png with json records, built by game/tools/build_hud_reaction_icons.py (grids, 1 px dark outline, deterministic). PixelLab: none, 0 generations. Style loop: heart 9, thumbs up 8, fire 9, clapping 8 (after 3 refines; weakest, reads a bit like a tent), star 8, smile 8 (1 refine). Style Evaluator was run by hand per round (not the run.py tool, which would call an agent to regenerate); rounds in Style review.
reactions.gd: placeholders (HEART/THUMB grids, COLORS) replaced by ICONS textures drawn with draw_texture_rect at icon_scale 2 (hud.json icon_scale 4 -> 2, so about 32 px, the placeholders' size); behaviour and other numbers unchanged. Tests: placeholder-colour test replaced by an icons test (6 textures of 16 x 16, each kind drawn); icon_scale assertion updated; new game/tools/test_build_hud_reaction_icons.py.
Docs: Visual style, game/docs/hud-and-menus/livestream-hud-art.md and hud.md (game/README.md already indexes the art file).
Tests: game/tools unittest 657 OK (1 skipped); tools unittest 560 OK; GUT 1816/1816 passing (all passed).
Archive: art-archive/T-352/ (contact_sheet.png enlarged dark and light, reactions_burst.png screenshot of a run, v1..v5 versions and sheets). The burst screenshot catches the right-side floaters small at the screen edge.
Note: untracked Godot .import files under game/art/buildings/creator_final are noise from Godot and not committed.
