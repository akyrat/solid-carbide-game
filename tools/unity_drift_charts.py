"""Re-implements the car movement of the board's Unity prototype and draws charts.

Task T-006. The formulas come from reading the Unity project's C# code
(`Assets/Scripts/Player/PlayerCarController.cs`, `PlayerStats.cs`,
`TilemapGroundDrag.cs`) and its serialized values (`Assets/Data/Vehicles/
Vehicle_Default.asset`, the stage scenes, `ProjectSettings/TimeManager.asset`).
Nothing here runs Unity: the charts show what the formulas do.

Run from the repo root:

    python tools/unity_drift_charts.py            # writes the SVG charts into docs/drifting/
    python tools/unity_drift_charts.py --summary  # also prints the key numbers used in the report

Python 3.9+ and matplotlib. Running it twice gives byte-identical SVG files.
"""

from __future__ import annotations

import argparse
import math
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Callable, List, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = REPO_ROOT / "docs" / "drifting"

# Unity's fixed timestep (ProjectSettings/TimeManager.asset, "Fixed Timestep: 0.02") = 50 Hz.
FIXED_DT = 0.02


@dataclass(frozen=True)
class Tuning:
    """The values PlayerCarController reads (through PlayerStats from VehicleData)."""

    forward_speed: float = 11.0          # cruise speed, units/s (Vehicle_Default.asset forwardSpeed)
    turn_speed: float = 202.0            # deg/s (Vehicle_Default.asset turnSpeed)
    top_speed_multiplier: float = 2.5    # top = forward_speed * this
    time_to_top_speed: float = 2.3       # s; sets the ramp/brake rate
    coast_decel_multiplier: float = 0.3  # fraction of top speed lost per second when coasting
    steer_sensitivity: float = 0.95      # multiplier on turn_speed
    drift_factor: float = 0.98           # sideways velocity kept per physics step, not drifting
    drift_grip_low_speed: float = 0.98   # sideways kept per step while drifting, at low speed
    drift_grip_high_speed: float = 0.98  # sideways kept per step while drifting, at high speed
    drift_speed_reference: float = 20.0  # forward speed (units/s) at which high-speed grip applies fully
    drift_enter_rate: float = 12.0       # drift amount per second towards 1
    drift_exit_rate: float = 3.0         # drift amount per second towards 0
    linear_damping: float = 0.0          # Rigidbody2D linear damping (2.0 extra off-road on Stage_Isometric)
    dt: float = FIXED_DT

    @property
    def top_speed(self) -> float:
        return self.forward_speed * self.top_speed_multiplier

    @property
    def ramp_delta(self) -> float:
        """Speed change per step for forward ramp, braking and reverse ramp."""
        return self.top_speed / max(0.1, self.time_to_top_speed) * self.dt

    @property
    def coast_delta(self) -> float:
        return self.top_speed * self.coast_decel_multiplier * self.dt

    @property
    def turn_rate(self) -> float:
        """Degrees per second the body rotates while A or D is held."""
        return self.turn_speed * self.steer_sensitivity


# Values the game actually uses: Vehicle_Default.asset, assigned to PlayerStats in every stage scene.
PROTOTYPE = Tuning()

# Defaults written in the C# source of VehicleData.cs (what a brand-new VehicleData asset would get).
# PlayerStats clamps the three grip values to 0..1, so 1.2 behaves as 1.0.
VEHICLEDATA_SCRIPT_DEFAULTS = Tuning(
    turn_speed=259.0, drift_factor=1.0, drift_grip_low_speed=1.0, drift_grip_high_speed=1.0,
    drift_exit_rate=12.0,
)


# --- Unity math helpers (same behaviour as UnityEngine.Mathf) ---------------------------------

def move_towards(current: float, target: float, max_delta: float) -> float:
    if abs(target - current) <= max_delta:
        return target
    return current + math.copysign(max_delta, target - current)


def clamp01(x: float) -> float:
    return 0.0 if x < 0.0 else 1.0 if x > 1.0 else x


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * clamp01(t)


