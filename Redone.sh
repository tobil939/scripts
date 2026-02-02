#!/usr/bin/env bash
# router-complete-v7.sh – idempotent, robust (Arch Linux)

user=$(whoami)
group=$(groups | awk '{print $1}')

drive1="sda"
drive2="nvme0n1"
UUID1=$(lsblk -f | grep -E '$drive1*|btrfs' | awk '{print $3}')
UUID2=$(lsblk -f | grep -E '$drive2*|btrfs' | awk '{print $3}')

WAN_IF="eno1"
LAN_ETH="enp7s0"
LAN_WLAN="wlan0"

LAN_IP="10.10.10.1/24"
DHCP_RANGE="10.10.10.50,10.10.10.250,12h"

SSID="bunga"
WPA_PASS="bungahart"
COUNTRY_CODE="DE"

loggin() {
  logfile="$HOME/logging/router-setup.log"
  mkdir -p "$(dirname "$logfile")"
  touch "$HOME/logging/router-setup.log"

  log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$logfile"; }

  log "=== Router-Setup Start ==="
}

handling() {
  local error="$1"
  case $error in
    0) echo "everything is good" ;;
    1) echo "stopping services went wronge" ;;
    2) echo "can not install yay" ;;
    3) echo "can not install programs" ;;
    4) echo "can not activated wifi" ;;
    5) echo "can not forward ip" ;;
    6) echo "can not set to bridge" ;;
    *) echo "" ;;
  esac
}

deactivated() {
  log "stopping services"
  log "stop NetworkManager"
  sudo systemctl disable --now NetworkManager || exit 1
  log "stop iptables"
  sudo systemctl stop iptables || exit 1
  log "stop dhcpcd"
  sudo systemctl stop "dhcpcd@$WAN_IF" || exit 1
  log "stop dnsmasq"
  sudo systemctl stop dnsmasq || exit 1
  log "stop daemon-reload"
  sudo systemctl stop daemon-reload || exit 1
  log "stop hostapd"
  sudo systemctl stop hostapd || exit 1
  log "stop smb"
  sudo systemctl stop smb || exit 1
  log "stop nmb"
  sudo systemctl stop nmb || exit 1
}

installprog() {
  log "Pakete installieren"
  needed=(
    "network-manager-applet"
    "fzf"
    "polkit"
    "qutebrowser"
    "pavucontrol"
    "kitty"
    "samba"
    "libreoffice-still"
    "gtk3"
    "gtk4"
    "copyq"
    "ddcutil"
    "bluez"
    "bluez-utils"
    "python"
    "python3"
    "python-debugpy"
    "python-pip"
    "blueman"
    "evolution"
    "nautilus"
    "lxappearance"
    "gedit"
    "ttf-meslo-nerd"
    "picom"
    "feh"
    "iw"
    "iptables-nft"
    "hostapd"
    "dnsmasq"
    "dhcpcd"
  )

  log "yay will be installed"
  sudo pacman -S --needed --noconfirm git base-devel
  if [[ ! -d "yay" ]]; then
    sudo -u "$user" git clone https://aur.archlinux.org/yay.git
    cd yay || exit 2
    sudo -u "$user" makepkg -si --noconfirm --needed || exit 2
    cd "$user" || exit 2
  fi

  log "install programs"
  for prog in "${needed[@]}"; do
    log "$prog will be installed"
    yay -S "$prog" --needed --noconfirm || exit 3
  done

  log "update yay"
  yay -Syu --noconfirm || exit 3
}

log "set up bashrc"
cat >>"$user/.bashrc" <<'HERE' || exit 3
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '
#export GREP_COLORS='mt=1;35'
#export LS_COLORS="di=1;35:fi=0:ln=36"

alias grep='grep --color=auto'
alias ls='ls --color=auto'
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

  local data
  local path
  local file
  local oldpath

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
    mkdir -p "$path"
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
    mkdir -p "$logpath" || { echo "$timestamp Failed to create logpath" | tee -a "$logfile"; exit 1; }
    touch "$logfile" || { echo "$timestamp Failed to create logfile" | tee -a "$logfile"; exit 2; }
    echo "$timestamp Logfile created" | tee -a "$logfile"
  fi
}

