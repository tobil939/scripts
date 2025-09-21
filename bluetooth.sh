#!/bin/bash

# bash-script for initialisation of bluetooth devices
# rev. 2.0
# includes basic error handling and improved messages

# logging
# place where the logfile will be saved
logfile="/var/log/bluetooth.log"

# timestamp
get_timestamp() {
  timestamp=$(date +"%Y-%m-%d_%h:%m:%s")
}

logging() {
  if [[ -f "$logfile" ]]; then
    echo "logfile exists"
  else
    echo "logfile will be created"
    touch "$logfile" || exit 1
  fi

  get_timestamp
  [[ -f "$logfile" ]] || exit 1
  echo "$timestamp first entry" | tee -a "$logfile" || exit 1
}

# errorhandling
# better errormessages
handling() {
  local error
  error="$?"
  get_timestamp
  case $error in
  0) (
    echo "$timestamp everything went as planned, no errors" | tee -a "$logfile"
    echo "$timestamp logfile will be moved into /tmp" | tee -a "$logfile"
    mv -v "$logfile" "/tmp/bluetooth.log"
  ) ;;
  1) echo "$timestamp failed to create or access logfile" | tee -a "$logfile" ;;
  2) echo "$timestamp must be run as root or with sudo!" | tee -a "$logfile" ;;
  3) echo "$timestamp can't start the bluetooth service" | tee -a "$logfile" ;;
  4) echo "$timestamp can't enable the bluetooth service" | tee -a "$logfile" ;;
  *) echo "$timestamp unknown error" | tee -a "$logfile" ;;
  esac
}

# root
# checking if it was started with sudo
rootcheck() {
  get_timestamp
  if [[ $UID -ne 0 ]]; then
    exit 2
  fi
}

# bluetooth
# starting service and enable it
blue() {
  get_timestamp
  systemctl start bluetooth.service || exit 3
  get_timestamp
  systemctl enable bluetooth.service || exit 4
}

# main
logging
rootcheck
blue

trap handling EXIT
