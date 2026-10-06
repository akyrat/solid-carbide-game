---
id: T-003
title: PixelLab test run: generate 1 isometric tile and 1 still car image
status: done
from: project-lead
to: asset-generation
epic: art
milestone: mvp
depends_on: [T-001]
documents_affected: []
files_to_read_first: [tasks/README.md, README.md, game/README.md, .env.example, .claude/agents/asset-generation.md]
files_expected_to_change: [the PixelLab client script and its tests, generated images and their record files]
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

A test run to prove the Asset Generation Agent can use the board's PixelLab API token to generate images and keep a record of each one. It depends on T-001 (done), so that `.gitignore` protects `.env` before the token is used.

The token is `PIXELLAB_API_KEY` in `.env` at the repo root, as described in the root README's "Secrets and API keys" section. Never print its value, write it to any other file, or put it in a commit.

What the PixelLab docs say (read them yourself before starting):
- AI-assistant docs: https://api.pixellab.ai/v2/llms.txt. Full machine-readable spec: https://api.pixellab.ai/v2/openapi.json. Interactive docs: https://api.pixellab.ai/v2/docs.
- Base URL `https://api.pixellab.ai/v2`. Every request sends `Authorization: Bearer <token>`.
- Most generation endpoints are asynchronous: they return a `background_job_id` to poll at `GET /background-jobs/{job_id}` every 5 to 10 seconds until the status is `completed` or `failed`. Then fetch the result.
- `GET /balance` returns the remaining USD credits and subscription generations. Responses include a `usage` field with the cost.
- An official Python SDK exists (`pip install pixellab`). Using it or calling the REST API directly is your choice; give the reason in the result notes.

Steps:

