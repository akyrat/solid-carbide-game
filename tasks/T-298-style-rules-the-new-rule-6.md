---
id: T-298
title: Style rules: the new rule 6 (Greenbull's colours), Greenbull's logo check, and Redgull as a banned word
status: open
from: project-lead
to: project-lead
lead: Goal-G-006
epic: tooling
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/tools/style_rules.py, game/tools/test_style_rules.py, game/tools/check_logo_one_colour.py, game/tools/test_check_logo_one_colour.py, game/tools/check_sprite_rules.py, tasks/T-290-style-rules-module.md, tasks/T-294-art-greenbull-emblem.md, tasks/T-295-art-greenbull-wordmark.md]
files_expected_to_change: [game/tools/style_rules.py, game/tools/test_style_rules.py, game/tools/check_logo_one_colour.py, game/tools/test_check_logo_one_colour.py, game/tools/check_sprite_rules.py, game/tools/test_check_sprite_rules.py, game/README.md]
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

The sponsor Redgull is now Greenbull (board, 2026-10-26; Visual style, Decisions, 'The rebrand', 'Greenbull's look', 'Red after the rebrand'; Content, 'Rules', rule 6 'Greenbull's colours'; Extended narrative, Decisions, 'The rebrand' and Content, 'Text rules'). The script checks in game/tools/style_rules.py (T-290) still follow the old rule 6. Bring them in line with the docs as written, without inventing anything:

- Art, rule 6: red is no longer reserved, so a sprite is never failed for red pixels. Greenbull's light green (RGB 104, 220, 96) and yellow (RGB 247, 208, 52) may appear only on Greenbull's own things: without the Greenbull flag, a sprite that uses either colour (or one that reads as it, the same way the red check measured closeness) fails rule 6; with the flag it passes. Rename the flag --redgull to --greenbull (and the art_checks keyword the same way). Keep --allow-red working, or rename it to fit the new rule, saying which in the result notes.
- Logo check: replace the one-colour Redgull logo check (--logo, check_logo, check_logo_one_colour.py) with a check that accepts Greenbull's approved emblem art-archive/T-294/greenbull_emblem_128.png, _64.png, _32.png and wordmark art-archive/T-295/greenbull_wordmark.png, following the rule that Greenbull's logo is flat brand art: exempt from rule 2, bound by rule 1 (Visual style, Content, Rules). Rename or replace check_logo_one_colour.py and its test; don't delete the old check's history (mark it as the old logo's, or rename it).
- Text: rule 2 bans 'Redgull' in any case; rule 3 becomes no 'Greenbull says ...' line; 'Greenbull' joins the proper names.
- The red-distance helpers used elsewhere (is_redgull_red, REDGULL_RED, HEART_COLOR) keep their values and behaviour here; their renaming is a later ticket of this goal. Only what rule 6 needs changes now.

Run check_sprite_rules.py over game/art on master and on your branch and compare the rule 6 results asset by asset. Update game/README.md, 'The style rules', to describe the new checks and flags. Tooling only: nothing to picture, so the result notes say so in one line instead of screenshots.

## Acceptance criteria

- [ ] style_rules.py's art check no longer fails a sprite for red pixels: a test with a pure red (255, 0, 0) sprite passes rule 6. (QA: pass / fail)
- [ ] Without the Greenbull flag, the art check fails rule 6 for a sprite using RGB 104, 220, 96 and for one using RGB 247, 208, 52 (one test each); with --greenbull (renamed from --redgull) the same sprites pass rule 6 (tests). (QA: pass / fail)
- [ ] The logo check accepts art-archive/T-294/greenbull_emblem_128.png, _64.png, _32.png and art-archive/T-295/greenbull_wordmark.png (tests), in place of the one-colour Redgull check. (QA: pass / fail)
- [ ] The text check fails rule 2 on a text containing 'Redgull', 'REDGULL' and 'redgull' (tests) and fails rule 3 on 'Greenbull says hi' (test); a text naming 'Greenbull' alone passes both rules (test). (QA: pass / fail)
- [ ] The result notes list check_sprite_rules.py's rule 6 result over game/art on master and on the branch: every asset that passed rule 6 on master still passes, except any asset now flagged, each listed with the reason. (QA: pass / fail)
- [ ] `python game/tools/style_rules.py art --help` shows --greenbull and no --redgull. (QA: pass / fail)
- [ ] game/README.md, 'The style rules', describes the new rule 6 check, the --greenbull flag, the Greenbull logo check and the Redgull ban, and doesn't say rule 6 reserves red. (QA: pass / fail)
- [ ] game/tools/test_style_rules.py, the logo check's test (test_check_logo_one_colour.py or its renamed successor) and all the Python tool tests in game/tools pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
