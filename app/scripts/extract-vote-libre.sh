#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ZIP_FILE="$ROOT_DIR/vote-libre-main 2.zip"

if [[ ! -f "$ZIP_FILE" ]]; then
  echo "Archive introuvable: $ZIP_FILE"
  exit 1
fi

cd "$ROOT_DIR"
unzip -o "$ZIP_FILE" -d "$ROOT_DIR"

echo "Extraction terminee dans: $ROOT_DIR"
