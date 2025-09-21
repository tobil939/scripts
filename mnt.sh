#!/bin/bash

# Bash-Script for mounting usb drives
# Rev. 2.0
# Includes Errorhandling, sort of, better Messages

# Logging
# Place where the Logfile will be saved
logfile="/var/log/mnt.sh"

# Timestamp
get_timestamp() {
  timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
}

# Root
# Checking if it was stared with sudo
rootcheck() {
  get_timestamp
  if [[ $UID -ne 0 ]]; then
    echo "must be run as root or with sudo!"
    exit 2
  fi
  echo "$timestamp rootcheck passed"
}

logging() {
  if [[ -f "$logfile" ]]; then
    echo "Logfile exists"
  else
    echo "Logfile will be created"
    touch "$logfile" || exit 1
  fi

  get_timestamp
  echo "$timestamp first entry" | tee -a "$logfile"

  if [[ ! -f "$logfile" ]]; then
    get_timestamp
    echo "$timestamp logfile does not exists" | tee -a "$logfile"
    exit 1
  fi

  if [[ ! -w "$logfile" ]]; then
    get_timestamp
    echo " $timestamp cannot write into $logfile"
    exit 1
  fi
}

# Errorhandling
# Better Errormessages
handling() {
  local error
  error="$?"
  get_timestamp
  case $error in
  0) (
    echo "$timestamp everything went as planned, no errors" | tee -a "$logfile"
    echo "$timestamp Logfile will be moved into /tmp" | tee -a "$logfile"
    mv -v "$logfile" "/tmp/mnt.sh"
  ) ;;
  1) echo "$timestamp something went wrong with the logfile" | tee -a "$logfile" ;;
  2) echo "$timestamp must be run as root or with sudo!" | tee -a "$logfile" ;;
  3) echo "$timestamp sdb1 and/or usb1 problems" | tee -a "$logfile" ;;
  4) echo "$timestamp sdb2 and/or usb2 problems" | tee -a "$logfile" ;;
  *) echo "$timestamp unknown error" | tee -a "$logfile" ;;
  esac
}

# sdb1 finding
sdb1grep() {
  get_timestamp
  if lsblk | grep -q "sdb1"; then
    sudo mkdir -p /mnt/usb1 || exit 3
    echo "$timestamp /mnt/usb1 was created" | tee -a "$logfile"
    sudo mount -t ntfs-3g /dev/sdb1 /mnt/usb1 || exit 3
    echo "$timestamp /mnt/usb1 was mounted" | tee -a "$logfile"

    get_timestamp
    if ! grep -Fxq "file:///mnt/usb1 usb1" ~/.config/gtk-3.0/bookmarks; then
      echo "file:///mnt/usb1 usb1" >>~/.config/gtk-3.0/bookmarks
      echo "$timestamp Bookmark was added" | tee -a "$logfile"
    else
      echo "$timestamp Bookmark already exists" | tee -a "$logfile"
    fi

  else
    get_timestamp
    echo "$timestamp no drive found" | tee -a "$logfile"
  fi
}

# sdb2 finding
sdb2grep() {
  get_timestamp
  if lsblk | grep -q "sdb2"; then
    sudo mkdir -p /mnt/usb2 || exit 4
    echo "$timestamp /mnt/usb2 was created" | tee -a "$logfile"
    sudo mount -t ntfs-3g /dev/sdb2 /mnt/usb2 || exit 4
    echo "$timestamp /mnt/usb2 was mounted" | tee -a "$logfile"

    get_timestamp
    if ! grep -Fxq "file:///mnt/usb2 usb2" ~/.config/gtk-3.0/bookmarks; then
      echo "file:///mnt/usb2 usb2" >>~/.config/gtk-3.0/bookmarks
      echo "$timestamp Bookmark was added" | tee -a "$logfile"
    else
      echo "$timestamp Bookmark already exists" | tee -a "$logfile"
    fi

  else
    get_timestamp
    echo "$timestamp no drive found" | tee -a "$logfile"
  fi
}

# Main
get_timestamp
rootcheck
logging
sdb1grep
sdb2grep

trap handling EXIT
