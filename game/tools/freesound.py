#!/usr/bin/env python3
"""Freesound downloader for the SFX Agent.

Searches Freesound and downloads ORIGINAL sound files (not previews), writing a
metadata JSON next to each sound (source, author, license, query, date).

Credentials come from .env at the repo root (FREESOUND_CLIENT_ID,
FREESOUND_API_KEY). OAuth2 tokens are stored in .secrets/freesound_token.json
(git-ignored) and renewed automatically with the refresh token, so the board
only logs in once.

Usage, from the repo root (Python 3.9+, standard library only):

  python game/tools/freesound.py auth-url
      Print the one-time login link for the board.
  python game/tools/freesound.py login <code>
      Exchange the code the board pastes back for tokens (stored in .secrets/).
  python game/tools/freesound.py status
      Say whether a usable login is stored (renews it if expired). Prints no secrets.
  python game/tools/freesound.py download --query "car engine idle" --count 3 --out game/audio/sfx/x
      Search and download the original files plus metadata JSON.

Exit codes: 0 ok; 1 bad usage or request error; 2 missing credentials;
3 login needed (no stored tokens, or the refresh token was rejected).

Never prints or writes the credential values anywhere except the token file.
"""

import argparse
import datetime as _dt
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

API_ROOT = "https://freesound.org/apiv2"
AUTHORIZE_URL = API_ROOT + "/oauth2/authorize/"
TOKEN_URL = API_ROOT + "/oauth2/access_token/"
SEARCH_URL = API_ROOT + "/search/text/"

# Godot 4 imports these audio formats. Other originals (flac, aiff, m4a) would not import.
GODOT_AUDIO_TYPES = ("wav", "ogg", "mp3")
# Renew the access token this many seconds before it actually expires.
EXPIRY_MARGIN_S = 60
METADATA_SCHEMA = "solid-carbide/sfx-metadata/1"
REQUIRED_METADATA_FIELDS = (
    "freesound_id", "name", "username", "freesound_url",
    "license_name", "license_url", "search_query", "download_date",
)

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(os.path.dirname(TOOLS_DIR))
ENV_PATH = os.path.join(REPO_ROOT, ".env")
TOKEN_PATH = os.path.join(REPO_ROOT, ".secrets", "freesound_token.json")


class LoginNeeded(Exception):
    """No usable tokens: the board must log in again."""


class ApiError(Exception):
    pass


# ---------------------------------------------------------------- pure helpers

