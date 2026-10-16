import json, os, sys, tempfile, unittest
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_sfx_licenses as c

META = {"freesound_id": 1, "name": "x", "username": "u", "freesound_url": "https://freesound.org/people/u/sounds/1/",
        "license_name": "CC0 1.0", "license_url": "https://creativecommons.org/publicdomain/zero/1.0/",
        "search_query": "q", "download_date": "2026-10-15"}

def make(d, meta, wav=True):
    open(os.path.join(d, "a.wav"), "wb").close()
    if meta is not None:
        with open(os.path.join(d, "a.json"), "w") as fh:
            json.dump(meta, fh)

class T(unittest.TestCase):
    def run_check(self, meta):
        with tempfile.TemporaryDirectory() as d:
            make(d, meta)
            return c.check(d)[1]
    def test_ok(self): self.assertEqual(self.run_check(dict(META)), 0)
    def test_missing_json(self): self.assertEqual(self.run_check(None), 1)
    def test_incomplete(self):
        m = dict(META); del m["username"]; self.assertEqual(self.run_check(m), 1)
    def test_noncommercial(self):
        m = dict(META, license_name="CC BY-NC 4.0", license_url="https://creativecommons.org/licenses/by-nc/4.0/")
        self.assertEqual(self.run_check(m), 1)

if __name__ == "__main__": unittest.main()
