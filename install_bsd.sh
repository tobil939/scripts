#!/bin/bash

#=======================#
#     PROGRAMMLISTEN    #
#=======================#

pkg_programme=(
  "sudo"
  "bash"
  "nano"
  "xfsprogs"
  "neovim"
  "kitty"
  "neofetch"
  "python"
  "npm"
  "shellcheck"
  "shfmt"
  "dhcp"
  "clamav"
  "samba"
  "git"
  "iftop"
  "nload"
  "vnstat"
  "unbound"
  "smartmontools"
  "hostapd"
  "iptables-nft"
)

npm_programme=(
  "bash-language-server"
  "tree-sitter"
)

WlanName="MeinHeimNetz"
WlanPW="1234"

router_benutzer=(
  "alice"
  "lbob"
)

#=======================#
#      FUNKTIONEN       #
#=======================#

log() {
  echo "[INFO] $1"
}

fail() {
  echo "[ERROR] $1" >&2
  exit 1
}

warn() {
  echo -e "\33[1;33mWARNUNG:\033[0m $1" >&2
}

install_pkg_programme() {
  log "Installiere Pakete..."
  pacman -Syu --noconfirm || fail "Systemupdate fehlgeschlagen"
  for pkg in "${pkg_programme[@]}"; do
    log "Installiere $pkg ..."
    pacman -S --noconfirm --needed "$pkg" || warn "$pkg konnte nicht installiert werden"
  done
}

install_npm_programme() {
  for npm_pkg in "${npm_programme[@]}"; do
    log "Installiere (npm) $npm_pkg ..."
    npm install -g "$npm_pkg" --silent || warn "$npm_pkg konnte nicht installiert werden"
  done
}

set_router_rechte() {
  log "Erstelle router-Gruppe und füge Benutzer hinzu ..."
  groupadd -f router
  for user in "${router_benutzer[@]}"; do
    usermod -aG router "$user" || warn "Benutzer $user konnte nicht hinzugefügt werden"
  done
}

setup_netzwerk() {
  log "Netzwerk konfigurieren ..."
  ip addr add 10.10.10.1/24 dev enp7s0
  ip link set enp7s0 up
  if ip link show wlan0 >/dev/null 2>&1; then
    ip addr add 10.10.10.2/24 dev wlan0
    ip link set wlan0 up
  else
    warn "wlan0 nicht gefunden – WLAN wird übersprungen"
  fi
}

create_dhcpd_conf() {
  log "Erstelle /etc/dhcp/dhcpd.conf ..."
  cat <<EOF >/etc/dhcp/dhcpd.conf
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
  log "Erstelle /etc/hostapd/hostapd.conf ..."
  cat <<EOF >/etc/hostapd/hostapd.conf
interface=wlan0
ssid=$WlanName
hw_mode=g
channel=6
auth_algs=1
wpa=2
wpa_passphrase=$WlanPW
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF
}

create_smb_conf() {
  log "Erstelle /etc/samba/smb.conf ..."
  cat <<EOF >/etc/samba/smb.conf
[global]
   workgroup = WORKGROUP
   server string = Arch Linux Samba Server
   security = user
   log file = /var/log/samba/%m.log
   max log size = 50

[speicher11]
   path = /mnt/speicher11
   read only = no
   browsable = yes

[speicher12]
   path = /mnt/speicher12
   read only = no
   browsable = yes
EOF
}

setup_dienste() {
  log "Aktiviere systemd-Dienste ..."
  systemctl enable --now sshd
  systemctl enable --now dhcpd4@enp7s0.service
  systemctl enable --now hostapd
  systemctl enable --now smb
  systemctl enable --now clamav-daemon
  freshclam || warn "ClamAV Signaturen konnten nicht aktualisiert werden"
}

setup_nat_firewall() {
  log "Aktiviere NAT über iptables ..."
  iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE
  iptables -A FORWARD -i eno1 -o enp7s0 -m state --state RELATED,ESTABLISHED -j ACCEPT
  iptables -A FORWARD -i enp7s0 -o eno1 -j ACCEPT

  iptables-save >/etc/iptables/iptables.rules
  systemctl enable --now iptables
}

#=======================#
#     HAUPTFUNKTION     #
#=======================#

main() {
  install_pkg_programme
  install_npm_programme
  set_router_rechte
  setup_netzwerk
  create_dhcpd_conf
  create_hostapd_conf
  create_smb_conf
  setup_nat_firewall
  setup_dienste
}

main
