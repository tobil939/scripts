#!/usr/local/bin/bash

#===== Programme die mit pkg installiert werden
prog1=(
  "neovim"
  "nautilus"
  "kitty"
  "neofetch"
  "python3"
  "npm"
  "shellcheck"
  "shfmt"
  "isc-dhcp44-server"
  "clamav"
  "samba413"
  "git"
  "qutebrowser"
  "iftop"
  "nload"
  "vnstat"
  "unbound"
  "smartmontools"
  "hostapd"
  "openssh"
)

#===== Programme die mit NPM installiert werden
npmprog=(
  "bash-language-server"
  "tree-sitter"
)

#===== Benutzer anlegen
users=(
  "user1"
  "user2"
  "user3"
  "user4"
)

#===== Zeitstempel werden definiert
stamp() {
  date '+%H:%M:%S'
}
day=$(date '+%Y-%m-%d')

#===== Konfigdateien
rcconf="/etc/rc.conf"
pfconf="/etc/pf.conf"
dhcpconf="/usr/local/etc/dhcpd.conf"
hostapdconf="/usr/local/etc/hostapd.conf"
sambaconf="/usr/local/etc/smb4.conf"
sshconf="/etc/ssh/sshd_config"

#===== Logging wird definerit
echo "logging einrichten"
echo "log anlegen"
sudo touch /var/log/install
sudo chmod 640 /var/log/install
echo "syslog.conf einstellen"
sudo sh -c 'echo "!bash_sh" >>/etc/syslog.conf'
sudo sh -c 'echo "*.*     /var/log/install" >>/etc/syslog.conf'
echo "syslog neu starten"
sudo service syslogd reload

#===== Erster Loggeintrag
log="$day $(stamp) LOG ### erster Log eintrag"
echo "$log"
logger -t bsd_sh "$log"

#===== erstes Update
log="$(stamp) LOG ### erstes Update"
echo "$log"
logger -t bsd_sh "$log"

