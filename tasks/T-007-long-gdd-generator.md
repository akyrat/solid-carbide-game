---
id: T-007
title: Long GDD generator and document staleness check
status: open
from: project-lead
to: project-lead
epic: tooling
milestone: mvp
depends_on: []
documents_affected: [docs/long-gdd.md, docs/README.md, docs/short-gdd/README.md]
files_to_read_first: [tasks/README.md, CLAUDE.md, docs/README.md, docs/long-gdd.md, docs/short-gdd/README.md]
files_expected_to_change: [tools/generate_long_gdd.py, tools/test_generate_long_gdd.py, docs/long-gdd.md, docs/README.md, docs/short-gdd/README.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**On hold until the board says to start.** The board wants this worked on once the separate documents have real content. It was written on 2026-10-04, right after the document structure was agreed, so that the board can see whether the task still fits when the time comes. If the structure in `docs/README.md` changed in the meantime, follow `docs/README.md`, not any detail repeated here, and note the difference in the result notes.

The separate documents are the source of truth, the long GDD condenses them, and the short GDD condenses the long GDD (`CLAUDE.md`, `docs/README.md`). This task writes the script that builds the long GDD from the separate documents, and the staleness check the Project Lead runs at the start of each session and before milestones. The Project Lead does it itself: it is documentation tooling.

### 1. Generator: `tools/generate_long_gdd.py`

Python 3.9+, standard library only, in `tools/` with the other project tooling.

- **Input:** every `.md` file in `docs/` whose front matter has a `gdd_order`. These are the separate documents. Their structure is defined in `docs/README.md`, "How separate documents are written".
- **Validation first:** before writing anything, check every separate document: front matter present with every field `docs/README.md` requires, unique `gdd_order` values, the five `##` sections present in the required order, and no other `##` headings. On any problem, write nothing, print each problem with file and line, and exit 2.
- **Output, `docs/long-gdd.md`:** a fixed header (title, the sync rule, "generated, do not edit by hand" with the command to regenerate), a table of contents, then one chapter per separate document in `gdd_order` order:
  - The chapter heading is the document's `title`.
  - The Summary, then the Decisions, then the Content, with every heading shifted down one level so the chapter structure holds.
  - The References, as links only.
  - **Open questions are left out.** They stay in their own documents (board decision, 2026-10-04).
  - Sections that still say "(To be written.)" or "(None yet.)" are left out. A chapter with nothing written yet says so in one line.
- **Links** in the separate documents are relative to `docs/` and must still resolve from `docs/long-gdd.md`.
- **Source fingerprints:** at the end of the long GDD, a table of each separate document and a fingerprint of its contents (for example SHA-256), so the check below can tell which documents changed since the last generation. No timestamps: generating twice from the same documents must give a byte-identical file.

### 2. Staleness check: `--check`

`python tools/generate_long_gdd.py --check` changes nothing and reports:

- every separate document whose fingerprint no longer matches the one recorded in the long GDD, plus any document added or removed since;
- whether the short GDD has caught up with the long GDD. For this, `docs/short-gdd/README.md` records the long GDD fingerprint it was last updated from, on one line in a fixed format defined by this task. The check compares it with the current long GDD.

Exit 0 when everything is in sync, 1 when anything is stale (listing what), 2 for structure problems.

### 3. Documentation

- Document both commands in `docs/README.md`, next to the document structure.
- Add the "last updated from long GDD" line to `docs/short-gdd/README.md`. Until the short GDD is first updated from a generated long GDD, it says so, and `--check` reports the short GDD as stale.
- Generate `docs/long-gdd.md` for real from the documents as they are when the task is done.

### 4. Tests: `tools/test_generate_long_gdd.py`

Using temporary folders with sample documents: validation (each kind of structure problem), chapter order, heading shifting, Open questions and placeholders left out, link handling, byte-identical regeneration, and `--check` detecting a changed document, an added or removed document, and a short GDD that hasn't caught up.

## Acceptance criteria

- [ ] `python tools/generate_long_gdd.py` regenerates `docs/long-gdd.md`, and running it a second time leaves the file byte-for-byte unchanged (QA: pass / fail)
- [ ] The long GDD has one chapter per separate document, in `gdd_order` order, each with the document's Summary, Decisions, Content and References, and no text from any Open questions section (QA: pass / fail)
- [ ] For 3 decisions picked by QA from different separate documents, the decision text appears in the matching long GDD chapter (QA: pass / fail)
- [ ] Every relative link in `docs/long-gdd.md` resolves to an existing file (QA: pass / fail)
- [ ] `--check` exits 0 right after generation. After QA temporarily edits one separate document, it exits 1 and names that document; QA then restores the file (QA: pass / fail)
- [ ] After QA temporarily adds a sixth `##` heading to one separate document, the generator exits 2, names the file and line, and leaves `docs/long-gdd.md` unchanged; QA then restores the file (QA: pass / fail)
- [ ] `--check` reports the short GDD as stale or up to date according to the line in `docs/short-gdd/README.md` (QA: pass / fail)
- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes (QA: pass / fail)
- [ ] `docs/README.md` documents both commands (QA: pass / fail)
- [ ] No separate document's text changed, and nothing under `game/` or `.claude/agents/` changed (QA: pass / fail)

The board's review: read the generated long GDD and judge whether it reads as one document.

## Result notes

Written by the agent when it finishes.
