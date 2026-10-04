#!/usr/bin/env python3
"""PixelLab API client for the Asset Generation Agent.

Calls the PixelLab REST API (https://api.pixellab.ai/v2) directly, using only
the Python standard library. It:

- reads PIXELLAB_API_KEY from the environment, or from .env at the repo root;
- handles direct endpoints (the image comes back in the response) and
  asynchronous ones (submit, poll GET /background-jobs/{id}, then fetch);
- saves the result as a PNG and writes a record JSON next to it;
- appends every paid generation call (success or failure) to a JSONL log.

It never retries a generation call: each one costs money. A failed call stops
with an error and is logged.

Usage, from the repo root (see game/README.md for details):

    python game/tools/pixellab_client.py balance
    python game/tools/pixellab_client.py generate \
        --endpoint create-image-pixflux --params-file req.json \
        --out-dir game/art/some/folder --name my-asset \
        --consulted docs/visual-style.md --task T-000

The token is never printed or written to any file.
"""

from __future__ import annotations

import argparse
import base64
import binascii
import datetime as _dt
import json
import os
import struct
import sys
import time
import urllib.error
import urllib.request
import zlib
from pathlib import Path
from typing import Any, Callable

API_BASE = "https://api.pixellab.ai/v2"
POLL_INTERVAL_SECONDS = 5.0
POLL_TIMEOUT_SECONDS = 600.0  # 10 minutes
HTTP_TIMEOUT_SECONDS = 120.0
TOKEN_VAR = "PIXELLAB_API_KEY"

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_LOG = REPO_ROOT / "game" / "art" / "pixellab-generation-log.jsonl"

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"

# Endpoints this client knows how to finish. "direct" endpoints return the
# image in the POST response. "async" endpoints return a background job id;
# after the job completes the result is fetched from `result_path`, filled in
# from fields of the POST response. Add endpoints here as they are needed.
ENDPOINTS: dict[str, dict[str, Any]] = {
    "/create-image-pixflux": {"mode": "direct"},
    "/create-image-bitforge": {"mode": "direct"},
    "/create-isometric-tile": {
        "mode": "async",
        "result_path": "/isometric-tiles/{tile_id}",
        "ids": ["tile_id"],
    },
}


class PixelLabError(RuntimeError):
    """Any failure talking to PixelLab or handling its result."""


class PollTimeout(PixelLabError):
    """Polling a background job went on for longer than the timeout."""


# ---------------------------------------------------------------- token ----

