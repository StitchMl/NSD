#!/usr/bin/env bash
set -euo pipefail

# Step 3: OSPF inside AS100 + BGP

write_file "$OUT/routing/ospf_r101.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router ospf
 ospf router-id 1.255.0.1
 passive-interface default
 no passive-interface eth1
 no passive-interface eth2
exit
interface eth1
 ip ospf area 0
 ip ospf network point-to-point
exit
interface eth2
 ip ospf area 0
 ip ospf network point-to-point
exit
interface lo
 ip ospf area 0
exit
end
write memory
VEOF
EOF

write_file "$OUT/routing/ospf_r102.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router ospf
 ospf router-id 1.255.0.2
 passive-interface default
 no passive-interface eth0
 no passive-interface eth2
exit
interface eth0
 ip ospf area 0
 ip ospf network point-to-point
exit
interface eth2
 ip ospf area 0
 ip ospf network point-to-point
exit
interface lo
 ip ospf area 0
exit
end
write memory
VEOF
EOF

write_file "$OUT/routing/ospf_r103.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router ospf
 ospf router-id 1.255.0.3
 passive-interface default
 no passive-interface eth0
 no passive-interface eth1
exit
interface eth0
 ip ospf area 0
 ip ospf network point-to-point
exit
interface eth1
 ip ospf area 0
 ip ospf network point-to-point
exit
interface lo
 ip ospf area 0
exit
end
write memory
VEOF
EOF

write_file "$OUT/routing/bgp_r101.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
router bgp 100
 bgp router-id 1.255.0.1
 no bgp ebgp-requires-policy
 neighbor 1.255.0.2 remote-as 100
 neighbor 1.255.0.2 update-source lo
 neighbor 1.255.0.3 remote-as 100
 neighbor 1.255.0.3 update-source lo
 !
 address-family ipv4 unicast
  neighbor 1.255.0.2 activate
  neighbor 1.255.0.3 activate
  network 1.0.101.0/30
 exit-address-family
end
write memory
VEOF
EOF

write_file "$OUT/routing/bgp_r102.sh" <<'EOF'
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
EOF

write_file "$OUT/routing/bgp_r103.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
!
! 1. CREIAMO LA ROTTA "FANTASMA" PER L'AGGREGATO
! BGP annuncia solo ciò che vede nella tabella di routing.
! Creiamo una rotta statica verso Null0 per l'intera rete AS100.
ip route 1.0.0.0/8 Null0
!
router bgp 100
 bgp router-id 1.255.0.3
 no bgp ebgp-requires-policy
 ! iBGP Interne
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
  !
  ! Fondamentale per iBGP: R101 e R102 devono sapere che per uscire si passa da qui
  neighbor 1.255.0.1 next-hop-self
  neighbor 1.255.0.2 next-hop-self
  !
  ! 2. ANNUNCIO UFFICIALE VERSO AS200
  ! Diciamo a R201: "Tutta la rete 1.x.x.x è roba mia"
  network 1.0.0.0/8
 exit-address-family
end
write memory
VEOF
EOF

write_file "$OUT/routing/bgp_r201.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
vtysh <<'VEOF'
conf t
!
! 1. AGGIORNAMENTO ROTTA STATICA (Fondamentale!)
! Rimuoviamo la vecchia che puntava all'IP privato
no ip route 2.80.200.0/24 10.0.200.2
! Aggiungiamo la nuova che punta al NUOVO IP PUBBLICO di GW200
ip route 2.80.200.0/24 2.0.200.2
!
router bgp 200
 bgp router-id 2.255.0.1
 no bgp ebgp-requires-policy
 neighbor 10.0.31.1 remote-as 100
 !
 address-family ipv4 unicast
  neighbor 10.0.31.1 activate
  
  ! Loopback (Ok)
  network 2.255.0.1/32
  
  ! DMZ Enterprise (Ok)
  network 2.80.200.0/24
  
  ! 2. NUOVI ANNUNCI (Fondamentali!)
  ! Dobbiamo dire ad AS100 che queste subnet pubbliche sono qui.
  ! Link verso GW200
  network 2.0.200.0/30
  ! Link verso R202
  network 2.0.202.0/30
  
 exit-address-family
end
write memory
VEOF
EOF
