#!/usr/bin/env python3
"""Writes the style loop briefs and action texts for T-613's kaiju animations into art-archive/T-613/. Free.

Run from the repo root: python game/tools/make_kaiju_anim_briefs.py
"""
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "art-archive" / "T-613"
FACE = {
    "s": "toward the camera (south, facing down the screen)",
    "se": "to the lower right (south-east)",
    "e": "to the right (east, side view)",
    "ne": "to the upper right (north-east, away from the camera)",
    "n": "away from the camera (north, seen from behind)",
}
ACT = {
    "walk": (
        "a heavy, slow kaiju stride: it walks forward on two thick legs, one foot lifting and planting down at a time, "
        "the body swaying slightly, the tail swinging behind, small arms swinging, head forward, keep the same colours "
        "and the same size, the sprite stays in the same place in the frame",
        6, "walk cycle (a loop: the last frame leads back into the first)"),
    "windup": (
        "meteor windup: the kaiju stops walking and plants both feet, then throws its head and chest back and raises its "
        "small arms and its open jaw up to the sky, roaring and calling down meteors; the pose rises in steady steps and "
        "the last two frames hold the arms raised, head thrown back, mouth wide open. The feet stay in place, it does not "
        "walk or slide. Keep the same colours and the same size: the dark slate-green hide, the lighter pale grey-green belly, the glowing yellow eyes and the pale cyan back plates must stay visible in every frame, not teal and not all-dark. No effects, no fire, no meteors, no particles, no shadow",
        6, "meteor windup (about 1 second before its meteors fall; it ends holding the raised roaring pose)"),
    "death": (
        "death animation: the kaiju is hit and jolts back, roars with its head thrown up, staggers, its legs buckle and it "
        "topples and collapses heavily onto the ground, small arms flopping, tail dropping flat, jaw hanging slack, eyes "
        "dimming; it ends lying still as a motionless huge corpse, the last two frames identical and still. The feet stay "
        "in place, it does not slide away. Keep the same colours. No blood, no liquid, no smoke, no particles, no shadow",
        8, "death (it ends as a still corpse, which the game holds and fades)"),
}

BRIEF = """Brief for T-613: the kaiju's {label}, direction {d} (it faces {face}), game/art/kaiju/kaiju_{d}.png.

Decision: docs/visual-style.md, Decisions, "The kaiju's animations" (board, 2026-11-09). The board's go (2026-11-09, new budget) covers this ONE sample only: at most 4 calls and 20 PixelLab units in total for it (a 224 px call costs 5 units; 1 plus up to 3 refines). No other PixelLab call. Write nothing outside art-archive/T-613/ except the style loop's own output.

What to make: ONE sheet, {n} frames of 224 x 224 px in one row ({w} x 224), transparent background, the same monster as the still sprite game/art/kaiju/kaiju_{d}.png (dark slate-green scaly hide, lighter grey-green belly, large pale cyan dorsal plates, glowing yellow eyes, same bold dark outline, same palette), same view, same size, same ground position as the still (feet where the still's feet are; frame 0 of the still is art-archive/T-613/reference_frame0_{d}.png). Every pixel fully opaque or fully transparent, at most 30 colours in the whole sheet (the still's own 30 colours), no shadow, no effects, none of Greenbull's colours.
Motion: {txt}

How: the request builder, from the repo root: python game/tools/pixellab_animate_req.py --first-frame art-archive/T-613/reference_frame0_{d}.png --out art-archive/T-613/req_{a}_{d}_vN.json --seed N --frames {n} --action-file art-archive/T-613/action_{a}.txt (for a refine write a new action file, never overwrite). Send it with: python game/tools/pixellab_client.py generate --endpoint animate-with-text-v3 --params-file art-archive/T-613/req_{a}_{d}_vN.json --out-dir art-archive/T-613/raw_{a}_{d}_vN --name {a}_{d} --consulted docs/visual-style.md --task T-613 (600 s HTTP timeout; a timed-out call is still charged; one call at a time, never retry blindly). PixelLab returns the frame it was given as image 0, so the {n} animated frames are raw images 1 to {n}.
Free script fixes come first, before any paid refine: python game/tools/build_kaiju_anim_sheet.py {d} art-archive/T-613/raw_{a}_{d}_vN {a}_{d} art-archive/T-613/kaiju_{a}_{d}_vN.png --count {n} --align [--hold K] [--pick DIR:I,...] --preview-dir art-archive/T-613/screenshots/{a}_{d}_vN --scale 3 (snaps to the still's palette, makes alpha 0 or 255, keeps the feet on the still's ground point, can pick frames from several raw folders and hold the last frames). It never overwrites a version. Look at the preview before submitting, and compare hide, belly and eyes with the still: an earlier animation (walk east) drifted to a teal hide with a lost belly and eyes; if frames drift, pick the frames that keep the look (--pick) before paying for a refine. The sheet it builds is what you hand to the loop.
Log lines go in game/art/pixellab-generation-log.jsonl automatically; the planned calls and cost are in the ticket's result notes.
"""


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for a, (txt, n, label) in ACT.items():
        (OUT / f"action_{a}.txt").write_text(txt, encoding="utf-8")
        for d, face in FACE.items():
            (OUT / f"brief_{a}_{d}.md").write_text(
                BRIEF.format(a=a, d=d, face=face, n=n, w=224 * n, txt=txt, label=label), encoding="utf-8")
    print("ok")


if __name__ == "__main__":
    main()
