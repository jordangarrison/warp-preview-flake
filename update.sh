#!/usr/bin/env bash
set -euo pipefail

URL="https://app.warp.dev/get_warp?package=deb&channel=preview"
echo "Prefetching RAW .deb: $URL"

RAW=$(nix store prefetch-file --name warp-preview.deb "$URL")
HASH=$(echo "$RAW" | awk '/^sha256:|^SHA256:/ {print $2}')
SRI="sha256-${HASH}"

echo "New SRI hash: ${SRI}"
sed -i "s#debSha = \"sha256-[^\"]\\+\";#debSha = \"${SRI}\";#" flake.nix

echo "Validating build…"
nix build .#default >/dev/null
echo "OK. Run with: nix run ."