def parse_env_file(text: str) -> dict[str, str]:
    """Parse simple KEY=VALUE lines. Ignores comments, blank lines and quotes."""
    values: dict[str, str] = {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        if key.startswith("export "):
            key = key[len("export "):].strip()
        value = value.strip()
        # Drop an inline comment on an unquoted value.
        if value and value[0] not in "\"'" and " #" in value:
            value = value.split(" #", 1)[0].rstrip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        values[key] = value
    return values


def load_token(env: dict[str, str] | None = None, env_file: Path | None = None) -> str:
    """Return the API token from the environment, else from .env. Never prints it."""
    env = os.environ if env is None else env
    token = (env.get(TOKEN_VAR) or "").strip()
    if token:
        return token
    env_file = REPO_ROOT / ".env" if env_file is None else env_file
    if env_file.is_file():
        token = parse_env_file(env_file.read_text(encoding="utf-8")).get(TOKEN_VAR, "").strip()
    if not token:
        raise PixelLabError(
            f"{TOKEN_VAR} is not set. Add it to .env at the repo root "
            "(see README.md, 'Secrets and API keys')."
        )
    return token


def redact(text: str, token: str) -> str:
    """Remove the token from any text before it is shown or stored."""
    if token:
        text = text.replace(token, "[REDACTED]")
    return text


def assert_no_token(obj: Any, token: str) -> None:
    """Raise if the token appears anywhere in obj's JSON form."""
    if token and token in json.dumps(obj, ensure_ascii=False):
        raise PixelLabError("Refusing to write data that contains the API token.")


# ------------------------------------------------------------------ PNG ----

def strip_data_url(b64: str) -> str:
    """Accept either raw base64 or a 'data:image/png;base64,...' URL."""
    if b64.startswith("data:"):
        _, _, b64 = b64.partition(",")
    return b64.strip()


def decode_base64_png(b64: str) -> bytes:
    try:
        data = base64.b64decode(strip_data_url(b64), validate=True)
    except (binascii.Error, ValueError) as exc:
        raise PixelLabError(f"Image is not valid base64: {exc}") from exc
    png_info(data)  # validates
    return data


def png_info(data: bytes) -> dict[str, int]:
    """Validate a PNG's signature and IHDR chunk, return its size and format.

    Checks the signature, the IHDR length/type/CRC, and that an IEND chunk
    ends the file. Does not decompress the pixel data.
    """
    if len(data) < 33 or data[:8] != PNG_SIGNATURE:
        raise PixelLabError("Data is not a PNG (bad signature or too short).")
    length, ctype = struct.unpack(">I4s", data[8:16])
    if ctype != b"IHDR" or length != 13:
        raise PixelLabError("PNG does not start with a valid IHDR chunk.")
    body = data[16:29]
    (crc,) = struct.unpack(">I", data[29:33])
    if zlib.crc32(b"IHDR" + body) & 0xFFFFFFFF != crc:
        raise PixelLabError("PNG IHDR checksum does not match.")
    width, height, bit_depth, color_type = struct.unpack(">IIBB", body[:10])
    if width == 0 or height == 0:
        raise PixelLabError("PNG has zero width or height.")
    if data[-12:-8] != b"\x00\x00\x00\x00" or data[-8:-4] != b"IEND":
        raise PixelLabError("PNG is truncated (no IEND chunk at the end).")
    return {"width": width, "height": height, "bit_depth": bit_depth, "color_type": color_type}


def extract_image_b64(response: dict[str, Any]) -> str:
    """Find the base64 image in a PixelLab result body."""
    candidates = [response.get("image")]
    last = response.get("last_response")
    if isinstance(last, dict):
        candidates.append(last.get("image"))
    for img in candidates:
        if isinstance(img, dict) and isinstance(img.get("base64"), str) and img["base64"]:
            return img["base64"]
        if isinstance(img, str) and img:
            return img
    raise PixelLabError("No image found in the PixelLab response.")


# --------------------------------------------------------------- record ----

def now_iso() -> str:
    return _dt.datetime.now(_dt.timezone.utc).replace(microsecond=0).isoformat()


def build_record(
    *,
    endpoint: str,
    params: dict[str, Any],
    job_id: str | None,
    ids: dict[str, Any],
    usage: Any,
    consulted: list[str],
    png: dict[str, int],
    png_file: str,
    task: str | None,
    generated_at: str,
    notes: str = "",
    job_status: str | None = None,
) -> dict[str, Any]:
    record: dict[str, Any] = {
        "file": png_file,
        "endpoint": endpoint,
        "api_base": API_BASE,
        "request_params": params,
        "prompt": params.get("description", ""),
        "job_id": job_id,
    }
    record.update(ids)
    record.update(
        {
            "usage": usage,
            "generated_at": generated_at,
            "image": png,
            "resources_consulted": consulted,
            "task": task,
            "job_status": job_status,
            "notes": notes,
            "generator": "game/tools/pixellab_client.py",
        }
    )
    return record


def write_json(path: Path, obj: Any, token: str) -> None:
    assert_no_token(obj, token)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def append_log(log_path: Path, entry: dict[str, Any], token: str) -> None:
    assert_no_token(entry, token)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(entry, ensure_ascii=False) + "\n")


# ----------------------------------------------------------------- HTTP ----

class Http:
    """Minimal JSON-over-HTTPS client. Replace in tests."""

    def __init__(self, token: str, base: str = API_BASE):
        self.token = token
        self.base = base.rstrip("/")

    def request(self, method: str, path: str, body: dict[str, Any] | None = None) -> tuple[int, Any]:
        data = None if body is None else json.dumps(body).encode("utf-8")
        req = urllib.request.Request(self.base + path, data=data, method=method)
        req.add_header("Authorization", f"Bearer {self.token}")
        req.add_header("Accept", "application/json")
        if data is not None:
            req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT_SECONDS) as resp:
                status, raw = resp.status, resp.read()
        except urllib.error.HTTPError as exc:
            status, raw = exc.code, exc.read()
        except urllib.error.URLError as exc:
            raise PixelLabError(redact(f"Network error calling {method} {path}: {exc.reason}", self.token)) from None
        text = raw.decode("utf-8", errors="replace")
        try:
            payload: Any = json.loads(text) if text else None
        except json.JSONDecodeError:
            payload = text
        return status, payload


