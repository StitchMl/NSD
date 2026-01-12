# MACsec con MKA (LAN Site 2)

## Obiettivo
Proteggere il traffico interno alla LAN del Site 2 tramite MACsec (IEEE 802.1AE), garantendo confidenzialità e integrità dei frame Ethernet tra CE2, client-B1 e client-B2.
La protezione è applicata a Layer 2 ed è complementare alla VPN IPsec già attiva tra i siti.

## Ambito di applicazione
- Site 2 LAN: 192.168.20.0/24
- Nodi coinvolti:
  - CE2 — 192.168.20.1
  - client-B1 — 192.168.20.10
  - client-B2 — 192.168.20.11
- Interfaccia LAN (parent): eth0 su tutti i nodi
- Interfaccia protetta MACsec: macsec0 (creata su eth0)

Nota: la WAN pubblica di CE2 (1.0.102.2/30) non è coinvolta da MACsec.

## Scelte progettuali
- MACsec (802.1AE): cifratura a livello Ethernet per proteggere il traffico locale (sniffing/attacchi L2).
- MKA: distribuzione/gestione chiavi MACsec tra peer.
- wpa_supplicant + driver macsec_linux: adatto a container, senza NetworkManager/DBus.
- CAK/CKN condivisi (PSK): configurazione deterministica per laboratorio.
- GCM-AES-128: scelta standard.

MACsec è applicato su tutti gli host della LAN (non “solo sul gateway”).

## Implementazione

### 1) Configurazione MKA (uguale su tutti i nodi)
File macsec.conf:

eapol_version=3
ap_scan=0

network={
    key_mgmt=NONE
    eapol_flags=0
    macsec_policy=1
    mka_cak=00112233445566778899aabbccddeeff
    mka_ckn=000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
}

### 2) Avvio MKA su interfaccia LAN (CE2, client-B1, client-B2)
wpa_supplicant -i eth0 -B -Dmacsec_linux -c macsec.conf

L’avvio crea automaticamente macsec0 associata a eth0.

### 3) Migrazione indirizzi IP su macsec0
- CE2:
  - ip addr del 192.168.20.1/24 dev eth0
  - ip addr add 192.168.20.1/24 dev macsec0
  - ip link set macsec0 up

- client-B1:
  - ip addr del 192.168.20.10/24 dev eth0
  - ip addr add 192.168.20.10/24 dev macsec0
  - ip link set macsec0 up

- client-B2:
  - ip addr del 192.168.20.11/24 dev eth0
  - ip addr add 192.168.20.11/24 dev macsec0
  - ip link set macsec0 up

eth0 resta senza IP ed è usata solo come parent MACsec.

## Verifica
- Ping riusciti:
  - client-B1 ↔ CE2
  - client-B1 ↔ client-B2
  - CE2 ↔ client-B2

- Evidenza cifratura (contatori MACsec):
  - ip -s link show macsec0

I contatori RX/TX aumentano durante il traffico → MACsec operativo.

## Risultato
- LAN Site 2 protetta a Layer 2
- MACsec + MKA operativi su tutti i nodi
- Nessuna interferenza con BGP (WAN) né con IPsec site-to-site (CE1 ↔ CE2)