# --- The prototype's formulas ------------------------------------------------------------------

def update_drift_amount(amount: float, accel: bool, reverse: bool, steer: float, t: Tuning) -> float:
    """PlayerCarController.UpdateDriftAmount: linear ramp towards 1 while drive + steer are held."""
    drifting = (accel or reverse) and abs(steer) > 0.01
    rate = t.drift_enter_rate if drifting else t.drift_exit_rate
    return move_towards(amount, 1.0 if drifting else 0.0, max(0.0, rate) * t.dt)


def sideways_grip(forward_speed: float, drift_amount: float, t: Tuning) -> float:
    """PlayerCarController.GetEffectiveSidewaysGrip: fraction of sideways velocity kept this step."""
    speed01 = clamp01(abs(forward_speed) / max(0.01, t.drift_speed_reference))
    grip_at_speed = lerp(t.drift_grip_low_speed, t.drift_grip_high_speed, speed01)
    return lerp(t.drift_factor, grip_at_speed, clamp01(drift_amount))


def new_forward_speed(current: float, accel: bool, reverse: bool, t: Tuning) -> float:
    """PlayerCarController.ApplyMovementAndDrift, forward-axis part. W wins over S."""
    if accel:
        if current < t.forward_speed:
            return t.forward_speed  # instant snap to cruise
        return move_towards(current, t.top_speed, t.ramp_delta)
    if reverse:
        if current > 0.0:
            return move_towards(current, 0.0, t.ramp_delta)  # brake
        if current > -t.forward_speed:
            return -t.forward_speed  # instant snap to reverse cruise
        return move_towards(current, -t.top_speed, t.ramp_delta)
    return move_towards(current, 0.0, t.coast_delta)  # coast


@dataclass
class CarState:
    x: float = 0.0
    y: float = 0.0
    angle: float = 0.0  # Rigidbody2D.rotation in degrees, counter-clockwise; 0 = nose up (+y)
    vx: float = 0.0
    vy: float = 0.0
    drift_amount: float = 0.0

    def axes(self) -> Tuple[Tuple[float, float], Tuple[float, float]]:
        """(transform.up, transform.right) for the current rotation."""
        a = math.radians(self.angle)
        return (-math.sin(a), math.cos(a)), (math.cos(a), math.sin(a))

    def forward_sideways(self) -> Tuple[float, float]:
        (ux, uy), (rx, ry) = self.axes()
        return self.vx * ux + self.vy * uy, self.vx * rx + self.vy * ry


def step(s: CarState, accel: bool, reverse: bool, steer: float, t: Tuning) -> CarState:
    """One FixedUpdate of PlayerCarController followed by one Physics2D step (grounded car).

    steer: +1 = A (rotate counter-clockwise, to the left), -1 = D. S counts only when W is not held.
    """
    reverse = reverse and not accel
    drift = update_drift_amount(s.drift_amount, accel, reverse, steer, t)
    # ApplySteering: MoveRotation; the body only reaches the new angle during the physics step,
    # so the velocity below is still built on this step's starting heading.
    new_angle = s.angle + steer * t.turn_rate * t.dt
    (ux, uy), (rx, ry) = s.axes()
    fwd, side = s.forward_sideways()
    nf = new_forward_speed(fwd, accel, reverse, t)
    ns = side * sideways_grip(nf, drift, t)
    vx = ux * nf + rx * ns
    vy = uy * nf + ry * ns
    # Box2D linear damping, applied in the physics step: v *= 1 / (1 + dt * damping).
    damp = 1.0 / (1.0 + t.dt * t.linear_damping)
    vx *= damp
    vy *= damp
    return CarState(s.x + vx * t.dt, s.y + vy * t.dt, new_angle, vx, vy, drift)


InputFn = Callable[[float], Tuple[bool, bool, float]]


