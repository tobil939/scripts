#!/usr/bin/env bash
# Script: rocky.sh
# Author: TOL2ST
# Updated: 2026-01-28
# License: MIT
# Description: Router-PC Setup (Rocky Linux) – Netzwerk + Storage + SMB/NFS + nftables

# ======= Einstellungen =======
# User/Logging
user="${SUDO_USER:-${LOGNAME:-root}}"
userpath="/home/$user"
logpath="$userpath/logging"
logfile="$logpath/logfile.log"#!/usr/bin/env bash
# Script: rocky.sh
# Author: TOL2ST
# Updated: 2026-01-28
# License: MIT
# Description: Router-PC Setup (Rocky Linux) – Netzwerk + Storage + SMB/NFS + nftables

set -euo pipefail

# ======= Einstellungen =======
# User/Logging
user="${SUDO_USER:-${LOGNAME:-root}}"
userpath="/home/$user"
logpath="$userpath/logging"
logfile="$logpath/logfile.log"

# WLAN
wlanname="bunga"
wlanpw="bungahart"

# Netzwerkkarten
wan_card="eno1"
bunga_card="eno2"
wlan_card="wlan1"

# Storage-Ziele (XFS empfohlen)
SDA_DEV="/dev/sda"
SDA_PART="/dev/sda1"
NVME_DEV="/dev/nvme1n1"
NVME_PART="/dev/nvme1n1p5"

MNT1="/router1"   # -> sda1
MNT2="/router2"   # -> nvme1n1p5
FS_TYPE="xfs"     # xfs|ext4

# Netzfreigaben
ENABLE_SAMBA=true
ENABLE_NFS=true

# Samba-User (optional automatisiert anlegen – Passwort hier setzen oder leer lassen)
SMB_USER="router"
SMB_PASS="changeme"   # <<-- ändere das! Wenn leer, wird kein Passwort gesetzt.

# Pakete
needed=(
  "iproute"
  "NetworkManager"
  "iw"
  "wireless-tools"
  "wpa_supplicant"
  "wireless-regdb"
  "tcpdump"
  "nmap"
  "traceroute"
  "nethogs"
  "iftop"
  "ntopng"
  "dnsmasq"
  "hostapd"
  "nftables"
  "parted"
  "xfsprogs"
  "e2fsprogs"
  "nfs-utils"
  "samba"
  "samba-client"
  "policycoreutils-python-utils"  # für semanage (SELinux)
)

# Services
services_base=(
  "NetworkManager"
  "dnsmasq"
  "hostapd"
  "nftables"
)
services_samba=("smb" "nmb")
services_nfs=("nfs-server")

# ======= Helpers =======
get_timestamp() { date +"%Y-%m-%d_%H:%M:%S"; }
log() { echo "$(get_timestamp) $*" | tee -a "$logfile"; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Bitte als root ausführen (sudo)." >&2
    exit 1
  fi
}

prepare_logging() {
  mkdir -p "$logpath"
  touch "$logfile"
  log "Log path: $logpath"
  log "Log file: $logfile"
}

preflight_checks() {
  mkdir -p /etc/NetworkManager/system-connections /etc/NetworkManager/conf.d
  ip link show "$wan_card" >/dev/null 2>&1 || log "WARN: $wan_card nicht gefunden"
  ip link show "$bunga_card" >/dev/null 2>&1 || log "WARN: $bunga_card nicht gefunden"
  ip link show "$wlan_card" >/dev/null 2>&1 || log "WARN: $wlan_card nicht gefunden"
}

disable_firewalld_enable_forwarding() {
  if systemctl is-enabled --quiet firewalld 2>/dev/null || systemctl is-active --quiet firewalld 2>/dev/null; then
    log "Deaktiviere firewalld (Verwendung eigener nftables-Regeln)"
    systemctl disable --now firewalld || true
  fi
  echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ipforward.conf
  sysctl --system | tee -a "$logfile"
}

installprog() {
  log "Installiere epel-release"
  dnf install -y epel-release
  log "Installiere Pakete"
  dnf install -y "${needed[@]}"
  log "System aktualisieren"
  dnf update -y
}

stopping() {
  log "Stoppe Services (falls aktiv)"
  local all_services=("${services_base[@]}")
  $ENABLE_SAMBA && all_services+=("${services_samba[@]}")
  $ENABLE_NFS && all_services+=("${services_nfs[@]}")
  for service in "${all_services[@]}"; do
    if systemctl is-active --quiet "$service"; then
      log "Stoppe $service"
      systemctl stop "$service"
    fi
  done
}

