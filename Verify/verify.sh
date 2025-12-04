#!/usr/bin/env bash
set -euo pipefail

KEYSERVER="hkps://keyserver.ubuntu.com"

if ! command -v gpg &>/dev/null; then
  echo "Error: gpg not found. Install GnuPG and try again." >&2
  exit 1
fi

usage() {
  cat <<EOF
Usage: $0 <file> <signature.asc>
Automatically fetches missing public keys.
EOF
  exit 1
}

[ $# -eq 2 ] || usage

file="$1"
sig="$2"

for path in "$file" "$sig"; do
  [ -f "$path" ] || { echo "Error: $path not found." >&2; exit 1; }
done

echo "Verifying signature of '$file' with '$sig'..."
gpg --batch --yes \
    --keyserver "$KEYSERVER" \
    --auto-key-retrieve \
    --verify "$sig" "$file" 2>&1 | tee /tmp/gpg-verify.log

# Check result
if grep -q "Good signature" /tmp/gpg-verify.log; then
  echo "✅ Signature is valid."
  exit 0
else
  echo "❌ Signature verification failed." >&2
  exit 2
fi
