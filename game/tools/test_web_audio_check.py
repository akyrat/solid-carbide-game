"""Tests for web_audio_check.mjs and the bus layout it checks (T-476)."""
import re
import subprocess
import unittest
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent


class WebAudioCheck(unittest.TestCase):
    def test_layout_defines_runtime_buses_up_front(self):
        text = (GAME / "default_bus_layout.tres").read_text(encoding="utf-8")
        self.assertIn('bus/1/name = &"SFX"', text)
        self.assertIn('bus/2/name = &"Music"', text)
        self.assertEqual(len(re.findall(r'/send = &"Master"', text)), 2)

    def test_script_has_no_syntax_errors(self):
        r = subprocess.run(["node", "--check", str(GAME / "tools" / "web_audio_check.mjs")], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)

    def test_music_and_engine_log_lines_exist(self):
        self.assertIn("WebAudioLog.say", (GAME / "scripts/game/music_player.gd").read_text(encoding="utf-8"))
        self.assertIn("WebAudioLog.say", (GAME / "scripts/run/run_sounds.gd").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