# Fehlerbehandlung
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
export PATH="/home/tobil/.pixi/bin:$PATH"
HERE

### WLAN freischalten (nicht aggressiv!)
log "WLAN freischalten"
rfkill unblock wifi || exit 4

### IP Forwarding
log "IP Forwarding aktivieren"
cat <<EOF >/etc/sysctl.d/99-ipforward.conf
net.ipv4.ip_forward=1
EOF
sysctl --system || exit 5

### dhcpcd auf WAN begrenzen
log "dhcpcd konfigurieren"
cat <<EOF >/etc/dhcpcd.conf
denyinterfaces br0
denyinterfaces $LAN_ETH
denyinterfaces $LAN_WLAN
EOF

### Bridge
log "Bridge konfigurieren"
ip link show br0 &>/dev/null || ip link add br0 type bridge
ip link set br0 up

ip link set "$LAN_ETH" up
ip link set "$LAN_ETH" master br0 || exit 6

ip addr flush dev br0 || exit 6
ip addr replace "$LAN_IP" dev br0

### NAT + Forwarding (idempotent)
log "iptables NAT & Forwarding"
iptables -t nat -C POSTROUTING -o "$WAN_IF" -j MASQUERADE 2>/dev/null \
  || iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE

iptables -C FORWARD -i "$WAN_IF" -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null \
  || iptables -A FORWARD -i "$WAN_IF" -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT

iptables -C FORWARD -i br0 -o "$WAN_IF" -j ACCEPT 2>/dev/null \
  || iptables -A FORWARD -i br0 -o "$WAN_IF" -j ACCEPT

mkdir -p /etc/iptables
iptables-save >/etc/iptables/iptables.rules

systemctl enable --now iptables

### WAN DHCP
log "WAN hochfahren + DHCP"
ip link set "$WAN_IF" up
systemctl enable --now "dhcpcd@$WAN_IF"

### dnsmasq
log "dnsmasq konfigurieren"
cat <<EOF >/etc/dnsmasq.conf
interface=br0
bind-interfaces
dhcp-range=$DHCP_RANGE
domain-needed
bogus-priv
log-dhcp
EOF

systemctl enable --now dnsmasq

### WLAN + Bridge
log "WLAN aktivieren & bridgen"
ip link set "$LAN_WLAN" up
ip link set "$LAN_WLAN" master br0 || exit 7

### Samba-Shares (router1 + router2)
sudo cat <<EOF >/etc/samba/smb.conf
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

log "Btrfs-Subvolumes & Mounts einrichten"
sudo btrfs subvolume show /router1 2>/dev/null || sudo btrfs subvolume create /router1
sudo btrfs subvolume show /router2 2>/dev/null || sudo btrfs subvolume create /router2
sudo mkdir -p /router1 /router2

grep -q router1 /etc/fstab || echo "$UUID1 /router1 btrfs subvol=router1,defaults 0 2" | sudo tee -a /etc/fstab
grep -q router2 /etc/fstab || echo "$UUID2 /router2 btrfs subvol=router2,defaults 0 2" | sudo tee -a /etc/fstab

sudo systemctl daemon-reload
sudo mount -a

sudo chown -R "$user":"$group" /router1
sudo chown -R "$user":"$group" /router1
sudo chmod -R 775 /router1
sudo chmod -R 775 /router2

sudo systemctl enable --now smb
sudo systemctl enable --now nmb

### hostapd
log "hostapd konfigurieren"
cat <<EOF >/etc/hostapd/hostapd.conf
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

echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' >/etc/conf.d/hostapd

### systemd-Override für WLAN-Device
log "hostapd systemd-Override"
mkdir -p /etc/systemd/system/hostapd.service.d
cat <<EOF >/etc/systemd/system/hostapd.service.d/override.conf
[Unit]
BindsTo=sys-subsystem-net-devices-$LAN_WLAN.device
After=sys-subsystem-net-devices-$LAN_WLAN.device
EOF

sudo chown -R "$user":"$group" /router1
sudo chown -R "$user":"$group" /router2

systemctl daemon-reload
systemctl enable --now hostapd

echo "cleaning up"
yay -Ycc

log "=== Fertig. Reboot empfohlen. ==="
