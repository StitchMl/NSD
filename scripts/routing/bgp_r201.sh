#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
! (opzionale) rotta verso DMZ per poterla annunciare via BGP
ip route 2.80.200.0/24 10.0.200.2
!
router bgp 200
 bgp router-id 2.255.0.1
 no bgp ebgp-requires-policy
 neighbor 10.0.31.1 remote-as 100
 !
 address-family ipv4 unicast
  neighbor 10.0.31.1 activate
  network 2.255.0.1/32
  network 2.80.200.0/24
 exit-address-family
end
write memory
VEOF