# ======= NetworkManager-Profile =======
nmwan() {
  local f="/etc/NetworkManager/system-connections/WAN-${wan_card}.nmconnection"
  log "Erzeuge NM-Profil WAN ($wan_card)"
  cat > "$f" <<EOF
[connection]
id=WAN-${wan_card}
type=ethernet
interface-name=${wan_card}
autoconnect=true

[ethernet]

[ipv4]
method=auto

[ipv6]
method=ignore
EOF
}

nmbung() {
  local f="/etc/NetworkManager/system-connections/LAN-${bunga_card}.nmconnection"
  log "Erzeuge NM-Profil LAN ($bunga_card)"
  cat > "$f" <<EOF
[connection]
id=LAN-${bunga_card}
type=ethernet
interface-name=${bunga_card}
autoconnect=true

[ethernet]

[ipv4]
address1=10.10.10.1/24
method=manual
never-default=true

[ipv6]
method=ignore
EOF
}

nmwlan() {
  local f="/etc/NetworkManager/system-connections/WLAN-${wlan_card}-static.nmconnection"
  log "Erzeuge NM-Profil WLAN ($wlan_card)"
  cat > "$f" <<EOF
[connection]
id=WLAN-${wlan_card}-static
type=ethernet
interface-name=${wlan_card}
autoconnect=true

[ethernet]

[ipv4]
address1=10.10.11.1/24
method=manual
never-default=true

[ipv6]
method=ignore
EOF
}

# ======= hostapd & dnsmasq =======
creatinghostapd() {
  local f="/etc/hostapd/hostapd.conf"
  log "Schreibe hostapd: $f"
  cat > "$f" <<EOF
interface=${wlan_card}
driver=nl80211
ssid=${wlanname}
hw_mode=g
channel=6
country_code=DE
ieee80211d=1
ieee80211h=1
ieee80211n=1
ht_capab=[HT40+][SHORT-GI-20][SHORT-GI-40]
wpa=2
auth_algs=1
wpa_key_mgmt=WPA-PSK
wpa_passphrase=${wlanpw}
rsn_pairwise=CCMP
macaddr_acl=0
ignore_broadcast_ssid=0
logger_syslog=1
logger_syslog_level=2
EOF
}

creatingdns() {
  local f="/etc/dnsmasq.conf"
  log "Schreibe dnsmasq: $f"
  cat > "$f" <<EOF
# ---- Allgemein ----
domain-needed
bogus-priv
no-resolv
server=1.1.1.1
server=8.8.8.8

# ---- LAN (${bunga_card}) ----
interface=${bunga_card}
dhcp-range=10.10.10.10,10.10.10.25,255.255.255.0,12h
dhcp-option=interface:${bunga_card},3,10.10.10.1
dhcp-option=interface:${bunga_card},6,10.10.10.1

# ---- WLAN (${wlan_card}) ----
interface=${wlan_card}
dhcp-range=10.10.11.10,10.10.11.25,255.255.255.0,12h
dhcp-option=interface:${wlan_card},3,10.10.11.1
dhcp-option=interface:${wlan_card},6,10.10.11.1

# ---- Logging ----
log-dhcp
log-queries
EOF
}

# ======= Storage: Partitionieren, Formatieren, Mounten, Freigaben =======
ensure_sda1() {
  log "Prüfe $SDA_PART"
  if [[ -b "$SDA_PART" ]]; then
    log "$SDA_PART existiert bereits"
    return
  fi
  # Wenn Disk keine Partitionen hat -> GPT + eine volle Partition
  if ! lsblk -no NAME "${SDA_DEV}" | grep -qE '^sda[0-9]'; then
    log "Erstelle GPT und primäre Partition auf $SDA_DEV"
    parted -s "$SDA_DEV" mklabel gpt
    parted -s "$SDA_DEV" mkpart primary ${FS_TYPE} 1MiB 100%
    partprobe "$SDA_DEV"
    sleep 2
  fi
  if [[ ! -b "$SDA_PART" ]]; then
    log "FEHLER: $SDA_PART wurde nicht erstellt." ; exit 20
  fi
}

