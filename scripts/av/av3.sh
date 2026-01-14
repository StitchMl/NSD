#setup
# Crea la cartella per il db se non esiste
mkdir -p /var/lib/aide

# Sovrascrivi la config con quella corretta e completa
cat > /etc/aide/aide_exam.conf << 'EOF'
database_in=file:/var/lib/aide/aide.db
database_out=file:/var/lib/aide/aide.db.new
# Controlla: permessi(p)+user(u)+group(g)+size(s)+checksum(md5+sha256)
/root/binary p+u+g+s+md5+sha256


aide --init --config /etc/aide/aide_exam.conf
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
#fine setup



#####inizio av
#!/bin/bash
# av3.sh - AIDE Integrity Scanner (Real Program - Fast Config)
CENTRAL_NODE_IP="10.202.3.10"
CONF_FILE="/etc/aide/aide_exam.conf"

echo "[AV3] AIDE Service avviato in ascolto sulla porta 9000..."

# CHECK INIZIALE: Se il DB non c'è, crealo al volo
if [ ! -f /var/lib/aide/aide.db ]; then
    echo "[AV3] Setup iniziale DB..."
    aide --init --config $CONF_FILE > /dev/null 2>&1
    mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
fi

while true; do
    # 1. Pulizia preventiva
    rm -f /root/binary report.txt
    
    # 2. Aggiornamento DB: Diciamo ad AIDE che l'assenza del file è lo stato "normale"
    #    Così quando il file arriva, sarà considerato una "novità/anomalia"
    aide --update --config $CONF_FILE > /dev/null 2>&1
    if [ -f /var/lib/aide/aide.db.new ]; then
        mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
    fi

    # 3. RICEZIONE
    nc -l -p 9000 > /root/binary
    echo "[AV3] File ricevuto. Analisi AIDE..."

    echo "--- REPORT AV3 (System Integrity AIDE) ---" > report.txt
    date >> report.txt

    # 4. SCANSIONE (Veloce perché controlla solo 1 file)
    # AIDE restituisce errore (exit code != 0) se trova differenze.
    # Noi cerchiamo proprio le differenze (file aggiunto).
    aide --check --config $CONF_FILE >> report.txt 2>&1
    
    # Verifica se AIDE ha notato il file
    if grep -q "/root/binary" report.txt; then
        echo "" >> report.txt
        echo "[!!!] ALLARME: File non autorizzato rilevato nel sistema!" >> report.txt
        echo "Status: INTEGRITY VIOLATION" >> report.txt
    else
        echo "[OK] Nessuna violazione critica." >> report.txt
    fi

    # 5. INVIO REPORT
    nc -w 2 $CENTRAL_NODE_IP 9003 < report.txt
    
    echo "[AV3] Ciclo completato."
done
