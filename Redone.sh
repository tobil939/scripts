#!/usr/bin/env bash
# Script: Redone.sh
# Author: tobil / grok
# Date: 2026-02-02
# License: MIT
# Description: Installation script for setting up router on Arch Linux (not Rocky)
# Version: v9.0
### Variables

fullname=$PWD
user=${PWD#/home/}
group=$(groups | awk '{print $1}')
drive1="zram0"
drive2="nvme0n1p2" # Fixed typo
UUID1=$(lsblk -f | grep "$drive1" | awk '{print $1}')
UUID2=$(lsblk -f | grep "$drive2" | awk '{print $1}')
WAN_IF="eno1"
LAN_ETH="enp7s0"
LAN_WLAN="wlp5s0"
LAN_IP="10.10.10.1/24"
DHCP_RANGE="10.10.10.50,10.10.10.250,12h"
SSID="bunga"
WPA_PASS="bungahart"
COUNTRY_CODE="DE"
needed=(
  "neovim"
  "less"
  "htop"
  "openssh"
  "fzf"
  "hostapd"
  "dnsmasq"
  "dhcpcd"
  "samba"
)
logfile="$HOME/logging/router-setup.log"
mkdir -p "$(dirname "$logfile")"
### Get timestamp
get_timestamp() {
  timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
}
### Logging
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
      log "Problems installing progs"
      exit 1
      ;;
    2)
      log "Logfile error"
      exit 2
      ;;
    3)
      log "Problems with logging"
      exit 3
      ;;
    4)
      log "Cannot set up WLAN"
      exit 4
      ;;
    5)
      log "Cannot bridge WLAN"
      exit 5
      ;;
    6)
      log "Cannot set forwarding IP"
      exit 6
      ;;
    7)
      log "Cannot configure dhcpcd"
      exit 7
      ;;
    8)
      log "Cannot configure bridge"
      exit 8
      ;;
    9)
      log "Cannot set NAT/Forwarding"
      exit 9
      ;;
    10)
      log "Cannot start WAN DHCP"
      exit 10
      ;;
    11)
      log "Cannot configure dnsmasq"
      exit 11
      ;;
    12)
      log "Cannot bridge WLAN"
      exit 12
      ;;
    13)
      log "Cannot configure Samba"
      exit 13
      ;;
    14)
      log "Cannot setup Btrfs"
      exit 14
      ;;
    15)
      log "Cannot configure hostapd"
      exit 15
      ;;
    16)
      log "Cannot override systemd"
      exit 16
      ;;
    *)
      log "Unknown error: $error"
      exit "$error"
      ;;
  esac
}
deactivated() {
  log "Stopping services"
  sudo systemctl disable --now NetworkManager || true
  sudo systemctl stop iptables || true
  sudo systemctl stop "dhcpcd@$WAN_IF" || true
  sudo systemctl stop dnsmasq || true
  sudo systemctl stop hostapd || true
  sudo systemctl stop smb || true
  sudo systemctl stop nmb || true
  sudo systemctl stop sshd || true
}
activated() {
  log "Starting network cards"
  sudo ip link add br0 type bridge || true
  sudo ip link set "$LAN_ETH" up
  sudo ip link set "$LAN_ETH" master br0
  sudo ip link set "$LAN_WLAN" up
  sudo iw dev "$LAN_WLAN" set 4addr on || true
  sudo ip link set "$LAN_WLAN" master br0
  sudo ip link set br0 up
  sudo ip addr flush dev br0 || true
  sudo ip addr add "$LAN_IP" dev br0
  log "Starting services"
  sudo systemctl disable --now NetworkManager || true
  sudo systemctl start iptables || true
  sudo systemctl start "dhcpcd@$WAN_IF" || true
  sudo systemctl start dnsmasq || true
  sudo systemctl start hostapd || true
  sudo systemctl start smb || true
  sudo systemctl start nmb || true
  sudo systemctl start sshd || true
}
### Pakete
installprog() {
  log "Installing base-devel and git"
  sudo pacman -S --needed --noconfirm base-devel git || exit 1
  if ! command -v yay &>/dev/null; then
    git clone https://aur.archlinux.org/yay.git || exit 1
    cd yay || exit 1
    makepkg -si --noconfirm || exit 1
    cd .. || exit 1
  fi
  for prog in "${needed[@]}"; do
    log "Installing $prog"
    yay -S --needed --noconfirm "$prog" || exit 1
  done
  yay -Syu --noconfirm || exit 1
}
### Cleanup
cleanup() {
  log "Cleaning up"
  yay -Ycc --noconfirm || true
}
### Creating bashrc
bashing() {
  log "Setting up bashrc"
  cat >>"$HOME/.bashrc" <<'HERE'
# ~/.bashrc
[[ $- != *i* ]] && return
alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
alias sl='ls -lh --color=auto'
fuzzy() {
  local file
  file=$(find . -type f | fzf --preview 'cat {}' --height 80% --border)
  [[ -n "$file" ]] && nvim "$file"
}
greppy() {
  local file=$(find . -type f | fzf --preview "grep -i --color=always {q} {} | head -n 20" --bind "change:reload:find . -type f")
  [[ -n "$file" ]] && nvim "$file" +/{q}
}
trs() {
  for file in "$@"; do
    filename=$(basename "$file")
    mv "$file" /tmp/"$filename"
  done
}
bashing() {
  local data path file oldpath
  oldpath=$(pwd)
  data="$1"
  [[ -z "$data" ]] && exit 91
  handling() {
    local error="$1"
    case $error in
      0) echo "completed successfully" ;;
      88) echo "can't change into directory" ;;
      89) echo "can't create file" ;;
      90) echo "can't make it executable" ;;
      91) echo "no filename" ;;
      *) echo "unknown error" ;;
    esac
  }
  trap 'handling $?' EXIT
  file=$(basename "$data")
  path=$(dirname "$data")
  if [[ -d "$path" ]]; then
    cd "$path" || exit 88
    [[ -f "$file" ]] && trs "$file"
    touch "$file" || exit 89
    chmod +x "$file" || exit 90
    ls -lh
  else
    mkdir -p "$path" || exit 88
    cd "$path" || exit 88
    touch "$file" || exit 89
    chmod +x "$file" || exit 90
    ls -lh
  fi
  cat <<EOF >"$file"
