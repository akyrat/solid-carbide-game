---
id: T-007
title: Long GDD generator and document staleness check
status: in-qa
from: project-lead
to: project-lead
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
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

Written on 2026-10-04 and put on hold until the game area docs had real content; reviewed and updated on 2026-10-08, when the MVP game area docs were done. The board chose a script only, with no agent rewriting (2026-10-08): the long GDD is exact and never drifts from the game area docs. If anything here disagrees with `docs/README.md`, follow `docs/README.md` and note the difference in the result notes.

**Changes since 2026-10-04 to handle:** there are now nine game area docs (HUD and menus was added); Content sections hold images and tables (for example the challenge drawings in Level design); and open questions that can wait start with "(After MVP)" (all open questions are left out anyway).

The separate documents are the source of truth, the long GDD condenses them, and the short GDD condenses the long GDD (`CLAUDE.md`, `docs/README.md`). This task writes the script that builds the long GDD from the separate documents, and the staleness check the Project Lead runs at the start of each session and before milestones. The Project Lead does it itself: it is documentation tooling.

### 1. Generator: `tools/generate_long_gdd.py`

Python 3.9+, standard library only, in `tools/` with the other project tooling.

- **Input:** every `.md` file in `docs/` whose front matter has a `gdd_order`. These are the separate documents. Their structure is defined in `docs/README.md`, "How separate documents are written".
- **Validation first:** before writing anything, check every separate document: front matter present with every field `docs/README.md` requires, unique `gdd_order` values, the five `##` sections present in the required order, and no other `##` headings. On any problem, write nothing, print each problem with file and line, and exit 2.
- **Output, `docs/long-gdd.md`:** a fixed header (title, the sync rule, "generated, do not edit by hand" with the command to regenerate), a table of contents, then one chapter per separate document in `gdd_order` order:
  - The chapter heading is the document's `title`.
  - The Summary, then the Decisions, then the Content, with every heading shifted down one level so the chapter structure holds.
  - **Decisions without their dates:** each decision bullet ends with a date note in parentheses, for example "(2026-10-08)" or "(2026-10-07; replaces ...)". Leave that note out, so the long GDD reads as a description of the game rather than a log. The dates stay in the game area docs and the timeline.
  - The References, as links only.
  - **Open questions are left out.** They stay in their own documents (board decision, 2026-10-04).
  - Sections that still say "(To be written.)" or "(None yet.)" are left out. A chapter with nothing written yet says so in one line.
- **Links and images** in the separate documents are relative to `docs/` and must still resolve from `docs/long-gdd.md`.
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
- [ ] For 3 decisions picked by QA from different separate documents, the decision text appears in the matching long GDD chapter, without its date note (QA: pass / fail)
- [ ] No decision bullet in `docs/long-gdd.md` ends with a date note such as "(2026-10-08)" (QA: pass / fail)
- [ ] Every relative link and image in `docs/long-gdd.md` resolves to an existing file (QA: pass / fail)
- [ ] Right after generation, `--check` lists no game area doc as stale (it still reports the short GDD as stale until T-025, as step 3 says). After QA temporarily edits one separate document, it names that document as changed; QA then restores the file (QA: pass / fail)
- [ ] After QA temporarily adds an extra `##` heading to one separate document, the generator exits 2, names the file and line, and leaves `docs/long-gdd.md` unchanged; QA then restores the file (QA: pass / fail)
- [ ] `--check` reports the short GDD as stale or up to date according to the line in `docs/short-gdd/README.md` (QA: pass / fail)
- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes (QA: pass / fail)
- [ ] `docs/README.md` documents both commands (QA: pass / fail)
- [ ] No separate document's text changed, and nothing under `game/` or `.claude/agents/` changed (QA: pass / fail)

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

The board's review: read the generated long GDD and judge whether it reads as one document.

## Result notes

Written by the Project Lead on 2026-10-08.

**Criterion change before QA:** the original criterion 5 said `--check` exits 0 right after generation, which contradicts step 3 (the short GDD is reported as stale until T-025 rewrites it). The criterion now says no game area doc is listed as stale right after generation. `--check` exits 1 today only because of the short GDD.

**Built:**
- `tools/generate_long_gdd.py`: reads every `docs/*.md` with a `gdd_order` (nine game area docs; `docs/README.md`'s example front matter sits in a code block, so it is not picked up). It validates the structure first and writes nothing on a problem (exit 2, file and line). It writes `docs/long-gdd.md`: a header, a table of contents, then one chapter per doc in `gdd_order` order with its scope line, Summary, Decisions (each bullet's trailing date note removed, a colon before sub-bullets kept), Content under "Details" and References. Every heading is shifted down one level outside code fences. Open questions and placeholder sections are left out. A table of SHA-256 fingerprints (of each doc with line endings normalised) closes the file. No timestamps, so it is byte-identical on every run.
- `--check`: lists every game area doc changed, added or removed since generation, and compares `docs/short-gdd/README.md`'s "Last updated from long GDD:" line with the long GDD's fingerprint (exit 0 / 1 / 2).
- `tools/test_generate_long_gdd.py`: 12 tests (order, open questions left out, date notes, heading shifting with code fences, byte-identical output, empty chapters, each structure problem, and check: in sync, changed, added, removed, short GDD behind, check changes nothing).
- `docs/README.md`: both commands, under "How the long and short GDD are made". `docs/short-gdd/README.md`: the "Last updated from long GDD: never" line.
- `docs/long-gdd.md`: generated for real (9 chapters, about 5,400 words).

**Game area doc fixes, made on `master` and merged in (not part of this branch's own changes):** Weapons linked to the T-022 report before it exists (now plain text until it does), and Visual style had no Summary (written from its decisions). Both are in the timeline.

**Self-check:** generation byte-identical on a second run; 9 chapters in order, no open questions; date notes left: 0; broken links or images: 0; `--check` lists no game area doc and reports the short GDD (exit 1, as designed); the structure checks are covered by tests; all Python tool tests pass (root `tools/` and `game/tools/`); no game area doc's text changed on this branch; nothing under `game/` or `.claude/agents/` changed.
