#!/usr/bin/env bash
# Script: nas_setup.sh
# Author: tobil
# Date: 2026-01-25_20:44:28
# License: MIT
# Description: Setup NAS with Samba shares
# Version: v1.0

# Variables
user=${SUDO_USER:-$(whoami)}
group=$(groups | awk '{print $1}')
WAN_IF="eno1"
LAN_WLAN="wlan0"
LAN_IP="10.10.10.100/24"

# Logfile
logfile="/home/$user/logging/install.log"
logpath="/home/$user/logging/"

# Get timestamp
get_timestamp() {
  timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
}

# Initialize logging
logging() {
  get_timestamp
  if [[ -f "$logfile" ]]; then
    echo "$timestamp Logfile exists" | tee -a "$logfile"
  else
    mkdir -p "$logpath"
    touch "$logfile"
    echo "$timestamp Logfile created" | tee -a "$logfile"
  fi
}

log() {
  get_timestamp
  echo "$timestamp $*" | tee -a "$logfile"
}

# Error handling
handling() {
  local error="$1"
  get_timestamp
  case $error in
    0) log "Script completed successfully" ;;
    1)
      log "Directory error"
      exit 1
      ;;
    2)
      log "Logfile error"
      exit 2
      ;;
    *)
      log "Unknown error: $error"
      exit "$error"
      ;;
  esac
}

trap 'handling $?' EXIT

deactivated() {
  log "Stopping services"
  sudo systemctl stop smb nmb || true
}

activated() {
  log "Setting fixed IP"
  sudo ip addr add "$LAN_IP" dev "$WAN_IF" || true
  sudo ip link set "$WAN_IF" up
  sudo ip link set "$LAN_WLAN" up

  log "Starting services"
  sudo systemctl daemon-reload
  sudo systemctl enable --now smb nmb
}

installprog() {
  log "Installing packages"
  needed=("samba" "gvfs-smb")
  sudo pacman -S --needed --noconfirm "${needed[@]}"
}

samba() {
  log "Configuring Samba"
  sudo tee /etc/samba/smb.conf <<EOF
[global]
workgroup = WORKGROUP
server string = NAS Shares
security = user
map to guest = bad user
guest account = nobody
usershare allow guests = yes

[bunga]
path = /mnt/bunga
browseable = yes
writable = yes
guest ok = yes
read only = no
force user = $user
force group = tobil
create mask = 0664
directory mask = 0775

[root]
path = /
browseable = yes
writable = yes
guest ok = yes
read only = no
force user = $user
force group = tobil
create mask = 0664
directory mask = 0775

[home]
path = /home
browseable = yes
writable = yes
guest ok = yes
read only = no
force user = $user
force group = tobil
create mask = 0664
directory mask = 0775
EOF
  sudo systemctl enable --now smb nmb
}

logging
deactivated
#installprog
#samba
activated
