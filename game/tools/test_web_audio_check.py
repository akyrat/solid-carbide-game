"""Tests for web_audio_check.mjs and the bus layout it checks (T-476)."""
import json
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

    def _verdict(self, log, states, sfx):
        js = ("import {verdict} from %r; console.log(JSON.stringify(verdict(%s, %s, %s)))"
              % ((GAME / "tools" / "web_audio_rules.mjs").as_uri(), json.dumps(log), json.dumps(states), sfx))
        r = subprocess.run(["node", "--input-type=module", "-e", js], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        return json.loads(r.stdout)

    def test_sfx_off_passes_on_music_and_running_context(self):
        v = self._verdict("[audio] music playing=true", ["running"], "false")
        self.assertTrue(v["ok"])
        self.assertTrue(any("SFX are off" in n for n in v["notes"]))

    def test_sfx_on_needs_the_engine_line(self):
        self.assertFalse(self._verdict("[audio] music playing=true", ["running"], "true")["ok"])
        self.assertTrue(self._verdict("[audio] music playing=true\n[audio] engine playing=true", ["running"], "true")["ok"])

    def test_music_and_running_context_always_needed(self):
        self.assertFalse(self._verdict("", ["running"], "false")["ok"])
        self.assertFalse(self._verdict("[audio] music playing=true", ["suspended"], "false")["ok"])

    def test_sfx_enabled_read_from_the_data_file(self):
        js = ("import {sfxEnabledFrom as f} from %r; console.log(JSON.stringify([f('{\"sfx_enabled\": false}'), f('{}'), f('x')]))"
              % (GAME / "tools" / "web_audio_rules.mjs").as_uri())
        r = subprocess.run(["node", "--input-type=module", "-e", js], capture_output=True, text=True)
        self.assertEqual(json.loads(r.stdout), [False, True, True])


if __name__ == "__main__":
    unittest.main()
