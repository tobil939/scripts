#!/bin/bash

# Bash-Script for initialisation of Bluetooth Devices
# Rev. 2.0
# Includes Errorhandling, sort of, better Messages

UF2_FILE="$1"
path=$(pwd)
cd "$path/build" || exit 3

# Logging
# Place where the Logfile will be saved
logfile="/var/log/bluetooth.log"

# Timestamp
get_timestamp() {
  timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
}

logging() {
  if [[ -f "$logfile" ]]; then
    echo "Logfile exists"
  else
    echo "Logfile will be created"
    touch "$logfile" || exit 1
  fi

  [[ -f "$logfile" ]] || exit 1
  get_timestamp
  echo "$timestamp first entry" | tee -a "$logfile" || exit 1
}

# Errorhandling
# Better Errormessages
handling() {
  get_timestamp
  local error
  error="$?"
  case $error in
  0) (
    echo "$timestamp everything went as planned, no errors" | tee -a "$logfile"
    echo "$timestamp Logfile will be moved into /tmp" | tee -a "$logfile"
    mv -v "$logfile" "/tmp/bluetooth.log"
  ) ;;
  1) echo "$timestamp something went wrong with the logfile" | tee -a "$logfile" ;;
  2) echo "$timestamp must be run as root or with sudo!" | tee -a "$logfile" ;;
  3) echo "$timestamp cannot change into build path" | tee -a "$logfile" ;;
  4) echo "$timestamp you have to run as root or sudo" | tee -a "$logfile" ;;
  5) echo "$timestamp there are no arguments enterd" | tee -a "$logfile" ;;
  6) echo "$timestamp uf2 file does not exists" | tee -a "$logfile" ;;
  7) echo "$timestamp problem finding the pico" | tee -a "$logfile" ;;
  8) echo "$timestamp problem finding the pico, start in Bootloader-Modus" | tee -a "$logfile" ;;
  9) echo "$timestamp problem writing on the pico" | tee -a "$logfile" ;;
  *) echo "$timestamp unknown error" | tee -a "$logfile" ;;
  esac
}

# Root
# Checking if it was stared with sudo
rootcheck() {
  get_timestamp
  if [[ $UID -ne 0 ]]; then
    exit 4
  fi
}

# uf2 check
uf2check() {
  get_timestamp
  # checking if arguments are set
  if [ $# -ne 1 ]; then
    echo "Verwendung: flash.sh <programm.uf2>"
    exit 5
  fi

  get_timestamp
  # check if uf2 file exists
  if [ ! -f "$UF2_FILE" ]; then
    echo "Fehler: $UF2_FILE existiert nicht!"
    exit 6
  fi

}

finddevice() {
  get_timestamp
  # finding the Pico
  PICO_DEVICE=$(lsblk -o NAME,SIZE,TYPE | grep "disk" | grep "M" | awk '{print $1}' | head -n 1) || exit 7

  echo "Debug: Gefundenes PICO_DEVICE: '$PICO_DEVICE'"

  if [ -z "$PICO_DEVICE" ]; then
    echo "Fehler: Raspberry Pi Pico nicht gefunden! Bitte in Bootloader-Modus versetzen (BOOTSEL gedrückt halten)."
    exit 8
  fi
  PICO_PATH="/dev/$PICO_DEVICE"
}

flash() {
  get_timestamp
  # check if the pico exists and is writeable
  if [ ! -w "$PICO_PATH" ]; then
    echo "Kein Schreibzugriff auf $PICO_PATH. Versuche mit sudo..."
    sudo cp "$UF2_FILE" "$PICO_PATH" || {
      echo "Fehler: Kopieren von $UF2_FILE nach $PICO_PATH fehlgeschlagen!"
      exit 9
    }
  else
    cp "$UF2_FILE" "$PICO_PATH" || {
      echo "Fehler: Kopieren von $UF2_FILE nach $PICO_PATH fehlgeschlagen!"
      exit 9
    }
  fi

}

# Main
get_timestamp
logging
rootcheck
uf2check "$@"
finddevice
flash

# Debugging: shows the lsblk output
echo "Debug: lsblk -o NAME,SIZE,TYPE Ausgabe:"
lsblk -o NAME,SIZE,TYPE

trap handling EXIT
