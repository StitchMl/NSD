#!/usr/bin/env bash
set -euo pipefail

# =========================
# AV services + test script
# =========================

write_file "$OUT/av/av1.sh" <<'EOF'
#!/bin/bash
# service_av.sh - ClamAV Listener Daemon
CENTRAL_NODE_IP="10.202.3.10" # Sostituisci con IP vero del Central Node
sleep 20
echo "[AV1] setup"
# 1. Collega al Proxy
export http_proxy=http://10.202.3.10:8888
export https_proxy=http://10.202.3.10:8888

# 2. Installa
apt-get update
apt-get install -y clamav netcat

# 3. Pulisci (Hardening locale)
unset http_proxy
unset https_proxy
echo "[AV1] setup completed"

echo "[AV1] ClamAV Service avviato in ascolto sulla porta 9000..."

while true; do
    rm -f binary report.txt
    nc -l -p 9000 > binary
    echo "[AV1] File ricevuto. Avvio scansione..."

    echo "--- REPORT AV1 (ClamAV) ---" > report.txt
    date >> report.txt
    clamscan binary >> report.txt

    echo "[AV1] Invio report..."
    nc -w 2 $CENTRAL_NODE_IP 9001 < report.txt

    rm -f binary report.txt

    echo "[AV1] Ciclo completato. In attesa del prossimo file."
    echo "----------------------------------------------------"
done
EOF

write_file "$OUT/av/av2.sh" <<'EOF'
#!/bin/bash
# service_av.sh - YARA Listener Daemon
CENTRAL_NODE_IP="10.202.3.10"

sleep 20

echo "[AV2] setup"
# 1. Collega al Proxy
export http_proxy=http://10.202.3.10:8888
export https_proxy=http://10.202.3.10:8888

# 2. Installa
apt-get update
apt-get install -y yara netcat

# 3. Pulisci
unset http_proxy
unset https_proxy

echo "[AV2] setup completed"

echo "[AV2] YARA Service avviato in ascolto sulla porta 9000..."

# Assicurati che la regola esista
if [ ! -f /root/rule.yar ]; then
    echo 'rule Malicious { strings: $a="malevolo" condition: $a }' > /root/rule.yar
fi

while true; do
    rm -f binary report.txt

    nc -l -p 9000 > binary
    echo "[AV2] File ricevuto. Avvio scansione..."

    echo "--- REPORT AV2 (YARA) ---" > report.txt
    date >> report.txt
    yara /root/rule.yar binary >> report.txt

    nc -w 2 $CENTRAL_NODE_IP 9002 < report.txt

    rm -f binary report.txt
    echo "[AV2] Ciclo completato."
done
EOF

write_file "$OUT/av/av3.sh" <<'EOF'
#!/bin/bash
#v3.sh - STRACE Listener Daemon (Sandbox)
CENTRAL_NODE_IP="10.202.3.10"
sleep 20

# 1. Collega al Proxy
export http_proxy=http://10.202.3.10:8888
export https_proxy=http://10.202.3.10:8888

# 2. Installa
apt-get update
apt-get install -y strace netcat

# 3. Pulisci
unset http_proxy
unset https_proxy

echo "[AV3] SANDBOX Service avviato in ascolto sulla porta 9000..."

if ! command -v strace &> /dev/null; then
    echo "Errore: strace non trovato!"
    exit 1
fi

while true; do
    rm -f binary report.txt
    nc -l -p 9000 > binary

    if [ -s binary ]; then
        echo "[AV3] File ricevuto. Avvio esecuzione sandbox..."

        chmod +x binary

        echo "--- REPORT AV3 (STRACE DYNAMIC ANALYSIS) ---" > report.txt
        date >> report.txt

        timeout 5s strace -f -e trace=openat,connect,execve,unlink ./binary >> report.txt 2>&1
    else
        echo "[AV3] Errore: File ricevuto vuoto o non valido." > report.txt
    fi

    nc -w 2 $CENTRAL_NODE_IP 9003 < report.txt

    rm -f binary report.txt
    echo "[AV3] Ciclo completato."
done
EOF

write_file "$OUT/av/test.sh" <<'EOF'
#!/bin/bash
# test.sh - Invia malware e raccoglie i report

IP_AV1="10.200.1.11"
IP_AV2="10.200.1.12"
IP_AV3="10.200.1.13"
VIRUS_FILE="virus.exe"

rm -f report_av*.txt

echo "=============================================="
echo "   CENTRAL NODE - MALWARE ANALYSIS SYSTEM     "
echo "=============================================="

echo "STOPPING PROXY BEFORE ANALISYS"
service tinyproxy stop

echo "[*] Avvio listener per i report in ingresso..."
nc -l -p 9001 > report_av1.txt &
PID1=$!
nc -l -p 9002 > report_av2.txt &
PID2=$!
nc -l -p 9003 > report_av3.txt &
PID3=$!

sleep 1

if [ ! -f "$VIRUS_FILE" ]; then
    echo "Errore: $VIRUS_FILE non trovato! Crealo prima."
    exit 1
fi

echo "[*] Invio malware ($VIRUS_FILE) ai nodi..."
nc -w 1 $IP_AV1 9000 < $VIRUS_FILE
echo "    -> Inviato a AV1"
nc -w 1 $IP_AV2 9000 < $VIRUS_FILE
echo "    -> Inviato a AV2"
nc -w 1 $IP_AV3 9000 < $VIRUS_FILE
echo "    -> Inviato a AV3"

echo "[*] Attesa risultati..."
wait $PID1 $PID2 $PID3 2>/dev/null

echo ""
echo "=============================================="
echo "             RISULTATI ANALISI                "
echo "=============================================="

echo ""
echo ">>> REPORT AV1 (ClamAV):"
cat report_av1.txt

echo ""
echo ">>> REPORT AV2 (YARA):"
cat report_av2.txt

echo ""
echo ">>> REPORT AV3 (Strace):"
cat report_av3.txt

echo "=============================================="
echo "Analisi completata."

service tinyproxy restart
EOF