def simulate(inputs: InputFn, seconds: float, t: Tuning = PROTOTYPE,
             start: CarState | None = None) -> List[Tuple[float, CarState]]:
    """Runs the car for `seconds`. inputs(time) -> (W held, S held, steer). Returns (time, state) per step."""
    s = start if start is not None else CarState()
    out = [(0.0, s)]
    n = int(round(seconds / t.dt))
    for i in range(n):
        w, back, steer = inputs(i * t.dt)
        s = step(s, w, back, steer, t)
        out.append(((i + 1) * t.dt, s))
    return out


def steady_state_sideways(forward: float, t: Tuning = PROTOTYPE, grip: float | None = None) -> float:
    """Sideways speed a held turn settles at, if forward speed stays at `forward`.

    Each step: side' = grip * (side * cos d + forward * sin d), d = turn per step.
    """
    g = sideways_grip(forward, 1.0, t) if grip is None else grip
    d = math.radians(t.turn_rate * t.dt)
    return g * forward * math.sin(d) / (1.0 - g * math.cos(d))


def slip_angle_deg(s: CarState) -> float:
    f, side = s.forward_sideways()
    if abs(f) < 1e-9 and abs(side) < 1e-9:
        return 0.0
    return math.degrees(math.atan2(side, f))


# --- Charts -----------------------------------------------------------------------------------

# Reference palette (dataviz skill, categorical slots 1-3 in fixed order) on the light surface.
C1, C2, C3 = "#2a78d6", "#eb6834", "#1baf7a"
INK, INK2, GRID, SURFACE = "#0b0b0b", "#52514e", "#e4e3df", "#fcfcfb"
FOOTNOTE = "Re-implemented from the Unity code at 50 physics steps per second; not recorded from Unity."


def _setup_matplotlib():
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    matplotlib.rcParams.update({
        "svg.hashsalt": "t006-unity-drift",  # fixed ids -> identical files on every run
        "svg.fonttype": "none",
        "font.family": "DejaVu Sans",
        "font.size": 10,
        "axes.edgecolor": INK2,
        "axes.labelcolor": INK,
        "axes.titlecolor": INK,
        "axes.titlesize": 12,
        "axes.titleweight": "bold",
        "axes.titlelocation": "left",
        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.grid": True,
        "grid.color": GRID,
        "grid.linewidth": 0.8,
        "xtick.color": INK2,
        "ytick.color": INK2,
        "figure.facecolor": SURFACE,
        "axes.facecolor": SURFACE,
        "legend.frameon": False,
        "lines.linewidth": 2.0,
    })
    return plt


def _finish(plt, fig, name: str, out_dir: Path) -> Path:
    fig.text(0.01, 0.01, FOOTNOTE, fontsize=8, color=INK2)
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    path = out_dir / name
    fig.savefig(path, format="svg", metadata={"Date": None, "Creator": "tools/unity_drift_charts.py"})
    plt.close(fig)
    return path


def chart_speed_forward(plt, out_dir: Path, t: Tuning = PROTOTYPE) -> Path:
    # Hold W for 3 s from standstill, then release (coast).
    run = simulate(lambda time: (time < 3.0, False, 0.0), 6.5, t)
    times = [tm for tm, _ in run]
    speeds = [s.forward_sideways()[0] for _, s in run]
    fig, ax = plt.subplots(figsize=(7.5, 4.2))
    ax.plot(times, speeds, color=C1, label="Forward speed")
    ax.axvline(3.0, color=INK2, linewidth=1, linestyle=":")
    ax.annotate("W released: coasting", (3.0, t.top_speed), xytext=(3.15, t.top_speed + 1.2), color=INK2, fontsize=9)
    ax.annotate(f"Instant jump to cruise {t.forward_speed:g}", (0.02, t.forward_speed),
                xytext=(0.35, t.forward_speed - 4.5), color=INK2, fontsize=9,
                arrowprops={"arrowstyle": "-", "color": INK2, "lw": 0.8})
    ax.annotate(f"Top speed {t.top_speed:g}", (1.6, t.top_speed), xytext=(1.6, t.top_speed + 1.2), color=INK2, fontsize=9)
    ax.set_title("Holding W from standstill, then letting go")
    ax.set_xlabel("Time (s)")
    ax.set_ylabel("Forward speed (units/s)")
    ax.set_ylim(0, t.top_speed + 4)
    ax.set_xlim(0, 6.5)
    return _finish(plt, fig, "speed-hold-w.svg", out_dir)