def parse_env(text):
    """Parse KEY=VALUE lines. Ignores comments, blank lines, quotes and trailing comments."""
    env = {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if key.startswith("export "):
            key = key[len("export "):].strip()
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        else:
            value = re.sub(r"\s+#.*$", "", value).strip()
        env[key] = value
    return env


def load_credentials(env_path=ENV_PATH):
    env = {}
    if os.path.isfile(env_path):
        with open(env_path, encoding="utf-8") as f:
            env = parse_env(f.read())
    client_id = os.environ.get("FREESOUND_CLIENT_ID") or env.get("FREESOUND_CLIENT_ID", "")
    secret = os.environ.get("FREESOUND_API_KEY") or env.get("FREESOUND_API_KEY", "")
    if not client_id or not secret:
        raise SystemExit_(2, "FREESOUND_CLIENT_ID and FREESOUND_API_KEY must be set in .env "
                             "(see README.md, 'Secrets and API keys').")
    return client_id, secret


def build_authorize_url(client_id):
    """Login link with no redirect URI, so Freesound shows the code on its own page."""
    return AUTHORIZE_URL + "?" + urllib.parse.urlencode(
        {"client_id": client_id, "response_type": "code"})


def token_record_from_response(resp, now):
    """Turn a token endpoint response into what we store. Keeps the old refresh token if none is returned."""
    if "access_token" not in resp:
        raise ApiError("token response has no access_token")
    expires_in = int(resp.get("expires_in", 0) or 0)
    return {
        "access_token": resp["access_token"],
        "refresh_token": resp.get("refresh_token", ""),
        "scope": resp.get("scope", ""),
        "obtained_at": int(now),
        "expires_at": int(now) + expires_in,
    }


def token_is_expired(record, now, margin=EXPIRY_MARGIN_S):
    return now >= int(record.get("expires_at", 0)) - margin


_LICENSE_NAMES = [
    (r"publicdomain/zero/", "CC0 1.0"),
    (r"licenses/by-nc/(\d\.\d)", "CC BY-NC {}"),
    (r"licenses/by/(\d\.\d)", "CC BY {}"),
    (r"licenses/sampling\+/(\d\.\d)", "CC Sampling+ {}"),
]


def license_name_from_url(url):
    """Freesound gives the license as a Creative Commons URL. Map it to a readable name."""
    for pattern, name in _LICENSE_NAMES:
        m = re.search(pattern, url or "")
        if m:
            return name.format(*m.groups())
    return url or ""


def normalize_license_url(url):
    url = (url or "").strip()
    if url.startswith("http://"):
        url = "https://" + url[len("http://"):]
    return url


def license_from_api(value):
    """Return (name, url). Freesound returns either a CC URL or a plain name."""
    value = (value or "").strip()
    if value.startswith("http"):
        url = normalize_license_url(value)
        return license_name_from_url(url), url
    known = {
        "creative commons 0": ("CC0 1.0", "https://creativecommons.org/publicdomain/zero/1.0/"),
        "attribution": ("CC BY 4.0", "https://creativecommons.org/licenses/by/4.0/"),
        "attribution noncommercial": ("CC BY-NC 4.0", "https://creativecommons.org/licenses/by-nc/4.0/"),
    }
    return known.get(value.lower(), (value, ""))


def slugify(text, max_len=40):
    slug = re.sub(r"[^a-z0-9]+", "-", (text or "").lower()).strip("-")
    slug = slug[:max_len].strip("-")
    return slug or "sound"


def file_base_name(sound):
    """<id>_<slug of name without extension>. Same base for the sound and its JSON."""
    name = os.path.splitext(sound.get("name", ""))[0]
    return "{}_{}".format(sound["id"], slugify(name))


def id_from_page_url(url):
    m = re.search(r"/sounds/(\d+)/?$", url or "")
    return int(m.group(1)) if m else None


def build_metadata(sound, query, today, file_name):
    license_name, license_url = license_from_api(sound.get("license", ""))
    return {
        "schema": METADATA_SCHEMA,
        "source": "freesound",
        "freesound_id": int(sound["id"]),
        "name": sound.get("name", ""),
        "username": sound.get("username", ""),
        "freesound_url": sound.get("url", ""),
        "license_name": license_name,
        "license_url": license_url,
        "search_query": query,
        "download_date": today,
        "file": file_name,
        "original_type": sound.get("type", ""),
        "duration_s": sound.get("duration"),
        "filesize_bytes": sound.get("filesize"),
    }


def validate_metadata(meta):
    """Return a list of problems (empty if fine)."""
    problems = []
    for key in REQUIRED_METADATA_FIELDS:
        if meta.get(key) in (None, ""):
            problems.append("missing or empty: " + key)
    url_id = id_from_page_url(meta.get("freesound_url", ""))
    if url_id is not None and meta.get("freesound_id") != url_id:
        problems.append("freesound_id does not match freesound_url")
    elif url_id is None and meta.get("freesound_url"):
        problems.append("freesound_url is not a sound page URL")
    return problems


def write_metadata(path, meta):
    problems = validate_metadata(meta)
    if problems:
        raise ValueError("invalid metadata: " + "; ".join(problems))
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)
        f.write("\n")
    os.replace(tmp, path)


def existing_ids(out_dir):
    """Freesound ids already downloaded into out_dir (from metadata JSON files)."""
    ids = set()
    if not os.path.isdir(out_dir):
        return ids
    for fname in os.listdir(out_dir):
        if fname.endswith(".json"):
            try:
                with open(os.path.join(out_dir, fname), encoding="utf-8") as f:
                    ids.add(int(json.load(f)["freesound_id"]))
            except (ValueError, KeyError, OSError, TypeError):
                pass
    return ids


def pick_sounds(results, count, skip_ids=()):
    """First `count` results in a Godot-importable format, skipping ids already present."""
    picked = []
    for s in results:
        if len(picked) >= count:
            break
        if s.get("id") in skip_ids:
            continue
        if str(s.get("type", "")).lower() not in GODOT_AUDIO_TYPES:
            continue
        picked.append(s)
    return picked


def search_filter(max_filesize):
    parts = ["type:(" + " OR ".join(GODOT_AUDIO_TYPES) + ")"]
    if max_filesize:
        parts.append("filesize:[* TO {}]".format(int(max_filesize)))
    return " ".join(parts)


class SystemExit_(Exception):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = code


# ---------------------------------------------------------------- HTTP

def _http(method, url, data=None, headers=None, timeout=60):
    body = urllib.parse.urlencode(data).encode() if data is not None else None
    req = urllib.request.Request(url, data=body, method=method, headers=headers or {})
    try:
        return urllib.request.urlopen(req, timeout=timeout)
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace")[:300]
        # Strip the query string so no token ever lands in an error message.
        raise ApiError("{} {} -> HTTP {}: {}".format(method, url.split("?")[0], e.code, detail))


def http_json(method, url, data=None, headers=None):
    with _http(method, url, data, headers) as r:
        return json.loads(r.read().decode("utf-8"))


# ---------------------------------------------------------------- tokens

def load_token(path=TOKEN_PATH):
    if not os.path.isfile(path):
        return None
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def save_token(record, path=TOKEN_PATH):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(record, f, indent=2)
    os.replace(tmp, path)


def exchange_code(code, client_id, secret, post=http_json, now=None):
    resp = post("POST", TOKEN_URL, {
        "client_id": client_id, "client_secret": secret,
        "grant_type": "authorization_code", "code": code.strip()})
    return token_record_from_response(resp, now if now is not None else time.time())


