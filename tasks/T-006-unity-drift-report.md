---
id: T-006
title: Report on driving, drifting and reverse in the board's Unity prototype, and how to port them to Godot
status: open
from: project-lead
to: driving-drift
depends_on: []
documents_affected: [docs/drifting/unity-prototype-report.md, docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/drifting.md, .claude/agents/driving-drift.md, game/README.md]
files_expected_to_change: [docs/drifting/unity-prototype-report.md, docs/drifting/ (chart images), docs/drifting.md, tools/unity_drift_charts.py, tools/test_unity_drift_charts.py]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board built a drift prototype in Unity that it is very happy with. Solid Carbide's driving and drifting will copy it, including reverse on the S key (see `docs/drifting.md`). This task studies how that prototype works and writes it up as a readable report with graphics, plus the preparations needed to reproduce it in Godot. It builds nothing in Godot yet: the next task builds the Godot version from this report.

**The Unity project:** `C:\Users\andre\drift-to-survive` (Unity 6000.3, project name DriftSurvivors, a git repository). The board confirmed its **current state** is the version with the driving it likes.

**The board's saved tuning:** the board tuned the driving in the prototype's pause menu. Those values are saved with Unity's PlayerPrefs in the Windows registry, not in the project files, and they are the reference. Read them read-only with `reg query` (look under `HKCU\Software\DefaultCompany\SolidCarbide` for built games and `HKCU\Software\Unity\UnityEditor\DefaultCompany\SolidCarbide` for the editor; Unity appends a hash to each key name). Never write, add or delete registry values. Work out from the code which saved keys the driving actually reads, and whether anything (for example `FriendBuildPauseTuning`) overwrites them on launch. If both locations hold values, report both and say which one the board most likely played with; if that is unclear, list it as an open question.
- **Read-only.** Do not change, add or delete any file in it, do not run git commands that change it (checkout, stash, commit, reset, clean), and do not open it in the Unity editor or build it. Its current uncommitted changes belong to the board and must stay exactly as they are.
- Skip the generated folders `Library/`, `Temp/`, `Logs/`, `Builds/`, `ProfilerCaptures/` and `Assets.zip`.
- Look in the C# scripts, the input actions asset (`Assets/InputSystem_Actions.inputactions`), the prefabs and scenes for the car (serialized values in `.prefab`, `.unity` and `.asset` files override the defaults in the scripts), anything under `Assets/Data/`, and the physics settings in `ProjectSettings/` (fixed timestep, gravity, physics materials).
- The project also contains design documents (`vision.md`, `mvp.md`, `devplan.md`, `docs/`). Read them only for what they say about driving, drifting, reverse or their tuning. This report covers only the car's movement; do not carry other game content over.

### 1. The report: `docs/drifting/unity-prototype-report.md`

Written for the board, who is not reading C# code. Plain language first, exact detail after. Sections:

1. **Summary:** in a few paragraphs, how the car drives, drifts and reverses, and what makes it feel the way it does.
2. **Controls:** every input that affects the car (keys, gamepad if any), what each does, and how the game switches between driving forward, braking and reversing on S.
3. **States:** the car's movement states (for example driving, drifting, reversing) and what moves it between them, as a Mermaid state diagram.
4. **How it works, step by step:** what happens to speed, direction, grip and rotation on each physics update, as formulas or short pseudocode, each with a plain-language explanation. Note whether the prototype is 2D or 3D physics, and which physics engine features it relies on (rigidbody, drag, friction, physics materials, forces or direct velocity changes). Identify the **drift curve** explicitly: how drift intensity grows while A or D is held, as a formula and its shape (the board decided Solid Carbide uses this curve).
5. **Every tuning value:** one table listing each parameter, its default in the project files (after prefab or scene overrides), the board's saved value from the registry where one exists, which of the two the game actually uses, its unit, what it does, and where it is set (file path plus line number or field name, or the registry key).
6. **Graphics:** charts that show the behaviour, for example speed over time when holding W from standstill, turning rate against speed, how the drift builds while A or D is held, and reverse speed. Produce them with a script (see 3), not by hand, and say in the report that they come from re-implementing the formulas, not from running Unity.
7. **Camera:** record how the camera behaves: how it follows the car, its zoom, any look-ahead or smoothing, and the values behind them (code defaults and saved values, as in the tuning table). Describe it only. The board decided this camera is Solid Carbide's default unless it decides otherwise later.
8. **Porting to Godot 4.6:** for each Unity feature used (including the camera), the closest Godot equivalent, and anything that will not carry over exactly (for example how drag and damping differ, unit and scale differences, and a 50 Hz versus 60 Hz physics rate). Then a proposed list of the settings the Godot version should expose, ready to become sliders in the drift prototype.
9. **Open questions:** anything that could not be worked out from the files, so the board can answer it.

