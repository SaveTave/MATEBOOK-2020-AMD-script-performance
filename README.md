# 🚀 Huawei MateBook (AMD Ryzen) Linux Optimizer

Script di ottimizzazione energetica, termica e prestazionale per laptop **Huawei MateBook (2020/2021/2022 con CPU AMD Ryzen 3000/4000/5000)** su distribuzioni Linux basate su **Fedora / Nobara / Arch / Debian / Ubuntu** con ambiente desktop GNOME o KDE.

---

## 🎯 Obiettivi del Progetto

1. **Riduzione drastica dei consumi in idle e streaming video:** Mantiene l'assorbimento tra i **7W e i 12W** durante lo streaming YouTube a 1080p/2K/4K a display acceso.
2. **Temperature basse:** Gestione dinamica dei C-States e del boost hardware.
3. **100% Compatibile con Produzione Audio / USB:** Nessuna sospensione aggressiva dei bus PCI/USB, garantendo zero click, pop o latenza (*xruns*) con schede audio esterne, interfacce USB e pedaliere multieffetto (testato con **Valeton GP-200**).
4. **Preservazione della batteria:** Gestione delle soglie di ricarica hardware Huawei (es. 40% - 80% o personalizzata 35% - 90%).

---

## 💻 Hardware di Riferimento & Note di Compatibilità

> **Configurazione di test:**
> * **CPU:** AMD Ryzen 7 4800H with Radeon Graphics
> * **RAM:** 16 GB DDR4
> * **Storage:** 500 GB NVMe SSD
> * **OS:** Nobara Linux (Fedora-based)

* **Adattamento frequenze:** I valori di default (1.7 GHz in risparmio energetico) sono tarati su Ryzen 7 4800H. Se utilizzi una CPU diversa (es. Ryzen 5 3500U, 4500U, 5500U), puoi verificare e modificare i limiti di frequenza direttamente all'interno dello script.
* **Flessibilità:** Tutti i parametri sono personalizzabili in base alle proprie esigenze.

---

## ⚡ Caratteristiche Principali

| Ottimizzazione | Descrizione |
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
git clone [https://github.com/SaveTave/MATEBOOK-2020-AMD-script-performance.git](https://github.com/SaveTave/MATEBOOK-2020-AMD-script-performance.git)
cd MATEBOOK-2020-AMD-script-performance
chmod +x setup.sh
sudo ./setup.sh
