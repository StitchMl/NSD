#!/usr/bin/env bash
set -euo pipefail
sysctl -w net.ipv4.ip_forward=1

# --- Verso DMZ (br1) ---
ip addr flush dev eth0 || true
ip addr add 2.80.200.2/24 dev eth0
ip link set eth0 up

# --- Verso LAN1 (br2) ---
ip addr flush dev eth1 || true
ip addr add 10.200.1.1/24 dev eth1
ip link set eth1 up

# --- Routing ---
# 1. Default Gateway: tutto ciò che non conosco va verso GW200
ip route replace default via 2.80.200.1 dev eth0

# 2. Verso LAN2 (LAN-client)
# LAN2 è dietro iFW. Dobbiamo sapere l'IP di iFW nella LAN1.
# Supponendo che iFW sia collegato a br2 e abbia IP 10.200.1.2:
ip route replace 10.200.2.0/24 via 10.200.1.2 dev eth1

echo "nameserver 2.80.200.3" > /etc/resolv.conf