def chart_reverse(plt, out_dir: Path, t: Tuning = PROTOTYPE) -> Path:
    # At top speed forward, hold S for 4.5 s (brake, then reverse), then press W.
    start = CarState(vy=t.top_speed)
    run = simulate(lambda time: (time >= 4.5, time < 4.5, 0.0), 5.5, t, start)
    times = [tm for tm, _ in run]
    speeds = [s.forward_sideways()[0] for _, s in run]
    fig, ax = plt.subplots(figsize=(7.5, 4.2))
    ax.plot(times, speeds, color=C1, label="Forward speed (negative = reversing)")
    ax.axhline(0, color=INK2, linewidth=0.8)
    ax.axvline(4.5, color=INK2, linewidth=1, linestyle=":")
    ax.annotate("S held: brakes to 0", (0.3, 22), color=INK2, fontsize=9)
    ax.annotate(f"then snaps to -{t.forward_speed:g}\nand ramps to -{t.top_speed:g}", (2.4, -7), color=INK2, fontsize=9)
    ax.annotate(f"W pressed: snaps\nstraight to +{t.forward_speed:g}", (4.55, 3), color=INK2, fontsize=9)
    ax.set_title("Reverse on S: brake first, then reverse")
    ax.set_xlabel("Time (s)")
    ax.set_ylabel("Forward speed (units/s)")
    ax.set_xlim(0, 5.5)
    return _finish(plt, fig, "speed-reverse.svg", out_dir)


def chart_turn_rate(plt, out_dir: Path, t: Tuning = PROTOTYPE) -> Path:
    speeds = [i * 0.5 for i in range(0, 61)]
    rates = [t.turn_rate for _ in speeds]
    fig, ax = plt.subplots(figsize=(7.5, 4.0))
    ax.plot(speeds, rates, color=C1)
    ax.annotate(f"{t.turn_rate:.1f} deg/s at every speed, even standing still or reversing",
                (1, t.turn_rate + 12), color=INK2, fontsize=9)
    ax.set_title("How fast the car rotates while A or D is held")
    ax.set_xlabel("Car speed (units/s)")
    ax.set_ylabel("Rotation rate (deg/s)")
    ax.set_ylim(0, 260)
    ax.set_xlim(0, 30)
    return _finish(plt, fig, "turn-rate-vs-speed.svg", out_dir)


def _drift_run(t: Tuning = PROTOTYPE, hold: float = 3.0, total: float = 5.0):
    # Driving straight at top speed with W held; A held from t=0 to `hold`, W kept on throughout.
    start = CarState(vy=t.top_speed)
    return simulate(lambda time: (True, False, 1.0 if time < hold else 0.0), total, t, start)


def chart_drift_build(plt, out_dir: Path, t: Tuning = PROTOTYPE) -> Path:
    run = _drift_run(t)
    times = [tm for tm, _ in run]
    fwd = [s.forward_sideways()[0] for _, s in run]
    side = [abs(s.forward_sideways()[1]) for _, s in run]
    total = [math.hypot(s.vx, s.vy) for _, s in run]
    fig, ax = plt.subplots(figsize=(7.5, 4.4))
    ax.plot(times, total, color=C3, label="Total speed")
    ax.plot(times, fwd, color=C1, label="Forward (along the nose)", linestyle="--")
    ax.plot(times, side, color=C2, label="Sideways (the slide)", linestyle="-.")
    ax.axvline(3.0, color=INK2, linewidth=1, linestyle=":")
    ax.annotate("A released\n(W still held)", (3.05, 3), color=INK2, fontsize=9)
    ax.set_title("Holding W + A from top speed: the slide builds")
    ax.set_xlabel("Time (s)")
    ax.set_ylabel("Speed (units/s)")
    ax.set_xlim(0, 5)
    ax.set_ylim(0, 40)
    ax.legend(loc="upper right", fontsize=9)
    return _finish(plt, fig, "drift-build-speeds.svg", out_dir)


