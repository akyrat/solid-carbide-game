"""Tests for unity_drift_charts.py (task T-006). Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"

Expected values are worked out by hand from the Unity code
(PlayerCarController.cs, PlayerStats.cs) and Vehicle_Default.asset.
"""

import hashlib
import math
import sys
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import unity_drift_charts as u  # noqa: E402

T = u.PROTOTYPE


def forward_after(steps, accel=False, reverse=False, steer=0.0, start=None, t=T):
    s = start if start is not None else u.CarState()
    for _ in range(steps):
        s = u.step(s, accel, reverse, steer, t)
    return s


class DerivedValues(unittest.TestCase):
    def test_prototype_values_match_vehicle_default_asset(self):
        self.assertEqual((T.forward_speed, T.turn_speed), (11.0, 202.0))
        self.assertEqual((T.top_speed_multiplier, T.time_to_top_speed), (2.5, 2.3))
        self.assertEqual((T.coast_decel_multiplier, T.steer_sensitivity), (0.3, 0.95))
        self.assertEqual((T.drift_factor, T.drift_grip_low_speed, T.drift_grip_high_speed), (0.98, 0.98, 0.98))
        self.assertEqual((T.drift_speed_reference, T.drift_enter_rate, T.drift_exit_rate), (20.0, 12.0, 3.0))
        self.assertEqual(T.dt, 0.02)

    def test_hand_worked_rates(self):
        self.assertAlmostEqual(T.top_speed, 27.5)                 # 11 * 2.5
        self.assertAlmostEqual(T.ramp_delta, 27.5 / 2.3 * 0.02)   # 0.2391304 per step
        self.assertAlmostEqual(T.coast_delta, 0.165)              # 27.5 * 0.3 * 0.02
        self.assertAlmostEqual(T.turn_rate, 191.9)                # 202 * 0.95
        self.assertAlmostEqual(T.turn_rate * T.dt, 3.838)


class MathfHelpers(unittest.TestCase):
    def test_move_towards(self):
        self.assertEqual(u.move_towards(0.0, 1.0, 0.24), 0.24)
        self.assertEqual(u.move_towards(0.96, 1.0, 0.24), 1.0)
        self.assertEqual(u.move_towards(5.0, 0.0, 2.0), 3.0)
        self.assertEqual(u.move_towards(-5.0, 0.0, 10.0), 0.0)

    def test_lerp_clamps(self):
        self.assertEqual(u.lerp(0.0, 10.0, 1.5), 10.0)
        self.assertEqual(u.lerp(0.0, 10.0, -1.0), 0.0)


class ForwardAxis(unittest.TestCase):
    def test_w_from_standstill_snaps_to_cruise_then_ramps(self):
        self.assertAlmostEqual(u.new_forward_speed(0.0, True, False, T), 11.0)
        self.assertAlmostEqual(u.new_forward_speed(11.0, True, False, T), 11.0 + 0.2391304, places=6)
        self.assertAlmostEqual(u.new_forward_speed(27.4, True, False, T), 27.5)

    def test_w_reaches_top_speed_after_70_steps(self):
        # 1 step to snap to 11, then ceil(16.5 / 0.2391304) = 69 steps of ramp.
        s69 = forward_after(69, accel=True)
        s70 = forward_after(70, accel=True)
        self.assertLess(s69.forward_sideways()[0], 27.5)
        self.assertAlmostEqual(s70.forward_sideways()[0], 27.5)

    def test_s_while_moving_forward_brakes_at_ramp_rate(self):
        self.assertAlmostEqual(u.new_forward_speed(27.5, False, True, T), 27.5 - 0.2391304, places=6)
        self.assertAlmostEqual(u.new_forward_speed(0.1, False, True, T), 0.0)

    def test_s_at_standstill_snaps_to_reverse_cruise_then_ramps(self):
        self.assertAlmostEqual(u.new_forward_speed(0.0, False, True, T), -11.0)
        self.assertAlmostEqual(u.new_forward_speed(-11.0, False, True, T), -11.2391304, places=6)
        self.assertAlmostEqual(u.new_forward_speed(-27.4, False, True, T), -27.5)

    def test_brake_from_top_speed_takes_about_2_3_seconds(self):
        start = u.CarState(vy=27.5)
        run = u.simulate(lambda tm: (False, True, 0.0), 3.0, T, start)
        stop = next(tm for tm, s in run if s.forward_sideways()[0] <= 1e-9)
        self.assertAlmostEqual(stop, 2.30, delta=0.021)

    def test_w_while_reversing_snaps_straight_to_forward_cruise(self):
        self.assertAlmostEqual(u.new_forward_speed(-27.5, True, False, T), 11.0)

    def test_w_wins_over_s(self):
        s = u.step(u.CarState(), True, True, 0.0, T)
        self.assertAlmostEqual(s.forward_sideways()[0], 11.0)

    def test_coast(self):
        self.assertAlmostEqual(u.new_forward_speed(27.5, False, False, T), 27.335)
        self.assertAlmostEqual(u.new_forward_speed(-1.0, False, False, T), -0.835)
        self.assertEqual(u.new_forward_speed(0.1, False, False, T), 0.0)


