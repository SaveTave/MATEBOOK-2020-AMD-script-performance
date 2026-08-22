#!/usr/bin/env bash

# Colori terminale
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================================================="
echo "   🔍 VERIFICA OTTIMIZZAZIONI HUAWEI MATEBOOK (FEDORA / NOBARA)"
echo -e "==========================================================================${NC}"

check_status() {
    local label="$1"
    local actual="$2"
    local expected="$3"
    
    if [[ "$actual" == *"$expected"* ]]; then
        echo -e "  [${GREEN}OK${NC}] $label: ${GREEN}$actual${NC}"
    else
        echo -e "  [${YELLOW}WARN${NC}] $label: $actual (Atteso: $expected)"
    fi
}

echo -e "\n${BLUE}=== 1. PARAMETRI KERNEL & MEMORIA (sysctl) ===${NC}"
SWAP=$(sysctl -n vm.swappiness 2>/dev/null)
VFS=$(sysctl -n vm.vfs_cache_pressure 2>/dev/null)
DIRTY=$(sysctl -n vm.dirty_ratio 2>/dev/null)
DIRTY_BG=$(sysctl -n vm.dirty_background_ratio 2>/dev/null)
DIRTY_TIME=$(sysctl -n vm.dirty_writeback_centisecs 2>/dev/null)
NMI=$(sysctl -n kernel.nmi_watchdog 2>/dev/null)

check_status "vm.swappiness" "$SWAP" "60"
check_status "vm.vfs_cache_pressure" "$VFS" "80"
check_status "vm.dirty_ratio" "$DIRTY" "20"
check_status "vm.dirty_background_ratio" "$DIRTY_BG" "10"
check_status "vm.dirty_writeback_centisecs" "$DIRTY_TIME" "800"
check_status "kernel.nmi_watchdog" "$NMI" "0"

echo -e "\n${BLUE}=== 2. SERVIZI SYSTEMD AUTOMATIZZATI ===${NC}"
BOOST_ACTIVE=$(systemctl is-active auto-boost.service 2>/dev/null || echo "inactive")
BOOST_ENABLED=$(systemctl is-enabled auto-boost.service 2>/dev/null || echo "disabled")
check_status "auto-boost.service (Attivo)" "$BOOST_ACTIVE" "active"
check_status "auto-boost.service (Abilitato al boot)" "$BOOST_ENABLED" "enabled"

BATT_ACTIVE=$(systemctl is-active huawei-battery-threshold.service 2>/dev/null || echo "inactive")
BATT_ENABLED=$(systemctl is-enabled huawei-battery-threshold.service 2>/dev/null || echo "disabled")
check_status "huawei-battery-threshold.service (Attivo)" "$BATT_ACTIVE" "active"
check_status "huawei-battery-threshold.service (Abilitato al boot)" "$BATT_ENABLED" "enabled"

MODEM_STATUS=$(systemctl is-enabled ModemManager.service 2>/dev/null || echo "disabled")
if [[ "$MODEM_STATUS" != "enabled" ]]; then
    echo -e "  [${GREEN}OK${NC}] ModemManager: ${GREEN}$MODEM_STATUS (disabilitato per risparmio risorse)${NC}"
else
    echo -e "  [${YELLOW}INFO${NC}] ModemManager: abilitato"
fi

echo -e "\n${BLUE}=== 3. STATO CPU, FREQUENZE & GOVERNOR ===${NC}"
PROFILE=$(powerprofilesctl get 2>/dev/null || echo "N/D")
BOOST_VAL=$(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || echo "N/D")
GOV_VAL=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/D")
MAX_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || echo "N/D")

echo "  -> Profilo GNOME attivo: $PROFILE"

if [ "$PROFILE" = "power-saver" ]; then
    check_status "CPU Boost (0=Disattivato)" "$BOOST_VAL" "0"
    check_status "CPU Governor" "$GOV_VAL" "schedutil"
    check_status "Frequenza Massima Core 0" "$MAX_FREQ" "1700000"
else
    check_status "CPU Boost (1=Attivo)" "$BOOST_VAL" "1"
    check_status "CPU Governor" "$GOV_VAL" "schedutil"
    echo -e "  [${GREEN}OK${NC}] Frequenza Massima Core 0: Sbloccata ($MAX_FREQ kHz)"
fi

echo -e "\n${BLUE}=== 4. SOGLIE BATTERIA HUAWEI ===${NC}"
if [ -f /sys/devices/platform/huawei-wmi/charge_control_thresholds ]; then
    THRESH_VAL=$(cat /sys/devices/platform/huawei-wmi/charge_control_thresholds 2>/dev/null)
    check_status "Soglie di Carica WMI (Min Max)" "$THRESH_VAL" "40 80"
else
    echo -e "  [${YELLOW}WARN${NC}] Modulo huawei-wmi non rilevato nel sysfs"
fi

echo -e "\n${BLUE}=== 5. WI-FI & DISCO (Journald) ===${NC}"
if [ -f /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf ]; then
    WIFI_CONF=$(grep "wifi.powersave" /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf 2>/dev/null || echo "N/D")
    check_status "NetworkManager Wi-Fi Powersave" "$WIFI_CONF" "wifi.powersave = 3"
else
    echo -e "  [${YELLOW}WARN${NC}] File di configurazione Wi-Fi powersave non presente"
fi

JOURNAL_SIZE=$(journalctl --disk-usage 2>/dev/null || echo "N/D")
echo "  -> Spazio attuale occupato dai log: $JOURNAL_SIZE"
if [ -f /etc/systemd/journald.conf.d/00-journal-size.conf ]; then
    echo -e "  [${GREEN}OK${NC}] File limite Journald (250MB): Configurato"
else
    echo -e "  [${YELLOW}WARN${NC}] File limite Journald: Non trovato in journald.conf.d"
fi

echo -e "\n${BLUE}=== 6. INDICIZZAZIONE TRACKER (GNOME) ===${NC}"
REAL_USER=${SUDO_USER:-$USER}
USER_ID=$(id -u "$REAL_USER")

if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
    TRACKER_THROTTLE=$(sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" gsettings get org.freedesktop.Tracker3.Miner.Files throttle 2>/dev/null || echo "N/D")
    TRACKER_BATT=$(sudo -u "$REAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$USER_ID/bus" gsettings get org.freedesktop.Tracker3.Miner.Files index-on-battery 2>/dev/null || echo "N/D")
else
    TRACKER_THROTTLE=$(gsettings get org.freedesktop.Tracker3.Miner.Files throttle 2>/dev/null || echo "N/D")
    TRACKER_BATT=$(gsettings get org.freedesktop.Tracker3.Miner.Files index-on-battery 2>/dev/null || echo "N/D")
fi

check_status "Tracker Throttle" "$TRACKER_THROTTLE" "10"
check_status "Tracker Index on Battery" "$TRACKER_BATT" "false"

echo -e "\n${BLUE}=== 7. MODALITÀ SOSPENSIONE (Standby) ===${NC}"
SLEEP_MODE=$(cat /sys/power/mem_sleep 2>/dev/null || echo "N/D")
echo "  -> Modalità sonno attiva: $SLEEP_MODE"

echo -e "\n${BLUE}==========================================================================${NC}"
echo -e "  Controllo terminato. Tutti i parametri contrassegnati con [OK] sono attivi."
echo -e "${BLUE}==========================================================================${NC}"
