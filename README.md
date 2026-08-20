# 🚀 Huawei MateBook (AMD Ryzen) Linux Optimizer

Script di ottimizzazione energetica, termica e prestazionale per laptop **Huawei MateBook (2020/2021/2022 con CPU AMD Ryzen 3000/4000/5000)** su distribuzioni Linux basate su **Fedora / Nobara / Arch / Debian / Ubuntu** con ambiente desktop GNOME o KDE.
---

## 🎯 Obiettivi del Progetto

1. **Riduzione drastica dei consumi in idle e streaming video:** Mantiene l'assorbimento tra i **7W e i 12W** durante lo streaming YouTube a 1080p/2K/4K a display acceso.
2. **Temperature basse:** Gestione dinamica dei C-States e del boost hardware.
3. **100% Compatibile con Produzione Audio / USB:** Nessuna sospensione aggressiva dei bus PCI/USB, garantendo zero click, pop o latenza (*xruns*) con schede audio esterne, interfacce USB e pedaliere multieffetto (testato con **Valeton GP-200**).
5. **Preservazione della batteria:** Gestione delle soglie di ricarica hardware Huawei (es. 40% - 80%). Io consiglio 35% - 90%

Setup attuale: AMD Ryzen 7 4800H Radeon Graphics
16GB RAM - 500GB Nvme
Fedora NObara 44
Le frequenze  impostate  sono state adattate a questo tipo di CPU. Se disponete di un modello diverso verificate le frequenze MIN e MAX per adattarle alla vostra CPU.
Si possono modificare tutti i valori. Ho impostato il tutto su valori medi senza creare troppe restrizioni. Attenzione a dove mettete le mani!
---

## ⚡ Caratteristiche Principali

| Ottimizzazione |
| :--- | :--- |
| **CPU Dynamic Governor & Boost** | Disattiva il Boost e fissa la frequenza a 1.7 GHz in modalità *Risparmio Energia*; sblocca frequenza massima e boost in modalità *Bilanciato/Prestazioni*. |
| **D-Bus Event Listener** | Intercetta all'istante il cambio profilo dal menu di sistema senza cicli continui (zero consumo CPU in background). |
| **C-States & NMI Watchdog** | Disabilita `nmi_watchdog` per permettere ai core Ryzen di entrare negli stati di sonno profondo (C2/C3/C6). |
| **Memory & ZRAM Tuning** | Bilanciamento di `swappiness` (60) e scrittura ritardata della cache (`dirty_writeback_centisecs=800` a 8 secondi) per ridurre le scritture sull'SSD NVMe. |
| **Wi-Fi Power Save** | Attivazione della modalità di risparmio energetico standard 802.11 (`wifi.powersave=3`). |
| **Tracker / Localsearch Throttle** | Indicizzazione intelligente: esclusione di cartelle pesanti (`node_modules`, `.cache`, `.git`, `.steam`) e stop automatico a batteria. |
| **Journald Log Limits** | Dimensione massima dei log limitata a 250 MB per evitare usura dell'SSD. |

---

## ⚙️ Installazione Rapida

Clona il repository ed esegui lo script con permessi di amministratore:

```bash
git clone [https://github.com/TUO-USERNAME/matebook_amd_linux_optimizer.git](https://github.com/TUO-USERNAME/matebook_amd_linux_optimizer.git)
cd matebook_amd_linux_optimizer
chmod +x setup.sh
sudo ./setup.sh