def refresh(record, client_id, secret, post=http_json, now=None):
    if not record.get("refresh_token"):
        raise LoginNeeded("no refresh token stored")
    try:
        resp = post("POST", TOKEN_URL, {
            "client_id": client_id, "client_secret": secret,
            "grant_type": "refresh_token", "refresh_token": record["refresh_token"]})
    except ApiError as e:
        raise LoginNeeded("refresh token rejected ({})".format(e))
    new = token_record_from_response(resp, now if now is not None else time.time())
    if not new["refresh_token"]:
        new["refresh_token"] = record["refresh_token"]
    return new


def get_access_token(client_id, secret, path=TOKEN_PATH, post=http_json, now=None):
    """Return a valid access token, renewing and saving it if expired. Raises LoginNeeded."""
    now = now if now is not None else time.time()
    record = load_token(path)
    if not record:
        raise LoginNeeded("no Freesound login stored yet")
    if token_is_expired(record, now):
        record = refresh(record, client_id, secret, post=post, now=now)
        save_token(record, path)
    return record["access_token"]


# ---------------------------------------------------------------- commands

def search(query, token, page_size=30, max_filesize=None):
    params = {
        "query": query,
        "filter": search_filter(max_filesize),
        "fields": "id,name,username,license,type,url,filesize,duration",
        "page_size": page_size,
        "sort": "score",
    }
    return http_json("GET", SEARCH_URL + "?" + urllib.parse.urlencode(params),
                     headers={"Authorization": "Bearer " + token}).get("results", [])


def download_original(sound_id, token, dest):
    url = "{}/sounds/{}/download/".format(API_ROOT, sound_id)
    tmp = dest + ".part"
    with _http("GET", url, headers={"Authorization": "Bearer " + token}, timeout=300) as r, \
            open(tmp, "wb") as f:
        while True:
            chunk = r.read(1 << 16)
            if not chunk:
                break
            f.write(chunk)
    os.replace(tmp, dest)


def cmd_download(args, client_id, secret):
    token = get_access_token(client_id, secret)
    out_dir = os.path.abspath(args.out)
    os.makedirs(out_dir, exist_ok=True)
    have = existing_ids(out_dir)
    needed = max(0, args.count - len(have))
    if needed == 0:
        print("{} already holds {} Freesound sounds; nothing to download".format(args.out, len(have)))
        return 0
    results = search(args.query, token, max_filesize=args.max_bytes)
    picked = pick_sounds(results, needed, skip_ids=have)
    if len(picked) < needed:
        print("Only found {} new importable sounds for '{}'".format(len(picked), args.query))
    today = _dt.date.today().isoformat()
    for s in picked:
        base = file_base_name(s)
        ext = str(s["type"]).lower()
        sound_file = base + "." + ext
        download_original(s["id"], token, os.path.join(out_dir, sound_file))
        meta = build_metadata(s, args.query, today, sound_file)
        write_metadata(os.path.join(out_dir, base + ".json"), meta)
        print("downloaded {}  [{}]  by {}".format(sound_file, meta["license_name"], meta["username"]))
    return 0 if len(picked) == needed else 1


def main(argv=None):
    try:
        sys.stdout.reconfigure(errors="replace")
    except AttributeError:
        pass
    p = argparse.ArgumentParser(description="Freesound downloader (SFX Agent)")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("auth-url", help="print the one-time login link")
    lg = sub.add_parser("login", help="exchange the code from the login page for tokens")
    lg.add_argument("code")
    sub.add_parser("status", help="check the stored login (renews it if needed)")
    dl = sub.add_parser("download", help="search and download original files with metadata")
    dl.add_argument("--query", required=True)
    dl.add_argument("--count", type=int, default=1,
                    help="how many sounds the folder should hold in total (already downloaded ones count)")
    dl.add_argument("--out", required=True, help="output folder, e.g. game/audio/sfx/...")
    dl.add_argument("--max-bytes", type=int, default=5_000_000,
                    help="skip originals larger than this (default 5 MB; 0 = no limit)")
    args = p.parse_args(argv)

    try:
        client_id, secret = load_credentials()
        if args.cmd == "auth-url":
            print(build_authorize_url(client_id))
            return 0
        if args.cmd == "login":
            save_token(exchange_code(args.code, client_id, secret))
            print("Login stored in .secrets/freesound_token.json")
            return 0
        if args.cmd == "status":
            get_access_token(client_id, secret)
            print("Freesound login OK")
            return 0
        if args.cmd == "download":
            return cmd_download(args, client_id, secret)
    except SystemExit_ as e:
        print(str(e), file=sys.stderr)
        return e.code
    except LoginNeeded as e:
        print("LOGIN NEEDED: {}. Run 'auth-url', have the board open the link, "
              "then run 'login <code>'.".format(e), file=sys.stderr)
        return 3
    except ApiError as e:
        print("Freesound request failed: {}".format(e), file=sys.stderr)
        return 1
    return 1


if __name__ == "__main__":
    sys.exit(main())
