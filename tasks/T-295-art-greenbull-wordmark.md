---
id: T-295
title: "Art: Greenbull's wordmark, the emblem with GREENBULL, through the style loop"
status: needs-playtest
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, agent-notes/asset-generation.md, tasks/T-294-art-greenbull-emblem.md, art-archive/T-294/greenbull_emblem_128.png]
files_expected_to_change: [art-archive/T-295/, docs/visual-style.md]
model: opus
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

The board's rebrand (2026-10-26; Visual style, Decisions, "Greenbull's look"): Greenbull's logo comes as an emblem (T-294, the bull's head) and a **wordmark**: the emblem with the name **GREENBULL** in pixel letters, for places with room for the name (the gift pack package, the level-up screen's header, menus). The name is the board's, spelled exactly GREENBULL (one word, capitals), so this task needs no text task from the Narrative Theme Agent.

**The wordmark:** the kept T-294 emblem on the left and GREENBULL to its right on one line, about 256 x 64 pixels (the agent may propose another size that suits the letters and says why in the result notes). Bold, chunky, readable pixel letters that match the emblem's cool, confident look, never a copy of a real brand's lettering. Colours from rule 6: the letters mostly in dark green RGB 12, 76, 44 with light green RGB 104, 220, 96, and yellow RGB 247, 208, 52 only as a small accent; a dark outline so it reads on dark and light backgrounds. Flat brand art: exempt from rule 2's shading and detail, follows rule 1.

**How:** through the style loop only, with the board's go of up to 12 PixelLab generations for this asset (2026-10-26). PixelLab is weak at lettering, so the letters may be drawn by a script (the loop allows script-drawn art) with the emblem pasted in, and PixelLab used only where it helps (for example a lettering style to trace). Free script work before paid generations; write the planned calls and their cost in the result notes before calling. If a loop run ends below 8, the Project Lead may start up to two more runs, each with an improved brief, within the 12 generations.

The Project Lead starts the loop: `python tools/style_loop/run.py art --task T-295 --brief art-archive/T-295/brief.md --out art-archive/T-295/greenbull_wordmark.png`. The kept wordmark stays in `art-archive/T-295/` until the board approves it.

This task's Style review is also Example 3 of the board's course assignment (`course-material/style-guide-agent/README.md`), so every round must be clear to an outside reader.

The board's review: look at the kept wordmark enlarged with nearest-neighbour, on a dark and a light background, next to the emblem; read the Style review.
Board review files: art-archive/T-295/review_wordmark_dark.png, art-archive/T-295/review_wordmark_light.png

## Acceptance criteria

- [ ] The task's `## Style review` section holds every round of every loop run: each version's file, the script checks, the score, the reason and (from round 2) what changed, and a "Kept" line per run. (QA: pass. Both runs hold every round with a Kept line, run 1 restored.)
- [ ] Every version is in `art-archive/T-295/style-loop/` (with its PixelLab record when PixelLab made it, or the script that drew it), and the kept wordmark is `art-archive/T-295/greenbull_wordmark.png`. (QA: pass. v1 and v1-2 with records and script copies in style-loop/; kept file present.)
- [ ] `python game/tools/style_rules.py art art-archive/T-295/greenbull_wordmark.png` passes, or its failures are named in the Style review. (QA: pass. Exit 0 on the kept file and on run 2.)
- [ ] The wordmark reads GREENBULL, spelled exactly, as the QA agent sees when it looks at the review image. (QA: pass. Reads GREENBULL in both review images.)
- [ ] Its colours are the three brand colours plus at most two dark outline or shade colours, and yellow covers fewer opaque pixels than either green, as a short script listing its colours shows. (QA: pass. 5 colours on both; yellow 46 px vs greens 1119/2709 and 1441/2387.)
- [ ] At most 12 PixelLab generations were used, as `game/art/pixellab-generation-log.jsonl` shows for T-295. (QA: pass. 0 T-295 lines in the log.)
- [ ] The two review images exist: the wordmark and the emblem, enlarged with nearest-neighbour, on a dark and a light background. (QA: pass. Both review images exist, as described.)
- [ ] Nothing under `game/art/` changed except the PixelLab log. (QA: pass. git diff master...HEAD -- game/art is empty.)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-26, Open → In progress

Started: the GREENBULL wordmark, built from the emblem's run 2, through the style loop (up to 12 PixelLab generations). The dependency on T-294 is dropped: its emblem is copied in, and a different pick by the board means a free script rebuild.

### 2026-10-26, In progress → In QA

