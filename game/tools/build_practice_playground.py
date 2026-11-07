"""Builds the practice playground level (task T-560) into game/data/level/practice_playground.json.

Level design, Decisions, "The practice playground", and Content, "The practice playground".
A small level the tutorial's practice windows load (T-561), in the format the game and the level
creator load (the elevation sample map's), on the drift prototype's dark purple grid ground
(ground_style, scripts/level/grid_ground.gd). Every number is a proposal for the board's playtest.

Layout (units, x east, y south, the map's rect is 120 by 72 around (0, 0)):
- an open area in the west (x -60 to -16) for drifts and alt drifts;
- a runway along y = 0 to a ramp onto a small rooftop (height 3), and on the rooftop a jump ramp
  (3 to 5) whose top launches the car at full speed for an AIR 360! (airtime about 1.8 s);
- three rails in the car's flight path beyond it: two in line (near and far) and one beside the far
  one, a jump apart (3.5 units), all 1 unit over the street.
- "start_points": one per trick slide (drift, alt_drift, air_spin, grind); "spawn" is the drift one.

Usage, from the repo root:  python game/tools/build_practice_playground.py
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "data" / "level" / "practice_playground.json"
W, H = 120, 72
HALF_W, HALF_H = W // 2, H // 2
CELL = 2

# Grid ground colours: the drift prototype's purple (ground_grid.gd) lightened, so the dark tyre marks show (T-560).
GROUND_STYLE = {
    "kind": "grid",
    "ground_color": [0.23, 0.21, 0.37],
    "minor_color": [0.30, 0.28, 0.48],
    "major_color": [0.45, 0.41, 0.68],
    "major_every": 5,
}

START_POINTS = [
    {"id": "drift", "x": -45.0, "y": -19.0, "heading": 0},
    {"id": "alt_drift", "x": -45.0, "y": 19.0, "heading": 0},
    {"id": "air_spin", "x": -55.0, "y": 1.0, "heading": 0},
    {"id": "grind", "x": -29.0, "y": 1.0, "heading": 0},
]


def build() -> dict:
    n_cols, n_rows = W // CELL, H // CELL
    rows = [[0] * n_cols for _ in range(n_rows)]
    return {
        "name": "Practice playground",
        "task": "T-560",
        "generated_by": "python game/tools/build_practice_playground.py",
        "units": "1 unit = the car's width; the car is drawn 1 x 3 units",
        "origin": "x and y in units from the map's centre, x to the right, y down; rectangles give their top-left corner",
        "map": {"width": W, "height": H, "rect": {"x": -HALF_W, "y": -HALF_H, "w": W, "h": H}, "edge": "hard stop"},
        "legend": {"B": "building", "G": "gravel", "R": "road"},
        "ground_rows": ["R" * W for _ in range(H)],
        "ground": {"cell_units": CELL, "origin": [-HALF_W, -HALF_H], "cols": n_cols, "rows": n_rows,
                   "tiles": ["ground-gravel0"], "cells": rows},
        "ground_style": GROUND_STYLE,
        "buildings": [],
        "pattern_copies": [],
        "platforms": [
            {"id": "roof-1", "x": -2, "y": -6, "w": 16, "h": 12, "height": 3, "style": "carpark"},
        ],
        "ramps": [
            # Onto the rooftop from the runway (the creator's 0-3 ramp, 12 long, top at the roof's west side).
            {"id": "ramp-1", "platform": "roof-1", "side": "west", "x": -14, "y": -4, "w": 12, "h": 8,
             "bottom_height": 0, "top_height": 3, "style": "carpark"},
            # The jump ramp on the rooftop (the creator's 3-5 jump ramp, 4 long), top at the roof's east end.
            {"id": "ramp-2", "platform": "", "side": "west", "x": 8, "y": -4, "w": 4, "h": 8,
             "bottom_height": 3, "top_height": 5, "jump": True, "style": "carpark"},
        ],
        "props": [],
        "rails": [
            {"id": "rail-1", "x1": 16.0, "y1": 0.0, "z1": 1.0, "x2": 34.0, "y2": 0.0, "z2": 1.0},
            {"id": "rail-2", "x1": 38.0, "y1": 0.0, "z1": 1.0, "x2": 52.0, "y2": 0.0, "z2": 1.0},
            {"id": "rail-3", "x1": 38.0, "y1": 3.5, "z1": 1.0, "x2": 56.0, "y2": 3.5, "z2": 1.0},
        ],
        "spawn": {"x": START_POINTS[0]["x"], "y": START_POINTS[0]["y"], "heading": START_POINTS[0]["heading"]},
        "start_points": START_POINTS,
    }


def main() -> None:
    OUT.write_text(json.dumps(build(), indent=1) + "\n", encoding="utf-8")
    print("Wrote %s" % OUT)


if __name__ == "__main__":
    main()
