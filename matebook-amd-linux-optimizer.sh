#!/usr/bin/env bash
set -e

echo "=========================================================================="
echo "   🚀 CONFIGURAZIONE E OTTIMIZZAZIONE HUAWEI MATEBOOK 2020 (LINUX)"
echo "	 - RYZEN 7 4800H - 16GB RAM - 500 GB SSD - FEDORA 44 NOBARA GNOME 50 "
echo "=========================================================================="

if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Esegui questo script con sudo: sudo ./setup.sh"
    exit 1
fi

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo "~$REAL_USER")

echo "=== 1. OTTIMIZZAZIONI KERNEL, MEMORIA & WATCHDOG ==="
tee /etc/sysctl.d/99-matebook-optimizations.conf << 'EOF'
# Bilanciamento memoria per ZRAM/SSD
vm.swappiness=60
vm.vfs_cache_pressure=80
vm.dirty_ratio=20
vm.dirty_background_ratio=10

# Intervallo scrittura dirty cache (800 centisecondi = 8 secondi)
vm.dirty_writeback_centisecs=800

# Disabilita Watchdog hardware per C-States profondi sui Ryzen
kernel.nmi_watchdog=0
EOF

sysctl --system

echo "=== 2. RISPARMIO ENERGETICO WI-FI ==="
tee /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf << 'EOF'
[connection]
wifi.powersave = 3
EOF

systemctl restart NetworkManager || true

echo "=== 3. OTTIMIZZAZIONE SYSTEMD-JOURNALD (LOG SU DISCO) ==="
mkdir -p /etc/systemd/journald.conf.d
tee /etc/systemd/journald.conf.d/00-journal-size.conf << 'EOF'
[Journal]
SystemMaxUse=250M
SystemMaxFileSize=30M
RuntimeMaxUse=80M
EOF

systemctl restart systemd-journald || true
journalctl --vacuum-size=250M || true

echo "=== 4. GESTIONE MODEM LTE/5G ==="
read -p "❓ Usi un modem cellulare SIM 4G/5G integrato o chiavette LTE? (s/N): " USE_MODEM
USE_MODEM=${USE_MODEM:-n}

if [[ "$USE_MODEM" =~ ^[sSyY]$ ]]; then
    echo "ℹ️  ModemManager mantenuto attivo."
    systemctl enable --now ModemManager.service 2>/dev/null || true
else
    echo "✅ ModemManager disabilitato per velocizzare il boot e risparmiare risorse."
    systemctl disable --now ModemManager.service 2>/dev/null || true
fi

echo "=== 5. SOGLIA DI CARICA BATTERIA HUAWEI ==="
read -p "❓ Vuoi impostare una soglia di stop ricarica della batteria? (S/n): " ENABLE_THRESH
ENABLE_THRESH=${ENABLE_THRESH:-s}

if [[ "$ENABLE_THRESH" =~ ^[sSyY]$ ]]; then
    read -p "-> Soglia minima di avvio carica [default: 35]: " BATT_MIN
    BATT_MIN=${BATT_MIN:-35}
    read -p "-> Soglia massima di stop carica [default: 90]: " BATT_MAX
    BATT_MAX=${BATT_MAX:-90}

    echo "⚙️  Configurazione soglia impostata su: $BATT_MIN% - $BATT_MAX%"
    
    tee /etc/systemd/system/huawei-battery-threshold.service << EOF
[Unit]
Description=Set Huawei Battery Charge Thresholds
After=basic.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo "$BATT_MIN $BATT_MAX" > /sys/devices/platform/huawei-wmi/charge_control_thresholds 2>/dev/null || true'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now huawei-battery-threshold.service 2>/dev/null || true
else
    echo "ℹ️  Soglia batteria non modificata (carica fino al 100%)."
fi

