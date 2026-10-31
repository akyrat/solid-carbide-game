"""Plots the bounce distance per Bouncy Bumpers tier (task T-462).

The numbers are the ones tests/unit/test_bouncy_bumpers.gd prints (a head-on hit at
cruise speed, W held): run `bash game/tools/run_tests.sh -gselect=test_bouncy_bumpers`
and pass its output file, or use the built-in measured values.
Usage: python game/tools/plot_bouncy_bumpers.py [out.png]
"""
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

# (tier, data multiplier, measured distance in units); tier 0 = no power-up.
MEASURED = [(0, 1.0, 0.8690), (1, 1.4, 1.2262), (2, 1.8, 1.5851), (3, 2.2, 1.9443), (4, 2.6, 2.3048)]


def main(out: str) -> None:
    base = MEASURED[0][2]
    fig, ax = plt.subplots(figsize=(6, 4))
    ax.bar([t for t, _, _ in MEASURED], [d for _, _, d in MEASURED], color="#e8a33d", label="measured")
    ax.plot([t for t, _, _ in MEASURED], [base * m for _, m, _ in MEASURED], "k--o", label="base x data factor")
    for t, m, d in MEASURED:
        ax.text(t, d + 0.04, "%.2f (x%.2f)" % (d, d / base), ha="center", fontsize=8)
    ax.set_xlabel("Bouncy Bumpers tier (0 = not owned)")
    ax.set_ylabel("bounce distance off a wall (units)")
    ax.set_title("Bouncy Bumpers: head-on hit at cruise speed")
    ax.legend()
    fig.tight_layout()
    fig.savefig(out, dpi=150)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "art-archive/T-462/screenshots/bounce_distance_per_tier.png")
