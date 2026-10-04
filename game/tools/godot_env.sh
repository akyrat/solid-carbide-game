#!/usr/bin/env bash
# Sourced by the other tools/*.sh scripts. Sets GODOT_BIN, REPO_ROOT and GAME_DIR.
# GODOT_BIN comes from the environment if already set, otherwise from .env at the repo root.

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAME_DIR="$(cd "$TOOLS_DIR/.." && pwd)"
REPO_ROOT="$(cd "$GAME_DIR/.." && pwd)"

if [ -z "${GODOT_BIN:-}" ] && [ -f "$REPO_ROOT/.env" ]; then
  # Read only the GODOT_BIN line; strip CR, surrounding quotes and spaces.
  GODOT_BIN="$(grep -E '^[[:space:]]*GODOT_BIN[[:space:]]*=' "$REPO_ROOT/.env" | tail -n 1 \
    | sed -E 's/^[^=]*=[[:space:]]*//; s/\r$//; s/[[:space:]]+$//; s/^"(.*)"$/\1/; s/^'"'"'(.*)'"'"'$/\1/')"
fi

if [ -z "${GODOT_BIN:-}" ]; then
  echo "GODOT_BIN is not set. Add it to .env at the repo root (see README.md, 'Secrets and API keys')." >&2
  exit 2
fi
if [ ! -f "$GODOT_BIN" ]; then
  echo "GODOT_BIN points to a file that does not exist: $GODOT_BIN" >&2
  exit 2
fi
export GODOT_BIN REPO_ROOT GAME_DIR
