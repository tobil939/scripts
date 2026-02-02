```bash
#!/usr/bin/env bash
# router-complete-v8.sh – idempotent, robust headless router + NAS (Arch Linux)
set -euo pipefail
user=$(whoami)
group=$(id -gn)
WAN_IF="eno1"
LAN_ETH="enp7s0"
LAN_WLAN="wlan0"
LAN_IP="10.10.10.1/24"
DHCP_RANGE="10.10.10.50,10.10.10.250,12h"
SSID="bunga"
WPA_PASS="bungahart"
COUNTRY_CODE="DE"
logfile="$HOME/logging/router-setup.log"
mkdir -p "$(dirname "$logfile")"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$logfile"; }
log "=== Router-Setup Start ==="
### Pakete (nur notwendig, headless)
log "Pakete installieren"
needed=(iw iptables-nft hostapd dnsmasq dhcpcd samba)
for pkg in "${needed[@]}"; do pacman -Q "$pkg" &>/dev/null || sudo pacman -S --noconfirm "$pkg"; done
### WLAN freischalten
log "WLAN freischalten"
rfkill unblock wifi 2>/dev/null || true
### NetworkManager deaktivieren
log "NetworkManager deaktivieren"
sudo systemctl disable --now NetworkManager 2>/dev/null || true
### IP Forwarding
log "IP Forwarding aktivieren"
sudo tee /etc/sysctl.d/99-ipforward.conf <<< "net.ipv4.ip_forward=1"
sudo sysctl --system
### dhcpcd auf WAN begrenzen
log "dhcpcd konfigurieren"
sudo tee /etc/dhcpcd.conf <<< "denyinterfaces br0 $LAN_ETH $LAN_WLAN"
### Bridge
log "Bridge konfigurieren"
ip link show br0 &>/dev/null || sudo ip link add br0 type bridge
sudo ip link set br0 up
sudo ip link set "$LAN_ETH" up
sudo ip link set "$LAN_ETH" master br0 2>/dev/null || true
sudo ip addr flush dev br0 2>/dev/null || true
sudo ip addr add "$LAN_IP" dev br0
### NAT + Forwarding (idempotent)
log "iptables NAT & Forwarding"
iptables -t nat -C POSTROUTING -o "$WAN_IF" -j MASQUERADE 2>/dev/null || sudo iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE
iptables -C FORWARD -i "$WAN_IF" -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || sudo iptables -A FORWARD -i "$WAN_IF" -o br0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -C FORWARD -i br0 -o "$WAN_IF" -j ACCEPT 2>/dev/null || sudo iptables -A FORWARD -i br0 -o "$WAN_IF" -j ACCEPT
sudo mkdir -p /etc/iptables
sudo iptables-save > /etc/iptables/iptables.rules
sudo systemctl enable --now iptables
### WAN DHCP
log "WAN hochfahren + DHCP"
sudo ip link set "$WAN_IF" up
sudo systemctl enable --now "dhcpcd@$WAN_IF"
### dnsmasq
log "dnsmasq konfigurieren"
sudo tee /etc/dnsmasq.conf <<EOF
interface=br0
bind-interfaces
dhcp-range=$DHCP_RANGE
domain-needed
bogus-priv
log-dhcp
EOF
sudo systemctl enable --now dnsmasq
### WLAN + Bridge
log "WLAN aktivieren & bridgen"
sudo ip link set "$LAN_WLAN" up
sudo ip link set "$LAN_WLAN" master br0 2>/dev/null || true
### Samba-Shares
log "Samba konfigurieren"
sudo tee /etc/samba/smb.conf <<EOF
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
### Btrfs-Subvolumes & Mounts (UUIDs anpassen!)
log "Btrfs-Subvolumes & Mounts einrichten"
sudo btrfs subvolume show /router1 2>/dev/null || sudo btrfs subvolume create /router1
sudo btrfs subvolume show /router2 2>/dev/null || sudo btrfs subvolume create /router2
sudo mkdir -p /router1 /router2
# UUIDs durch echte ersetzen, z.B. via blkid
grep -q router1 /etc/fstab || echo "UUID=<real-uuid> /router1 btrfs subvol=router1,defaults 0 2" | sudo tee -a /etc/fstab
grep -q router2 /etc/fstab || echo "UUID=<real-uuid> /router2 btrfs subvol=router2,defaults 0 2" | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo mount -a
sudo chown -R "$user:$group" /router1 /router2
sudo chmod -R 775 /router1 /router2
sudo systemctl enable --now smb nmb
### hostapd
log "hostapd konfigurieren"
sudo tee /etc/hostapd/hostapd.conf <<EOF
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
sudo tee /etc/conf.d/hostapd <<< 'DAEMON_CONF="/etc/hostapd/hostapd.conf"'
### systemd-Override
log "hostapd systemd-Override"
sudo mkdir -p /etc/systemd/system/hostapd.service.d
sudo tee /etc/systemd/system/hostapd.service.d/override.conf <<EOF
[Unit]
BindsTo=sys-subsystem-net-devices-$LAN_WLAN.device
After=sys-subsystem-net-devices-$LAN_WLAN.device
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now hostapd
log "=== Fertig. Reboot empfohlen. ==="
```
