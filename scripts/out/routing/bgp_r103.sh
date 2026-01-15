##!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router bgp 100
 bgp router-id 1.255.0.3
 no bgp ebgp-requires-policy
 ! iBGP
 neighbor 1.255.0.1 remote-as 100
 neighbor 1.255.0.1 update-source lo
 neighbor 1.255.0.2 remote-as 100
 neighbor 1.255.0.2 update-source lo
 ! eBGP verso AS200
 neighbor 10.0.31.2 remote-as 200
 !
 address-family ipv4 unicast
  neighbor 1.255.0.1 activate
  neighbor 1.255.0.2 activate
  neighbor 10.0.31.2 activate
  neighbor 1.255.0.1 next-hop-self
  neighbor 1.255.0.2 next-hop-self
 exit-address-family
end
write memory
VEOF