# Erzeuge p5 im größten freien Bereich (NVMe hat bereits p1..p4)
ensure_nvme_p5() {
  log "Prüfe $NVME_PART"
  if [[ -b "$NVME_PART" ]]; then
    log "$NVME_PART existiert bereits"
    return
  fi
  log "Suche freien Bereich auf $NVME_DEV für $NVME_PART"
  # parse parted machine-readable free space
  local startMiB endMiB
  IFS=';' read -r _ _ _ _ _ _ _ _ <<< "$(parted -m "$NVME_DEV" unit MiB print free | awk -F: '/free/ {gsub("MiB","",$2); gsub("MiB","",$3); print $2";"$3}' | sort -n | tail -1)"
  startMiB="${_%%;*}"; endMiB="${_##*;}"
  if [[ -z "${startMiB:-}" || -z "${endMiB:-}" ]]; then
    log "FEHLER: Konnte freien Bereich nicht ermitteln." ; exit 21
  fi
  log "Erzeuge Partition von ${startMiB}MiB bis ${endMiB}MiB"
  parted -s "$NVME_DEV" mkpart primary ${FS_TYPE} "${startMiB}MiB" "${endMiB}MiB"
  partprobe "$NVME_DEV"
  sleep 2
  if [[ ! -b "$NVME_PART" ]]; then
    log "FEHLER: $NVME_PART wurde nicht erstellt." ; exit 22
  fi
}

make_fs_if_needed() {
  local dev="$1" fs="$2"
  local cur
  cur="$(blkid -o value -s TYPE "$dev" || true)"
  if [[ -z "$cur" ]]; then
    log "Formatiere $dev als $fs"
    case "$fs" in
      xfs)  mkfs.xfs -f "$dev" ;;
      ext4) mkfs.ext4 -F "$dev" ;;
      *) log "Unbekanntes FS: $fs" ; exit 23 ;;
    esac
  else
    log "$dev hat bereits Dateisystem: $cur (überspringe Formatierung)"
  fi
}

mount_and_fstab() {
  local dev="$1" mnt="$2" fs="$3"
  mkdir -p "$mnt"
  local uuid
  uuid="$(blkid -o value -s UUID "$dev")"
  if [[ -z "$uuid" ]]; then
    log "FEHLER: Keine UUID für $dev gefunden" ; exit 24
  fi
  # fstab Eintrag prüfen/setzen
  if ! grep -q "UUID=$uuid" /etc/fstab ; then
    log "Sichere /etc/fstab und trage $mnt ein"
    cp -a /etc/fstab "/etc/fstab.bak.$(date +%F_%H%M%S)"
    echo "UUID=$uuid  $mnt  $fs  defaults,noatime  0 0" >> /etc/fstab
  fi
  mountpoint -q "$mnt" || mount "$mnt"
}

samba_setup() {
  $ENABLE_SAMBA || return 0
  log "Richte Samba (SMB) ein"
  # SELinux-Kontext für Freigaben (falls Enforcing)
  if command -v getenforce >/dev/null && [[ "$(getenforce)" != "Disabled" ]]; then
    log "Setze SELinux-Kontexte für Samba-Freigaben"
    semanage fcontext -a -t samba_share_t "${MNT1}(/.*)?" || true
    semanage fcontext -a -t samba_share_t "${MNT2}(/.*)?" || true
    restorecon -Rv "${MNT1}" "${MNT2}" || true
  fi

  cat > /etc/samba/smb.conf <<'EOF'
[global]
   workgroup = WORKGROUP
   server string = Rocky Router
   security = user
   map to guest = Bad User
   smb encrypt = required

[router1]
   path = /router1
   browsable = yes
   writable = yes
   guest ok = no
   force create mode = 0664
   force directory mode = 2775

[router2]
   path = /router2
   browsable = yes
   writable = yes
   guest ok = no
   force create mode = 0664
   force directory mode = 2775
EOF

  # Benutzer anlegen (optional, wenn Passwort gesetzt)
  if [[ -n "${SMB_USER}" ]]; then
    id -u "${SMB_USER}" >/dev/null 2>&1 || useradd -M -s /sbin/nologin "${SMB_USER}"
    if [[ -n "${SMB_PASS}" && "${SMB_PASS}" != "changeme" ]]; then
      printf "%s\n%s\n" "$SMB_PASS" "$SMB_PASS" | smbpasswd -s -a "${SMB_USER}" || true
    else
      log "HINWEIS: SMB_PASS ist 'changeme' oder leer – Passwort bitte manuell setzen: smbpasswd -a ${SMB_USER}"
    fi
  fi
}

