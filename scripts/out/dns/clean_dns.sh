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
