# NSD Project – Deliverable

## 1. Sintesi
Questo repository contiene il progetto NSD realizzato in GNS3:
- routing (OSPF + iBGP + eBGP),
- DMZ con DNS authoritative DNSSEC e web server,
- firewalling perimetrale e interno,
- VPN IPsec (enterprise e customer),
- MACsec con MKA in Site2,
- sandbox antivirus con 3 runner e nodo centrale.

## 2. Topologia e naming
Il naming dei nodi è congelato come segue:
- AS100: R101, R102, R103
- AS200: R201, R202, GW200
- Firewalls: eFW, iFW
- Customer: CE1 (Site1), CE2 (Site2), client-A1, client-B1, client-B2
- DMZ/Services: dns-server (DNS+HTTP), central-node
- AV runners: AV1, AV2, AV3
- LAN user: LAN-client

## 3. Documentazione
- Scope & assunzioni: `docs/00-scope-and-assumptions.md`
- Addressing plan: `docs/01-addressing-plan.md`
- Routing: `docs/02-routing.md`
- Firewall policy: `docs/03-firewall-policy.md`
- DNS/DNSSEC/Web: `docs/04-dns-dnssec-web.md`
- VPN IPsec: `docs/05-vpn-ipsec.md`
- MACsec MKA: `docs/06-macsec-mka.md`
- AV Sandbox: `docs/07-av-sandbox.md`
- Test plan: `docs/08-test-plan.md`
- Submission checklist: `docs/09-submission-checklist.md`

## 4. Dove sono le configurazioni
- Configurazioni e dump: `configs/`
- Evidenze (output comandi, log): `evidence/`

## 5. Sviluppo (igiene repository)

### Line endings (Windows/macOS/Linux)
Il repository normalizza i file di testo a **LF** tramite `.gitattributes` per compatibilità con ambienti Linux/Docker.

Su Windows è consigliato (nel clone locale):
```bash
git config --local core.autocrlf false
git config --local core.eol lf
```