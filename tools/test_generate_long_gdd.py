"""Tests for generate_long_gdd.py. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import generate_long_gdd as gen  # noqa: E402


def area_doc(title, order, decisions="- A decision. (2026-10-08)", content="(To be written.)",
             summary="A summary.", questions="- An open question nobody answered.", extra=""):
    return f"""---
title: {title}
gdd_order: {order}
scope: What {title} covers.
agents_work_on: [ui]
agents_read: []
---

# {title}

## Summary

{summary}

## Decisions

{decisions}

## Content

{content}

## Open questions

{questions}
{extra}
## References

(None yet.)
"""


class Docs:
    def __init__(self, files):
        self._dir = tempfile.TemporaryDirectory()
        self.path = Path(self._dir.name)
        (self.path / "short-gdd").mkdir()
        (self.path / "short-gdd" / "README.md").write_text("# Short GDD\n\nLast updated from long GDD: never\n", encoding="utf-8")
        for name, text in files.items():
            (self.path / name).write_text(text, encoding="utf-8")

    def run(self, *argv):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = gen.main(list(argv), docs_dir=self.path)
        return code, out.getvalue() + err.getvalue()

    def long(self):
        return (self.path / "long-gdd.md").read_text(encoding="utf-8")

    def set_short_line(self, value):
        (self.path / "short-gdd" / "README.md").write_text(f"# Short GDD\n\nLast updated from long GDD: {value}\n", encoding="utf-8")

    def close(self):
        self._dir.cleanup()


def two_docs():
    return {
        "b.md": area_doc("Second", 2, content="### Details here\n\nText.\n\n```mermaid\n## not a heading\n```"),
        "a.md": area_doc("First", 1, decisions="- Cars are green. (2026-10-08)\n- Two patterns (2026-10-08; replaces the plan of 3):\n  - Pattern one.\n- Keeps its note (Visual style, Decisions)."),
        "README.md": "# Documents\n\n```markdown\n---\ntitle: Example\ngdd_order: 9\n---\n```\n",
    }


class GenerateTests(unittest.TestCase):
    def setUp(self):
        self.docs = Docs(two_docs())

    def tearDown(self):
        self.docs.close()

    def test_chapters_in_order_without_open_questions(self):
        code, _ = self.docs.run()
        self.assertEqual(code, 0)
        text = self.docs.long()
        self.assertLess(text.index("## 1. First"), text.index("## 2. Second"))
        self.assertNotIn("An open question", text)
        self.assertNotIn("(None yet.)", text)
        self.assertNotIn("## 3.", text)   # README.md is not a game area doc

    def test_decision_dates_removed_but_other_notes_kept(self):
        self.docs.run()
        text = self.docs.long()
        self.assertIn("- Cars are green.\n", text)
        self.assertIn("- Two patterns:\n  - Pattern one.", text)
        self.assertIn("- Keeps its note (Visual style, Decisions).", text)
        self.assertNotIn("(2026-10-08", text)

    def test_content_headings_shifted_and_code_fences_untouched(self):
        self.docs.run()
        text = self.docs.long()
        self.assertIn("### Content", text)
        self.assertIn("#### Details here", text)
        self.assertIn("```mermaid\n## not a heading\n```", text)

    def test_byte_identical_regeneration(self):
        self.docs.run()
        first = (self.docs.path / "long-gdd.md").read_bytes()
        self.docs.run()
        self.assertEqual(first, (self.docs.path / "long-gdd.md").read_bytes())

    def test_links_and_images_pass_through_unchanged(self):
        content = "See [the report](drifting/report.md) and ![a picture](level-design/a.svg).\n\n![Own line](visual-style/ref.png)"
        refs = "- [Elsewhere](weapons.md#decisions) and an outside link: [Godot](https://godotengine.org)"
        docs = Docs({"a.md": area_doc("Links", 1, content=content).replace("## References\n\n(None yet.)", "## References\n\n" + refs)})
        try:
            docs.run()
            text = docs.long()
            for link in ("[the report](drifting/report.md)", "![a picture](level-design/a.svg)",
                         "![Own line](visual-style/ref.png)", "[Elsewhere](weapons.md#decisions)",
                         "[Godot](https://godotengine.org)", "[a.md](a.md)"):
                self.assertIn(link, text)
        finally:
            docs.close()

    def test_empty_chapter_says_not_written(self):
        docs = Docs({"a.md": area_doc("Empty", 1, decisions="(To be written.)", summary="(To be written.)")})
        try:
            docs.run()
            self.assertIn("Not written yet.", docs.long())
        finally:
            docs.close()


class StructureTests(unittest.TestCase):
    def run_with(self, files):
        docs = Docs(files)
        try:
            code, out = docs.run()
            return code, out, (docs.path / "long-gdd.md").exists()
        finally:
            docs.close()

    def test_extra_heading_is_rejected_with_file_and_line(self):
        code, out, written = self.run_with({"a.md": area_doc("A", 1, extra="\n## Extra\n\nText.\n")})
        self.assertEqual(code, 2)
        self.assertIn("a.md: line", out)
        self.assertIn("## Extra", out)
        self.assertFalse(written)

    def test_missing_section_and_bad_order_are_rejected(self):
        text = area_doc("A", 1).replace("## References\n\n(None yet.)\n", "")
        self.assertEqual(self.run_with({"a.md": text})[0], 2)
        swapped = area_doc("A", 1).replace("## Summary", "## TEMP").replace("## Decisions", "## Summary").replace("## TEMP", "## Decisions")
        code, out, _ = self.run_with({"a.md": swapped})
        self.assertEqual(code, 2)
        self.assertIn("order", out)

    def test_duplicate_order_and_missing_field_are_rejected(self):
        code, out, _ = self.run_with({"a.md": area_doc("A", 1), "b.md": area_doc("B", 1)})
        self.assertEqual(code, 2)
        self.assertIn("also used by", out)
        code, out, _ = self.run_with({"a.md": area_doc("A", 1).replace("scope: What A covers.\n", "")})
        self.assertEqual(code, 2)
        self.assertIn("scope", out)


class CheckTests(unittest.TestCase):
    def setUp(self):
        self.docs = Docs(two_docs())
        self.docs.run()
        self.docs.set_short_line(gen.fingerprint(self.docs.long()))

    def tearDown(self):
        self.docs.close()

    def test_in_sync_right_after_generation(self):
        self.assertEqual(self.docs.run("--check")[0], 0)

    def test_changed_added_and_removed_docs_are_reported(self):
        (self.docs.path / "a.md").write_text(area_doc("First", 1, summary="Changed."), encoding="utf-8")
        code, out = self.docs.run("--check")
        self.assertEqual(code, 1)
        self.assertIn("a.md: changed", out)
        (self.docs.path / "c.md").write_text(area_doc("Third", 3), encoding="utf-8")
        self.assertIn("c.md: added", self.docs.run("--check")[1])
        (self.docs.path / "b.md").unlink()
        self.assertIn("b.md: removed", self.docs.run("--check")[1])

    def test_short_gdd_behind_is_reported(self):
        self.docs.set_short_line("never")
        code, out = self.docs.run("--check")
        self.assertEqual(code, 1)
        self.assertIn("short GDD", out)

    def test_check_changes_nothing(self):
        before = self.docs.long()
        (self.docs.path / "a.md").write_text(area_doc("First", 1, summary="Changed."), encoding="utf-8")
        self.docs.run("--check")
        self.assertEqual(before, self.docs.long())


if __name__ == "__main__":
    unittest.main()
