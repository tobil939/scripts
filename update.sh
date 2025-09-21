#!/bin/bash

# Bash-Script for updateing pacman, yay and npm
# Rev. 2.0
# Includes Errorhandling, sort of, better Messages

deathtime="180s"
warntime="170s"

# Logging
# Place where the Logfile will be saved
logfile="/var/log/update.log"

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
    mv -v "$logfile" "/tmp/update.log"
  ) ;;
  1) echo "$timestamp something went wrong with the logfile" | tee -a "$logfile" ;;
  2) echo "$timestamp must be run as root or with sudo!" | tee -a "$logfile" ;;
  3) echo "$timestamp error while pacman keyring update" | tee -a "$logfile" ;;
  4) echo "$timestamp error while pacman update" | tee -a "$logfile" ;;
  5) echo "$timestamp error while yay update" | tee -a "$logfile" ;;
  6) echo "$timestamp error while npm update" | tee -a "$logfile" ;;
  7) echo "$timestamp db.lck cannot be deleted" | tee -a "$logfile" ;;
  124) echo "$timestamp Watchdog hit, 180s are reached" | tee -a "$logfile" ;;
  *) echo "$timestamp unknown error" | tee -a "$logfile" ;;
  esac
}

lckcheck() {
  rootcheck
  get_timestamp
  echo "$timestamp checking if the update is blocked" | tee -a "$logfile"
  if [[ -f "/var/lib/pacman/db.lck" ]]; then
    echo "$timestamp db.lck exists and will be deleted" | tee -a "$logfile"
    rm /var/lib/pacman/db.lck || exit 7
  else
    echo "$timestamp no db.lck found" | tee -a "$logfile"
  fi
}

uppacman() {
  rootcheck
  get_timestamp
  echo "$timestamp pacman keyring update" | tee -a "$logfile"
  watchdog pacman -Syu archlinux-keyring --noconfirm || exit 3

  get_timestamp
  echo "$timestamp pacman update" | tee -a "$logfile"
  watchdog pacman -Syu --noconfirm || exit 4
}

upyay() {
  rootcheck
  get_timestamp
  echo "$timestamp yay update" | tee -a "$logfile"
  watchdog yay -Syu --noconfirm || exit 5
}

upnpm() {
  rootcheck
  get_timestamp
  echo "$timestamp npm update" | tee -a "$logfile"
  watchdog npm update -g || exit 6
}

watchdog() {
  local cmd=("$@")

  (sleep ${warntime%s} && get_timestamp && echo "$timestamp Warning, 10s left before the script will be stopped" | tee -a "$logfile") &
  local warn_pid=$!

  if ! timeout "$deathtime" "${cmd[@]}"; then
    get_timestamp
    echo "$timestamp Watchdog was reached, script will be stopped" | tee -a "$logfile"
    exit 124
  fi

  kill "$warn_pid" 2>/dev/null
}

# Main

get_timestamp
rootcheck
logging
lckcheck
uppacman
upyay
upnpm

trap handling EXIT
