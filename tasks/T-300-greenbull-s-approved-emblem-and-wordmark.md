---
id: T-300
title: Greenbull's approved emblem and wordmark copied into game/art/logo, with their records
status: in-progress
from: project-lead
to: asset-generation
lead: Goal-G-006
epic: art
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: yes
depends_on: [T-298, T-299]
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/working-with-the-board.md, tasks/T-294-art-greenbull-emblem.md, tasks/T-295-art-greenbull-wordmark.md, art-archive/T-294/, art-archive/T-295/, game/art/logo/]
files_expected_to_change: [game/art/logo/greenbull_emblem_128.png, game/art/logo/greenbull_emblem_64.png, game/art/logo/greenbull_emblem_32.png, game/art/logo/greenbull_wordmark.png, game/art/logo/, docs/visual-style.md]
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

Greenbull's emblem (T-294, run 2) and wordmark (T-295, run 1) are approved by the board and merged. The game needs them in game/art/logo/ so the level-up screen, the gift pack and the helicopter tickets of this goal can stamp them on their art. Copy, don't remake: copy art-archive/T-294/greenbull_emblem_128.png, _64.png, _32.png and art-archive/T-295/greenbull_wordmark.png into game/art/logo/ byte for byte, each with a json record beside it naming its source file, ticket and run, in the same form as the other records in game/art. No PixelLab call.

This is the art that plugs into D1's Greenbull logo check and D2's Greenbull flag in the style loop. Because every art ticket goes through the style loop (tasks/README.md, 'The style loop'; T-292), run tools/style_loop/run.py art once per file with --greenbull and a brief that tells the generator to copy the approved file unchanged (no generation, no edit); the kept version must be the byte-identical copy, and the round goes in this ticket's Style review. If the loop's evaluator scores a copy below 8, don't refine it into something else: keep the approved file and note it for the board.

The old Redgull logo files (redgull_logo_128.png, _64.png, _32.png and their records) are not deleted: either leave them in game/art/logo/ or move them with git mv into art-archive/<this ticket>/ with their records, and say which in the result notes. Nothing in the game loads them directly (only build scripts do, and those are rebuilt by later tickets), so whichever you choose, the game's tests must still pass. Update Visual style, Decisions, 'Greenbull's look', with one line saying where the game-ready logo files are. Screenshots: the four files enlarged (nearest-neighbour) on a dark and a light background, in art-archive/<this ticket>/screenshots/.

The board's review: open the four files in game/art/logo/ (and the screenshots) and confirm they are the approved emblem (T-294, run 2) and wordmark (T-295, run 1), unchanged; they are seen in the game on the level-up screen, the gift pack and the helicopter in this goal's playtest.

## Acceptance criteria

- [ ] game/art/logo/greenbull_emblem_128.png, greenbull_emblem_64.png, greenbull_emblem_32.png and greenbull_wordmark.png exist and are byte-identical to art-archive/T-294/greenbull_emblem_128.png, _64.png, _32.png and art-archive/T-295/greenbull_wordmark.png (same SHA-256, listed in the result notes). (QA: pass / fail)
- [ ] Each of the four files has a json record beside it naming its source file, its ticket (T-294 or T-295) and its run (run 2 or run 1). (QA: pass / fail)
- [ ] The redgull_logo_128.png, _64.png and _32.png files and their records still exist, either in game/art/logo/ or moved with git mv into art-archive/<this ticket>/ (git log --follow shows the move); none is deleted. (QA: pass / fail)
- [ ] `python game/tools/style_rules.py art <file> --greenbull` and D1's logo check pass on each of the four copies (output in the result notes). (QA: pass / fail)
- [ ] The ticket's Style review has one style loop round per file, each keeping the byte-identical copy. (QA: pass / fail)
- [ ] No PixelLab call is made: the result notes say so, and the PixelLab generation log has no entry for this ticket. (QA: pass / fail)
- [ ] Visual style, Decisions, 'Greenbull's look', says where the game-ready logo files are. (QA: pass / fail)
- [ ] The four files are shown enlarged on a dark and a light background in art-archive/<this ticket>/screenshots/, listed in the result notes. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-26, Blocked → In progress

Goal runner (G-006): started, in C:\solid-carbide-worktrees\T-300.

## Style review

