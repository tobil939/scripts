#!/usr/bin/env bash
# Script: router.sh
# Author: tobil
# Date: 2026-01-19_21:37:35
# License: MIT
# Description: installing script for my router PC
# The router haste two networks, outside from the prowider and the inside home network

# Logfile
logfile="$HOME/logging/logfile.log"
logpath="$HOME/logging/"

# Needed Programs
needed=(
  "iptables"
  "bridge-utils"
  "hostapd"
  "dnsmasq"
  "dhcpcd"
)

# Zeitstempel holen
get_timestamp() {
  timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
}

# Logging initialisieren
logging() {
  get_timestamp
  echo "$timestamp Log path: $logpath" | tee -a "$logfile"
  echo "$timestamp Log file: $logfile" | tee -a "$logfile"

  # Logfile pruefen/erstellen
  if [[ -f "$logfile" ]]; then
    get_timestamp
    echo "$timestamp Logfile exists" | tee -a "$logfile"
  else
    get_timestamp
    echo "$timestamp Creating logfile" | tee -a "$logfile"
    mkdir -p "$logpath" || {
      echo "$timestamp Failed to create logpath" | tee -a "$logfile"
      exit 1
    }
    touch "$logfile" || {
      echo "$timestamp Failed to create logfile" | tee -a "$logfile"
      exit 2
    }
    echo "$timestamp Logfile created" | tee -a "$logfile"
  fi
}

# Fehlerbehandlung
handling() {
  local error="$1"
  get_timestamp
  case $error in
    0) echo "$timestamp Script completed successfully" | tee -a "$logfile" ;;
    1) echo "$timestamp Directory error" | tee -a "$logfile" ;;
    2) echo "$timestamp Logfile error" | tee -a "$logfile" ;;
    4) echo "$timestamp nvim not installed" | tee -a "$logfile" ;;
    5) echo "$timestamp problems installing" | tee -a "$logfile" ;;
    6) echo "$timestamp problems forwarding the ip" | tee -a "$logfile" ;;
    7) echo "$timestamp can't start the DNS Server" | tee -a "$logfile" ;;
    8) echo "$timestamp can't starting the DHCP" | tee -a "$logfile" ;;
    9) echo "$timestamp problems updating yay" | tee -a "$logfile" ;;
    10) echo "$timestamp problems cleaning up yay" | tee -a "$logfile" ;;
    *)
      echo "$timestamp Unknown error: $error" | tee -a "$logfile"
      exit "$error"
      ;;
  esac
}

# Installing the needed Programs
install() {
  get_timestamp
  echo "$timestamp installing the needed programms" | tee -a "$logfile"

  for prog in "${needed[@]}"; do
    get_timestamp
    echo "$timestamp installing $prog"
    yay -S --noconfirm "$prog" || exit 5
  done
}

# IP Forwarding
ipforward() {
  get_timestamp
  echo "$timestamp activating IP Forwarding" | tee -a "$logfile"
  echo 1 >/proc/sys/ipv4/ip_forward
  sysctl -w net.ipv4.ip_forward=1 || exit 6
}

# LAN-Bridge setup
bridge() {
  get_timestamp
  echo "$timestamp setting up the LAN-Bridge" | tee -a "$logfile"
  ip link add name br0 type bridge
  ip link set en1 master br0
  ip link set wlan0 master br0
  ip link set br0 up
  ip addr add 10.10.10.1/24 dev br0
}

# NAT with iptables
nattables() {
  get_timestamp
  echo "$timestamp setting up the iptables"
  iptables -t nat -A POSTROUTING -o en0 -j MASQUERADE
  iptables -A FORWARD -i en0 -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables -A FORWARD -i br0 -o en0 -j ACCEPT
}

# DHCP SERVER
dhcpserver() {
  get_timestamp
  echo "$timestamp DHCP Server setup" | tee -a "$logfile"
  cat <<EOF >/etc/dnsmasq.conf
interface=br0 
dhcp-range=10.10.10.10,10.10.10.15,12h
EOF

  echo "$timestamp starting DNSMASQ" | tee -a "$logfile"
  systemctl start dnsmasq || exit 7
}

# WLAN as AP hostapd
hostAP() {
  get_timestamp
  echo "$timestamp setting up the Wlan AP" | tee -a "$logfile"
  cat <<EOF >/etc/hostapd/hostapd.conf
interface=wlan0 
bridge=br0
ssid=bunga
wpa_passphrase=bungahart 
channel=6
hw_mode=g 
EOF

  get_timestamp
  echo "$timestamp starting the Host AP" | tee -a "$logfile"
  systemctl start hostapd
}

# DHCP start
startdhcp() {
  get_timestamp
  echo "$timestamp starting DHCP" | tee -a "$logfile"
  dhcpcd en0 || exit 8
}

# Updating yay
updateyay() {
  get_timestamp
  echo "$timestamp updating yay" | tee -a "$logfile"
  yay -Syu --noconfirm || exit 9
}

# Cleaning up yay
cleanup() {
  get_timestamp
  echo "$timestamp cleaning up" | tee -a "$logfile"
  yay -Ycc --noconfirm || exit 10
}

trap 'handling $?' EXIT

get_timestamp
logging
install
ipforward
bridge
nattables
dhcpserver
hostAP
startdhcp
updateyay
cleanup
