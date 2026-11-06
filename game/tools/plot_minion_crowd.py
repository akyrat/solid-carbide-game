"""Plots the crowd benchmark's frame time against the number of minions alive (task T-538).

Reads one or more CSV files written by minion_crowd_bench.gd --csv (normally through
minion_crowd_ab.sh, which labels each measure "before" or "after") and draws, per file, one
panel: for each label the average frame time at each count (the median of the rounds, with the
lowest and highest round as a bar), and the 16.6 ms line (60 frames a second).

Usage, from the repo root:
    python game/tools/plot_minion_crowd.py FILE.csv [FILE2.csv ...] --out PATH.png
        [--titles "Headless,In the window"] [--stat frame_avg_ms]
Exit codes: 0 = written; 1 = no data; 2 = bad arguments.
"""
import argparse
import csv
import statistics
import sys
from pathlib import Path

BUDGET_MS = 1000.0 / 60.0
# Categorical slots 1 and 2 of the reference palette (dataviz skill), in fixed order.
COLOURS = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100"]
SURFACE = "#fcfcfb"
TEXT = "#0b0b0b"
MUTED = "#52514e"


def read_rows(path):
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def summarise(rows, stat="frame_avg_ms"):
    """{label: [(count, median, low, high), ...]} sorted by count, labels in first-seen order."""
    groups = {}
    for r in rows:
        label = r["label"] or "run"
        groups.setdefault(label, {}).setdefault(int(r["count"]), []).append(float(r[stat]))
    out = {}
    for label, by_count in groups.items():
        out[label] = [(c, statistics.median(v), min(v), max(v)) for c, v in sorted(by_count.items())]
    return out


def plot(panels, out_path, stat="frame_avg_ms"):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, axes = plt.subplots(1, len(panels), figsize=(5.2 * len(panels), 4.2), squeeze=False, facecolor=SURFACE)
    top = BUDGET_MS * 1.25
    for _, summary in panels:
        for series in summary.values():
            top = max(top, max(s[3] for s in series) * 1.1)
    for ax, (title, summary) in zip(axes[0], panels):
        ax.set_facecolor(SURFACE)
        ax.axhline(BUDGET_MS, color=MUTED, linewidth=1, linestyle=(0, (4, 3)))
        ax.text(0.01, BUDGET_MS, " 16.6 ms (60 fps)", transform=ax.get_yaxis_transform(), va="bottom",
                ha="left", fontsize=8, color=MUTED)
        for i, (label, series) in enumerate(summary.items()):
            colour = COLOURS[i % len(COLOURS)]
            xs = [s[0] for s in series]
            ys = [s[1] for s in series]
            lo = [s[1] - s[2] for s in series]
            hi = [s[3] - s[1] for s in series]
            ax.errorbar(xs, ys, yerr=[lo, hi], color=colour, linewidth=2, marker="o", markersize=7,
                        markeredgecolor=SURFACE, markeredgewidth=2, capsize=3, elinewidth=1, label=label)
            ax.annotate("%s %.1f ms" % (label, ys[-1]), (xs[-1], ys[-1]), textcoords="offset points",
                        xytext=(6, 0), va="center", fontsize=8, color=TEXT)
        ax.set_title(title, fontsize=10, color=TEXT, loc="left")
        ax.set_xlabel("minions alive", fontsize=9, color=MUTED)
        ax.set_ylabel("%s (median of rounds)" % stat.replace("_", " "), fontsize=9, color=MUTED)
        ax.set_ylim(0, top)
        all_x = sorted({s[0] for series in summary.values() for s in series})
        ax.set_xticks(all_x)
        ax.set_xlim(0, max(all_x) * 1.25)
        ax.grid(axis="y", color="#e4e3df", linewidth=0.8)
        for side in ("top", "right"):
            ax.spines[side].set_visible(False)
        for side in ("left", "bottom"):
            ax.spines[side].set_color("#c9c8c2")
        ax.tick_params(colors=MUTED, labelsize=8)
        ax.legend(frameon=False, fontsize=8, loc="upper left", bbox_to_anchor=(0.0, 0.93))
    fig.tight_layout()
    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=150, facecolor=SURFACE)
    plt.close(fig)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("files", nargs="+")
    p.add_argument("--out", required=True)
    p.add_argument("--titles", default="")
    p.add_argument("--stat", default="frame_avg_ms")
    a = p.parse_args(argv)
    titles = [t.strip() for t in a.titles.split(",")] if a.titles else []
    panels = []
    for i, f in enumerate(a.files):
        rows = read_rows(f)
        if not rows:
            continue
        if a.stat not in rows[0]:
            print("plot_minion_crowd: no column %s in %s" % (a.stat, f), file=sys.stderr)
            return 2
        panels.append((titles[i] if i < len(titles) else Path(f).stem, summarise(rows, a.stat)))
    if not panels:
        print("plot_minion_crowd: no data", file=sys.stderr)
        return 1
    plot(panels, a.out, a.stat)
    print("plot_minion_crowd: wrote %s" % a.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
