import json
import tempfile
import unittest
from pathlib import Path

import copy_greenbull_logo as c


class CopyTest(unittest.TestCase):
    def test_copies_byte_identical_with_records(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            for ticket, _run, name, _what in c.FILES:
                p = root / "art-archive" / ticket / name
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_bytes(name.encode())
            shas = c.copy_all(root)
            self.assertEqual(len(shas), 4)
            for ticket, run, name, _what in c.FILES:
                dst = root / "game" / "art" / "logo" / name
                self.assertEqual(dst.read_bytes(), name.encode())
                rec = json.loads(dst.with_name(name + ".json").read_text())
                self.assertEqual(rec["source_ticket"], ticket)
                self.assertEqual(rec["source_run"], run)
                self.assertEqual(rec["source_file"], f"art-archive/{ticket}/{name}")


if __name__ == "__main__":
    unittest.main()
