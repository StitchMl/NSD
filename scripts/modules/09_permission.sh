#!/usr/bin/env bash
set -euo pipefail

# Rende eseguibili tutti gli script generati (solo .sh)
# NB: i file di config DNS (named.conf.*, db zone, config.txt) NON devono essere executable.

chmod +x "$OUT"/setup/*.sh || true
chmod +x "$OUT"/routing/*.sh || true
chmod +x "$OUT"/ipsec/*.sh || true
chmod +x "$OUT"/macsec/*.sh || true
chmod +x "$OUT"/firewall/*.sh || true
chmod +x "$OUT"/av/*.sh || true

# DNS: solo gli script, non i file config / txt
chmod +x "$OUT"/dns/*.sh || true
