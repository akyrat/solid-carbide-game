---
id: T-003
title: PixelLab test run: generate 1 isometric tile and 1 still car image
status: open
from: project-lead
to: asset-generation
depends_on: [T-001]
documents_affected: []
files_to_read_first: [tasks/README.md, README.md, game/README.md, .env.example, .claude/agents/asset-generation.md]
files_expected_to_change: [the PixelLab client script and its tests, generated images and their record files]
qa_rounds: 0
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

- [ ] `iso-tile/` contains exactly 1 PNG and `car/` contains exactly 1 PNG (QA: pass / fail)
- [ ] Every PNG opens as a valid image with the dimensions given in its record, and Godot imports it without errors using the headless runner from T-001 (QA: pass / fail)
- [ ] Every asset has a record JSON next to it, and every field listed in step 4 is present and non-empty, except the car's job id, which is `null` (QA: pass / fail)
- [ ] No record JSON, script or other tracked file contains the value of `PIXELLAB_API_KEY` from `.env` (QA: pass / fail)
- [ ] `git status` and `git ls-files` show no `.env` file (QA: pass / fail)
- [ ] The result notes give the balance before and after the run, and the cost of each call (QA: pass / fail)
- [ ] The PixelLab job log or records show exactly 2 generation calls, with no regeneration (QA: pass / fail)
- [ ] The script's tests pass, and are run by the test command from T-001 or a documented command next to it (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