echo "=== 6. CONFIGURAZIONE TRACKER / LOCALSEARCH ==="
su - "$REAL_USER" -c "
gsettings set org.freedesktop.Tracker3.Miner.Files index-recursive-directories \"['$USER_HOME']\"
gsettings set org.freedesktop.Tracker3.Miner.Files ignored-directories \"['po', 'CVS', 'core-dumps', 'lost+found', '.cache', '.local', '.var', 'node_modules', 'target', 'build', 'dist', '.git', '.wine', '.steam']\"
gsettings set org.freedesktop.Tracker3.Miner.Files throttle 10
gsettings set org.freedesktop.Tracker3.Miner.Files index-on-battery false
gsettings set org.freedesktop.Tracker3.Miner.Files index-on-battery-first-time false
"

echo "=== 7. SCRIPT GESTIONE CPU BOOST / FREQUENZE ==="
tee /usr/local/bin/auto-boost.sh << 'EOF'
#!/usr/bin/env bash

apply_profile() {
    PROFILE=$(powerprofilesctl get 2>/dev/null || echo "balanced")
    
    if [ "$PROFILE" = "power-saver" ]; then
        # Risparmio energetico: Boost OFF, Frequenza a 1.7GHz, Governor Powersave
        echo 0 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
            echo 1700000 > "$cpu/scaling_max_freq" 2>/dev/null || true
            echo powersave > "$cpu/scaling_governor" 2>/dev/null || true
        done
    else
        # Bilanciato o Prestazioni: Boost ON, Frequenza Massima sbloccata, Governor Schedutil
        echo 1 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
            MAX_FREQ=$(cat "$cpu/cpuinfo_max_freq" 2>/dev/null || echo 2900000)
            echo "$MAX_FREQ" > "$cpu/scaling_max_freq" 2>/dev/null || true
            echo schedutil > "$cpu/scaling_governor" 2>/dev/null || true
        done
    fi
}

# Attesa post-boot per sincronizzazione con GNOME
(
    sleep 4
    apply_profile
) &

apply_profile

# Ascolto continuo D-Bus
gdbus monitor --system --dest net.hadess.PowerProfiles --object-path /net/hadess/PowerProfiles | while read -r line; do
    if echo "$line" | grep -qE "ActiveProfile|PropertiesChanged"; then
        sleep 0.1
        apply_profile
    fi
done
EOF

chmod +x /usr/local/bin/auto-boost.sh

echo "=== 8. CREAZIONE ED ATTIVAZIONE SERVIZIO AUTO-BOOST ==="
tee /etc/systemd/system/auto-boost.service << 'EOF'
[Unit]
Description=Auto CPU Boost and Frequency Manager for PowerProfiles
After=dbus.service
Wants=dbus.service

[Service]
Type=simple
ExecStart=/usr/local/bin/auto-boost.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now auto-boost.service

cat << 'EOF'

================================================================================
  📌 PROMEMORIA POST-INSTALLAZIONE: OTTIMIZZAZIONE BROWSER & YOUTUBE 
================================================================================

1. ESTENSIONE YOUTUBE (Evita la decodifica software AV1 via CPU):
   - Installa l'estensione: "enhanced-h264ify"
   - Clicca sull'icona dell'estensione e SPUNTA:
     [✔] Block AV1
     [ ] Block VP9 (lascialo non bloccato per abilitare 1440p/4K su GPU Radeon)

2. FLAG ACCELERAZIONE HARDWARE (Chrome / Brave / Chromium):
   - Digita nella barra indirizzi: chrome://flags (o brave://flags)
   - Cerca e imposta su "Enabled":
     * Override software rendering list  (#ignore-gpu-blocklist) -> Enabled
     * GPU rasterization                 (#enable-gpu-rasterization) -> Enabled
     * Zero-copy rasterizer              (#enable-zero-copy) -> Enabled

3. VERIFICA STATO ACCELERAZIONE HARDWARE:
   - Apri una scheda e digita: chrome://gpu (o brave://gpu)
   - Verifica che compaiano in verde:
     * Video Decode: Hardware accelerated
     * Rasterization: Hardware accelerated

4. VERIFICA DRIVER VA-API AMD DA TERMINALE:
   - Esegui il comando:
     vainfo
     Pacchetto in caso non sia installato: libva-utils

5. ESTENSIONE CONSIGLIATA GNOME:
   - VITALS 
================================================================================
  ✅ CONFIGURAZIONE COMPLETATA CON SUCCESSO!
================================================================================
EOF
