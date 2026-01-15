#!/usr/bin/env bash
set -euo pipefail

# Scrive un file creando automaticamente la directory
# Uso:
#   write_file "$OUT/setup/r101.sh" <<'EOF'
#   ...
#   EOF
write_file() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  cat > "$path"
}
