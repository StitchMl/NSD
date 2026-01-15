#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router bgp 100
 bgp router-id 1.255.0.2
 no bgp ebgp-requires-policy
 neighbor 1.255.0.1 remote-as 100
 neighbor 1.255.0.1 update-source lo
 neighbor 1.255.0.3 remote-as 100
 neighbor 1.255.0.3 update-source lo
 !
 address-family ipv4 unicast
  neighbor 1.255.0.1 activate
  neighbor 1.255.0.3 activate
  network 1.0.102.0/30
 exit-address-family
end
write memory
VEOF
