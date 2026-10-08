---
id: T-006
title: Report on driving, drifting and reverse in the board's Unity prototype, and how to port them to Godot
status: done
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/drifting/unity-prototype-report.md, docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/drifting.md, .claude/agents/driving-drift.md, game/README.md]
files_expected_to_change: [docs/drifting/unity-prototype-report.md, docs/drifting/ (chart images), docs/drifting.md, tools/unity_drift_charts.py, tools/test_unity_drift_charts.py]
qa_rounds: 1
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

- [x] `docs/drifting/unity-prototype-report.md` exists and has the 9 sections listed above, in that order (QA: pass)
- [x] Section 4 names the drift curve the prototype uses, with its formula, and section 7 describes the camera with its values (QA: pass)
- [x] The tuning table has a code-default column and a saved-value column, names the registry location the saved values came from, and the result notes confirm the registry was only read with `reg query` (QA: pass)
- [x] The report contains at least one Mermaid state diagram, and at least 3 charts that are image files in `docs/drifting/`, each referenced with a relative link that resolves (QA: pass)
- [x] For 5 tuning values picked by QA from the table, the value, file and line or field given in the report match the Unity project's files, including any prefab or scene override, and any saved value given matches what `reg query` shows for that key (QA: pass)
- [x] The controls section matches the bindings in `Assets/InputSystem_Actions.inputactions` and the scripts that read them, including S for reverse (QA: pass)
- [x] `python tools/unity_drift_charts.py` regenerates the chart images, and running it a second time leaves them byte-for-byte unchanged (QA: pass)
- [x] `python -m unittest discover -s tools -p "test_*.py"` passes, including the new chart-script tests (QA: pass)
- [x] `docs/drifting.md` links to the report and has a `### Unity prototype summary` subsection in "Content", still follows the five-section structure in `docs/README.md`, and its "Summary", "Decisions" and "Open questions" sections are unchanged (QA: pass)
- [x] The Unity project is unchanged: in `C:\Users\andre\drift-to-survive`, `git rev-parse HEAD` prints `126e7ec3845fa4023aa0854569a5449be3d4c2a6`, `git status --porcelain` prints exactly the three lines ` M .cursor/rules/project.mdc`, ` M docs/ideas.md` and `?? docs/ISOMETRIC_MAP_GENERATOR_PLAN.md`, and `git diff | sha256sum` prints `428db3b753a54e4752759f534f28e444bebd7dd54c30894f960e66e98fadcd30` (QA: pass)
- [x] No file under `game/`, `.claude/agents/` or other `docs/` files changed, apart from `docs/drifting.md` and `docs/drifting/` (QA: pass)

The board's review: read the report and judge whether it describes the prototype's feel as the board remembers it.

## Result notes

**Handed to QA:** 2026-10-04, by the Driving & Drift Agent.

**What was found.** The prototype is a top-down 2D car (`Rigidbody2D`, 50 Hz). Its code sets the velocity directly each step. W snaps to cruise speed 11, then ramps to top speed 27.5. S brakes at the same rate, snaps to -11 at zero, then ramps to -27.5. W always wins. A and D rotate the body at a fixed 191.9 deg/s at every speed. The drift comes from sideways speed being kept at 0.98 per step, so a held W + A builds a slide that levels off near 75 degrees at about 34 units/s. The coded "drift amount" (linear, full in 0.08 s, gone in 0.33 s) does not change the handling, because all three grip values in the car data are 0.98. The report lists both as candidates for "the drift curve" (open question 1). The camera is orthographic, snaps to the car every frame and never rotates, with no smoothing or look-ahead. Its zoom is the saved pause-menu value (default 14.4). The car ignores `InputSystem_Actions.inputactions` and reads keys directly, so the arrow keys do not steer.

**Where the tuning came from.** Driving values come from `Assets/Data/Vehicles/Vehicle_Default.asset`. Every stage scene assigns it to `PlayerStats`, and it overrides the `VehicleData.cs` defaults (for example turn speed 202 instead of 259, and drift exit rate 3 instead of 12). Since commit `122ef42` (2026-04-30) the code reads **no** driving value from the registry. The `Driving.*` registry keys are leftovers; their readable lower halves match 2.5, 2.3, 0.3 and 0.95, the asset's values. `FriendBuildPauseTuning` overwrites no driving or camera key on launch. The registry was read **only with `reg query`** (no writes, adds or deletes), at `HKCU\Software\DefaultCompany\SolidCarbide` (built game), `HKCU\Software\Unity\UnityEditor\DefaultCompany\SolidCarbide` (editor) and the old `HKCU\Software\Unity\UnityEditor\DefaultCompany\DriftSurvivors`. The game still reads two saved values: `CameraZoom`, and `Driving.ShowDriftLaunchIndicator` (absent, so off).

**Blocked / limits.** `reg query` prints only the lower 4 bytes of Unity's 8-byte float entries, so the board's saved camera zoom cannot be read exactly. The built game's value is neither 14.4 nor 12; the editor's is unreadable. Reading it fully needs either the board reading the slider, or approval for another read-only method (for example PowerShell `Get-ItemProperty`). That was not attempted, per the working rules. No command was blocked by permissions. The Unity project's `Builds/` folder was not looked at.

**How to run.**
- Charts: `python tools/unity_drift_charts.py` writes 7 SVGs into `docs/drifting/`. `--summary` also prints the key numbers quoted in the report. Running it twice gives byte-identical files (checked with sha256).
- Tests: `python -m unittest discover -s tools -p "test_*.py"` runs 42 tests and prints OK. 23 of them are new, in `tools/test_unity_drift_charts.py`, and check the formulas against values worked out by hand from the Unity code.