def chart_slip_angle(plt, out_dir: Path, t: Tuning = PROTOTYPE) -> Path:
    run = _drift_run(t)
    times = [tm for tm, _ in run]
    slip = [abs(slip_angle_deg(s)) for _, s in run]
    fig, ax = plt.subplots(figsize=(7.5, 4.0))
    ax.plot(times, slip, color=C1)
    ax.axvline(3.0, color=INK2, linewidth=1, linestyle=":")
    ax.annotate("A released", (3.05, 5), color=INK2, fontsize=9)
    ax.set_title("Drift angle while W + A is held (angle between nose and travel)")
    ax.set_xlabel("Time (s)")
    ax.set_ylabel("Drift angle (deg)")
    ax.set_xlim(0, 5)
    ax.set_ylim(0, 90)
    return _finish(plt, fig, "drift-angle.svg", out_dir)


def chart_drift_amount(plt, out_dir: Path, t: Tuning = PROTOTYPE) -> Path:
    run = simulate(lambda time: (True, False, 1.0 if time < 0.5 else 0.0), 1.0, t, CarState(vy=t.top_speed))
    times = [tm for tm, _ in run]
    amount = [s.drift_amount for _, s in run]
    fig, ax = plt.subplots(figsize=(7.5, 3.8))
    ax.step(times, amount, where="post", color=C1)
    ax.axvline(0.5, color=INK2, linewidth=1, linestyle=":")
    ax.annotate(f"in: +{t.drift_enter_rate:g}/s (full after {1 / t.drift_enter_rate:.2f} s)", (0.03, 1.05), color=INK2, fontsize=9)
    ax.annotate(f"out: -{t.drift_exit_rate:g}/s (gone after {1 / t.drift_exit_rate:.2f} s)", (0.53, 1.05), color=INK2, fontsize=9)
    if t.drift_factor == t.drift_grip_low_speed == t.drift_grip_high_speed:
        ax.annotate(f"With the saved car values all three grips are {t.drift_factor:g},\n"
                    "so this blend does not change the handling.", (0.45, 0.35), color=INK2, fontsize=9,
                    ha="right")
    ax.set_title("The coded \"drift amount\" while W + A is held, then A released")
    ax.set_xlabel("Time (s)")
    ax.set_ylabel("Drift amount (0 to 1)")
    ax.set_ylim(0, 1.2)
    ax.set_xlim(0, 1.0)
    return _finish(plt, fig, "drift-amount.svg", out_dir)


def chart_drift_path(plt, out_dir: Path, t: Tuning = PROTOTYPE) -> Path:
    run = _drift_run(t, hold=3.0, total=4.0)
    fig, ax = plt.subplots(figsize=(6.5, 6.5))
    ax.plot([s.x for _, s in run], [s.y for _, s in run], color=C1, label="Path of the car")
    for i in range(0, len(run), 10):  # nose direction every 0.2 s
        _, s = run[i]
        (ux, uy), _ = s.axes()
        ax.plot([s.x, s.x + ux * 2.0], [s.y, s.y + uy * 2.0], color=C2, linewidth=1.2,
                label="Nose direction (every 0.2 s)" if i == 0 else None)
    ax.set_aspect("equal", adjustable="datalim")
    ax.set_title("Top-down path: 3 s of W + A from top speed, then 1 s of W")
    ax.set_xlabel("x (units; the car is 1 unit long)")
    ax.set_ylabel("y (units)")
    ax.legend(loc="upper left", fontsize=9)
    return _finish(plt, fig, "drift-path.svg", out_dir)


