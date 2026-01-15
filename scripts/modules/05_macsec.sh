#!/usr/bin/env bash
set -euo pipefail

# Phase C: MACsec (MKA) - Site 2 LAN

write_file "$OUT/macsec/mka_ce2.sh" <<'EOF'
#!/bin/bash

# LAN interface
LAN_IF=eth0

# MACsec interface
MACSEC_IF=macsec0

# IP LAN
IP_ADDR=192.168.20.1/24

# MKA keys
CAK=00112233445566778899aabbccddeeff
CKN=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f

# MACsec config
cat > macsec.conf <<'EOF2'
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

# Start MKA
wpa_supplicant -i $LAN_IF -B -Dmacsec_linux -c macsec.conf
sleep 2
# Move IP to MACsec
ip addr del $IP_ADDR dev $LAN_IF
ip addr add $IP_ADDR dev $MACSEC_IF
ip link set $MACSEC_IF up

EOF

write_file "$OUT/macsec/mka_b1.sh" <<'EOF'
#!/bin/bash

LAN_IF=eth0
MACSEC_IF=macsec0
IP_ADDR=192.168.20.10/24
GW=192.168.20.1

CAK=00112233445566778899aabbccddeeff
CKN=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f

cat > macsec.conf <<'EOF2'
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
sleep 2
ip addr del $IP_ADDR dev $LAN_IF
ip addr add $IP_ADDR dev $MACSEC_IF
ip link set $MACSEC_IF up

ip route add default via $GW dev $MACSEC_IF
EOF

write_file "$OUT/macsec/mka_b2.sh" <<'EOF'
#!/bin/bash

LAN_IF=eth0
MACSEC_IF=macsec0
IP_ADDR=192.168.20.11/24
GW=192.168.20.1

CAK=00112233445566778899aabbccddeeff
CKN=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f

cat > macsec.conf <<'EOF2'
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
sleep 2
ip addr del $IP_ADDR dev $LAN_IF
ip addr add $IP_ADDR dev $MACSEC_IF
ip link set $MACSEC_IF up

ip route add default via $GW dev $MACSEC_IF
EOF
