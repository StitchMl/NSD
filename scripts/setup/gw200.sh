#!/usr/bin/env bash
set -euo pipefail
sysctl -w net.ipv4.ip_forward=1

# --- Verso Internet (R201) ---
ip addr flush dev eth0 || true
ip addr add 10.0.200.2/30 dev eth0
ip link set eth0 up
# Rotta di default verso internet
ip route replace default via 10.0.200.1 dev eth0

# --- Verso DMZ (br1) ---
# GW200 è il gateway della DMZ. 
# [cite_start]Usiamo il pool AS200 come da traccia[cite: 177].
ip addr flush dev eth1 || true
ip addr add 2.80.200.1/24 dev eth1
ip link set eth1 up

# --- Rotte verso l'interno (Enterprise) ---
# Per raggiungere LAN1 (10.200.1.0) e LAN2 (10.200.2.0)
# devo passare per eFW che ha IP .2 nella DMZ
ip route replace 10.200.1.0/24 via 2.80.200.2 dev eth1
ip route replace 10.200.2.0/24 via 2.80.200.2 dev eth1
