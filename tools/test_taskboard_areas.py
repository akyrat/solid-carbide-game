"""The task board's AREAS list (T-410): the audit epic has its own bubble."""
import re
import unittest
from pathlib import Path

HTML = Path(__file__).parent / "taskboard" / "taskboard.html"


def areas():
    text = HTML.read_text(encoding="utf-8")
    block = re.search(r"const AREAS = \[(.*?)\n\];", text, re.S).group(1)
    return [l for l in block.splitlines() if l.strip().startswith("{")]


class AreasTest(unittest.TestCase):
    def test_audit_bubble(self):
        lines = [l for l in areas() if 'name: "Audit"' in l]
        self.assertEqual(len(lines), 1)
        line = lines[0]
        self.assertIn('epics: ["audit"]', line)
        self.assertIn("doc: null", line)
        self.assertNotIn("excluded", line)

    def test_colours_unique(self):
        colours = [re.search(r'color: "(#[0-9a-fA-F]+)"', l).group(1).lower() for l in areas()]
        self.assertEqual(len(colours), len(set(colours)))

    def test_every_epic_in_one_area(self):
        epics = [e for l in areas() for e in re.findall(r'"([a-z-]+)"', re.search(r"epics: \[(.*?)\]", l).group(1))]
        self.assertEqual(len(epics), len(set(epics)))


if __name__ == "__main__":
    unittest.main()
