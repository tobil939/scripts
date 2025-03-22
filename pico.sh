#!/bin/bash

# Fehlerprüfung aktivieren
set -e

# Prüfen, ob eine Datei als Argument übergeben wurde
if [[ -z "$1" ]]; then
    echo "Verwendung: $0 <datei.c>"
    exit 1
fi

SOURCE_FILE="$1"
PROJECT_DIR="$(pwd)"
SDK_PATH="$HOME/pico-sdk"
SEP_PATH="$HOME/pico-sdk/sep"
LOG_FILE="$PROJECT_DIR/logging.txt"
CMAKE_FILE="CMakeLists.txt"
PROJECT_NAME=$(basename "$SOURCE_FILE" .c)

export SDK_PATH="$HOME/pico-sdk"

# Simulierte Liste der vorhandenen Libraries im Pico-SDK
LIBRARIES=(
    "pico_stdlib"
    "hardware_adc"
    "hardware_base"
    "hardware_boot_lock"
    "hardware_clocks"
    "hardware_dma"
    "hardware_flash"
    "hardware_gpio"
    "hardware_i2c"
    "hardware_interp"
    "hardware_irq"
    "hardware_pio"
    "hardware_pll"
    "hardware_pwm"
    "hardware_rtc"
    "hardware_spi"
    "hardware_sync"
    "hardware_timer"
    "hardware_uart"
    "hardware_vreg"
    "hardware_watchdog"
    "pico_multicore"
    "pico_bootrom"
    "pico_printf"
    "pico_time"
    "pico_unique_id"
    "pico_stdio"
    "pico_stdio_uart"
    "pico_stdio_usb"
)

# Arrays für aktive und nicht-aktive Bibliotheken
ACTIV=()
NOTACTIV=()

# Erstelle/leere die Log-Datei
echo "Build-Prozess gestartet: $(date)" | tee -a "$LOG_FILE"

# Lösche alle Dateien im Projektordner außer der Quelldatei
find . -type f -not -name "$SOURCE_FILE" -delete &>> "$LOG_FILE"
echo "Alle Dateien außer $SOURCE_FILE gelöscht" | tee -a "$LOG_FILE"

# Kopiere pico_sdk_import.cmake
cp "$SDK_PATH/external/pico_sdk_import.cmake" . &>> "$LOG_FILE"
if [ $? -eq 0 ]; then
    echo "pico_sdk_import.cmake erfolgreich kopiert" | tee -a "$LOG_FILE"
else
    echo "Fehler beim Kopieren von pico_sdk_import.cmake" | tee -a "$LOG_FILE"
    exit 1
fi

# Erstelle Build-Ordner
mkdir -p build &>> "$LOG_FILE"
echo "Build-Ordner erstellt" | tee -a "$LOG_FILE"

