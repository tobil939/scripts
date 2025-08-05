#!/usr/local/bin/bash

#=======================#
#     PROGRAMMLISTEN    #
#=======================#

pkg_programme=(
  "sudo"
  "bash"
  "nano"
  "zfs"
  "neovim"
  "kitty"
  "neofetch"
  "python3"
  "npm"
  "hs-ShellCheck"
  "shfmt"
  "isc-dhcp44-server"
  "clamav"
  "samba420"
  "git"
  "iftop"
  "nload"
  "vnstat"
  "unbound"
  "smartmontools"
  "hostapd"
)

npm_programme=(
  "bash-language-server"
  "tree-sitter"
)

router_benutzer=(alice bob)

#=======================#
#      FUNKTIONEN       #
#=======================#

log() {
  echo "[INFO] $1"
}

fail() {
  echo "[ERROR] $1"
  exit 1
}

install_pkg_programme() {
  for pkg in "${pkg_programme[@]}"; do
    log "Installiere $pkg ..."
    pkg install -y "$pkg" || fail "$pkg konnte nicht installiert werden"
  done
}

install_npm_programme() {
  for npm_pkg in "${npm_programme[@]}"; do
    log "Installiere (npm) $npm_pkg ..."
    npm install -g "$npm_pkg" --silent || fail "$npm_pkg konnte nicht installiert werden"
  done
}

set_router_rechte() {
  log "Richte router-Gruppe ein ..."
  pw groupadd router 2>/dev/null
  for user in "${router_benutzer[@]}"; do
    pw groupmod router -m "$user" || fail "Benutzer $user konnte nicht hinzugefügt werden"
  done
}

setup_sudo() {
  log "Füge sudo-Regel für router-Gruppe mit Passwort hinzu ..."
  echo "%router ALL=(ALL) ALL" >>/usr/local/etc/sudoers || fail "Sudo-Konfiguration fehlgeschlagen"
}

setup_netwerk() {
  log "Netzwerkschnittstellen konfigurieren ..."
  sysrc ifconfig_em0="DHCP"
  sysrc ifconfig_re0="inet 10.10.10.1 netmask 255.255.255.0"
  sysrc ifconfig_iwm0="inet 10.10.10.2 netmask 255.255.255.0"
}

setup_dhcp() {
  log "DHCP-Server einrichten ..."
  sysrc dhcpd_enable="YES"
  sysrc dhcpd_ifaces="re0 iwm0"
}

setup_ssh() {
  log "SSH aktivieren ..."
  sysrc sshd_enable="YES"
  service sshd start || fail "sshd konnte nicht gestartet werden"
}

setup_wlan_ap() {
  log "hostapd konfigurieren ..."
  sysrc hostapd_enable="YES"
}

setup_samba() {
  log "Samba aktivieren ..."
  sysrc samba_server_enable="YES"
}

setup_firewall_pf() {
  log "Firewall (pf) aktivieren ..."
  sysrc pf_enable="YES"

  cat <<EOF >/etc/pf.conf
ext_if = "em0"
lan_if = "bridge0"
lan_net = "10.10.10.0/24"

nat on \$ext_if from \$lan_net to any -> (\$ext_if)

block all
pass quick on lo0
pass in quick on \$lan_if inet from \$lan_net to any keep state
pass out quick on \$ext_if inet from any to any keep state
EOF
}

setup_clamav() {
  log "ClamAV aktivieren ..."
  sysrc clamav_clamd_enable="YES"
  sysrc clamav_freshclam_enable="YES"

  log "Signaturen aktualisieren ..."
  freshclam || fail "ClamAV Signaturen konnten nicht aktualisiert werden"
}

create_dhcpd_conf() {
  log "Erstelle /usr/local/etc/dhcpd.conf ..."
  cat <<EOF >/usr/local/etc/dhcpd.conf
subnet 10.10.10.0 netmask 255.255.255.0 {
  range 10.10.10.100 10.10.10.200;
  option routers 10.10.10.1;
  option domain-name-servers 1.1.1.1, 8.8.8.8;
  default-lease-time 600;
  max-lease-time 7200;
}
EOF
}

create_hostapd_conf() {
  log "Erstelle /usr/local/etc/hostapd.conf ..."
  cat <<EOF >/usr/local/etc/hostapd.conf
interface=iwm0
ssid=FreeBSD-AP
hw_mode=g
channel=6
auth_algs=1
wpa=2
wpa_passphrase=MeinGeheimesPasswort
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF
}

create_smb4_conf() {
  log "Erstelle /usr/local/etc/smb4.conf ..."
  cat <<EOF >/usr/local/etc/smb4.conf
[global]
   workgroup = WORKGROUP
   server string = FreeBSD Samba Server
   security = user
   passdb backend = tdbsam
   load printers = no
   log file = /var/log/samba4/log.%m
   max log size = 50

[zfs1]
   path = /mnt/zfs1
   read only = no
   browsable = yes

[zfs2]
   path = /mnt/zfs2
   read only = no
   browsable = yes
EOF
}

start_services() {
  log "Starte alle Dienste ..."
  service pf start || fail "pf konnte nicht gestartet werden"
  service isc-dhcpd start || fail "DHCP konnte nicht gestartet werden"
  service sshd start || fail "sshd konnte nicht gestartet werden"
  service samba_server start || fail "Samba konnte nicht gestartet werden"
  service hostapd start || fail "hostapd konnte nicht gestartet werden"
  service clamav-clamd start || fail "ClamAV konnte nicht gestartet werden"
}

#=======================#
#     HAUPTFUNKTION     #
#=======================#

main() {
  install_pkg_programme
  install_npm_programme
  set_router_rechte
  setup_sudo
  setup_netwerk
  create_dhcpd_conf
  create_hostapd_conf
  create_smb4_conf
  setup_dhcp
  setup_ssh
  setup_wlan_ap
  setup_samba
  setup_firewall_pf
  setup_clamav
  start_services
}

main