#!/usr/bin/env bash
# Script: $file
# Author: $(whoami)
# Date: $(date +"%Y-%m-%d_%H:%M:%S")
# License: MIT
# Description: ....
EOF
  cat <<'EOF' >>"$file"
# Logfile
logfile="$HOME/logging/logfile.log"
logpath="$HOME/logging/"
get_timestamp() {
  timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
}
logging() {
  get_timestamp
  echo "$timestamp Log path: $logpath" | tee -a "$logfile"
  echo "$timestamp Log file: $logfile" | tee -a "$logfile"
  if [[ -f "$logfile" ]]; then
    echo "$timestamp Logfile exists" | tee -a "$logfile"
  else
    mkdir -p "$logpath" || { echo "$timestamp Failed to create logpath" | tee -a "$logfile"; exit 1; }
    touch "$logfile" || { echo "$timestamp Failed to create logfile" | tee -a "$logfile"; exit 2; }
    echo "$timestamp Logfile created" | tee -a "$logfile"
  fi
}
handling() {
  local error="$1"
  get_timestamp
  case $error in
    0) echo "$timestamp Script completed successfully" | tee -a "$logfile";;
    1) echo "$timestamp Directory error" | tee -a "$logfile"; exit 1;;
    2) echo "$timestamp Logfile error" | tee -a "$logfile"; exit 2;;
    4) echo "$timestamp nvim not installed" | tee -a "$logfile"; exit 4;;
    *) echo "$timestamp Unknown error: $error" | tee -a "$logfile"; exit "$error";;
  esac
}
trap 'handling $?' EXIT
EOF
  cd "$oldpath" || exit 88
}
HERE
}
### SSH
sshing() {
  log "Enabling SSH"
  sudo systemctl enable --now sshd || exit 4
}
### WLAN freischalten
wlan() {
  log "WLAN freischalten"
  rfkill unblock wifi 2>/dev/null || exit 4
}
### NetworkManager deaktivieren
networkdeac() {
  log "NetworkManager deaktivieren"
  sudo systemctl disable --now NetworkManager 2>/dev/null || exit 4
}
### IP Forwarding
forwarding() {
  log "IP Forwarding aktivieren"
  sudo tee /etc/sysctl.d/99-ipforward.conf <<<"net.ipv4.ip_forward=1" || exit 6
  sudo sysctl --system || exit 6
}
### dhcpcd auf WAN begrenzen
dhcp() {
  log "dhcpcd konfigurieren"
  sudo tee /etc/dhcpcd.conf <<<"denyinterfaces br0 $LAN_ETH $LAN_WLAN" || exit 7
}
### Bridge
bridge() {
  log "Bridge konfigurieren"
  ip link show br0 &>/dev/null || sudo ip link add br0 type bridge || exit 8
  sudo ip link set br0 up || exit 8
  sudo ip link set "$LAN_ETH" up || exit 8
  sudo ip link set "$LAN_ETH" master br0 2>/dev/null || exit 8
  sudo ip addr flush dev br0 2>/dev/null || exit 8
  sudo ip addr add "$LAN_IP" dev br0 || exit 8
}
### NAT + Forwarding
nat() {
  log "iptables NAT & Forwarding"
  iptables -t nat -C POSTROUTING -o "$WAN_IF" -j MASQUERADE 2>/dev/null || sudo iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE || exit 9
  iptables -C FORWARD -i "$WAN_IF" -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || sudo iptables -A FORWARD -i "$WAN_IF" -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT || exit 9
  iptables -C FORWARD -i br0 -o "$WAN_IF" -j ACCEPT 2>/dev/null || sudo iptables -A FORWARD -i br0 -o "$WAN_IF" -j ACCEPT || exit 9
  sudo mkdir -p /etc/iptables || exit 9
  sudo iptables-save >/etc/iptables/iptables.rules || exit 9
  sudo systemctl enable --now iptables || exit 9
}
### WAN DHCP
wandhcp() {
  log "WAN hochfahren + DHCP"
  sudo ip link set "$WAN_IF" up || exit 10
  sudo systemctl enable --now "dhcpcd@$WAN_IF" || exit 10
}
### dnsmasq
dnsmasq() {
  log "dnsmasq konfigurieren"
  sudo tee /etc/dnsmasq.conf <<EOF || exit 11
interface=br0
bind-interfaces
dhcp-range=$DHCP_RANGE
domain-needed
bogus-priv
log-dhcp
EOF
  sudo systemctl enable --now dnsmasq || exit 11
}
### WLAN + Bridge
wlanbridge() {
  log "WLAN aktivieren & bridgen"
  sudo ip link set "$LAN_WLAN" up || exit 12
  sudo ip link set "$LAN_WLAN" master br0 2>/dev/null || exit 12
}
### Samba-Shares
samba() {
  log "Samba konfigurieren"
  sudo tee /etc/samba/smb.conf <<EOF || exit 13
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
force user = $user
force group = $group
create mask = 0644
directory mask = 0775
[router2]
path = /router2
browseable = yes
writable = yes
guest ok = yes
read only = no
force user = $user
force group = $group
create mask = 0644
directory mask = 0775
EOF
}
### Btrfs-Subvolumes & Mounts
btrfssetup() {
  log "Btrfs-Subvolumes & Mounts einrichten"
  sudo btrfs subvolume show /router1 2>/dev/null || sudo btrfs subvolume create /router1 || exit 14
  sudo btrfs subvolume show /router2 2>/dev/null || sudo btrfs subvolume create /router2 || exit 14
  sudo mkdir -p /router1 /router2 || exit 14
  grep -q router1 /etc/fstab || echo "UUID=$UUID1 /router1 btrfs subvol=router1,defaults 0 2" | sudo tee -a /etc/fstab || exit 14
  grep -q router2 /etc/fstab || echo "UUID=$UUID2 /router2 btrfs subvol=router2,defaults 0 2" | sudo tee -a /etc/fstab || exit 14
  sudo systemctl daemon-reload || exit 14
  sudo mount -a || exit 14
  sudo chown -R "$user:$group" /router1 /router2 || exit 14
  sudo chmod -R 775 /router1 /router2 || exit 14
  sudo systemctl enable --now smb nmb || exit 14
}
### hostapd
hostapd() {
  log "hostapd konfigurieren"
  sudo tee /etc/hostapd/hostapd.conf <<EOF || exit 15
interface=$LAN_WLAN
bridge=br0
driver=nl80211
ssid=$SSID
country_code=$COUNTRY_CODE
ieee80211d=1
hw_mode=g
channel=6
wmm_enabled=1
ieee80211n=1
ht_capab=[HT40+][SHORT-GI-20][SHORT-GI-40]
auth_algs=1
macaddr_acl=0
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$WPA_PASS
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
rsn_pairwise=CCMP
wpa_disable_eapol_key_retries=1
EOF
  sudo tee /etc/conf.d/hostapd <<<'DAEMON_CONF="/etc/hostapd/hostapd.conf"' || exit 15
}
### systemd-Override
systemdover() {
  log "hostapd systemd-Override"
  sudo mkdir -p /etc/systemd/system/hostapd.service.d || exit 16
  sudo tee /etc/systemd/system/hostapd.service.d/override.conf <<EOF || exit 16
[Unit]
BindsTo=sys-subsystem-net-devices-$LAN_WLAN.device
After=sys-subsystem-net-devices-$LAN_WLAN.device
EOF
  sudo systemctl daemon-reload || exit 16
  sudo systemctl enable --now hostapd || exit 16
}
trap 'handling $?' EXIT
log "=== Router-Setup Start ==="
deactivated
installprog
bashing
sshing
wlan
networkdeac
forwarding
dhcp
bridge
nat
wandhcp
dnsmasq
wlanbridge
samba
btrfssetup
hostapd
systemdover
activated
cleanup
log "=== Fertig. Reboot empfohlen. ==="