### 2. Update `docs/drifting.md`

Follow the document structure in `docs/README.md` ("How separate documents are written"). In the "Content" section, add a `### Unity prototype summary` subsection: a few bullet points of facts about the prototype's driving, no new decisions. Change the "is being written" sentence under "### Prototypes so far" to say the report is done, and remove "(being written in task T-006)" from the report link in "References". Do not change "Summary", "Decisions" or "Open questions": decisions come from the board. If the report raises open questions, list them in the report's own section 9; the Project Lead moves the ones the board wants tracked into the document.

### 3. Chart script: `tools/unity_drift_charts.py`

Python 3.9+. matplotlib 3.10 is installed on the board's machine and may be used. The script re-implements the prototype's movement formulas with its tuning values, simulates the scenarios in the charts, and writes the images (SVG preferred) into `docs/drifting/`. Running it twice must produce the same images. Write tests in `tools/test_unity_drift_charts.py` that check the re-implemented formulas against values worked out by hand from the Unity code, and run them.

## Acceptance criteria

- [ ] `docs/drifting/unity-prototype-report.md` exists and has the 9 sections listed above, in that order (QA: pass / fail)
- [ ] Section 4 names the drift curve the prototype uses, with its formula, and section 7 describes the camera with its values (QA: pass / fail)
- [ ] The tuning table has a code-default column and a saved-value column, names the registry location the saved values came from, and the result notes confirm the registry was only read with `reg query` (QA: pass / fail)
- [ ] The report contains at least one Mermaid state diagram, and at least 3 charts that are image files in `docs/drifting/`, each referenced with a relative link that resolves (QA: pass / fail)
- [ ] For 5 tuning values picked by QA from the table, the value, file and line or field given in the report match the Unity project's files, including any prefab or scene override, and any saved value given matches what `reg query` shows for that key (QA: pass / fail)
- [ ] The controls section matches the bindings in `Assets/InputSystem_Actions.inputactions` and the scripts that read them, including S for reverse (QA: pass / fail)
- [ ] `python tools/unity_drift_charts.py` regenerates the chart images, and running it a second time leaves them byte-for-byte unchanged (QA: pass / fail)
- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, including the new chart-script tests (QA: pass / fail)
- [ ] `docs/drifting.md` links to the report and has a `### Unity prototype summary` subsection in "Content", still follows the five-section structure in `docs/README.md`, and its "Summary", "Decisions" and "Open questions" sections are unchanged (QA: pass / fail)
- [ ] The Unity project is unchanged: in `C:\Users\andre\drift-to-survive`, `git rev-parse HEAD` prints `126e7ec3845fa4023aa0854569a5449be3d4c2a6`, `git status --porcelain` prints exactly the three lines ` M .cursor/rules/project.mdc`, ` M docs/ideas.md` and `?? docs/ISOMETRIC_MAP_GENERATOR_PLAN.md`, and `git diff | sha256sum` prints `428db3b753a54e4752759f534f28e444bebd7dd54c30894f960e66e98fadcd30` (QA: pass / fail)
- [ ] No file under `game/`, `.claude/agents/` or other `docs/` files changed, apart from `docs/drifting.md` and `docs/drifting/` (QA: pass / fail)

The board's review: read the report and judge whether it describes the prototype's feel as the board remembers it.

## Result notes

Written by the agent when it finishes.
