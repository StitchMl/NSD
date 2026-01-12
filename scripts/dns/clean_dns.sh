#!/bin/bash
set -e

echo "--- INIZIO PULIZIA CONFIGURAZIONE DNSSEC ---"

# 1. Arresto del servizio (gestione errore se gia' fermo)
service named stop || true

# 2. Rimozione file chiavi, firme e journal residui
rm -f /etc/bind/Knsdcourse.xyz*
rm -f /etc/bind/db.nsdcourse.xyz.signed
rm -f /etc/bind/dsset-nsdcourse.xyz*
rm -f /etc/bind/*.jnl

# 3. Ripristino configurazione zona (named.conf.local)
cat > /etc/bind/named.conf.local <<CONF
zone "nsdcourse.xyz" {
    type master;
    file "/etc/bind/db.nsdcourse.xyz";
};
CONF

# 4. Ripristino file di zona originale (Clean State)
cat > /etc/bind/db.nsdcourse.xyz <<ZONE
$TTL 3h
@   IN SOA  ns.nsdcourse.xyz. admin.nsdcourse.xyz. (
            1       ; Serial
            3h      ; Refresh
            1h      ; Retry
            1w      ; Expire
            1h )    ; Negative caching TTL

; Name Servers
@       IN NS   ns.nsdcourse.xyz.

; Record A
@       IN A    2.80.200.3
ns      IN A    2.80.200.3
www     IN A    2.80.200.3
ZONE

# 5. Correzione permessi
chown -R bind:bind /etc/bind

# 6. Riavvio del servizio
service named start

echo "--- PULIZIA COMPLETATA ---"
echo "Il server e' stato ripristinato allo stato iniziale (senza DNSSEC)."
