#!/usr/bin/env bash
set -euo pipefail

LAN_IF=eth0
MACSEC_IF=macsec0
IP_ADDR=192.168.20.1/24

CAK=00112233445566778899aabbccddeeff
CKN=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f

cat > macsec.conf <<EOF2
eapol_version=3
ap_scan=0
network={
  key_mgmt=NONE
  eapol_flags=0
  macsec_policy=1
  mka_cak=$CAK
  mka_ckn=$CKN
}
EOF2

wpa_supplicant -i $LAN_IF -B -Dmacsec_linux -c macsec.conf

# piccolo delay: macsec0 viene creata qualche istante dopo
sleep 2

ip addr del $IP_ADDR dev $LAN_IF 2>/dev/null || true
ip addr replace $IP_ADDR dev $MACSEC_IF
ip link set $MACSEC_IF up