1. Write a reusable PixelLab client script (the agent will use it for all future art). It reads the token from `.env`, handles both kinds of endpoint (asynchronous ones it submits and polls, and direct ones that return the image in the response), downloads the result as PNG, and writes the record file described in step 4. It stops with a clear error on `failed`, and when polling has gone on for more than 10 minutes.
2. Call `GET /balance` before and after the run, and put both values in the result notes.
3. Generate exactly these two test assets, one call each:
   - **1 isometric tile** with `POST /create-isometric-tile`: a plain asphalt road tile, 32x32.
   - **1 car** as a single still image with `POST /create-image-pixflux`: a generic sports car, 64x64, `isometric: true`, `no_background: true`. This endpoint answers directly instead of through a background job, and is among the cheapest (the docs' example shows about $0.01). Do not use the object endpoints (`/create-1-direction-object`, `/create-8-direction-object`): they cost 20 to 40 subscription generations per call.
   The descriptions are deliberately generic: the Visual style document is not written yet, and this run tests the pipeline, not the game's look. Do not make any style decision and do not update the Visual style document.
4. Save the images under the art folder T-001 created, in a subfolder marked as a test run, for example `art/_test-run/iso-tile/` and `art/_test-run/car/`. Next to each generated asset, write a record JSON with at least: endpoint, the full request parameters (without the token), the prompt, PixelLab job id and tile id (for the tile; the car call returns no job id, so record `null`), the cost from `usage`, the generation date, and the documents or other resources consulted.
5. One round only: if a result looks wrong, do not regenerate it. Report it in the result notes. Never judge whether an asset is good; the board decides that.
6. Write tests for the parts of the script that don't call PixelLab (for example, record writing, PNG decoding and the polling timeout), and run them.

## Acceptance criteria

- [x] `iso-tile/` contains exactly 1 PNG and `car/` contains exactly 1 PNG (QA: pass)
- [x] Every PNG opens as a valid image with the dimensions given in its record, and Godot imports it without errors using the headless runner from T-001 (QA: pass)
- [x] Every asset has a record JSON next to it, and every field listed in step 4 is present and non-empty, except the car's job id, which is `null` (QA: pass)
- [x] No record JSON, script or other tracked file contains the value of `PIXELLAB_API_KEY` from `.env` (QA: pass)
- [x] `git status` and `git ls-files` show no `.env` file (QA: pass)
- [x] The result notes give the balance before and after the run, and the cost of each call (QA: pass)
- [x] The PixelLab job log or records show exactly 2 generation calls, with no regeneration (QA: pass)
- [x] The script's tests pass, and are run by the test command from T-001 or a documented command next to it (QA: pass)

## Result notes

Written by the agent when it finishes.

**Asset Generation Agent, 2026-10-04**

**What was built.** `game/tools/pixellab_client.py`, a reusable PixelLab client for all future art. Two commands: `balance` (free) and `generate` (exactly one paid call, never retried). It reads `PIXELLAB_API_KEY` from the environment or `.env`, handles direct endpoints (image in the response) and asynchronous ones (submits, polls `GET /background-jobs/{id}` every 5 s, stops with an error on `failed` or after 10 minutes, then fetches the result, e.g. `GET /isometric-tiles/{tile_id}`). It validates the PNG (signature, IHDR checksum, IEND), saves `<name>.png` with a record `<name>.json` next to it, and appends every generation call (success or failure) to `game/art/pixellab-generation-log.jsonl`. It refuses to overwrite an existing asset, so nothing can be regenerated by accident, and it refuses to write any data containing the token; error messages are redacted.

**SDK vs direct REST: direct REST** (Python standard library, `urllib`). Reasons: no package to install, matching the SFX Agent's Freesound tool; the client needs only a few calls; it gives full control over the 10-minute polling limit, the no-retry rule and exactly what goes into the records; and it follows the OpenAPI spec directly instead of depending on how current the SDK is.

**How to run it.** See `game/README.md`, section "Generating art with PixelLab". Example: `python game/tools/pixellab_client.py balance`. Give `--endpoint` without its leading slash (`create-image-pixflux`), because Git Bash rewrites a leading `/` into a Windows path.

**Tests.** `game/tools/test_pixellab_client.py` (22 Python tests, HTTP faked, no PixelLab calls): `.env` parsing and token loading, redaction, PNG decoding and validation (data URL and raw base64, bad signature, bad checksum, truncated file), polling (completes, `failed`, 10-minute timeout, transient 429 keeps polling, 401 stops), direct and async generation, no retry on failure, refusal to overwrite, token never written. Run with the documented Python tool tests command next to `run_tests.sh`: `python -m unittest discover -s game/tools -p "test_*.py"` (45 tests, mine plus the SFX Agent's, all OK). I also added `game/tests/unit/test_pixellab_assets.gd` to the GUT suite: it loads every PixelLab-generated PNG under `res://art/` and checks Godot's texture size against its record. `bash game/tools/run_tests.sh`: 11/11 passed, TESTS PASSED.

**The two calls** (resources consulted for both: this task file, https://api.pixellab.ai/v2/llms.txt and the OpenAPI spec):

| Asset | Endpoint | Request | Job id / tile id | Cost (`usage`) | Output |
| --- | --- | --- | --- | --- | --- |
| Isometric tile | `POST /create-isometric-tile` | `description: "plain asphalt road tile"`, `image_size` 32x32, `isometric_tile_size: 32` | job `ff81b007-7bcc-4f2a-999d-359afce89388`, tile `fe1293a2-e569-4251-ab5c-c0bb9fafd3a1` | 1 subscription generation ($0.00) | `game/art/_test-run/iso-tile/asphalt-road-tile.png`, 32x32 RGBA |
| Car | `POST /create-image-pixflux` | `description: "generic sports car"`, `image_size` 64x64, `isometric: true`, `no_background: true` | job `null` (direct endpoint) | 1 subscription generation ($0.00) | `game/art/_test-run/car/sports-car.png`, 64x64 RGBA |

All other optional parameters were left at PixelLab's defaults. The only one I set beyond the task's list is `isometric_tile_size: 32`, so the tile matches the 32x32 canvas (the default is 16). No style decision was made, and the Visual style document was not touched.

**Balance.** Before: USD credits $0.00, subscription (trial) 19 of 40 generations remaining. Immediately after both calls: 18 (the tile's charge had not posted yet). A few minutes later: **17 of 40**, USD still $0.00. Total: 2 generations, matching the two `usage` values. The account is on a trial with no USD credits, so both calls were paid from trial generations.

**Observation, not a judgement.** The tile came out as a cube-shaped block, not a flat road surface. This matches PixelLab's default `isometric_tile_shape: "block"` (~50% of the canvas height); `"thin tile"` and `"thick tile"` also exist. Not regenerated (one round only). Whether that matters is for the board.

**Files created or changed**
- Created: `game/tools/pixellab_client.py`, `game/tools/test_pixellab_client.py`
- Created: `game/tests/unit/test_pixellab_assets.gd` and its `.uid` (made by Godot)
- Created: `game/art/_test-run/iso-tile/asphalt-road-tile.png`, `.png.import` (made by Godot), `asphalt-road-tile.json`
- Created: `game/art/_test-run/car/sports-car.png`, `.png.import` (made by Godot), `sports-car.json`
- Created: `game/art/pixellab-generation-log.jsonl` (2 entries, both `saved`)
- Changed: `game/README.md` (new section "Generating art with PixelLab" only)
- Changed: `agent-notes/asset-generation.md` (notes from experience)
- Changed: this task file
- Documents affected: none

**Problems**
- My first `generate` command used `--endpoint /create-isometric-tile`. Git Bash rewrote it into a Windows path and argparse rejected it before any request was sent (no log entry, no charge). The script now accepts the endpoint without the slash. A test covers this.
- I first put the script in `game/tools/pixellab/`, then moved it up into `game/tools/` so the SFX Agent's shared Python test command finds its tests. The two records' `generator` field was updated to the new path; nothing else in them changed.
- The `tools/` row of the folder table in `game/README.md` doesn't mention the PixelLab client. I left it alone because the SFX Agent had just edited that line; the Project Lead may want to add it.
- `godot --import` prints Godot's generic "ObjectDB instances leaked at exit" warning. Exit code 0, and no import errors for either PNG.

### QA round 1

**QA/Integration Agent, 2026-10-04.** All 8 criteria pass. No PixelLab endpoint was called (not even `balance`).

- Files: `find game/art/_test-run -type f`: `iso-tile/` and `car/` each hold exactly 1 PNG, plus its `.json` record and `.png.import`.
- PNGs: a Python stdlib script read each file's signature, IHDR, every chunk CRC and the decompressed IDAT length. Tile 32x32, car 64x64, both 8-bit RGBA, ending in IEND, matching their records. `.godot/imported/` holds a `.ctex` for both. `bash game/tools/run_tests.sh -gselect=test_pixellab_assets`: 1/1 passed, 6 asserts (load + width + height for each of the 2 assets), no import errors in the output. Looked at both images: a cube-shaped purple-grey block and a red isometric sports car on a transparent background, as the result notes describe.
- Records: every step 4 field (endpoint, request_params, prompt, job_id, tile_id for the tile, usage, generated_at, resources_consulted) is present and non-empty; the car's `job_id` is `null`.
- Secret: a script read `PIXELLAB_API_KEY` from `.env` and searched all 362 files from `git ls-files -co --exclude-standard`, plus every file under `game/` including ignored ones (`.godot/`): no match. The value was never printed.
- `.env`: not in `git ls-files` (only `.env.example`) or `git status --porcelain --untracked-files=all`; `git check-ignore -v .env` matches `.gitignore:2`.
- Balance and cost: the result notes give before (19 of 40 trial generations, $0.00 USD) and after (17 of 40), and 1 generation per call, matching `usage` in both records.
- Calls: `game/art/pixellab-generation-log.jsonl` has exactly 2 entries (tile, car), both `saved`; 2 records; no regeneration.
- Tests: `bash game/tools/run_tests.sh`: 11/11 passed, TESTS PASSED, exit 0. `python -m unittest discover -s game/tools -p "test_*.py"`: 45 tests OK, exit 0 (22 of them in `test_pixellab_client.py`, also OK alone). No clash with T-002's in-progress files.
- Observations: the records' `usage` gives the cost in generations, not USD, because the account is on a trial; that counts as the cost. The `tools/` row of the folder table in `game/README.md` still doesn't mention the PixelLab client (noted by the agent, left for the Project Lead).

### Board review

2026-10-04: the board reviewed the test run, kept both images, and marked the task `done`.
