#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$ROOT/out"

# Pulizia output precedente
rm -rf "$OUT"
mkdir -p "$OUT"

# Carica libreria IO
source "$ROOT/lib/io.sh"

# Carica i moduli in ordine alfabetico
for m in "$ROOT"/modules/*.sh; do
  source "$m"
done

echo "OK: script generati in $OUT"