def check(status: int, payload: Any, what: str, token: str) -> Any:
    if 200 <= status < 300:
        return payload
    detail = payload if isinstance(payload, str) else json.dumps(payload)
    raise PixelLabError(redact(f"{what} failed with HTTP {status}: {detail[:1000]}", token))


def get_balance(http: Http) -> Any:
    status, payload = http.request("GET", "/balance")
    return check(status, payload, "GET /balance", http.token)


def poll_job(
    http: Http,
    job_id: str,
    *,
    interval: float = POLL_INTERVAL_SECONDS,
    timeout: float = POLL_TIMEOUT_SECONDS,
    clock: Callable[[], float] = time.monotonic,
    sleep: Callable[[float], None] = time.sleep,
    echo: Callable[[str], None] = lambda s: None,
) -> dict[str, Any]:
    """Poll GET /background-jobs/{id} until completed. Raise on failed or timeout."""
    start = clock()
    while True:
        status, payload = http.request("GET", f"/background-jobs/{job_id}")
        if status in (429, 500, 502, 503, 504, 529):
            echo(f"  poll got HTTP {status}, will poll again")
            payload = {"status": "processing"}
        else:
            payload = check(status, payload, f"GET /background-jobs/{job_id}", http.token)
        job_status = (payload or {}).get("status")
        if job_status == "completed":
            return payload
        if job_status == "failed":
            detail = json.dumps(payload.get("last_response"))[:1000]
            raise PixelLabError(redact(f"Background job {job_id} failed: {detail}", http.token))
        elapsed = clock() - start
        if elapsed >= timeout:
            raise PollTimeout(
                f"Background job {job_id} still '{job_status}' after {int(elapsed)} s "
                f"(limit {int(timeout)} s). Stopped polling; the job may still finish on PixelLab's side."
            )
        echo(f"  job {job_id}: {job_status} ({int(elapsed)} s)")
        sleep(interval)


# ------------------------------------------------------------- generate ----

