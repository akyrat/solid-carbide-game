import contextlib, io, struct, sys, tempfile, unittest, zlib
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import check_sprite_rules as c


def make_png(w, h, pixel):
    raw = b"".join(b"\x00" + b"".join(bytes(pixel(x, y)) for x in range(w)) for y in range(h))
    def chunk(t, b):
        return struct.pack(">I", len(b)) + t + b + struct.pack(">I", zlib.crc32(t + b))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


class T(unittest.TestCase):
    def run_check(self, png, **kw):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "s.png"
            p.write_bytes(png)
            return c.check(str(p), **kw)

    def test_good(self):
        r, info = self.run_check(make_png(8, 8, lambda x, y: (10, 20, 30, 255) if 2 <= x < 5 and 2 <= y < 5 else (0, 0, 0, 0)), size=8)
        self.assertTrue(all(ok for _, ok, _ in r))
        self.assertEqual(info["bbox"], (2, 2, 4, 4))

    def test_semi_transparent_fails(self):
        r, _ = self.run_check(make_png(8, 8, lambda x, y: (1, 2, 3, 128) if x == 3 else (0, 0, 0, 0)), size=8)
        self.assertFalse(dict((n, ok) for n, ok, _ in r)["no semi-transparent pixels"])

    def test_wrong_size_and_colours_fail(self):
        r, _ = self.run_check(make_png(8, 8, lambda x, y: (x * 10, y, 0, 255)), size=16, max_colors=5)
        d = {n: ok for n, ok, _ in r}
        self.assertFalse(d["frame size 16x16"])
        self.assertFalse(d["about 5 colours or fewer"])
        self.assertFalse(d["transparent background (corners)"])

    def test_sheet_checks_each_frame(self):
        # Two 8x8 frames side by side: the first is good, the second has a semi-transparent pixel.
        def px(x, y):
            if x < 8:
                return (10, 20, 30, 255) if 2 <= x < 5 and 2 <= y < 5 else (0, 0, 0, 0)
            return (1, 2, 3, 128) if (x, y) == (12, 4) else (0, 0, 0, 0)
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "sheet.png"
            p.write_bytes(make_png(16, 8, px))
            out = c.check_sheet(str(p), 2, size=8)
            self.assertEqual(len(out), 2)
            self.assertTrue(all(ok for _, ok, _ in out[0][0]))
            self.assertEqual(out[0][1]["bbox"], (2, 2, 4, 4))
            self.assertFalse(dict((n, ok) for n, ok, _ in out[1][0])["no semi-transparent pixels"])
            self.assertEqual(quiet(c.main, [str(p), "--size", "8", "--frames", "2"])[0], 1)
            with self.assertRaises(ValueError):
                c.check_sheet(str(p), 3, size=8)


def quiet(fn, *a):
    with contextlib.redirect_stdout(io.StringIO()) as out:
        code = fn(*a)
    return code, out.getvalue()


def square(colour):
    return make_png(128, 128, lambda x, y: colour + (255,) if 40 <= x < 80 and 40 <= y < 80 else (0, 0, 0, 0))


class Rule6(unittest.TestCase):
    """T-298: the new rule 6 (Greenbull's light green and yellow, red not reserved)."""

    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        d = Path(self.dir.name)
        self.red, self.yellow = d / "red.png", d / "yellow.png"
        self.red.write_bytes(square((255, 0, 0)))
        self.yellow.write_bytes(square((247, 208, 52)))

    def tearDown(self):
        self.dir.cleanup()

    def test_the_old_command_leaves_rule_6_out(self):
        self.assertEqual(quiet(c.main, [str(self.yellow)])[0], 0)
        self.assertEqual(quiet(c.main, [str(self.red)])[0], 0)

    def test_rule6_flag_runs_the_new_rule_6(self):
        self.assertEqual(quiet(c.main, [str(self.yellow), "--rule6"])[0], 1)
        self.assertEqual(quiet(c.main, [str(self.red), "--rule6"])[0], 0)

    def test_rule6_report(self):
        rows = {Path(r["path"]).name: r for r in c.rule6_report(self.dir.name)}
        self.assertTrue(rows["red.png"]["ok"])
        self.assertFalse(rows["yellow.png"]["ok"])
        code, out = quiet(c.main, ["--rule6-report", self.dir.name])
        self.assertEqual(code, 1)
        self.assertIn("yellow.png  now FAIL", out)

    def test_rule6_report_against_a_revision(self):
        rows = {Path(r["path"]).name: r for r in c.rule6_report(self.dir.name, "HEAD")}
        self.assertIn("old_ok", rows["red.png"])


if __name__ == "__main__":
    unittest.main()
