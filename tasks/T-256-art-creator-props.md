---
id: T-256
title: "Art: the creator's props, in four rotations"
status: in-progress
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, tasks/T-253-placeable-props.md, game/tools/pixellab_client.py]
files_expected_to_change: [game/art/props/, game/art/pixellab-generation-log.jsonl, art-archive/T-256/, art-archive/README.md, game/data/level/, docs/visual-style.md, game/README.md]
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

The board's go for PixelLab (Level design, Decisions, "Level creator piece set", 2026-10-22: up to 100 generations across the creator's art tickets). **This ticket's cap: 40 generations.** T-253 added eight props with code-drawn placeholders, each in four rotations: concrete barrier, traffic cones, crate stack, AC unit, water tank, roof vent, street lamp, rooftop sign. Generate their final art: one isometric sprite per prop and rotation (north, east, south, west), at the game's scale (32 art pixels per unit, drawn at 0.5) and fitted to T-253's footprints, in the city's palette (Visual style, Decisions, "City colours"; amber light on the lamp and sign; the sign shows Japanese-like marks that aren't real words, no brands), with the pixel-art rules, never Redgull red.

Choose the cheapest way that keeps the four rotations consistent (for example one generation per prop and PixelLab's rotate or rotations call for the others, or mirroring by script where a prop is symmetric, as free fixes first). Plan your calls and their cost in the result notes before calling (`docs/working-with-the-board.md`, "Art and money"; 600 s timeout), one round only: report weak results, don't regenerate, and stop and report if a call costs more than planned or the cap would be passed. Log every call, keep every generation (game-ready in `game/art/props/`, the rest in `art-archive/T-256/`), and swap them in through T-253's props data only.

Your folder is built on T-253's branch (the Project Lead makes it). End with a screenshot of every prop in its four rotations in the creator, and one in a run.

## Acceptance criteria

- [ ] The result notes list the planned calls and cost before the calls, and the generations used, at most 40; every call is in the generation log (QA: pass; plan with cost written before the calls, 8 of 40 generations, 8 T-256 entries in the log, raws and requests archived)
- [ ] All 8 props have art in four rotations that read as the same object, fit their footprints, pass `check_sprite_rules.py`, and have no Redgull red (screenshot) (QA: fail; the sign's marks are real Chinese characters, one the real word 天, against the ticket's 'Japanese-like marks that aren't real words'; also props are 60 to 80% of their footprints and north/south repeat each other, which the agent reported and the board may judge; passes: 32 PNGs, no RGB 135,17,27, no semi-transparent pixels, 30 colours, transparent corners, same object in all four rotations per the sheet; check_sprite_rules only 'fails' the square frame-size rule, which non-square props can't meet)
- [ ] The props use the new art through T-253's data; every generation is kept (QA: pass; props.json lists 32 *_art.png textures, placeholders left on disk, 8 raws in art-archive/T-256/raw, no code changes beyond the data and tools)
- [ ] Screenshots are in `art-archive/T-256/screenshots/`; Visual style and `game/README.md` record the art; the full GUT suite and all Python tool tests pass (QA: pass; 6 screenshots present and seen, Visual style and game/README.md updated, GUT all passed, game/tools tests OK, tools tests 439 OK)

The board's review: place every prop in each rotation and judge the art.
Board review files: the screenshots in `art-archive/T-256/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Started on T-253's branch: PixelLab art for the eight props in four rotations, cap 40 generations.

### 2026-10-22, In progress → In QA

Art in: 8 of 40 generations, one picture per prop, rotations by mirroring. Weak: several props are small for their footprints, and the rooftop sign shows real Chinese characters. Sent to QA.

### 2026-10-22, In QA → In progress

QA failed one point: the sign shows real Chinese characters. Sent back for a free script fix (made-up glyphs), no new generations.

## Result notes

### Plan before any call (Asset Generation Agent, 2026-10-22)

- **Cost note:** the client's log shows every `/create-image-pixflux` call at `{"type": "generations", "generations": 1.0}`, whatever the size (up to 128 x 128 so far); `/rotate` is also 1.0 each but only ever used at 128 x 128 and with no way to check its size limit here, and the props are up to 171 x 193 art px, so `/rotate` is not relied on.
- **Planned calls: 8 x `/create-image-pixflux`, 1 generation each = 8 generations** (cap 40; 13 already used by other tickets). One per prop, `isometric: true`, `view: high top-down`, `no_background`, `outline: single color black outline`, `shading: medium shading`, `detail: highly detailed`, sizes near the placeholders (barrier 160 x 112, cones 96 x 96, crates 144 x 144, AC unit 128 x 112, water tank 192 x 192, roof vent 96 x 96, street lamp 64 x 208, roof sign 160 x 192), 600 s HTTP timeout, no retries, log `game/art/pixellab-generation-log.jsonl`.
- **The four rotations are made free, by script, from each one generation:** the footprint swaps for east and west, and a horizontal mirror of an isometric view is the same object seen along the other axis. Long props (barrier, roof sign) and square props (crates, AC unit): north and south are the generated picture, east and west its mirror. Round or near-round props (cones, water tank, roof vent, street lamp): the same picture, mirrored for east and west (so the lit side flips). The cost is that south repeats north (and west repeats east), so a one-sided detail (the sign's face) shows on both sides; noted honestly below. Spare budget (up to 32) is not spent: one round only.
- Then a script (`game/tools/build_prop_final_art.py`) fits each sprite (crop to content, no upscaling), sets the anchor from the footprint, reduces to at most 30 colours, removes any Redgull red, writes `game/art/props/<name>_<rotation>_art.png` and switches `props.json` textures to them. The placeholders stay on disk.

## Result (Asset Generation Agent, 2026-10-22)

**Generations used: 8 of 40** (8 x `/create-image-pixflux`, 1.0 each as planned; all 8 in `game/art/pixellab-generation-log.jsonl`; the run was cut by a usage limit after the last call had been saved and logged, so nothing was repeated). One round, no regeneration. Raw generations, request bodies and records: `art-archive/T-256/raw/`, `art-archive/T-256/requests/`.

How: one picture per prop, the four rotations made free by script (`game/tools/build_prop_final_art.py`: crop, alpha 0/255, at most 30 colours, red to orange, mirror for the other axis, anchor from the footprint). Final files `game/art/props/<name>_<rotation>_art.png`, selected through `props.json` textures only; the code-drawn placeholders are still on disk and `build_prop_art.py build` no longer overwrites the final textures. North and south are the same picture and east and west its mirror (barrier and sign are mirrored for north/south, since the generation's long axis ran the east/west way).

What each looks like (honestly):
- **Barrier:** a plain pale blue-grey concrete slab with a lighter top and a separate end block; clean but very pale and featureless, reads as a bright bar against the dark ground. 125 x 85 px, about 78% of the 4 x 1 diamond's width.
- **Cones:** three orange and white cones on a small grey pad. Reads well, tiny (67 x 57 px).
- **Crates:** a two-level stack of dark brown wooden crates with metal corners; reads as crates but is quite dark and warm, outside the steel palette (muted). 78 x 88 px, smaller than the 2 x 2 footprint (128 px wide).
- **AC unit:** pale blue-grey box with a fan grille, a small amber light and side vents, on a pale pad. Good. 97 x 84 px.
- **Water tank:** steel cylinder with bands, a conical lid, a cage and legs on a big blue pad; the best looking one. 156 x 167 px, its round pad is the collision's size, smaller than the 4 x 4 diamond (256 px).
- **Roof vent:** a short round grey stack with a mushroom cap on a dark pad; small (58 x 74 px), smaller than its 2 x 2 footprint.
- **Street lamp:** thin dark pole on a round grey base, curved arm and a warm amber lamp head; good. 56 x 134 px. The lamp head points one way, so east and west show it on the other side.
- **Roof sign:** a dark panel with a cyan neon edge on two steel legs, amber glowing marks. The generation came with a rooftop and building around it; those were cut out by a script mask (panel and legs kept). **QA round 1 fix (free, no PixelLab):** the generated marks were real Chinese characters (one the real word 天), so `build_prop_final_art.py` (`replace_marks`) paints them over with the panel's colour and draws four made-up glyphs of a few straight strokes, amber with an orange halo, hard pixel edges, on the panel's slope. **The glyphs are script-drawn and are not real characters or words of any script.** All four rotations use them (mirrored in north and south; the same face shows from both sides). The generated original stays in `art-archive/T-256/raw/roof_sign_raw.png`.
- **General weak points, not regenerated:** props are smaller than their footprints (crates, AC unit, vent, cones, barrier about 60 to 80% of the footprint's diamond), so their art sits inside the blocked area; the footprints or collisions in `props.json` can be tuned instead (board's playtest). Several props came with a base pad, which reads as a rooftop pad or footing. No Redgull red in any sprite (check passes).

Tests: full GUT suite passed (`bash game/tools/run_tests.sh`, 400 s), `game/tools` Python tests 445 OK (new `test_build_prop_final_art.py`), `tools` Python tests 439 OK. Screenshots in `art-archive/T-256/screenshots/`: `rotations_sheet.png` (every prop, four rotations, anchors in magenta), `creator_close.png`, `creator_street.png`, `creator_roof.png`, `creator_panel.png` (every prop in four rotations in the creator, street and rooftop), `drive_end.png` (a run: the car beside the lamp). Refusals: two shell commands were refused by the guard hook (one using `set -a` to read the env file, one `curl` of PixelLab's openapi); I did not work around them, and the client reads the token itself, so nothing was needed. Documents updated: `docs/visual-style.md`, `game/README.md`, `art-archive/README.md`.
