---
id: T-430
title: Art: one HUD style sheet, and script redraws of the HUD pieces that break it
status: blocked
from: project-lead
to: asset-generation
lead: Goal-G-008
epic: art
milestone: mvp
goal: G-008
user_facing_text: no
changes_visuals: yes
depends_on: [T-428]
documents_affected: [docs/visual-style.md, game/docs/hud-and-menus/livestream-hud-art.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, game/docs/hud-and-menus/livestream-hud-art.md, game/tools/build_hud_livestream_art.py, game/tools/style_rules.py]
files_expected_to_change: [docs/visual-style.md, game/art/hud/, game/tools/build_hud_livestream_art.py, game/tools/test_build_hud_livestream_art.py, game/docs/hud-and-menus/livestream-hud-art.md]
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

Goal G-008, 'A consistent HUD' (HUD and menus, Decisions): every HUD piece shares one visual language. D3 has moved the HUD's style values into one shared place. Write one HUD style sheet in Visual style (Decisions): outline thickness and colour, palette, panel shapes and corners, the font for numbers and the font for words, and the pixel scale. Then go through every HUD piece (clock, coins, hearts, weapon icons, sub goal, live viewers counter and its fire, reactions, trick and combo broken popups, kaiju health bar, pause strip, level-up screen) and redraw by script, through the style loop, the art of those that break the sheet, writing them over the files the game already loads in game/art/hud/ (or their existing folder) so the game picks them up; archive the old versions in art-archive/<id>/. No PixelLab: these are script redraws; if one is truly needed, list it with the reason. Code-side changes (fonts, colours, outline widths drawn in code) are not yours: list them piece by piece in the result notes for the UI ticket D5. Greenbull's colours stay on Greenbull's things only (rule 6).

The board's review: Compare the before and after screenshots in art-archive/<id>/screenshots/, then play a run with the redrawn HUD art.

## Acceptance criteria

- [ ] docs/visual-style.md holds one HUD style sheet: outline thickness and colour, palette, panel shapes and corners, the number font and the word font, and the pixel scale. (QA: pass / fail)
- [ ] The result notes list every HUD piece named in the description, saying for each what differs from the sheet and what changed, or why it already fits. (QA: pass / fail)
- [ ] Every redrawn piece is in game/art/hud/ (or its existing folder) with its record, the old versions are in art-archive/<id>/, and no PixelLab generations were used (or any used are listed with the reason). (QA: pass / fail)
- [ ] Each redrawn piece went through the style loop, with every round in the Style review; python game/tools/style_rules.py finds no Greenbull colour in any HUD piece outside Greenbull's things. (QA: pass / fail)
- [ ] The result notes list, piece by piece, the code changes the UI ticket needs (fonts, colours, outline widths). (QA: pass / fail)
- [ ] Before and after screenshots of the same moment in a run, the after one showing the redrawn art in the game, are in art-archive/<id>/screenshots/. (QA: pass / fail)
- [ ] python -m unittest discover -s game/tools -p "test_*.py" passes, with the count in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
