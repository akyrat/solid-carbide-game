"""Tests for generate_agent_diagrams.py. Run from the repo root:

  python -m unittest discover -s tools -p "test_*.py"
"""

import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import generate_agent_diagrams as gen  # noqa: E402


def working_copy(name, gets=(), hands=(), collab=(), extra=""):
    def block(title, entries):
        lines = [f"**{title}**", ""] + [f"- {who}: {what}" for who, what in entries]
        return "\n".join(lines) + "\n\n"

    return (
        f"# Working copy: {name}\n\nIntro text.\n\n"
        + block("Gets work from", gets)
        + block("Hands work to", hands)
        + block("Collaborates with", collab)
        + "## Notes from experience\n\n"
        + extra
    )


OVERVIEW = (
    "# Overview\n\nHand-written intro.\n\n"
    f"{gen.BEGIN_MARKER}\nold generated text\n{gen.END_MARKER}\n\n"
    "## 2. Hand-written section\n\nKeep me exactly.\n"
)


class TempNotes:
    """A temporary agent-notes folder with a few working copies."""

    def __init__(self, copies, overview=OVERVIEW):
        self._dir = tempfile.TemporaryDirectory()
        self.path = Path(self._dir.name)
        for stem, text in copies.items():
            (self.path / f"{stem}.md").write_text(text, encoding="utf-8")
        (self.path / gen.OVERVIEW_NAME).write_text(overview, encoding="utf-8")

    def overview(self):
        return (self.path / gen.OVERVIEW_NAME).read_text(encoding="utf-8")

    def run(self, *argv):
        err = io.StringIO()
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(err):
            code = gen.main(list(argv), notes_dir=self.path)
        return code, err.getvalue()

    def close(self):
        self._dir.cleanup()


def basic_copies():
    return {
        "project-lead": working_copy(
            "Project Lead",
            gets=[("The board", "Requests and decisions.")],
            hands=[("Driving & Drift Agent", "Task files for car movement.")],
        ),
        "driving-drift": working_copy(
            "Driving & Drift Agent",
            gets=[("Project Lead", "Task files for car movement.")],
            hands=[("SFX Agent", "Drift state, for the engine sound.")],
            collab=[("SFX Agent", "Drift sounds follow the drift.")],
        ),
        "sfx": working_copy(
            "SFX Agent",
            collab=[("Driving & Drift Agent", "Drift sounds follow the drift.")],
        ),
    }


class ParsingTests(unittest.TestCase):
    def test_parses_title_and_three_lists(self):
        name, sections = gen.parse_working_copy(basic_copies()["driving-drift"])
        self.assertEqual(name, "Driving & Drift Agent")
        self.assertEqual(sections[gen.GETS], [("Project Lead", "Task files for car movement.")])
        self.assertEqual(sections[gen.HANDS], [("SFX Agent", "Drift state, for the engine sound.")])
        self.assertEqual(sections[gen.COLLAB], [("SFX Agent", "Drift sounds follow the drift.")])

    def test_ignores_notes_and_unknown_sections(self):
        text = working_copy(
            "UI Agent",
            hands=[("QA/Integration Agent", "Screens to check.")],
            extra="- Project Lead: a note from experience, not a relationship.\n\n"
                  "**Areas of overlap**\n\n- Game Data Agent: a new kind of section.\n",
        )
        _, sections = gen.parse_working_copy(text)
        self.assertEqual(sections[gen.HANDS], [("QA/Integration Agent", "Screens to check.")])
        self.assertEqual(sections[gen.GETS], [])
        self.assertEqual(sections[gen.COLLAB], [])

    def test_missing_lists_give_empty_sections(self):
        name, sections = gen.parse_working_copy("# Working copy: SFX Agent\n\nNothing else.\n")
        self.assertEqual(name, "SFX Agent")
        self.assertEqual(sections, {gen.GETS: [], gen.HANDS: [], gen.COLLAB: []})

    def test_accepts_markdown_headings_for_lists(self):
        text = "# Working copy: UI Agent\n\n## Hands work to\n\n- SFX Agent: Screen events.\n"
        _, sections = gen.parse_working_copy(text)
        self.assertEqual(sections[gen.HANDS], [("SFX Agent", "Screen events.")])

    def test_normalize_name(self):
        self.assertEqual(gen.normalize_name("The QA/Integration Agent"), "qa/integration")
        self.assertEqual(gen.normalize_name("The board"), "board")
        self.assertEqual(gen.normalize_name("Project Lead"), "project lead")