Wordmark made: two loop runs, both 8/10 on their first version, script-drawn (0 PixelLab generations). Run 1 (light green letters) reads best on dark and is the main file; run 2 (dark green leads) is stronger on light. Review: art-archive/T-295/review_wordmark_dark.png and _light.png. Now in QA.

### 2026-10-26, Needs playtest

Passed QA (round 1). Waiting for your review: run 1 (light green letters) is the main file, run 2 (dark green leads) the alternative. Patch notes: https://claude.ai/artifact/L47vbXEL6wYndn4tx22fMt

## Style review

The loop ran twice on this asset. The tool sets this whole section on each run (fix: T-296), so run 2 replaced run 1's record; the Project Lead restored run 1 below, word for word from a copy of the ticket saved right after run 1, including its refused command. (A first attempt at run 1 stopped before any round, with no image: the agent's drawing script was kept under `art-archive/T-295/`, where the ticket guard refuses to run scripts; the brief then asked for scripts in `game/tools/`.)

### Run 1, round 1 (restored)

Run by `tools/style_loop/run.py` on 2026-10-26: art, brief `art-archive/T-295/brief.md`. Generator: asset-generation; evaluator: style-evaluator.

- Version 1: `art-archive/T-295/style-loop/v1.png`
- Script checks: 5 of 5 pass
- Score: 8/10
- Reason: The checks pass: rule 1 (transparent background, hard edges, 5 colours) and rule 6 (no Redgull red). The image reads as a clean flat wordmark. The angular bull-head emblem sits on the left, reused unchanged. GREENBULL is spelled correctly in capitals, with bold, slanted, even-height letters. They have a near-black outline and a dark green drop shade, so they should read on dark and light backgrounds. The lettering is custom and doesn't copy Red Bull or any real brand (rule 9). Yellow stays a tiny accent, only in the emblem's eyes. Rule 2 does not apply to flat brand art. One soft point against rule 6: the letter faces are mostly light green, and the dark green appears only as the shade and the emblem. The rule says dark green leads on Greenbull's things (and the board asked for it as the main theme colour). For the next version, make dark green the dominant letter colour. For example, use a dark green face with a light green top highlight or edge, or make the dark green shade thicker. Keep the black outline. I only judged the image at its small displayed size, so check that the letter gaps and the E/B/U shapes stay crisp at the full 256 x 64.
- Rules broken: 6
- Refused: one read-only command (checking the emblem's palette with inline Python and listing `game/tools`).

**Kept (run 1):** version 1, score 8/10 (`art-archive/T-295/style-loop/v1.png`, copied to `art-archive/T-295/greenbull_wordmark.png`): it reached 8 or more. The Project Lead agreed with the soft point on rule 6 and ran the loop again for a dark-green-led version.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-26: art, brief `art-archive/T-295/brief_run2.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: `art-archive/T-295/style-loop/v1-2.png`
- Script checks: 5 of 5 pass
- Score: 8/10
- Reason: No rule is clearly broken. Rule 1: the script checks pass (transparent background, no semi-transparent pixels, 5 colours). Rule 2's shading is waived for flat brand art. Rule 6: dark green now leads the letters, as the board asked. Each letter has a dark green body and a light green edge line, with the near-black outline around it. Yellow stays confined to the emblem's eyes and blaze, so it is not overused. Rule 9: the slanted, sharp-cornered GREENBULL lettering doesn't copy a real brand, and the spelling is correct. The emblem is reused unchanged. I viewed the image only at its small native size and did not count pixels. The one soft point is legibility: the thin light green edge is what separates the dark green letters from a dark background, so at 1x it is a little busy and the letters read slightly less crisply than in run 1. A heavier or more continuous light green top and left edge would fix this without losing dark green's lead.
- Rules broken: none
- Refused: {"tool_input": {"command": "python - <<'EOF'\nfrom pathlib import Path\np=Path(\"game/tools/greenbull_wordmark.py\"); s=p.read_text()\ns=s.replace('''def word_layer(word):\n    \"\"\"Dict (x, y) -> colour for the word, before slant, origin at (1, 1).\"\"\"''','''# Colour schemes (run 1 = \"light\"; run 2 = \"dark\", where dark green leads as the board asked).\n#   face: letter body colour; edge: colour of the face's top edge rows (None = no edge);\n#   edge_rows: how many rows of the face's top edge; shade: drop shade colour.\nSCHEMES = {\n    \"light\": {\"face\": LIGHT, \"edge\": None, \"edge_rows\": 0, \"shade\": DARK},\n    \"dark\": {\"face\": DARK, \"edge\": LIGHT, \"edge_rows\": 2, \"shade\": LIGHT},\n}\n\n\ndef word_layer(word, scheme=\"light\"):\n    \"\"\"Dict (x, y) -> colour for the word, before slant, origin at (1, 1).\"\"\"\n    sc = SCHEMES[scheme]''')\ns=s.replace('''    px.update({p: DARK for p in shade})\n    px.update({p: LIGHT for p in face})\n    return px''','''    px.update({p: sc[\"shade\"] for p in shade})\n    px.update({p: sc[\"face\"] for p in face})\n    if sc[\"edge\"] is not None:\n        for (x, y) in face:\n            if any((x, y - d) not in face for d in range(1, sc[\"edge_rows\"] + 1)):\n                px[(x, y)] = sc[\"edge\"]\n    return px''')\ns=s.replace('def render(emblem_path=EMBLEM):','def render(emblem_path=EMBLEM, scheme=\"light\"):')\ns=s.replace('px = slant(word_layer(WORD))','px = slant(word_layer(WORD, scheme))')\ns=s.replace('''    if len(argv) != 2:\n        print(__doc__)\n        return 2\n    out = Path(argv[1])''','''    args = list(argv[1:])\n    scheme = \"light\"\n    if \"--scheme\" in args:\n        i = args.index(\"--scheme\")\n        scheme = args[i + 1] if i + 1 < len(args) else \"\"\n        del args[i:i + 2]\n    if len(args) != 1 or scheme not in SCHEMES:\n        print(__doc__)\n        return 2\n    out = Path(args[0])''')\ns=s.replace('img, emblem, (w, h) = render()','img, emblem, (w, h) = render(scheme=scheme)')\ns=s.replace('''It refuses to overwrite''','''Run 2 (dark green leads): add --scheme dark (dark green face, 2 px light green top edge,\nlight green drop shade), e.g.\n    python game/tools/greenbull_wordmark.py --scheme dark art-archive/T-295/style-loop/v1-2.png\nIt refuses to overwrite''')\np.write_text(s)\nEOF\nmkdir -p /tmp/t295 && python game/tools/greenbull_wordmark.py --scheme dark /tmp/t295/a.png && python - <<'EOF'\nfrom PIL import Image\nfrom collections import Counter\nim=Image.open(\"/tmp/t295/a.png\"); \nc=Counter(im.crop((64,0,256,64)).getdata()); print({k:v for k,v in c.items() if k[3]})\nS=4\nbig=im.resize((256*S,64*S),Image.NEAREST)\nout=Image.new(\"RGBA\",(256*S,128*S+8))\nout.paste((20,20,28,255),(0,0,256*S,64*S)); out.paste((235,235,230,255),(0,64*S+8,256*S,128*S+8))\nout.alpha_composite(big,(0,0)); out.alpha_composite(big,(0,64*S+8)); out.save(\"/tmp/t295/a_prev.png\")\nEOF", "description": "Add dark scheme option, render candidate and preview"}, "tool_name": "Bash", "tool_use_id": "toolu_01SR7xCs4jtmkVKLR4XEinxq"}; {"tool_input": {"command": "mkdir -p \"$TEMP/t295\" && python game/tools/greenbull_wordmark.py --scheme dark \"$TEMP/t295/a.png\" && python game/tools/art_preview.py \"$TEMP/t295/a.png\" \"$TEMP/t295/a_prev.png\" --from-x 66 && cygpath -w \"$TEMP/t295/a_prev.png\"", "description": "Render dark-scheme candidate to temp and preview it"}, "tool_name": "Bash", "tool_use_id": "toolu_01GGrvZtd3X487m76VW7phcK"}; {"tool_input": {"command": "mkdir -p /c/Users/andre/AppData/Local/Temp/t295 && python game/tools/greenbull_wordmark.py --scheme dark /c/Users/andre/AppData/Local/Temp/t295/a.png && python game/tools/art_preview.py /c/Users/andre/AppData/Local/Temp/t295/a.png /c/Users/andre/AppData/Local/Temp/t295/a_prev.png --from-x 66", "description": "Render dark-scheme candidate to temp and preview it"}, "tool_name": "Bash", "tool_use_id": "toolu_016CjjkEm2SbGcevRwayks5P"}; {"tool_input": {"command": "python game/tools/test_greenbull_wordmark.py && python game/tools/greenbull_wordmark.py --scheme dark art-archive/T-295/style-loop/v1-2.png && cp game/tools/greenbull_wordmark.py art-archive/T-295/style-loop/v1-2_greenbull_wordmark.py && python game/tools/art_preview.py art-archive/T-295/style-loop/v1-2.png art-archive/T-295/style-loop/v1-2_preview.png --from-x 66 && python -c \"from PIL import Image; im=Image.open('art-archive/T-295/style-loop/v1-2.png'); print(im.mode, im.size)\"", "description": "Run tests, save v1-2, keep script copy and preview"}, "tool_name": "Bash", "tool_use_id": "toolu_01SJW3TEibvuTs7uFPsY986G"}

**Kept:** version 1, score 8/10 (`art-archive/T-295/style-loop/v1-2.png`, copied to `art-archive/T-295/greenbull_wordmark_run2.png`): it reached 8 or more.

## Result notes

- 2026-10-26, Project Lead: the dependency on T-294 is dropped so the wordmark can be made while the board is away. T-294 passed QA and waits for the board's review in needs-playtest; its kept emblem (run 2, the Project Lead's pick) is copied into `art-archive/T-295/` (128, 64 and 32). If the board picks the other run, the wordmark is rebuilt with that emblem by script, for free.
- 2026-10-26, Asset Generation Agent (wrap-up, free script work only, no PixelLab calls):
  - **What was made:** two script-drawn wordmarks, 256 x 64 RGBA. Both have the 64 px T-294 emblem (run 2) on the left, pasted unchanged, and GREENBULL in slanted 16 x 25 pixel letters with a 1 px near-black outline. Both come from `game/tools/greenbull_wordmark.py`: `--scheme light` (the default) is run 1 and `--scheme dark` is run 2. Each rebuilds its kept file pixel for pixel, and a test checks this. Copies of the script as it was for each version are kept at `art-archive/T-295/style-loop/v1_greenbull_wordmark.py` and `v1-2_greenbull_wordmark.py`. Run 1's first drawing script is `style-loop/draw_v1.py`. Run 2's unscored drafts are in `style-loop/run2-drafts/`.
    - Run 1 (`greenbull_wordmark.png`, kept for now): light green letter faces with a 3 px dark green drop shade.
    - Run 2 (`greenbull_wordmark_run2.png`): dark green letter faces with a light green edge line and a light green shade.
  - **Colours** (opaque pixels in the whole image; the letters alone, x 64 and up, in brackets):
    - Run 1: light green 104,220,96: 2709 (2370); outline 14,22,18: 1461 (1091); dark green 12,76,44: 1119 (660); emblem shade 6,46,26: 246 (0); yellow 247,208,52: 46 (0).
    - Run 2: dark green: 2387 (1928); outline: 1461 (1091); light green: 1441 (1102); emblem shade: 246 (0); yellow: 46 (0).
    - Both runs: 5 colours, the emblem's own. Yellow is only in the emblem (46 px, far below either green).
  - **Checks:**
    - `python game/tools/style_rules.py art` passes all 5 checks on both `greenbull_wordmark.png` and `greenbull_wordmark_run2.png`: transparent corners, 0 semi-transparent pixels, 5 colours, 5581 opaque pixels, no Redgull red.
    - `python -m unittest discover -s game/tools -p "test_*.py"`: 434 tests, OK (1 skipped, not one of this task's).
    - Added to `game/tools/test_greenbull_wordmark.py`: both schemes are 256 x 64, use exactly the emblem's 5 colours and no semi-transparent pixels, yellow is the smallest green-or-yellow count, and both kept files rebuild exactly. A small test also covers `game/tools/art_preview.py`, the preview helper added in run 2.
  - **PixelLab generations used by T-295:** 0 (no T-295 lines in `game/art/pixellab-generation-log.jsonl`). Nothing under `game/art/` changed.
  - **Review images:** `art-archive/T-295/review_wordmark_dark.png` and `review_wordmark_light.png`. Each shows run 1, run 2 and the 128 px emblem at 3x, nearest-neighbour.
  - **My honest view:**
    - On dark, run 1 is clearly better. Its light green faces read at once, and the dark shade adds depth. In run 2 the dark green bodies almost merge into the dark background, so the letters are carried by the thin light green edges and read like stripes. That makes them busier and less crisp, especially E, B and the two Ls.
    - On light, both read well. Run 2 is the stronger and more on-brand of the two there: the dark green letters with a light edge match the emblem's dark-green-led look. Run 1 looks a little lighter but is still clear.
    - Most game uses are on dark screens (the level-up header, menus), so I would keep run 1. Run 2 would suit light surfaces such as the gift pack package. A cheap middle option, if the board wants dark green to lead on dark too, is a free script change: a thicker light green top and left edge on run 2, as the evaluator suggested. The board chooses.
- 2026-10-26, in-qa → needs-playtest: QA round 1: all 8 criteria pass