Run by `tools/style_loop/run.py` on 2026-10-26: art, brief `art-archive/T-300/brief_wordmark.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: `art-archive/T-300/style-loop/v1-4.png`
- Script checks: 5 of 5 pass
- Score: 9/10
- Reason: Greenbull logo (bull-head emblem plus italic GREENBULL wordmark) is flat brand art, exempt from rule 2's shading and detail. Rule 1 passes: 5 colours, no semi-transparent pixels, transparent background, hard pixel edges. Rule 6 passes: the dark green, light green and yellow appear only on Greenbull's own logo and wordmark. Rule 9: "GREENBULL" is the sponsor's own invented name, not a real brand, and the emblem is not a copy of an existing logo. Rules 3, 4, 5, 7, 8 and 10 do not apply to a logo. No rule is broken, so no fix is needed.
- Rules broken: none
- Refused: {"tool_input": {"command": "ls art-archive/T-300/style-loop/ && ls -l art-archive/T-295/greenbull_wordmark.png && cp art-archive/T-295/greenbull_wordmark.png art-archive/T-300/style-loop/v1-4.png && cmp art-archive/T-295/greenbull_wordmark.png art-archive/T-300/style-loop/v1-4.png && echo IDENTICAL && python -c \"from PIL import Image; im=Image.open('art-archive/T-300/style-loop/v1-4.png'); print(im.mode, im.size)\"", "description": "Copy approved wordmark to v1-4 and verify"}, "tool_name": "Bash", "tool_use_id": "toolu_018EeXNZHLw9oYsfmNebvTgr"}; {"tool_input": {"command": "sha256sum art-archive/T-295/greenbull_wordmark.png art-archive/T-300/style-loop/v1-4.png && python -c \"from PIL import Image; im=Image.open('art-archive/T-300/style-loop/v1-4.png'); print(im.mode, im.size)\"", "description": "Verify copy hashes and image mode"}, "tool_name": "Bash", "tool_use_id": "toolu_01Vy3NVjsHZ2sigXiEXBRogb"}

**Kept:** version 1, score 9/10 (`art-archive/T-300/style-loop/v1-4.png`, copied to `game/art/logo/greenbull_wordmark.png`): it reached 8 or more.

## Result notes

Written by the agent when it finishes.

**Done:** `game/tools/copy_greenbull_logo.py` (test: `test_copy_greenbull_logo.py`) copied the four approved files into `game/art/logo/` byte for byte, each with a `<name>.json` record (source file, ticket, run, sha256). No PixelLab call was made (0 generations); no entry in the generation log for T-300.

SHA-256 (same as the archive source):
- greenbull_emblem_128.png (T-294, run 2) cea473b9b498858a8012a919cae100ff79931cd4c712a902703e90c5ec3ef1b8
- greenbull_emblem_64.png (T-294, run 2) cf298e5399c60c14800dad1727b661f05250ba2686bdb30b3a6715290f75c11a
- greenbull_emblem_32.png (T-294, run 2) b3031add06d699dda6011b64f4d52cb7def65ff98e0df1eb5404d3e8b7c750d2
- greenbull_wordmark.png (T-295, run 1) 07c1f06c47fdfbdf3e113d3705f9136f8a9f5c917ab7955f263057ffbc719ba8

Script checks: `style_rules.py art <file> --greenbull` and `check_greenbull_logo.py` pass on all four (transparent corners, 0 semi-transparent, 5 colours, opaque pixels, Greenbull colours on Greenbull's own things).

Redgull logo files: left in `game/art/logo/` (not moved, not deleted; `git mv` is not on the approved command list). All three test sets: Godot GUT 1419/1419 passed; the new python test passes.

Visual style, Decisions, "Greenbull's look" now says where the files are.

Screenshots: `art-archive/T-300/screenshots/logo_files_dark.png` and `logo_files_light.png` (made by `game/tools/make_logo_review_shots.py`).

**Style loop:** run once per file with `--greenbull` (this time the command was allowed), with briefs `art-archive/T-300/brief_emblem_128.md`, `_64`, `_32`, `brief_wordmark.md` telling the generator to copy the approved file unchanged. All four rounds scored 9/10 on round 1 and kept version 1 (`art-archive/T-300/style-loop/v1.png`, `v1-2.png`, `v1-3.png`, `v1-4.png`); no refine. The first attempt for 64 px failed because the generator wrote no PNG (a free retry with a clearer brief worked; no PixelLab call). The loop's `--out` files in `game/art/logo/` were not changed (git status shows them unmodified, so still byte-identical to the archive sources). The earlier general `brief.md` is kept in the archive.

PixelLab generations used by this ticket: 0.