class GraphTests(unittest.TestCase):
    def setUp(self):
        self.notes = TempNotes(basic_copies())
        self.roles, self.parsed, self.problems = gen.load_roles(self.notes.path)

    def tearDown(self):
        self.notes.close()

    def test_handoff_listed_on_both_sides_is_one_edge(self):
        handoffs, _, _ = gen.build_graph(self.roles, self.parsed)
        edge = handoffs[("project lead", "driving & drift")]
        self.assertEqual(edge["sender"], "Task files for car movement.")
        self.assertEqual(edge["receiver"], "Task files for car movement.")
        self.assertEqual(sum(1 for k in handoffs if k == ("project lead", "driving & drift")), 1)

    def test_handoff_listed_by_one_side_is_kept(self):
        handoffs, _, _ = gen.build_graph(self.roles, self.parsed)
        self.assertEqual(handoffs[("board", "project lead")], {"sender": None, "receiver": "Requests and decisions."})
        self.assertEqual(handoffs[("driving & drift", "sfx")]["receiver"], None)

    def test_collaboration_listed_by_both_is_one_pair(self):
        _, collabs, _ = gen.build_graph(self.roles, self.parsed)
        self.assertEqual(len(collabs), 1)
        pair = frozenset(("driving & drift", "sfx"))
        self.assertEqual(collabs[pair]["sfx"], "Drift sounds follow the drift.")

    def test_unknown_role_is_reported_not_dropped(self):
        copies = basic_copies()
        copies["sfx"] = working_copy("SFX Agent", collab=[("Music Agent", "Not a real role.")])
        notes = TempNotes(copies)
        try:
            roles, parsed, _ = gen.load_roles(notes.path)
            _, _, unmatched = gen.build_graph(roles, parsed)
            self.assertEqual(unmatched, ["SFX Agent: Collaborates with: 'Music Agent'"])
            code, err = notes.run()
            self.assertEqual(code, 3)
            self.assertIn("Music Agent", err)
        finally:
            notes.close()

    def test_overview_file_is_not_read_as_a_working_copy(self):
        self.assertEqual(set(self.parsed), {"project lead", "driving & drift", "sfx"})
        self.assertEqual(self.problems, [])


class RenderTests(unittest.TestCase):
    def test_edge_labels_are_short(self):
        self.assertEqual(gen.edge_label("Task files for car movement, starting with X."), "task files")
        self.assertEqual(gen.edge_label("Enemy sprites, which replace the placeholders."), "Enemy sprites")
        self.assertEqual(gen.edge_label("HUD, menu and garage art, which replaces X."), "HUD, menu and garage art")
        self.assertEqual(
            gen.edge_label("The verification script that checks a challenge design is achievable."),
            "The verification script that checks a…",
        )

    def test_render_has_two_mermaid_blocks_and_every_role_in_handoffs(self):
        notes = TempNotes(basic_copies())
        try:
            roles, parsed, _ = gen.load_roles(notes.path)
            handoffs, collabs, _ = gen.build_graph(roles, parsed)
            out = gen.render(roles, handoffs, collabs)
            self.assertEqual(out.count("```mermaid"), 2)
            handoff_block = out.split("```mermaid")[1]
            for role in roles.values():
                self.assertIn(f'{role.node_id}["', handoff_block)
            self.assertIn('driving_drift -->|"Drift state"| sfx', out)
            self.assertIn("driving_drift --- sfx", out)
            self.assertIn("| Board | Project Lead | Requests and decisions. | Project Lead only |", out)
        finally:
            notes.close()

    def test_table_escapes_pipes(self):
        self.assertEqual(gen.table_text("a | b"), "a \\| b")
        self.assertEqual(gen.table_text(None), "—")


class FileTests(unittest.TestCase):
    def setUp(self):
        self.notes = TempNotes(basic_copies())

    def tearDown(self):
        self.notes.close()

    def test_rewrites_only_between_markers(self):
        code, _ = self.notes.run()
        self.assertEqual(code, 0)
        text = self.notes.overview()
        self.assertTrue(text.startswith("# Overview\n\nHand-written intro.\n\n" + gen.BEGIN_MARKER))
        self.assertTrue(text.endswith(gen.END_MARKER + "\n\n## 2. Hand-written section\n\nKeep me exactly.\n"))
        self.assertNotIn("old generated text", text)

    def test_check_detects_out_of_date_then_up_to_date(self):
        self.assertEqual(self.notes.run("--check")[0], 1)
        self.assertIn("old generated text", self.notes.overview())  # --check changes nothing
        self.notes.run()
        self.assertEqual(self.notes.run("--check")[0], 0)

    def test_check_notices_a_changed_working_copy(self):
        self.notes.run()
        copies = basic_copies()
        copies["sfx"] = working_copy(
            "SFX Agent",
            collab=[("Driving & Drift Agent", "Drift sounds follow the drift."),
                    ("Project Lead", "A new collaboration.")],
        )
        (self.notes.path / "sfx.md").write_text(copies["sfx"], encoding="utf-8")
        self.assertEqual(self.notes.run("--check")[0], 1)

    def test_second_run_changes_nothing(self):
        self.notes.run()
        first = self.notes.overview()
        self.notes.run()
        self.assertEqual(self.notes.overview(), first)

    def test_keeps_crlf_line_endings(self):
        crlf = OVERVIEW.replace("\n", "\r\n")
        (self.notes.path / gen.OVERVIEW_NAME).write_bytes(crlf.encode("utf-8"))
        self.notes.run()
        raw = (self.notes.path / gen.OVERVIEW_NAME).read_bytes()
        self.assertNotIn(b"\n", raw.replace(b"\r\n", b""))
        self.assertEqual(self.notes.run("--check")[0], 0)

    def test_missing_markers_is_an_error(self):
        (self.notes.path / gen.OVERVIEW_NAME).write_text("# No markers here\n", encoding="utf-8")
        code, err = self.notes.run()
        self.assertEqual(code, 2)
        self.assertIn("markers", err)


if __name__ == "__main__":
    unittest.main()