class DriftAndGrip(unittest.TestCase):
    def test_drift_amount_enters_at_0_24_per_step_and_exits_at_0_06(self):
        a = 0.0
        seen = []
        for _ in range(5):
            a = u.update_drift_amount(a, True, False, 1.0, T)
            seen.append(round(a, 6))
        self.assertEqual(seen, [0.24, 0.48, 0.72, 0.96, 1.0])
        self.assertAlmostEqual(u.update_drift_amount(1.0, True, False, 0.0, T), 0.94)

    def test_drift_needs_drive_and_steer(self):
        self.assertEqual(u.update_drift_amount(0.0, False, False, 1.0, T), 0.0)  # steering only
        self.assertAlmostEqual(u.update_drift_amount(0.0, False, True, -1.0, T), 0.24)  # reverse counts

    def test_grip_is_0_98_whatever_the_drift_amount_with_saved_values(self):
        for f in (0.0, 11.0, 27.5):
            for a in (0.0, 0.5, 1.0):
                self.assertAlmostEqual(u.sideways_grip(f, a, T), 0.98)

    def test_grip_blend_formula(self):
        t = replace(T, drift_factor=0.98, drift_grip_low_speed=0.5, drift_grip_high_speed=0.9)
        # speed01 = 10/20 = 0.5 -> grip at speed 0.7; drift 0.5 -> lerp(0.98, 0.7, 0.5) = 0.84
        self.assertAlmostEqual(u.sideways_grip(10.0, 0.5, t), 0.84)
        self.assertAlmostEqual(u.sideways_grip(-40.0, 1.0, t), 0.9)  # uses |forward|, clamped

    def test_sideways_decays_by_2_percent_per_step(self):
        start = u.CarState(vx=10.0)  # nose up, sliding right at 10
        s = u.step(start, False, False, 0.0, T)
        self.assertAlmostEqual(s.forward_sideways()[1], 9.8)

    def test_steady_state_slide_at_cruise(self):
        d = math.radians(3.838)
        expected = 0.98 * 11.0 * math.sin(d) / (1 - 0.98 * math.cos(d))
        self.assertAlmostEqual(u.steady_state_sideways(11.0, T), expected)
        self.assertAlmostEqual(expected, 32.5, delta=0.1)


class Steering(unittest.TestCase):
    def test_a_turns_left_d_turns_right_at_3_838_deg_per_step(self):
        self.assertAlmostEqual(u.step(u.CarState(), False, False, 1.0, T).angle, 3.838)
        self.assertAlmostEqual(u.step(u.CarState(), False, False, -1.0, T).angle, -3.838)

    def test_rotates_even_when_standing_still(self):
        s = u.step(u.CarState(), False, False, 1.0, T)
        self.assertEqual((s.vx, s.vy), (0.0, 0.0))
        self.assertNotEqual(s.angle, 0.0)

    def test_velocity_uses_heading_from_start_of_step(self):
        # First step of W + A from rest: velocity is along the old heading (+y), body has turned.
        s = u.step(u.CarState(), True, False, 1.0, T)
        self.assertAlmostEqual(s.vx, 0.0)
        self.assertAlmostEqual(s.vy, 11.0)
        self.assertAlmostEqual(s.angle, 3.838)


class Damping(unittest.TestCase):
    def test_box2d_damping_formula(self):
        t = replace(T, linear_damping=2.0)
        s = u.step(u.CarState(vy=20.0), False, False, 0.0, t)
        self.assertAlmostEqual(s.vy, (20.0 - 0.165) / 1.04)


class Charts(unittest.TestCase):
    def test_writes_charts_deterministically(self):
        with tempfile.TemporaryDirectory() as d1, tempfile.TemporaryDirectory() as d2:
            a = u.write_charts(Path(d1))
            b = u.write_charts(Path(d2))
            self.assertGreaterEqual(len(a), 3)
            for p, q in zip(a, b):
                self.assertEqual(p.suffix, ".svg")
                self.assertEqual(hashlib.sha256(p.read_bytes()).hexdigest(),
                                 hashlib.sha256(q.read_bytes()).hexdigest(), p.name)


if __name__ == "__main__":
    unittest.main()
