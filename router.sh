#!/usr/bin/env bash
# Script: router-complete.sh
# Author: tobil
# Date: 2026-01-20
# License: MIT
# Description: Router + Samba Shares Setup (einmalig ausführen)

set -e

logfile="$HOME/logging/router-setup.log"
logpath="$HOME/logging/"

# Logging-Funktionen
get_timestamp() { date +"%Y-%m-%d_%H:%M:%S"; }

log() {
  local ts=$(get_timestamp)
  echo "$ts $*" | tee -a "$logfile"
}

mkdir -p "$logpath" 2>/dev/null
touch "$logfile" 2>/dev/null || { echo "Kann Log nicht erstellen"; exit 1; }

# Pakete
needed=(iw iptables bridge-utils hostapd dnsmasq dhcpcd samba)

# Hauptfunktionen
install_packages() {
  log "Installiere Pakete..."
  for pkg in "${needed[@]}"; do
    yay -S --noconfirm "$pkg" || pacman -S --noconfirm "$pkg" || { log "Fehler bei $pkg"; exit 5; }
  done
}

enable_ip_forward() {
  log "Aktiviere IP-Forwarding (dauerhaft)"
  echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-ipforward.conf
  sudo sysctl --system
}

setup_bridge() {
  log "Bridge einrichten"
  ip link set enp7s0 down 2>/dev/null || true
  ip link set wlan0 down 2>/dev/null || true
  iw dev wlan0 set type managed 2>/dev/null || true

  ip link add name br0 type bridge || true
  ip link set enp7s0 master br0
  ip link set wlan0 master br0
  ip link set br0 up
  ip link set enp7s0 up
  ip addr add 10.10.10.1/24 dev br0
}

setup_nat() {
  log "NAT + Forwarding-Regeln"
  iptables -t nat -F POSTROUTING
  iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE
  iptables -A FORWARD -i eno1 -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables -A FORWARD -i br0 -o eno1 -j ACCEPT
}

setup_dnsmasq() {
  log "dnsmasq konfigurieren"
  cat <<EOF | sudo tee /etc/dnsmasq.conf
interface=br0
dhcp-range=10.10.10.10,10.10.10.15,12h
EOF
  sudo systemctl enable --now dnsmasq
}

setup_hostapd() {
  log "hostapd konfigurieren"
  cat <<EOF | sudo tee /etc/hostapd/hostapd.conf
interface=wlan0
driver=nl80211
ssid=bunga
channel=6
hw_mode=g
wpa=2
wpa_passphrase=bungahart
wmm_enabled=1
ieee80211n=0
ignore_broadcast_ssid=0
bridge=br0
macaddr_acl=0
auth_algs=1
EOF
  sudo systemctl enable --now hostapd
}

setup_samba_shares() {
  log "Samba Shares einrichten"

  sudo btrfs subvolume show /router1 2>/dev/null || sudo btrfs subvolume create /router1
  sudo btrfs subvolume show /router2 2>/dev/null || sudo btrfs subvolume create /router2

  sudo mkdir -p /router1 /router2

  grep -q router1 /etc/fstab || echo "UUID=22bb2f09-87fe-45c8-a68b-678d699dab19 /router1 btrfs subvol=router1,defaults 0 2" | sudo tee -a /etc/fstab
  grep -q router2 /etc/fstab || echo "UUID=652b1234-dae7-45e3-a349-a551cc1ee217 /router2 btrfs subvol=router2,defaults 0 2" | sudo tee -a /etc/fstab

  sudo systemctl daemon-reload
  sudo mount -a || log "mount -a fehlgeschlagen"

  sudo chown -R tobil:tobil /router1 /router2
  sudo chmod -R 775 /router1 /router2

  cat <<EOF | sudo tee /etc/samba/smb.conf
[global]
   workgroup = WORKGROUP
   server string = Router Shares
   security = user
   map to guest = bad user
   usershare allow guests = yes

[router1]
   path = /router1
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no

[router2]
   path = /router2
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
EOF

  sudo systemctl enable --now smb nmb

  if command -v firewall-cmd &>/dev/null; then
    log "Firewall: Samba freigeben"
    sudo firewall-cmd --permanent --add-service=samba
    sudo firewall-cmd --reload
  fi
}

# Ausführung
log "=== Router + Samba Setup Start ==="
install_packages
enable_ip_forward
setup_bridge
setup_nat
setup_dnsmasq
setup_hostapd
setup_samba_shares
log "=== Setup abgeschlossen ==="
