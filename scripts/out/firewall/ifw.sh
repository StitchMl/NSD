#!/bin/bash
echo "--- Configurazione Firewall iFW ---"

# 1. Abilita il forwarding
sysctl -w net.ipv4.ip_forward=1

# 2. Pulizia regole
iptables -F
iptables -X
iptables -t nat -F

# 3. Policy di Default: DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# ================================
# CHAIN INPUT (Traffico diretto a iFW)
# ================================
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT

# ================================
# CHAIN FORWARD (Traffico che attraversa iFW)
# ================================
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# REGOLA 1: LAN-Client (LAN2) verso OVUNQUE
iptables -A FORWARD -s 10.200.2.0/24 -j ACCEPT

# REGOLA 2: Antivirus (LAN1) verso Central Node (VPN)
iptables -A FORWARD -s 10.200.1.0/24 -d 10.202.3.0/24 -j ACCEPT

echo "Firewall iFW configurato."
iptables -L -v -n
