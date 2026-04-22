#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_NAME="app-release.zip"

cd "$ROOT_DIR"
rm -f "$OUTPUT_NAME"
zip -r "$OUTPUT_NAME" . -x "*.git*" "node_modules/*" "app-release.zip"
echo "Archive creee: $ROOT_DIR/$OUTPUT_NAME"
