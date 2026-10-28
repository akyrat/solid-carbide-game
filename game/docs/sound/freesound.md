# Downloading sounds from Freesound

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Downloading sounds from Freesound

`game/tools/freesound.py` (used by the SFX Agent) searches Freesound and downloads the **original** sound files, not previews, with a metadata JSON next to each one. It reads `FREESOUND_CLIENT_ID` and `FREESOUND_API_KEY` from `.env` (see [Secrets and API keys](../../../README.md#secrets-and-api-keys)) and needs Python 3.9+ (standard library only). Run it from the repo root.

**One-time login.** Downloading originals needs the board's Freesound login (OAuth2):

```
python game/tools/freesound.py auth-url          # prints the login link for the board
python game/tools/freesound.py login <code>      # exchange the code Freesound shows after approving
```

The code expires within minutes, so run `login` as soon as it arrives. The tokens are stored in `.secrets/freesound_token.json` (git-ignored). The access token is renewed automatically with the refresh token, so later runs do not need the board. `python game/tools/freesound.py status` checks the stored login without downloading anything.

**Download:**

```
python game/tools/freesound.py download --query "car engine idle" --count 3 --out game/audio/sfx/<folder>
```

- Only Godot-importable formats (wav, ogg, mp3) are picked, and originals over 5 MB are skipped (`--max-bytes`, 0 = no limit). The downloader accepts only CC0 and CC BY sounds: the search is filtered, and each result is checked again before saving, so a disallowed sound is skipped (one line is printed) and never written. The rule is in [`docs/unfiled-game-details.md`](../../../docs/unfiled-game-details.md) ("Sound licenses"); the allowed list is `ALLOWED_LICENSES` in the script.
- `--count` is how many sounds the folder should hold in total. Sounds already there (found by the Freesound id in their JSON) count towards it and are never downloaded twice, so re-running the same command downloads nothing, though it still checks (and if needed renews) the login.
- Each sound is saved as `<id>_<name>.<ext>` with `<id>_<name>.json` next to it. The JSON holds `freesound_id`, `name`, `username`, `freesound_url`, `license_name`, `license_url`, `search_query`, `download_date`, plus `file`, `original_type`, `duration_s` and `filesize_bytes`.
- Exit codes: 0 = done; 1 = request failed or fewer sounds found than asked; 2 = credentials missing from `.env`; 3 = login needed (run `auth-url` and `login` again).

**Checking licences.** `python game/tools/check_sfx_licenses.py [folder] [--credits]` (default `game/audio`) checks every sound has a metadata JSON with all required fields and a CC0 or CC BY licence; it exits 1 on any problem. `--credits` also prints the credit line each CC BY sound needs.

**MVP sound candidates (T-076).** Folders under `game/audio/sfx/`: `engine`, `drift`, `gun`, `flames`, `hit`, `coin`, `meteor-warning`, `meteor-impact`, each with two or three candidates. The recommended file per sound is in the result notes of `tasks/T-076-mvp-sound-effects.md`. `_test-run/` holds the earlier T-002 test downloads.

