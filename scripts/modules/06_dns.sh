#!/usr/bin/env bash
set -euo pipefail

# =========================
# Phase D: DNSSEC + HTTP
# Configuration files + helper scripts
# =========================

# 1) Opzioni BIND
write_file "$OUT/dns/named.conf.options" <<'EOF'
options {
    directory "/var/cache/bind";
    recursion no;
    allow-query { any; };
    listen-on-v6 { any; };
    dnssec-validation auto;
};
EOF

# 2) Zona (punta al file firmato)
write_file "$OUT/dns/named.conf.local" <<'EOF'
zone "nsdcourse.xyz" {
    type master;
    file "/etc/bind/db.nsdcourse.xyz.signed";
};
EOF

# 3) File di zona NON firmato (base)
write_file "$OUT/dns/db.nsdcourse.xyz" <<'EOF'
$TTL 3h
@   IN  SOA ns.nsdcourse.xyz. admin.nsdcourse.xyz. (
        1       ; Serial
        3h      ; Refresh
        1h      ; Retry
        1w      ; Expire
        1h      ; Negative Cache TTL
)

@       IN  NS  ns.nsdcourse.xyz.
@       IN  A   2.80.200.3
ns      IN  A   2.80.200.3
www     IN  A   2.80.200.3
EOF

# 4) Promemoria comandi manuali
write_file "$OUT/dns/config.txt" <<'EOF'
# --- COMANDI DA LANCIARE MANUALMENTE NEL NODO DNS ---

# (opzionale) copia i file:
# cp named.conf.options /etc/bind/
# cp named.conf.local   /etc/bind/
# cp db.nsdcourse.xyz   /etc/bind/

cd /etc/bind

# Genera chiavi DNSSEC
dnssec-keygen -a ECDSAP384SHA384 -n ZONE nsdcourse.xyz
dnssec-keygen -f KSK -a ECDSAP384SHA384 -n ZONE nsdcourse.xyz

# Includi le chiavi nel file di zona
for key in Knsdcourse.xyz*.key; do
    echo "\$INCLUDE $key" >> db.nsdcourse.xyz
done

# Firma la zona
dnssec-signzone -A -3 $(head -c 1000 /dev/random | sha1sum | cut -b 1-16) \
  -N INCREMENT -o nsdcourse.xyz -t db.nsdcourse.xyz

# Permessi
chown -R bind:bind /etc/bind

# Avvio servizi
service apache2 start
service named restart
EOF

# 5) Script di pulizia/reset DNSSEC
write_file "$OUT/dns/clean_dns.sh" <<'EOF'
#!/bin/bash
set -e

echo "--- INIZIO PULIZIA DNSSEC ---"

service named stop || true

rm -f /etc/bind/Knsdcourse.xyz*
rm -f /etc/bind/db.nsdcourse.xyz.signed
rm -f /etc/bind/dsset-nsdcourse.xyz*
rm -f /etc/bind/*.jnl

cat > /etc/bind/named.conf.local <<CONF
zone "nsdcourse.xyz" {
    type master;
    file "/etc/bind/db.nsdcourse.xyz";
};
CONF

cat > /etc/bind/db.nsdcourse.xyz <<ZONE
$TTL 3h
@   IN SOA  ns.nsdcourse.xyz. admin.nsdcourse.xyz. (
            1       ; Serial
            3h      ; Refresh
            1h      ; Retry
            1w      ; Expire
            1h )    ; Negative caching TTL

@       IN NS   ns.nsdcourse.xyz.
@       IN A    2.80.200.3
ns      IN A    2.80.200.3
www     IN A    2.80.200.3
ZONE

chown -R bind:bind /etc/bind
service named start

echo "--- PULIZIA COMPLETATA ---"
EOF