**Files created or changed.**
- Created: `docs/drifting/unity-prototype-report.md`; `docs/drifting/speed-hold-w.svg`, `speed-reverse.svg`, `turn-rate-vs-speed.svg`, `drift-amount.svg`, `drift-build-speeds.svg`, `drift-angle.svg`, `drift-path.svg`; `tools/unity_drift_charts.py`; `tools/test_unity_drift_charts.py`.
- Changed: `docs/drifting.md`. In Content, "is being written" now says the report is done, and there is a new `### Unity prototype summary`. In References, "(being written in task T-006)" is removed. Summary, Decisions and Open questions are untouched. Also this task file.

**Documents affected:** `docs/drifting/unity-prototype-report.md` (new), `docs/drifting.md` (updated).

**Unity project unchanged** (checked at the end): HEAD is `126e7ec3845fa4023aa0854569a5449be3d4c2a6`; `git status --porcelain` prints the three expected lines; `git diff | sha256sum` prints `428db3b753a54e4752759f534f28e444bebd7dd54c30894f960e66e98fadcd30`. Only read-only git commands were used (`rev-parse`, `status`, `diff`, `log`, `show`).

**Problems / notes for the Project Lead.**
- In `docs/drifting.md`, Content, "Prototypes so far" still says the reference driving values are "saved in the Windows registry rather than in the project files". The report shows that is no longer true for the driving; only the camera zoom is saved there. This was not edited here, because the task limited the changes to the new subsection and the two sentences. The Project Lead may want to correct it.
- The charts re-implement the formulas. They are not recordings from Unity, and they ignore collisions.
- The open questions for the board are in the report's section 9 (12 questions). The most important: which "drift curve" is meant, the saved camera zoom, which stage the feel was judged on, and whether to run Godot at 50 Hz.

### QA round 1

2026-10-04, QA/Integration Agent. Result: all 11 criteria pass. Status set to `needs-playtest`.

- **Report structure:** the 9 `##` sections are present in the required order. Section 4 has `### The drift curve` with formulas for (a) the coded drift amount and (b) the felt slide. Section 7 gives the camera's follow mode, offset, rotation and zoom values with file and line references. The tuning table has "Default in script", "Value in project files (used)" and "Saved value (registry)" columns and names both registry locations. The Mermaid state diagram is present. All 7 SVG links in section 6 resolve to files in `docs/drifting/`.
- **5 tuning values checked against the Unity project (read only):** `turnSpeed` 202 (`Vehicle_Default.asset` line 16; script default 259 at `VehicleData.cs` line 16); `driftExitRate` 3 (asset line 26; script default 12 at line 50); `timeToTopSpeedSeconds` 2.3 (asset line 18; `reg query` shows `Driving.TimeToTopSpeedSeconds_h811639555` = `0x60000000` under both the built-game and editor keys, which is the lower half of 2.3f stored as a double); linear damping 0 (`m_LinearDamping` at `Stage_Grass.unity` line 75320, `Stage_Isometric.unity` line 167836, `MainScene.unity` line 447); camera zoom (`orthographic size: 12` at `Stage_Grass.unity` line 76683, `orthoSize: 12` at line 76622, `CameraZoomDefault = 14.4f` at `PauseUI.cs` line 109, read at line 173; `reg query` shows `CameraZoom_h3219581099` = `0x20000000` built and `0x0` editor). All match. All three stage scenes assign `Vehicle_Default.asset` (GUID `b2c3d4e5...03`) to `PlayerStats`. A grep of `PlayerPrefs` in `Assets/Scripts` confirms no driving value is read from the registry. The registry was read only with `reg query`.
- **Controls:** `PlayerCarController.cs` reads W, S, A, D, the triggers (0.2), the left stick (0.15 dead zone) and Space directly, with S ignored while W is held, and the reverse logic in `ApplyMovementAndDrift` matches section 2. No car script uses `InputSystem_Actions.inputactions`; its `Player` map binds `Move` to WASD, the arrow keys and the stick, as the report says. Escape and Start pause (`PauseUI.cs` lines 201-205).
- **Charts:** `python tools/unity_drift_charts.py` was run twice. The sha256 of all 7 SVGs was identical before the first run, after it and after the second run.
- **Tests:** `python -m unittest discover -s tools -p "test_*.py"` ran 42 tests and printed OK.
- **`docs/drifting.md`:** `git diff` shows changes only under "### Prototypes so far", the new "### Unity prototype summary" (both in Content), and the References link. Summary, Decisions and Open questions are unchanged. The front matter and the five `##` sections are in the right order.
- **Unity baseline:** HEAD is `126e7ec3845fa4023aa0854569a5449be3d4c2a6`; `git status --porcelain` prints exactly the three expected lines; `git diff | sha256sum` prints `428db3b753a54e4752759f534f28e444bebd7dd54c30894f960e66e98fadcd30`.
- **Scope:** `git status --porcelain --untracked-files=all` lists only `docs/drifting.md`, the files in `docs/drifting/`, the two `tools/` scripts and this task file.
- **Observations:** (1) The report's "velocity lags the body by one step" depends on how `MoveRotation` is applied. That cannot be checked without running Unity, and the report already lists it as open question 12. (2) The image links in the report are relative to `docs/drifting/`, not `docs/`. They resolve, and the report is a reference rather than a separate document, but the links would need adjusting if the report were ever pulled into the long GDD.

### Board review

2026-10-06: the board read the report, discussed its findings with the Project Lead, and marked the task `done`. Its open questions were answered in Drifting, Decisions (2026-10-06).