# Alle #include-Namen extrahieren und verarbeiten
while IFS= read -r line; do
    if [[ $line =~ ^#include\ *\"([^\"]+)\"$ ]]; then
        HEADER="${BASH_REMATCH[1]}"
        LIB_NAME=$(echo "$HEADER" | sed 's#/#_#g' | sed 's/\.h$//')
        if [[ " ${LIBRARIES[*]} " =~ " $LIB_NAME " ]]; then
            ACTIV+=("$LIB_NAME")
            echo "Aktive Bibliothek gefunden: $LIB_NAME" | tee -a "$LOG_FILE"
        else
            NOTACTIV+=("$HEADER")
            echo "Bibliothek nicht gefunden: $HEADER" | tee -a "$LOG_FILE"
        fi
    fi
done < "$SOURCE_FILE"

# Suche und kopiere zugehörige Dateien aus SEP_PATH (z. B. .pio statt .h)
for header in "${NOTACTIV[@]}"; do
    # Entferne .h und suche nach der Quelldatei (z. B. .pio)
    base_name="${header%.h}"
    source_file="$SEP_PATH/$base_name"
    if [[ -f "$source_file" ]]; then
        echo "Quelldatei gefunden: $source_file -> Kopiere nach $PROJECT_DIR" | tee -a "$LOG_FILE"
        cp "$source_file" "$PROJECT_DIR/" &>> "$LOG_FILE"
        if [ $? -eq 0 ]; then
            echo "Erfolgreich kopiert: $base_name" | tee -a "$LOG_FILE"
            # Wenn es eine .pio-Datei ist, füge hardware_pio hinzu
            if [[ "$source_file" =~ \.pio$ ]]; then
                ACTIV+=("hardware_pio")
                echo "Aktive Bibliothek hinzugefügt: hardware_pio (für $header)" | tee -a "$LOG_FILE"
            fi
        else
            echo "Fehler beim Kopieren von $base_name" | tee -a "$LOG_FILE"
        fi
    else
        echo "Warnung: $base_name nicht in $SEP_PATH gefunden" | tee -a "$LOG_FILE"
    fi
done

# Erstelle die CMakeLists.txt
echo "CMakeLists.txt wird erstellt" | tee -a "$LOG_FILE"

cat > "$CMAKE_FILE" <<EOL
cmake_minimum_required(VERSION 3.13)

# Automatisch den SDK-Pfad setzen (falls nicht gesetzt)
if(NOT DEFINED PICO_SDK_PATH)
    set(PICO_SDK_PATH "\$ENV{SDK_PATH}")
endif()

if(NOT EXISTS "\${PICO_SDK_PATH}")
    message(FATAL_ERROR "PICO_SDK_PATH ist nicht gesetzt oder ungültig!")
endif()

include(pico_sdk_import.cmake)

# Projektname setzen
project($PROJECT_NAME C CXX ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

# Alle C- und C++-Dateien automatisch erkennen
file(GLOB SRC_FILES *.c *.cpp)

add_executable(\${PROJECT_NAME} \${SRC_FILES})

# Bibliotheken automatisch einbinden
target_link_libraries(\${PROJECT_NAME}
EOL

# Aktive Bibliotheken hinzufügen
for LIB in "${ACTIV[@]}"; do
    echo "    $LIB" >> "$CMAKE_FILE"
    echo "Aktive Bibliotheken wurden hinzugefügt: $LIB" | tee -a "$LOG_FILE"
done

cat >> "$CMAKE_FILE" <<EOL
)

# Falls USB genutzt wird
if(EXISTS "\${CMAKE_CURRENT_LIST_DIR}/usb.c" OR EXISTS "\${CMAKE_CURRENT_LIST_DIR}/usb.cpp")
    target_link_libraries(\${PROJECT_NAME} tinyusb_device tinyusb_host)
endif()

# Falls Floating Point-Unterstützung benötigt wird
target_link_libraries(\${PROJECT_NAME} pico_float pico_double)

# Falls C++ Standardbibliothek genutzt wird
if(CMAKE_CXX_COMPILER)
    target_link_libraries(\${PROJECT_NAME} pico_standard_link)
endif()

# USB- oder UART-Standardausgabe aktivieren
pico_enable_stdio_usb(\${PROJECT_NAME} 1)
pico_enable_stdio_uart(\${PROJECT_NAME} 0)

# Extra-Ausgaben für Flash
pico_add_extra_outputs(\${PROJECT_NAME})

# Generiere PIO-Header für gefundene .pio-Dateien
file(GLOB PIO_FILES *.pio)
foreach(pio_file \${PIO_FILES})
    pico_generate_pio_header(\${PROJECT_NAME} \${pio_file})
endforeach()
EOL

echo "CMakeLists.txt erstellt" | tee -a "$LOG_FILE"

## Prüfe, ob mehrere Einträge in NOTACTIV sind, und breche ab
#if [ ${#NOTACTIV[@]} -gt 0 ]; then
#    echo "Fehler: Mehrere unbekannte Bibliotheken gefunden:" | tee -a "$LOG_FILE"
#    for lib in "${NOTACTIV[@]}"; do
#        echo "  - $lib" | tee -a "$LOG_FILE"
#    done
#    echo "Build-Prozess abgebrochen wegen fehlender Bibliotheken." | tee -a "$LOG_FILE"
#    exit 1
#fi

# Wechsel in Build-Ordner
cd build || { echo "Fehler: Konnte nicht in build-Ordner wechseln" | tee -a "$LOG_FILE"; exit 1; }
echo "In Build-Ordner gewechselt" | tee -a "$LOG_FILE"

# Führe cmake aus
cmake .. &>> "$LOG_FILE"
if [ $? -eq 0 ]; then
    echo "cmake erfolgreich ausgeführt" | tee -a "$LOG_FILE"
else
    echo "cmake fehlgeschlagen - siehe Log für Details" | tee -a "$LOG_FILE"
    cd ..
    exit 1
fi

# Führe make aus
make &>> "$LOG_FILE"
if [ $? -eq 0 ]; then
    echo "make erfolgreich ausgeführt" | tee -a "$LOG_FILE"
else
    echo "make fehlgeschlagen - siehe Log für Details" | tee -a "$LOG_FILE"
    cd ..
    exit 1
fi

# Zeige Verzeichnisinhalt
ls -l | tee -a "$LOG_FILE"

COPIE_FILE="${PROJECT_NAME}.uf2"
cp "$COPIE_FILE" "$PROJECT_DIR/$COPIE_FILE"

# Zurück ins Projektverzeichnis
cd .. || { echo "Fehler: Konnte nicht zurück wechseln" >> "$LOG_FILE"; exit 1; }
echo "Zurück ins Projektverzeichnis gewechselt" | tee -a "$LOG_FILE"
echo "Build-Prozess abgeschlossen: $(date)" | tee -a "$LOG_FILE"

# Zeige Verzeichnisinhalt
ls -l | tee -a "$LOG_FILE"

echo "Kompilierung abgeschlossen. Details in $LOG_FILE"

