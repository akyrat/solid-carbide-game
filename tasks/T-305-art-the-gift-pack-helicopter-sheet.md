---
id: T-305
title: Art: the gift pack helicopter sheet in Greenbull's colours
status: in-progress
from: project-lead
to: asset-generation
lead: Goal-G-006
epic: art
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: yes
depends_on: [T-144, T-300, T-299]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/game-loop-architecture.md, docs/working-with-the-board.md, game/README.md, tasks/T-144-gift-pack-drop.md, tasks/T-145-art-redgull-helicopter.md, game/tools/build_helicopter.py, game/tools/test_build_helicopter.py, game/scenes/run/gift_helicopter.tscn, game/art/gift_pack/, game/art/logo/]
files_expected_to_change: [game/art/gift_pack/helicopter_sheet.png, game/tools/build_helicopter.py, game/tools/test_build_helicopter.py, art-archive/, docs/visual-style.md, game/README.md]
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

The helicopter that drops the gift pack (T-145; T-144) is in Redgull's colours with its gull on the fuselage panel and the tail fin. Rebuild game/art/gift_pack/helicopter_sheet.png in Greenbull's colours (Visual style, Decisions, 'The rebrand', 'Greenbull's look', 'Red after the rebrand'; rule 6), with Greenbull's emblem from game/art/logo/ (D3) on its logo spots. build_helicopter.py first (a free recolour and restamp); PixelLab only where a recolour can't do it, each call listed with its reason and count in the result notes before calling, up to 12 generations within the goal's art cap. It goes through the style loop with --greenbull and --max-colors 30. Keep its frame count and size so gift_helicopter.tscn loads it unchanged. Keep the old sheet in art-archive/<this ticket>/. Update Visual style and game/README.md, 'The gift pack drop', where they describe the helicopter. An in-run screenshot of the helicopter carrying the package in art-archive/<this ticket>/screenshots/.

The board's review: play a run to a gift pack drop: the helicopter in Greenbull's colours with its emblem, carrying the package.

## Acceptance criteria

- [ ] game/art/gift_pack/helicopter_sheet.png is rebuilt in Greenbull's colours with Greenbull's emblem on its logo spots and no gull, with the same frame count and size as before (gift_helicopter.tscn unchanged). (QA: pass / fail)
- [ ] It has no pixel the Redgull red check (style_rules.is_redgull_red, or its renamed successor) flags (output in the result notes). (QA: pass / fail)
- [ ] build_helicopter.py rebuilds it by script; any PixelLab call is listed in the result notes with its reason and count, within 12 generations. (QA: pass / fail)
- [ ] It passes `python game/tools/style_rules.py art game/art/gift_pack/helicopter_sheet.png --greenbull --max-colors 30` and has a style loop record in the ticket's Style review. (QA: pass / fail)
- [ ] The old helicopter_sheet.png is in art-archive/<this ticket>/. (QA: pass / fail)
- [ ] test_build_helicopter.py and test_gift_drops.gd pass. (QA: pass / fail)
- [ ] An in-run screenshot of the helicopter carrying the package is in art-archive/<this ticket>/screenshots/, listed in the result notes. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Goal runner (G-006): started, in C:\solid-carbide-worktrees\T-305.

## Style review

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-305/briefs/helicopter_sheet.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: `art-archive/T-305/style-loop/v1.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: The sheet passes the script checks (768x160, 30 colours, no semi-transparent pixels, rule 6 allowed for the helicopter). Looking at the image: it is a 3/4 isometric view with the nose down-right, and it reads as a dark green helicopter with light green trim and a night, retro feel. The emblem sits on cream panels on the fuselage side and the tail fin, with no gull and no red. The shading is detailed and the outline is dark. There are two small flaws. Rule 2: the rotor blades are thin, flat, near-black purple lines with no highlight pixels or shading, so they look weaker than the body and break the "outline broken by lighter highlight pixels" look. Fix by giving the blades a dark green or light-edged highlight pixel run, or a slightly thicker 2 px blade. Rules 4 and 6: the cockpit and cabin glass is saturated purple, which is not part of Greenbull's palette or the night glass look. Consider recolouring it to a dark blue-grey or teal with a pale highlight so it doesn't read as an alien (rule 8) colour. Neither flaw is severe.
- Rules broken: 2, 4
- Refused: {"tool_input": {"command": "mkdir -p art-archive/T-305/style-loop && python game/tools/build_helicopter.py piece art-archive/T-305/style-loop/v1.png && python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-305/style-loop/v1.png'); print(im.mode, im.size)\npx=im.getdata(); cols=set(p for p in px if p[3]); print('colours',len(cols)); print('alphas',sorted(set(p[3] for p in px)))\nprint('reds',[c for c in cols if c[0]>150 and c[1]<90 and c[2]<90])\nbig=im.resize((im.width*3,im.height*3),Image.NEAREST); bg=Image.new('RGBA',big.size,(20,20,30,255)); bg.alpha_composite(big); bg.save('art-archive/T-305/style-loop/v1_preview_dark.png')\n\"", "description": "Build version 1 and check palette, alpha, size"}, "tool_name": "Bash", "tool_use_id": "toolu_01JNGM5xMwWnyP32zNZA53Ba"}; {"tool_input": {"command": "python -m pytest -q game/tools/test_build_helicopter.py 2>&1 | tail -5", "description": "Run the helicopter script's tests"}, "tool_name": "Bash", "tool_use_id": "toolu_016wJzNrQTkCAA7YTQxjtCLf"}

**Kept:** version 1, score 8/10 (`art-archive/T-305/style-loop/v1.png`, copied to `game/art/gift_pack/helicopter_sheet.png`): it reached 8 or more.

## Result notes

Written by the agent when it finishes.
