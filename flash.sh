#!/bin/bash

path=$(pwd)
cd "$path/build"

# Überprüfe, ob ein Argument (die .uf2-Datei) angegeben wurde
if [ $# -ne 1 ]; then
    echo "Verwendung: flash.sh <programm.uf2>"
    exit 1
fi

# Pfad zur .uf2-Datei
UF2_FILE="$1"

# Prüfe, ob die Datei existiert
if [ ! -f "$UF2_FILE" ]; then
    echo "Fehler: $UF2_FILE existiert nicht!"
    exit 1
fi

# Debugging: Zeige lsblk-Ausgabe
echo "Debug: lsblk -o NAME,SIZE,TYPE Ausgabe:"
lsblk -o NAME,SIZE,TYPE

# Finde den Pico (suche nach einem disk mit M Größe)
PICO_DEVICE=$(lsblk -o NAME,SIZE,TYPE | grep "disk" | grep "M" | awk '{print $1}' | head -n 1)

# Debugging: Zeige gefundenes Gerät
echo "Debug: Gefundenes PICO_DEVICE: '$PICO_DEVICE'"

if [ -z "$PICO_DEVICE" ]; then
    echo "Fehler: Raspberry Pi Pico nicht gefunden! Bitte in Bootloader-Modus versetzen (BOOTSEL gedrückt halten)."
    exit 1
fi

# Vollständiger Gerätepfad
PICO_PATH="/dev/$PICO_DEVICE"

# Prüfe, ob das Gerät existiert und beschreibbar ist
if [ ! -w "$PICO_PATH" ]; then
    echo "Kein Schreibzugriff auf $PICO_PATH. Versuche mit sudo..."
    sudo cp "$UF2_FILE" "$PICO_PATH" || {
        echo "Fehler: Kopieren von $UF2_FILE nach $PICO_PATH fehlgeschlagen!"
        exit 1
    }
else
    cp "$UF2_FILE" "$PICO_PATH" || {
        echo "Fehler: Kopieren von $UF2_FILE nach $PICO_PATH fehlgeschlagen!"
        exit 1
    }
fi

echo "Erfolg: $UF2_FILE wurde auf den Pico geflasht. Der Pico startet jetzt neu."
exit 0