sudo pkg update || {
  ero="$(stamp) ERO ### Update konnte nicht durchgeführt werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

log="$(stamp) LOG ### erstes Upgrade"
echo "$log"
logger -t bsd_sh "$log"

sudo pkg upgrade -y || {
  ero="$(stamp) ERO ### Upgrade konnte nicht installiert werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

#===== Programme werden mit pkg installiert
for prog in "${prog1[@]}"; do
  log="$(stamp) LOG ### $prog wird installiert"
  ero="$(stamp) ERO ### $prog konnte nicht installiert werden"
  echo "$log" && logger -t bsd_sh "$log"
  sudo pkg install -y "$prog" || {
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
done

#===== zweites update
log="$(stamp) LOG ### zweites update"
echo "$log"
logger -t bsd_sh "$log"

sudo pkg update || {
  ero="$(stamp) ERO ### update konnte nicht durchgeführt werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

log="$(stamp) LOG ### zweites Upgrade"
echo "$log"
logger -t bsd_sh "$log"

sudo pkg upgrade -y || {
  ero="$(stamp) ERO ### Upgrade konnte nicht installiert werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

#===== Programme werden mit npm installiert
for prog in "${npmprog[@]}"; do
  log="$(stamp) LOG ### $prog wird installiert"
  ero="$(stamp) ERO ### $prog konnte nicht installiert werden"
  sudo npm install -g "$prog" --silent || {
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
done

#===== drittes update
log="$(stamp) LOG ### drittes update"
echo "$log"
logger -t bsd_sh "$log"

sudo pkg update || {
  ero="$(stamp) ERO ### update konnte nicht durchgeführt werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

log="$(stamp) LOG ### drittes Upgrade"
echo "$log"
logger -t bsd_sh "$log"

sudo pkg upgrade -y || {
  ero="$(stamp) ERO ### Upgrade konnte nicht installiert werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

#===== Netzwerkschnittstellen konfigurieren
log="$(stamp) LOG ### rc.conf wird beschhrieben"
echo "$log"
logger -t bsd_sh "$log"

cat >>"$rcconf" <<EOL
# Interet-Schnittstell (DHCP vom Provider)
ifconfig_eno1="DHCP"

# Bridge fuer LAN (eno2 + wlan1)
cloned_interfaces="bridge0 wlan1"
ifconfig_bridge0="addm eno2 addm wlan1 up"
ifconfig_eno2="up"
ifconfig_wlan1="up"

# IP-Adrese fuer das LAN (auf Bridge setzen)
ifconfig_bridge0_alias0="inet 10.10.10.1 netmask 255.255.255.0"

# IP=Forwarding aktivieren
gateway_enable="YES"

# Firewall aktivieren
pf_enable="YES"
pf_rules="/etc/pf.conf"

# DHCP aktivieren 
dhcp_enable="YES"
dhcp_ifaces="bridge0"

# Wlan Accespoint aktivieren 
hostapd_enable="YES"
hostapd_flags="/usr/local/etc/hostapd.conf"

EOL

#===== Firewall konfigurieren
log="$(stamp) LOG ### pf.conf wird beschhrieben"
echo "$log"
logger -t bsd_sh "$log"

cat >>"$pfconf" <<EOL
# Interfaces
ext_if = "eno1"
lan_if = "bridge0"

# LAN-Subnetz
lan_net = "10.10.10.0/24"

# NAT: LAN -> WAN (masquerading)
nat on $ext_if from $lan_net to any -> ($ext_if)

# Block all by default
block all

# Allow all on loopback
pass quick on lo0

# Allow all from LAN to anywhere
pass quick on $lan_if inet from $lan_net to any keep state

# Allow all on WAN interface for established connections only
pass in on $ext_if inet proto tcp from any to ($ext_if) flags S/SA keep state

# Allow DHCP replies from WAN (optional, falls du DHCP client bist)
pass in on $ext_if proto udp from any port 67 to any port 68 keep state

# Allow DNS queries from LAN
pass out on $ext_if proto udp from any to any port 53 keep state
pass out on $ext_if proto tcp from any to any port 53 keep state

# Allow SSH
pass in on $ext_if proto tcp from any to ($ext_if) port 22 keep state
pass in on $lan_if proto tcp from any to any port 22 keep state

# Allow Samba 
pass in on $lan_if prot tcp from any to any port {139, 445} keep state 
EOL

#===== DHCP konfigurieren
log="$(stamp) LOG ### pf.conf wird beschhrieben"
echo "$log"
logger -t bsd_sh "$log"

cat >>"$dhcpconf" <<EOL
option domain-name "home.local";
option domain-name-servers 10.10.10.1, 1.1.1.1;

default-lease-time 600;
max-lease-time 7200;

subnet 10.10.10.0 netmask 255.255.255.0 {
  range 10.10.10.100 10.10.10.200;
  option routers 10.10.10.1;
  option broadcast-address 10.10.10.255;
  option subnet-mask 255.255.255.0;
}

EOL

#===== WLan Accespoint konfigurieren
log="$(stamp) LOG ### hostapd.conf wird beschhrieben"
echo "$log"
logger -t bsd_sh "$log"

cat >>"$hostapdconf" <<EOL
interface=wlan1
driver=bsd
ssid=MeinHeimnetz
hw_mode=g
channel=6
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=DeinSicheresPasswort
rsn_pairwise=CCMP

EOL

#===== Samba einrichten
log="$(stamp) LOG ### smb4.conf wird beschrieben"
echo "$log"
logger -t bsd_sh "$log"

cat >>"$sambaconf" <<EOL
[global]
   workgroup = WORKGROUP
   server string = FreeBSD Samba Server
   netbios name = FREESERVER
   security = user
   map to guest = Bad User
   log file = /var/log/samba4/log.%m
   max log size = 50
   dns proxy = no

[public]
   path = /srv/samba/public
   public = yes
   writable = yes
   guest ok = yes
   guest only = yes
   create mask = 0775
   directory mask = 0775

[private]
   path = /srv/samba/private
   valid users = @users
   guest ok = no
   writable = yes
   create mask = 0700
   directory mask = 0700
EOL

#===== SSH Konfiguration ändern
log="$(stamp) LOG ### sshd_config wird angepasst"
echo "$log"
logger -t bsd_sh "$log"
sudo sed -i '' -e '/^#\?X11Forwarding/s/.*/X11Forwarding yes/' "$sshconf"
sudo sed -i '' -e '/^#\?X11UseLocalhost/s/.*/X11UseLocalhost no/' "$sshconf"
grep -q '^X11Forwarding' "$sshconf" || echo "X11Forwarding yes" | sudo tee -a "$sshconf"
grep -q '^X11UseLocalhost' "$sshconf" || echo "X11UseLocalhost no" | sudo tee -a "$sshconf"

#===== Samba Verzeichnisse und Rechte anlegen
log="$(stamp) LOG ### public Verzeiniss anlegen"
echo "$log"
logger -t bsd_sh "$log"
sudo mkdir -p /srv/samba/public || {
  ero="$(stamp) ERO ### public Verzeiniss konnte nicht anlegen werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}
log="$(stamp) LOG ### private Verzeiniss anlegen"
echo "$log"
logger -t bsd_sh "$log"
sudo mkdir -p /srv/samba/private || {
  ero="$(stamp) ERO ### private Verzeiniss konnte nicht anlegen werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}
log="$(stamp) LOG ### Rechte nobody vergeben"
echo "$log"
logger -t bsd_sh "$log"
sudo chown -R nobody:nogroup /srv/samba/public || {
  ero="$(stamp) ERO ### rechte nobody konnten nicht vergeben werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}
log="$(stamp) LOG ### 0775 für public"
echo "$log"
logger -t bsd_sh "$log"
sudo chmod -R 0775 /srv/samba/public || {
  ero="$(stamp) ERO ### 0775 konten nicht vergeben werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

for user in "${users[@]}"; do
  log="$(stamp) log ### user wir erzeugt"
  echo "$log"
  logger -t bsd_sh "$log"
  sudo pw useradd $user -m || {
    ero="$(stamp) ero ### $user konnte nicht erstellt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
done

for user in "${users[@]}"; do
  log="$(stamp) log ### $user wir irgendwas"
  echo "$log"
  logger -t bsd_sh "$log"
  sudo pdbedit -a $user || {
    ero="$(stamp) ero ### $user konnte nicht irgendwas werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
done

log="$(stamp) LOG ### User fuer Samba anlegen"
echo "$log"
logger -t bsd_sh "$log"
for user in "${users[@]}"; do
  log="$(stamp) LOG ### $user wird angelegt"
  ero="$(stamp) ERO ### $user konnte nicht angelegt werden"
  sudo chown -R $user:users /srv/samba/private || {
    echo "$log"
    logger -t bsd_sh "$log"
    exit 1
  }
done

log="$(stamp) LOG ### User 0700 Rechte vergeben"
echo "$log"
logger -t bsd_sh "$log"
sudo chmod -R 0700 /srv/samba/private || {
  ero="$(stamp) ERO ### 0700 konten nicht vergeben werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

log="$(stamp) LOG ### Firewall starten"
echo "$log"
logger -t bsd_sh "$log"
sudo service pf start || {
  ero="$(stamp) ERO ### Firewall konnte nicht neu gestartet werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

sudo pfctl -f /etc/pf.conf || {
  ero="$(stamp) ERO ### Firewall konnte nicht neu gestartet werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

log="$(stamp) LOG ### DHCP starten"
echo "$log"
logger -t bsd_sh "$log"
sudo service isc-dhcpd start || {
  ero="$(stamp) ERO ### DHCP konnte nicht neu gestartet werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

log="$(stamp) log ### ssh starten"
echo "$log"
logger -t bsd_sh "$log"
sudo service sshd start || {
  ero="$(stamp) ero ### ssh konnte nicht neu gestartet werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

log="$(stamp) log ### ssh aktivieren"
echo "$log"
logger -t bsd_sh "$log"
sudo sysrc sshd_enable="YES" || {
  ero="$(stamp) ero ### ssh konnte nicht aktiviert werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

log="$(stamp) LOG ### Samba starten"
echo "$log"
logger -t bsd_sh "$log"
sudo service samba_server start || {
  ero="$(stamp) ERO ### Samba konnte nicht gestartet werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

log="$(stamp) LOG ### Samba aktivieren"
echo "$log"
logger -t bsd_sh "$log"
sudo sysrc samba_server_enable="YES" || {
  ero="$(stamp) ERO ### Samba konnte nicht aktiviert werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

#===== Konfig ueberpruefen
ifconfig || {
  ero="$(stamp) ERO ### ifconfig konnte nicht ausgefuehrt werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

sudo pfctl -s info || {
  ero="$(stamp) ERO ### Firewall info konnte nicht ausgelesen werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}

sudo pfctl -s rules || {
  ero="$(stamp) ERO ### Firewall rules konnte nicht ausgelesen werden"
  echo "$ero"
  logger -t bsd_sh "$ero"
  exit 1
}