nfs_setup() {
  $ENABLE_NFS || return 0
  log "Richte NFS Exports ein"
  # /etc/exports schreiben (idempotent)
  local exports=/etc/exports
  cp -a "$exports" "${exports}.bak.$(date +%F_%H%M%S)" 2>/dev/null || true
  cat > "$exports" <<EOF
${MNT1} 10.10.10.0/24(rw,sync,no_subtree_check) 10.10.11.0/24(rw,sync,no_subtree_check)
${MNT2} 10.10.10.0/24(rw,sync,no_subtree_check) 10.10.11.0/24(rw,sync,no_subtree_check)
EOF
  exportfs -ra
}

# ======= nftables =======
creatingnftables() {
  local f="/etc/nftables.conf"
  log "Schreibe nftables: $f"

  # Zusätzliche Regeln je nach Freigaben
  local smb_rules="" nfs_rules=""
  if $ENABLE_SAMBA; then
    smb_rules=$(cat <<'EOS'
    # SMB (Samba) nur intern
    iifname @lan_ifaces tcp dport { 139, 445 } accept
    iifname @lan_ifaces udp dport { 137, 138 } accept
EOS
)
  fi
  if $ENABLE_NFS; then
    nfs_rules=$(cat <<'EOS'
    # NFS nur intern (rpcbind 111, nfsd 2049, mountd 20048)
    iifname @lan_ifaces tcp dport { 111, 2049, 20048 } accept
    iifname @lan_ifaces udp dport { 111, 2049, 20048 } accept
EOS
)
  fi

  cat > "$f" <<EOF
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
  set lan_ifaces {
    type ifname
    elements = { "${bunga_card}", "${wlan_card}" }
  }

  chain input {
    type filter hook input priority 0; policy drop;

    iif lo accept
    ct state { established, related } accept

    # ICMP/ICMPv6
    icmp type { echo-request, echo-reply, destination-unreachable, time-exceeded, parameter-problem } accept
    ip6 nexthdr icmpv6 icmpv6 type { echo-request, echo-reply, destination-unreachable, time-exceeded, packet-too-big, parameter-problem, router-solicitation, router-advertisement, neighbour-solicitation, neighbour-advertisement } accept

    # DHCP/DNS lokal von internen Netzen
    iifname @lan_ifaces udp dport { 67, 68 } accept
    iifname @lan_ifaces udp dport 53 accept
    iifname @lan_ifaces tcp dport 53 accept

    # SSH nur intern
    iifname @lan_ifaces tcp dport 22 accept

$(printf "%s" "$smb_rules")
$(printf "%s" "$nfs_rules")
  }

  chain forward {
    type filter hook forward priority 0; policy drop;

    ct state { established, related } accept
    iifname @lan_ifaces oif "${wan_card}" accept

    # Optional: Inter-LAN/WLAN freigeben:
    # iifname "${bunga_card}" oif "${wlan_card}" accept
    # iifname "${wlan_card}" oif "${bunga_card}" accept
  }

  chain output {
    type filter hook output priority 0; policy accept;
  }
}

table ip nat {
  chain prerouting {
    type nat hook prerouting priority -100; policy accept;
    # DNAT-Beispiele:
    # iif "${wan_card}" tcp dport 80 dnat to 10.10.10.20
    # iif "${wan_card}" tcp dport 2222 dnat to 10.10.11.15:22
  }

  chain postrouting {
    type nat hook postrouting priority 100; policy accept;
    oif "${wan_card}" masquerade
  }
}
EOF
}

