"""Draws the speed bot's CSV (game/tools/speed_bot.gd --csv=...) as a PNG: forward speed over time
for the wheel at tier 1 and tier 2, log scale, with the car's normal top speed as a line (task T-527).
Usage: python game/tools/speed_bot_plot.py <in.csv> <out.png> [title]"""
import csv
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

TOP_SPEED = 16.5


def read(path):
    t, a, b = [], [], []
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            t.append(float(row["time"]))
            a.append(float(row["tier1"]))
            b.append(float(row["tier2"]))
    return t, a, b


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    t, a, b = read(argv[1])
    for dark in (True, False):
        fig, ax = plt.subplots(figsize=(9, 4.5), facecolor="#14141c" if dark else "white")
        fg = "white" if dark else "black"
        ax.set_facecolor("#14141c" if dark else "white")
        big = 1e300
        ax.plot(t, [min(x, big) for x in a], label="wheel tier 1", color="#ff9f43")
        ax.plot(t, [min(x, big) for x in b], label="wheel tier 2", color="#48dbfb")
        ax.axhline(TOP_SPEED, color="#ff6b6b", ls="--", label="normal top speed (16.5)")
        ax.set_yscale("log")
        ax.set_xlabel("seconds", color=fg)
        ax.set_ylabel("forward speed, units/s (log)", color=fg)
        ax.set_title(argv[3] if len(argv) > 3 else "Polarized Steering Wheel: the speed bot", color=fg)
        ax.tick_params(colors=fg)
        ax.legend(facecolor=ax.get_facecolor(), labelcolor=fg)
        out = argv[2] if dark else argv[2].replace(".png", "_light.png")
        fig.savefig(out, dpi=110, facecolor=fig.get_facecolor())
        plt.close(fig)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
