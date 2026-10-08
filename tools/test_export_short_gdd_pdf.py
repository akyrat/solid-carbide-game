"""Tests for export_short_gdd_pdf.py (the parts that don't need a browser). Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import json
import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import export_short_gdd_pdf as ex  # noqa: E402


class BuildHtmlTests(unittest.TestCase):
    def test_markdown_travels_as_json_and_cannot_close_the_script(self):
        text = '# Title\n\n</script><script>alert("x")</script>\n\n```mermaid\nflowchart LR\n  a --> b\n```'
        page = ex.build_html(text)
        self.assertEqual(page.count("</script>"), 3)   # only the page's own scripts: 2 libraries and 1 inline; the source's is escaped
        payload = re.search(r"const md = (.*);\nconst doc", page, re.S).group(1)
        self.assertEqual(json.loads(payload.replace("<\\/", "</")), text)

    def test_page_loads_marked_and_mermaid_and_renders_mermaid_blocks(self):
        page = ex.build_html("x")
        self.assertIn(ex.MARKED, page)
        self.assertIn(ex.MERMAID, page)
        self.assertIn("language-mermaid", page)
        self.assertIn("mermaid.run()", page)

    def test_source_is_the_short_gdd(self):
        self.assertTrue(ex.SOURCE.exists())
        self.assertEqual(ex.OUTPUT.name, "short-gdd.pdf")


if __name__ == "__main__":
    unittest.main()
