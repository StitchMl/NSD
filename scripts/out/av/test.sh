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