def generate(
    http: Http,
    *,
    endpoint: str,
    params: dict[str, Any],
    out_dir: Path,
    name: str,
    consulted: list[str],
    task: str | None,
    notes: str = "",
    log_path: Path = DEFAULT_LOG,
    poll_kwargs: dict[str, Any] | None = None,
    echo: Callable[[str], None] = print,
) -> dict[str, Any]:
    """Make exactly one generation call, save PNG + record. No retries."""
    if endpoint not in ENDPOINTS:
        raise PixelLabError(f"Unknown endpoint {endpoint}. Known: {', '.join(sorted(ENDPOINTS))}")
    if not consulted:
        raise PixelLabError("List at least one resource consulted (--consulted).")
    if not params.get("description"):
        raise PixelLabError("Request params need a 'description' (the prompt).")
    png_path = out_dir / f"{name}.png"
    record_path = out_dir / f"{name}.json"
    if png_path.exists() or record_path.exists():
        raise PixelLabError(f"{png_path} or its record already exists. Refusing to overwrite (no regeneration).")
    assert_no_token(params, http.token)

    spec = ENDPOINTS[endpoint]
    log_entry: dict[str, Any] = {
        "time": now_iso(), "endpoint": endpoint, "name": name, "out_dir": str(out_dir).replace("\\", "/"),
        "task": task, "prompt": params.get("description"),
    }
    job_id: str | None = None
    ids: dict[str, Any] = {}
    usage: Any = None
    job_status: str | None = None
    try:
        echo(f"POST {endpoint} (one paid call, no retries)")
        status, payload = http.request("POST", endpoint, params)
        payload = check(status, payload, f"POST {endpoint}", http.token)
        usage = payload.get("usage")
        if spec["mode"] == "direct" or isinstance(payload.get("image"), dict):
            # Direct endpoint, or an async one that answered with the image at once.
            result = payload
            ids = {k: payload.get(k) for k in spec.get("ids", [])}
            job_id = payload.get("background_job_id")
        else:
            job_id = payload.get("background_job_id")
            if not job_id:
                raise PixelLabError(f"POST {endpoint} returned no background_job_id.")
            ids = {k: payload.get(k) for k in spec.get("ids", [])}
            log_entry.update({"job_id": job_id, **ids})
            echo(f"  job {job_id} submitted, polling every {int((poll_kwargs or {}).get('interval', POLL_INTERVAL_SECONDS))} s")
            job = poll_job(http, job_id, echo=echo, **(poll_kwargs or {}))
            job_status = job.get("status")
            if job.get("usage") and not usage:
                usage = job.get("usage")
            try:
                extract_image_b64(job)
                result = job
            except PixelLabError:
                path = spec["result_path"].format(**ids)
                st, res = http.request("GET", path)
                result = check(st, res, f"GET {path}", http.token)
            if result.get("usage") and not usage:
                usage = result.get("usage")
        png_bytes = decode_base64_png(extract_image_b64(result))
        info = png_info(png_bytes)
        out_dir.mkdir(parents=True, exist_ok=True)
        png_path.write_bytes(png_bytes)
        record = build_record(
            endpoint=endpoint, params=params, job_id=job_id, ids=ids, usage=usage,
            consulted=consulted, png=info, png_file=png_path.name, task=task,
            generated_at=now_iso(), notes=notes, job_status=job_status,
        )
        write_json(record_path, record, http.token)
        log_entry.update({"result": "saved", "usage": usage, "file": png_path.name})
        echo(f"  saved {png_path} ({info['width']}x{info['height']}), usage {json.dumps(usage)}")
        return record
    except Exception as exc:
        log_entry.update({"result": "error", "error": redact(str(exc), http.token), "usage": usage})
        raise
    finally:
        append_log(log_path, log_entry, http.token)


# ------------------------------------------------------------------ CLI ----

def normalize_endpoint(name: str) -> str:
    """'create-image-pixflux' or '/create-image-pixflux' -> '/create-image-pixflux'."""
    return "/" + name.strip().lstrip("/")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="PixelLab client for the Asset Generation Agent.")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("balance", help="Show the account balance (free).")
    g = sub.add_parser("generate", help="Make ONE paid generation call and save PNG + record.")
    g.add_argument("--endpoint", required=True, type=normalize_endpoint, choices=sorted(ENDPOINTS),
                   help="e.g. create-image-pixflux (leading slash optional; Git Bash mangles a leading slash).")
    src = g.add_mutually_exclusive_group(required=True)
    src.add_argument("--params", help="Request body as a JSON string.")
    src.add_argument("--params-file", help="Path to a JSON file holding the request body.")
    g.add_argument("--out-dir", required=True, help="Folder for the PNG and its record.")
    g.add_argument("--name", required=True, help="Base file name, without extension.")
    g.add_argument("--consulted", action="append", default=[], help="A resource consulted. Repeatable.")
    g.add_argument("--task", help="Task id, e.g. T-003.")
    g.add_argument("--notes", default="", help="Free-text notes for the record.")
    g.add_argument("--log", default=str(DEFAULT_LOG), help="Generation log (JSONL).")
    args = parser.parse_args(argv)

    try:
        token = load_token()
        http = Http(token)
        if args.cmd == "balance":
            print(json.dumps(get_balance(http), indent=2))
            return 0
        params = json.loads(args.params) if args.params else json.loads(Path(args.params_file).read_text(encoding="utf-8"))
        if not isinstance(params, dict):
            raise PixelLabError("Request params must be a JSON object.")
        record = generate(
            http, endpoint=args.endpoint, params=params, out_dir=Path(args.out_dir), name=args.name,
            consulted=args.consulted, task=args.task, notes=args.notes, log_path=Path(args.log),
        )
        print(json.dumps({k: record[k] for k in ("file", "job_id", "usage", "image")}, indent=2))
        return 0
    except (PixelLabError, json.JSONDecodeError, OSError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
