"""Tests for run_scene_headless.py (task T-196): finding GODOT_BIN and the error lines."""

import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run_scene_headless as rsh  # noqa: E402


class ErrorLinesTest(unittest.TestCase):
    def test_clean_output_has_no_errors(self):
        out = "Godot Engine v4.3.stable\nelevation_sample_demo: stopped\n"
        self.assertEqual(rsh.error_lines(out), [])

    def test_error_lines_are_found(self):
        out = "ok\nERROR: something broke\n   at: foo\nSCRIPT ERROR: Invalid call\nUSER ERROR: x\n"
        self.assertEqual(len(rsh.error_lines(out)), 3)

    def test_parse_errors_are_found(self):
        self.assertEqual(len(rsh.error_lines("Parse Error: bad\nFailed to load script \"x\"")), 2)

    def test_a_word_error_inside_a_line_is_not_an_error(self):
        self.assertEqual(rsh.error_lines("print: no errors here, error_count 0"), [])


class GodotBinTest(unittest.TestCase):
    def test_from_the_environment(self):
        self.assertEqual(rsh.godot_bin({"GODOT_BIN": "C:/g.exe"}, "nope"), "C:/g.exe")

    def test_from_the_env_file(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, ".env")
            with open(path, "w", encoding="utf-8") as f:
                f.write("OTHER=1\nGODOT_BIN = \"C:/Godot/godot.exe\"\r\n")
            self.assertEqual(rsh.godot_bin({}, path), "C:/Godot/godot.exe")

    def test_missing(self):
        with tempfile.TemporaryDirectory() as d:
            self.assertIsNone(rsh.godot_bin({}, os.path.join(d, ".env")))


class ArgumentsTest(unittest.TestCase):
    def test_bad_arguments_exit_2(self):
        self.assertEqual(rsh.main(["x"]), 2)
        self.assertEqual(rsh.main(["x", "scenes/a.tscn"]), 2)


if __name__ == "__main__":
    unittest.main()
