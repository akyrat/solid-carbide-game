---
id: T-007
title: Long GDD generator and document staleness check
status: done
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
qa_rounds: 1
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

- [x] `python tools/generate_long_gdd.py` regenerates `docs/long-gdd.md`, and running it a second time leaves the file byte-for-byte unchanged (QA: pass)
- [x] The long GDD has one chapter per separate document, in `gdd_order` order, each with the document's Summary, Decisions, Content and References, and no text from any Open questions section (QA: pass)
- [x] For 3 decisions picked by QA from different separate documents, the decision text appears in the matching long GDD chapter, without its date note (QA: pass)
- [x] No decision bullet in `docs/long-gdd.md` ends with a date note such as "(2026-10-08)" (QA: pass)
- [x] Every relative link and image in `docs/long-gdd.md` resolves to an existing file (QA: pass)
- [x] Right after generation, `--check` lists no game area doc as stale (it still reports the short GDD as stale until T-025, as step 3 says). After QA temporarily edits one separate document, it names that document as changed; QA then restores the file (QA: pass)
- [x] After QA temporarily adds an extra `##` heading to one separate document, the generator exits 2, names the file and line, and leaves `docs/long-gdd.md` unchanged; QA then restores the file (QA: pass)
- [x] `--check` reports the short GDD as stale or up to date according to the line in `docs/short-gdd/README.md` (QA: pass)
- [x] `python -m unittest discover -s tools -p "test_*.py"` passes (QA: pass)
- [x] `docs/README.md` documents both commands (QA: pass)
- [x] No separate document's text changed, and nothing under `game/` or `.claude/agents/` changed (QA: pass)

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

### QA round 1

Checked by the QA/Integration Agent on 2026-10-08 in `C:\solid-carbide-worktrees\T-007`. All 11 criteria pass.

- **1:** `python tools/generate_long_gdd.py` run twice; SHA-256 of `docs/long-gdd.md` was `e353f545...2359` before, after the first and after the second run (exit 0, "already up to date (9 chapters)").
- **2:** 9 chapters; their order (Game loop architecture 1, Drifting 2, Level design 3, Enemies 4, Weapons 5, Garage design 6, Visual style 7, Extended narrative 8, HUD and menus 9) matches every doc's `gdd_order`. A script compared the first 60 characters of all 24 Open questions lines from the nine docs against the long GDD: 0 found. Sections missing from a chapter (Content in Enemies, Weapons, Garage design, Visual style, HUD and menus; References in Enemies and Garage design) are "(To be written.)" / "(None yet.)" in the source, so leaving them out is as specified.
- **3:** Drifting ("The car bounces off walls slightly..."), Enemies ("Over a run, the number of enemies grows slightly..." and "The kaiju's health is set so that...") and HUD and menus ("Escape pauses the game...") found in their chapters with the date note gone. "; replaces ..." notes (Drifting zoom, Level design boulders and patterns) are also removed, with the colon before sub-bullets kept.
- **4:** 0 occurrences of "(2026-" and of any "(YYYY-MM-DD" in the file.
- **5:** 22 relative links and images checked by script against `docs/`: 0 broken; the table of contents anchors also resolve.
- **6:** `--check` right after generation: only "short GDD: not yet updated" (exit 1). With a line appended to `docs/garage-design.md`: "garage-design.md: changed since the long GDD was generated" (exit 1). File restored from a copy; `git status` clean.
- **7:** With `## Something` added before `## Content` in `docs/enemies.md`: "structure problem: enemies.md: line 30: unknown section heading '## Something'", "nothing was written", exit 2; `docs/long-gdd.md` hash unchanged; `--check` also exits 2. File restored; `git status` clean.
- **8:** With the line "never": stale (exit 1). Set temporarily to the current long GDD fingerprint: "in sync" (exit 0). Set to a wrong 64-digit value: stale (exit 1). File restored; `git status` clean.
- **9:** `python -m unittest discover -s tools -p "test_*.py"`: 62 tests OK (12 in `test_generate_long_gdd.py`). `game/tools` Python tests: 45 OK.
- **10:** `docs/README.md`, "How the long and short GDD are made", documents both commands, the exit codes and what `--check` reports.
- **11:** `git diff master...HEAD --stat` touches only `docs/README.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, this task file and the two `tools/` files.

**Observations for the board's review (not failures):**
- Content is renamed "Details" in the long GDD, but decision text still says "see Content, 'Prototypes so far'" (Drifting) and "(Content, 'MVP challenges')" (Level design), so those pointers name a heading that doesn't exist in the long GDD.
- Other cross-references read as written for the separate doc: "References" inside Visual style's decisions ("from the board's reference image, References"; "See the reference photos in References"), and "(below)" in Weapons' decisions.
- Five chapters (Enemies, Weapons, Garage design, Visual style, HUD and menus) are only a summary plus a decision list, so the long GDD reads more like a set of decision lists than one flowing document; this follows the docs having no Content yet.
- Visual style's References put three images inline in the middle of sentences, and the third is followed by its file path as code, which renders awkwardly.
- No separator between the last chapter (HUD and menus) and "Source fingerprints" in contrast with the blank-line gap between chapters; cosmetic.
- The tests have no explicit link-handling test (description section 4 lists one); links are passed through unchanged, so the generated file's links were checked directly instead.

### Fixes after QA round 1

Made by the Project Lead on 2026-10-08, from QA's reading notes, at the board's request:
- The long GDD keeps each game area doc's "Content" heading (it said "Details"), so decisions that point to "Content, ..." resolve inside the chapter.
- Visual style's references (a game area doc edit, made on `master` and merged in) now put each image on its own line with a caption.
- Added `test_links_and_images_pass_through_unchanged` (the link-handling test the task asked for). 13 tests now.
- Regenerated `docs/long-gdd.md`.

### Board review

2026-10-08: the board reviewed the long GDD (after the post-QA fixes) and marked the task `done`.