CHARTS = [chart_speed_forward, chart_reverse, chart_turn_rate, chart_drift_amount,
          chart_drift_build, chart_slip_angle, chart_drift_path]


def write_charts(out_dir: Path = OUT_DIR) -> List[Path]:
    plt = _setup_matplotlib()
    out_dir.mkdir(parents=True, exist_ok=True)
    return [fn(plt, out_dir) for fn in CHARTS]


def summary(t: Tuning = PROTOTYPE) -> List[str]:
    lines = [
        f"top speed: {t.top_speed:.3f} units/s",
        f"ramp/brake per step: {t.ramp_delta:.5f} ({t.ramp_delta / t.dt:.3f} units/s^2)",
        f"coast per step: {t.coast_delta:.5f} ({t.coast_delta / t.dt:.3f} units/s^2)",
        f"turn rate: {t.turn_rate:.2f} deg/s = {t.turn_rate * t.dt:.3f} deg/step",
        f"sideways kept per second at grip {t.drift_factor}: {t.drift_factor ** (1 / t.dt):.4f}",
        f"steady sideways at cruise: {steady_state_sideways(t.forward_speed, t):.3f}",
    ]
    run = simulate(lambda time: (True, False, 0.0), 3.0, t)
    reach = next(tm for tm, s in run if s.forward_sideways()[0] >= t.top_speed - 1e-9)
    lines.append(f"W from rest reaches top at t={reach:.2f} s")
    drift = _drift_run(t)
    at3 = [s for tm, s in drift if abs(tm - 3.0) < 1e-9][0]
    peak = max(math.hypot(s.vx, s.vy) for _, s in drift)
    f3, s3 = at3.forward_sideways()
    lines.append(f"W+A from top, at 3 s: forward {f3:.2f}, sideways {s3:.2f}, slip {slip_angle_deg(at3):.1f} deg, "
                 f"total {math.hypot(f3, s3):.2f}; peak total {peak:.2f}")
    for target in (45.0, 60.0, 70.0):
        tm = next((tm for tm, s in drift if abs(slip_angle_deg(s)) >= target), None)
        lines.append(f"slip reaches {target:g} deg at t={tm}")
    for tm, s in drift:
        if tm in (0.5, 1.0, 2.0):
            lines.append(f"t={tm}: forward {s.forward_sideways()[0]:.2f} sideways {s.forward_sideways()[1]:.2f} slip {slip_angle_deg(s):.1f}")
    after = [s for tm, s in drift if abs(tm - 5.0) < 1e-9][0]
    lines.append(f"2 s after releasing A (W held): slip {slip_angle_deg(after):.1f} deg, forward {after.forward_sideways()[0]:.2f}")
    xs = [s.x for _, s in drift if _ <= 3.0]
    ys = [s.y for tm, s in drift if tm <= 3.0]
    lines.append(f"path extent first 3 s: x {min(xs):.1f}..{max(xs):.1f}, y {min(ys):.1f}..{max(ys):.1f}")
    off_run = _drift_run(replace(t, linear_damping=2.0))
    off3 = [s for tm, s in off_run if abs(tm - 3.0) < 1e-9][0]
    lines.append(f"off-road (damping 2), W+A at 3 s: total {math.hypot(off3.vx, off3.vy):.2f}, "
                 f"slip {slip_angle_deg(off3):.1f} deg")
    straight = simulate(lambda time: (True, False, 0.0), 10.0, replace(t, linear_damping=2.0))
    lines.append(f"off-road, W held 10 s straight: speed {straight[-1][1].forward_sideways()[0]:.2f}")
    return lines


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", type=Path, default=OUT_DIR, help="folder for the SVG files")
    parser.add_argument("--summary", action="store_true", help="print the key numbers used in the report")
    args = parser.parse_args(argv)
    for p in write_charts(args.out):
        print(f"wrote {p.relative_to(REPO_ROOT) if p.is_relative_to(REPO_ROOT) else p}")
    if args.summary:
        print("\n".join(summary()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