# ======= Start/Enable =======
starting() {
  log "Setze Rechte für NM-Profile"
  chmod 600 /etc/NetworkManager/system-connections/*.nmconnection
  chown root:root /etc/NetworkManager/system-connections/*.nmconnection

  log "Starte NetworkManager"
  systemctl enable NetworkManager
  systemctl restart NetworkManager
  nmcli connection reload

  # Services aktivieren
  local all_services=("${services_base[@]}")
  $ENABLE_SAMBA && all_services+=("${services_samba[@]}")
  $ENABLE_NFS && all_services+=("${services_nfs[@]}")

  log "Aktiviere/Starte Services: ${all_services[*]}"
  for service in "${all_services[@]}"; do
    systemctl enable "$service"
  done
  for service in "${all_services[@]}"; do
    systemctl restart "$service"
  done

  log "Aktuelle nft-Regeln:"
  nft list ruleset | tee -a "$logfile"
}

# ======= MAIN =======
main() {
  require_root
  prepare_logging
  preflight_checks
  stopping
  installprog
  disable_firewalld_enable_forwarding

  # Netzwerk
  nmwan
  nmbung
  nmwlan
  creatinghostapd
  creatingdns

  # Storage
  ensure_sda1
  ensure_nvme_p5
  make_fs_if_needed "$SDA_PART" "$FS_TYPE"
  make_fs_if_needed "$NVME_PART" "$FS_TYPE"
  mount_and_fstab "$SDA_PART" "$MNT1" "$FS_TYPE"
  mount_and_fstab "$NVME_PART" "$MNT2" "$FS_TYPE"

  # Freigaben
  samba_setup
  nfs_setup

  # Firewall
  creatingnftables

  # Start
  starting

  log "Script completed successfully"
}

trap 'log "Beendet mit Code: $?"; exit $?' EXIT
main

# WLAN
wlanname="bunga"
wlanpw="bungahart"

# Netzwerkkarten
wan_card="eno1"
bunga_card="eno2"
wlan_card="wlan1"

# Storage-Ziele (XFS empfohlen)
SDA_DEV="/dev/sda"
SDA_PART="/dev/sda1"
NVME_DEV="/dev/nvme1n1"
NVME_PART="/dev/nvme1n1p5"

MNT1="/router1"   # -> sda1
MNT2="/router2"   # -> nvme1n1p5
FS_TYPE="xfs"     # xfs|ext4

# Netzfreigaben
ENABLE_SAMBA=true
ENABLE_NFS=true

# Samba-User (optional automatisiert anlegen – Passwort hier setzen oder leer lassen)
SMB_USER="router"
SMB_PASS="changeme"   # <<-- ändere das! Wenn leer, wird kein Passwort gesetzt.

# Pakete
needed=(
  "iproute"
  "NetworkManager"
  "iw"
  "wireless-tools"
  "wpa_supplicant"
  "wireless-regdb"
  "tcpdump"
  "nmap"
  "traceroute"
  "nethogs"
  "iftop"
  "ntopng"
  "dnsmasq"
  "hostapd"
  "nftables"
  "parted"
  "xfsprogs"
  "e2fsprogs"
  "nfs-utils"
  "samba"
  "samba-client"
  "policycoreutils-python-utils"  # für semanage (SELinux)
)

# Services
services_base=(
  "NetworkManager"
  "dnsmasq"
  "hostapd"
  "nftables"
)
services_samba=("smb" "nmb")
services_nfs=("nfs-server")

# ======= Helpers =======
get_timestamp() { date +"%Y-%m-%d_%H:%M:%S"; }
log() { echo "$(get_timestamp) $*" | tee -a "$logfile"; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Bitte als root ausführen (sudo)." >&2
    exit 1
  fi
}

prepare_logging() {
  mkdir -p "$logpath"
  touch "$logfile"
  log "Log path: $logpath"
  log "Log file: $logfile"
}

preflight_checks() {
  mkdir -p /etc/NetworkManager/system-connections /etc/NetworkManager/conf.d
  ip link show "$wan_card" >/dev/null 2>&1 || log "WARN: $wan_card nicht gefunden"
  ip link show "$bunga_card" >/dev/null 2>&1 || log "WARN: $bunga_card nicht gefunden"
  ip link show "$wlan_card" >/dev/null 2>&1 || log "WARN: $wlan_card nicht gefunden"
}

disable_firewalld_enable_forwarding() {
  if systemctl is-enabled --quiet firewalld 2>/dev/null || systemctl is-active --quiet firewalld 2>/dev/null; then
    log "Deaktiviere firewalld (Verwendung eigener nftables-Regeln)"
    systemctl disable --now firewalld || true
  fi
  echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ipforward.conf
  sysctl --system | tee -a "$logfile"
}

installprog() {
  log "Installiere epel-release"
  dnf install -y epel-release
  log "Installiere Pakete"
  dnf install -y "${needed[@]}"
  log "System aktualisieren"
  dnf update -y
}

stopping() {
  log "Stoppe Services (falls aktiv)"
  local all_services=("${services_base[@]}")
  $ENABLE_SAMBA && all_services+=("${services_samba[@]}")
  $ENABLE_NFS && all_services+=("${services_nfs[@]}")
  for service in "${all_services[@]}"; do
    if systemctl is-active --quiet "$service"; then
      log "Stoppe $service"
      systemctl stop "$service"
    fi
  done
}

# ======= NetworkManager-Profile =======
nmwan() {
  local f="/etc/NetworkManager/system-connections/WAN-${wan_card}.nmconnection"
  log "Erzeuge NM-Profil WAN ($wan_card)"
  cat > "$f" <<EOF
[connection]
id=WAN-${wan_card}
type=ethernet
interface-name=${wan_card}
autoconnect=true

[ethernet]

[ipv4]
method=auto

[ipv6]
method=ignore
EOF
}

nmbung() {
  local f="/etc/NetworkManager/system-connections/LAN-${bunga_card}.nmconnection"
  log "Erzeuge NM-Profil LAN ($bunga_card)"
  cat > "$f" <<EOF
[connection]
id=LAN-${bunga_card}
type=ethernet
interface-name=${bunga_card}
autoconnect=true

[ethernet]

[ipv4]
address1=10.10.10.1/24
method=manual
never-default=true

[ipv6]
method=ignore
EOF
}

nmwlan() {
  local f="/etc/NetworkManager/system-connections/WLAN-${wlan_card}-static.nmconnection"
  log "Erzeuge NM-Profil WLAN ($wlan_card)"
  cat > "$f" <<EOF
[connection]
id=WLAN-${wlan_card}-static
type=ethernet
interface-name=${wlan_card}
autoconnect=true

[ethernet]

[ipv4]
address1=10.10.11.1/24
method=manual
never-default=true

[ipv6]
method=ignore
EOF
}

# ======= hostapd & dnsmasq =======
creatinghostapd() {
  local f="/etc/hostapd/hostapd.conf"
  log "Schreibe hostapd: $f"
  cat > "$f" <<EOF
interface=${wlan_card}
driver=nl80211
ssid=${wlanname}
hw_mode=g
channel=6
country_code=DE
ieee80211d=1
ieee80211h=1
ieee80211n=1
ht_capab=[HT40+][SHORT-GI-20][SHORT-GI-40]
wpa=2
auth_algs=1
wpa_key_mgmt=WPA-PSK
wpa_passphrase=${wlanpw}
rsn_pairwise=CCMP
macaddr_acl=0
ignore_broadcast_ssid=0
logger_syslog=1
logger_syslog_level=2
EOF
}

creatingdns() {
  local f="/etc/dnsmasq.conf"
  log "Schreibe dnsmasq: $f"
  cat > "$f" <<EOF
# ---- Allgemein ----
domain-needed
bogus-priv
no-resolv
server=1.1.1.1
server=8.8.8.8

# ---- LAN (${bunga_card}) ----
interface=${bunga_card}
dhcp-range=10.10.10.10,10.10.10.25,255.255.255.0,12h
dhcp-option=interface:${bunga_card},3,10.10.10.1
dhcp-option=interface:${bunga_card},6,10.10.10.1

# ---- WLAN (${wlan_card}) ----
interface=${wlan_card}
dhcp-range=10.10.11.10,10.10.11.25,255.255.255.0,12h
dhcp-option=interface:${wlan_card},3,10.10.11.1
dhcp-option=interface:${wlan_card},6,10.10.11.1

# ---- Logging ----
log-dhcp
log-queries
EOF
}

# ======= Storage: Partitionieren, Formatieren, Mounten, Freigaben =======
ensure_sda1() {
  log "Prüfe $SDA_PART"
  if [[ -b "$SDA_PART" ]]; then
    log "$SDA_PART existiert bereits"
    return
  fi
  # Wenn Disk keine Partitionen hat -> GPT + eine volle Partition
  if ! lsblk -no NAME "${SDA_DEV}" | grep -qE '^sda[0-9]'; then
    log "Erstelle GPT und primäre Partition auf $SDA_DEV"
    parted -s "$SDA_DEV" mklabel gpt
    parted -s "$SDA_DEV" mkpart primary ${FS_TYPE} 1MiB 100%
    partprobe "$SDA_DEV"
    sleep 2
  fi
  if [[ ! -b "$SDA_PART" ]]; then
    log "FEHLER: $SDA_PART wurde nicht erstellt." ; exit 20
  fi
}

# Erzeuge p5 im größten freien Bereich (NVMe hat bereits p1..p4)
ensure_nvme_p5() {
  log "Prüfe $NVME_PART"
  if [[ -b "$NVME_PART" ]]; then
    log "$NVME_PART existiert bereits"
    return
  fi
  log "Suche freien Bereich auf $NVME_DEV für $NVME_PART"
  # parse parted machine-readable free space
  local startMiB endMiB
  IFS=';' read -r _ _ _ _ _ _ _ _ <<< "$(parted -m "$NVME_DEV" unit MiB print free | awk -F: '/free/ {gsub("MiB","",$2); gsub("MiB","",$3); print $2";"$3}' | sort -n | tail -1)"
  startMiB="${_%%;*}"; endMiB="${_##*;}"
  if [[ -z "${startMiB:-}" || -z "${endMiB:-}" ]]; then
    log "FEHLER: Konnte freien Bereich nicht ermitteln." ; exit 21
  fi
  log "Erzeuge Partition von ${startMiB}MiB bis ${endMiB}MiB"
  parted -s "$NVME_DEV" mkpart primary ${FS_TYPE} "${startMiB}MiB" "${endMiB}MiB"
  partprobe "$NVME_DEV"
  sleep 2
  if [[ ! -b "$NVME_PART" ]]; then
    log "FEHLER: $NVME_PART wurde nicht erstellt." ; exit 22
  fi
}

make_fs_if_needed() {
  local dev="$1" fs="$2"
  local cur
  cur="$(blkid -o value -s TYPE "$dev" || true)"
  if [[ -z "$cur" ]]; then
    log "Formatiere $dev als $fs"
    case "$fs" in
      xfs)  mkfs.xfs -f "$dev" ;;
      ext4) mkfs.ext4 -F "$dev" ;;
      *) log "Unbekanntes FS: $fs" ; exit 23 ;;
    esac
  else
    log "$dev hat bereits Dateisystem: $cur (überspringe Formatierung)"
  fi
}

mount_and_fstab() {
  local dev="$1" mnt="$2" fs="$3"
  mkdir -p "$mnt"
  local uuid
  uuid="$(blkid -o value -s UUID "$dev")"
  if [[ -z "$uuid" ]]; then
    log "FEHLER: Keine UUID für $dev gefunden" ; exit 24
  fi
  # fstab Eintrag prüfen/setzen
  if ! grep -q "UUID=$uuid" /etc/fstab ; then
    log "Sichere /etc/fstab und trage $mnt ein"
    cp -a /etc/fstab "/etc/fstab.bak.$(date +%F_%H%M%S)"
    echo "UUID=$uuid  $mnt  $fs  defaults,noatime  0 0" >> /etc/fstab
  fi
  mountpoint -q "$mnt" || mount "$mnt"
}

samba_setup() {
  $ENABLE_SAMBA || return 0
  log "Richte Samba (SMB) ein"
  # SELinux-Kontext für Freigaben (falls Enforcing)
  if command -v getenforce >/dev/null && [[ "$(getenforce)" != "Disabled" ]]; then
    log "Setze SELinux-Kontexte für Samba-Freigaben"
    semanage fcontext -a -t samba_share_t "${MNT1}(/.*)?" || true
    semanage fcontext -a -t samba_share_t "${MNT2}(/.*)?" || true
    restorecon -Rv "${MNT1}" "${MNT2}" || true
  fi

  cat > /etc/samba/smb.conf <<'EOF'
[global]
   workgroup = WORKGROUP
   server string = Rocky Router
   security = user
   map to guest = Bad User
   smb encrypt = required

[router1]
   path = /router1
   browsable = yes
   writable = yes
   guest ok = no
   force create mode = 0664
   force directory mode = 2775

[router2]
   path = /router2
   browsable = yes
   writable = yes
   guest ok = no
   force create mode = 0664
   force directory mode = 2775
EOF

  # Benutzer anlegen (optional, wenn Passwort gesetzt)
  if [[ -n "${SMB_USER}" ]]; then
    id -u "${SMB_USER}" >/dev/null 2>&1 || useradd -M -s /sbin/nologin "${SMB_USER}"
    if [[ -n "${SMB_PASS}" && "${SMB_PASS}" != "changeme" ]]; then
      printf "%s\n%s\n" "$SMB_PASS" "$SMB_PASS" | smbpasswd -s -a "${SMB_USER}" || true
    else
      log "HINWEIS: SMB_PASS ist 'changeme' oder leer – Passwort bitte manuell setzen: smbpasswd -a ${SMB_USER}"
    fi
  fi
}

nfs_setup() {
  $ENABLE_NFS || return 0
  log "Richte NFS Exports ein"
  # /etc/exports schreiben (idempotent)
  local exports=/etc/exports
  cp -a "$exports" "${exports}.bak.$(date +%F_%H%M%S)" 2>/dev/null || true
  cat > "$exports" <<EOF
${MNT1} 10.10.10.0/24(rw,sync,no_subtree_check) 10.10.11.0/24(rw,sync,no_subtree_check)
${MNT2} 10.10.10.0/24(rw,sync,no_subtree_check) 10.10.11.0/24(rw,sync,no_subtree_check)
EOF
  exportfs -ra
}

# ======= nftables =======
creatingnftables() {
  local f="/etc/nftables.conf"
  log "Schreibe nftables: $f"

  # Zusätzliche Regeln je nach Freigaben
  local smb_rules="" nfs_rules=""
  if $ENABLE_SAMBA; then
    smb_rules=$(cat <<'EOS'
    # SMB (Samba) nur intern
    iifname @lan_ifaces tcp dport { 139, 445 } accept
    iifname @lan_ifaces udp dport { 137, 138 } accept
EOS
)
  fi
  if $ENABLE_NFS; then
    nfs_rules=$(cat <<'EOS'
    # NFS nur intern (rpcbind 111, nfsd 2049, mountd 20048)
    iifname @lan_ifaces tcp dport { 111, 2049, 20048 } accept
    iifname @lan_ifaces udp dport { 111, 2049, 20048 } accept
EOS
)
  fi

  cat > "$f" <<EOF
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
  set lan_ifaces {
    type ifname
    elements = { "${bunga_card}", "${wlan_card}" }
  }

  chain input {
    type filter hook input priority 0; policy drop;

    iif lo accept
    ct state { established, related } accept

    # ICMP/ICMPv6
    icmp type { echo-request, echo-reply, destination-unreachable, time-exceeded, parameter-problem } accept
    ip6 nexthdr icmpv6 icmpv6 type { echo-request, echo-reply, destination-unreachable, time-exceeded, packet-too-big, parameter-problem, router-solicitation, router-advertisement, neighbour-solicitation, neighbour-advertisement } accept

    # DHCP/DNS lokal von internen Netzen
    iifname @lan_ifaces udp dport { 67, 68 } accept
    iifname @lan_ifaces udp dport 53 accept
    iifname @lan_ifaces tcp dport 53 accept

    # SSH nur intern
    iifname @lan_ifaces tcp dport 22 accept

$(printf "%s" "$smb_rules")
$(printf "%s" "$nfs_rules")
  }

  chain forward {
    type filter hook forward priority 0; policy drop;

    ct state { established, related } accept
    iifname @lan_ifaces oif "${wan_card}" accept

    # Optional: Inter-LAN/WLAN freigeben:
    # iifname "${bunga_card}" oif "${wlan_card}" accept
    # iifname "${wlan_card}" oif "${bunga_card}" accept
  }

  chain output {
    type filter hook output priority 0; policy accept;
  }
}

table ip nat {
  chain prerouting {
    type nat hook prerouting priority -100; policy accept;
    # DNAT-Beispiele:
    # iif "${wan_card}" tcp dport 80 dnat to 10.10.10.20
    # iif "${wan_card}" tcp dport 2222 dnat to 10.10.11.15:22
  }

  chain postrouting {
    type nat hook postrouting priority 100; policy accept;
    oif "${wan_card}" masquerade
  }
}
EOF
}

# ======= Start/Enable =======
starting() {
  log "Setze Rechte für NM-Profile"
  chmod 600 /etc/NetworkManager/system-connections/*.nmconnection
  chown root:root /etc/NetworkManager/system-connections/*.nmconnection

  log "Starte NetworkManager"
  systemctl enable NetworkManager
  systemctl restart NetworkManager
  nmcli connection reload

  # Services aktivieren
  local all_services=("${services_base[@]}")
  $ENABLE_SAMBA && all_services+=("${services_samba[@]}")
  $ENABLE_NFS && all_services+=("${services_nfs[@]}")

  log "Aktiviere/Starte Services: ${all_services[*]}"
  for service in "${all_services[@]}"; do
    systemctl enable "$service"
  done
  for service in "${all_services[@]}"; do
    systemctl restart "$service"
  done

  log "Aktuelle nft-Regeln:"
  nft list ruleset | tee -a "$logfile"
}

# ======= MAIN =======
main() {
  require_root
  prepare_logging
  preflight_checks
  stopping
  installprog
  disable_firewalld_enable_forwarding

  # Netzwerk
  nmwan
  nmbung
  nmwlan
  creatinghostapd
  creatingdns

  # Storage
  ensure_sda1
  ensure_nvme_p5
  make_fs_if_needed "$SDA_PART" "$FS_TYPE"
  make_fs_if_needed "$NVME_PART" "$FS_TYPE"
  mount_and_fstab "$SDA_PART" "$MNT1" "$FS_TYPE"
  mount_and_fstab "$NVME_PART" "$MNT2" "$FS_TYPE"

  # Freigaben
  samba_setup
  nfs_setup

  # Firewall
  creatingnftables

  # Start
  starting

  log "Script completed successfully"
}

trap 'log "Beendet mit Code: $?"; exit $?' EXIT
main
