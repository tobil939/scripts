#!/usr/local/bin/bash

#===== Programme die mit pkg installiert werden
prog1=(
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

#===== Programme die mit NPM installiert werden
npmprog=(
  "bash-language-server"
  "tree-sitter"
)

#===== Benutzer anlegen
users=(
  "speicher"
  "tobil"
)

git_repo=(
  "config"
  "scripts"
  "neovim"
)

nvim_plugin_files=(
  "aerial.lua"
  "alpha.lua"
  "cmp.lua"
  "dap.lua"
  "formatter.lua"
  "help.lua"
  "lint.lua"
  "lsp.lua"
  "lualine.lua"
  "luasnip.lua"
  "mason.lua"
  "nvim-tree.lua"
  "telescope.lua"
  "toggleterm.lua"
  "treesitter.lua"
  "theme.lua"
)
nvim_config_files=(
  "autocmds.lua"
  "keymaps.lua"
  "options.lua"
)

user_name="$(whoami)"

#===== Wlan Accespoint Konfiguration
wpaID=""
wpaPW=""
lan_net="10.10.10.0/24"
ext_if="eno1"
lan_if="bridge0"

#===== IP-Adrese
netMask="255.255.255.0"
routerIP="10.10.10.1"
speicher2IP="10.10.10.2"
ext_if="eno1"
lan_if="bridge0"

#===== Ports
portDHCPfrom="67"
portDHCPto="68"
portDNS="53"
portSSH="22"
portSambafrom="139"
portSambato="455"

#===== Zeitstempel werden definiert
stamp() {
  date '+%H:%M:%S'
}

#===== Konfigdateien
rcconf="/etc/rc.conf"
pfconf="/etc/pf.conf"
dhcpconf="/usr/local/etc/dhcpd.conf"
hostapdconf="/usr/local/etc/hostapd.conf"
sambaconf="/usr/local/etc/smb4.conf"
sshconf="/etc/ssh/sshd_config"

#===== Logging wird definerit
loggin() {
  day=$(date '+%Y-%m-%d')
  echo "logging einrichten"
  echo "log anlegen"
  touch /var/log/install
  chmod 640 /var/log/install
  echo "syslog.conf einstellen"
  sh -c 'echo "bsd_sh" >>/etc/syslog.conf'
  sh -c 'echo "*.*     /var/log/install" >>/etc/syslog.conf'
  echo "syslog neu starten"
  service syslogd reload

  #===== Erster Loggeintrag
  log="$day $(stamp) LOG ### erster Log eintrag"
  echo "$log"
  logger -t bsd_sh "$log"
}

#===== als Root anmelden
rooting() {
  log="$(stamp) LOG ### als Root anmelden"
  echo "$log"
  logger -t bsd_sh "$log"
  su
}

#===== erstes Update
updates() {
  log="$(stamp) LOG ### erstes Update"
  echo "$log"
  logger -t bsd_sh "$log"

  pkg update || {
    ero="$(stamp) ERO ### Update konnte nicht durchgeführt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### erstes Upgrade"
  echo "$log"
  logger -t bsd_sh "$log"

  pkg upgrade -y || {
    ero="$(stamp) ERO ### Upgrade konnte nicht installiert werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
}

#===== Bash einrichten
setupBash() {
  log="$(stamp) LOG ### Bash einrichten"
  echo "$log"
  logger -t bsd_sh "$log"
  touch ~/.bashrc || {
    ero="$(stamp) ERO ### bashrc konnte nicht angelegt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### Neofetch hinzugefuegt"
  echo "$log"
  logger -t bsd_sh "$log"
  echo "neofetch" >>~/.bashrc || {
    ero="$(stamp) ERO ### Neofetch konnte nicht hinzugefuegt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### Kitty als Terminal hinzugefuegt"
  echo "$log"
  logger -t bsd_sh "$log"
  echo "export TERMINAL=kitty" >>~/.bashrc || {
    ero="$(stamp) ERO ### Kitty als Termnial konnte nicht hinzugefuegt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
}

#===== Programme werden mit pkg installiert
installprog() {
  for prog in "${prog1[@]}"; do
    log="$(stamp) LOG ### $prog wird installiert"
    ero="$(stamp) ERO ### $prog konnte nicht installiert werden"
    echo "$log" && logger -t bsd_sh "$log"
    pkg install -y "$prog" || {
      echo "$ero"
      logger -t bsd_sh "$ero"
      exit 1
    }
  done
}

#===== Programme werden mit npm installiert
installnpm() {
  for prog in "${npmprog[@]}"; do
    log="$(stamp) LOG ### $prog wird installiert"
    ero="$(stamp) ERO ### $prog konnte nicht installiert werden"
    npm install -g "$prog" --silent || {
      echo "$ero"
      logger -t bsd_sh "$ero"
      exit 1
    }
  done
}

#===== Ordnererstellung
makeDir() {
  log="$(stamp) LOG ### Ordnerstruktur wird erstellt"
  echo "$log"
  logger -t bsd_sh "$log"
  log="$(stamp) LOG ### /.config/nvim/lua/config/ wird erstellt"
  mkdir -p "/home/$user_name/.config/nvim/lua/config/" || {
    ero="$(stamp) ERO ### nvim/lua/config/ konnte nicht erstellt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### /.config/nvim/lua/plugins wird erstellt"
  echo "$log"
  logger -t bsd_sh "$log"
  mkdir -p "/home/$user_name/.config/nvim/lua/plugins/" || {
    ero="$(stamp) ERO ### nvim/lua/plugins/ konnte nicht erstellt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### /.config/kitty wird erstellt"
  echo "$log"
  logger -t bsd_sh "$log"
  mkdir -p "/home/$user_name/.config/kitty/" || {
    ero="$(stamp) ERO ### /.config/kitty/ konnte nicht erstellt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### Scripts wird erstellt"
  echo "$log"
  logger -t bsd_sh "$log"
  mkdir -p "/home/$user_name/Scripts" || {
    ero="$(stamp) ERO ### Scritps konnte nicht erstellt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### git1 wird erstellt"
  echo "$log"
  logger -t bsd_sh "$log"
  mkdir -p "/home/$user_name/git1" || {
    ero="$(stamp) ERO ### git1 konnte nicht erstellt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
}

#===== Git-Repositories klonen
gitClone() {
  for repo in "${git_repo[@]}"; do
    log="$(stamp) LOG ### $repo wird gecloned"
    echo "$log"
    logger -t bsd_sh "$log"
    git clone "https://github.com/tobil939/$repo.git" || {
      ero="$(stamp) ERO ### $repo konnte nicht gecloned werden"
      echo "$ero"
      logger -t bsd_sh "$ero"
      exit 1
    }
  done
}

#===== Dateien aus tobil939/git kopieren
gitCopy() {
  log="$(stamp) LOG ### git Daten werden kopiert"
  echo "$log"
  logger -t bsd_sh "$log"

  log="$(stamp) LOG ### Scripts Daten werden kopiert"
  echo "$log"
  logger -t bsd_sh "$log"
  cp -r "/home/$user_name/git1/scripts/" "/home/$user_name/Scripts/" || {
    ero="$(stamp) ERO ### Scripts konnte nicht kopiert werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### kitty.conf Daten werden kopiert"
  echo "$log"
  logger -t bsd_sh "$log"
  cp "/home/$user_name/git1/config/kitty.conf" "/home/$user_name/.config/kitty/kitty.conf" || {
    ero="$(stamp) ERO ### kitty.conf konnte nicht kopiert werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### init.lua Daten werden kopiert"
  echo "$log"
  logger -t bsd_sh "$log"
  cp "/home/$user_name/git1/neovim/init.lua" "/home/$user_name/.config/nvim/init.lua" || {
    ero="$(stamp) ERO ### init.lua konnte nicht kopiert werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### nvim/lua/config/ werden kopiert"
  echo "$log"
  logger -t bsd_sh "$log"
  for file in "${nvim_config_files[@]}"; do
    log="$(stamp) LOG ### $file wird kopiert"
    echo "$log"
    logger -t bsd_sh "$log"
    cp "/home/$user_name/git1/neovim/$file" "/home/$user_name/.config/nvim/lua/config/$file" || {
      ero="$(stamp) ERO ### $file konnte nicht kopiert werden"
      echo "$ero"
      logger -t bsd_sh "$ero"
      exit 1
    }
  done

  log="$(stamp) LOG ### nvim/lua/plugins/ werden kopiert"
  echo "$log"
  logger -t bsd_sh "$log"
  for file in "${nvim_plugin_files[@]}"; do
    log="$(stamp) LOG ### $file wird kopiert"
    echo "$log"
    logger -t bsd_sh "$log"
    cp "/home/$user_name/git1/neovim/$file" "/home/$user_name/.config/nvim/lua/plugins/$file" || {
      ero="$(stamp) ERO ### $file konnte nicht kopiert werden"
      echo "$ero"
      logger -t bsd_sh "$ero"
      exit 1
    }
  done
}

#===== Netzwerkschnittstellen konfigurieren
ipRouterConfig() {
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
ifconfig_bridge0_alias0="inet $routerIP netmask $netMask"

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
}

ipSpeicherConfig() {
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
ifconfig_bridge0_alias0="inet $speicher2IP netmask $netMask"

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
}
#===== Firewall konfigurieren
firewallConfigRouter() {
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
pass in on $ext_if proto udp from any port $portDHCPfrom to any port $portDHCPto keep state

# Allow DNS queries from LAN
pass out on $ext_if proto udp from any to any port $portDNS keep state
pass out on $ext_if proto tcp from any to any port $portDNS keep state

# Allow SSH
pass in on $ext_if proto tcp from any to ($ext_if) port $portSSH keep state
pass in on $lan_if proto tcp from any to any port $portSSH keep state

# Allow Samba 
pass in on $lan_if proto tcp from any to any port {$portSambafrom, $portSambato} keep state 
EOL
}

#===== DHCP konfigurieren
dhcpConfig() {
  log="$(stamp) LOG ### dhcp.conf wird beschhrieben"
  echo "$log"
  logger -t bsd_sh "$log"

  cat >>"$dhcpconf" <<EOL
option domain-name "home.local";
option domain-name-servers $routerIP, 1.1.1.1;

default-lease-time 600;
max-lease-time 7200;

subnet 10.10.10.0 netmask $netMask {
  range 10.10.10.100 10.10.10.200;
  option routers $routerIP;
  option broadcast-address 10.10.10.255;
  option subnet-mask $netMask;
}
EOL
}

#===== WLan Accespoint konfigurieren
wlanConfig() {
  log="$(stamp) LOG ### hostapd.conf wird beschhrieben"
  echo "$log"
  logger -t bsd_sh "$log"

  cat >>"$hostapdconf" <<EOL
interface=wlan1
driver=bsd
ssid=$wpaID
hw_mode=g
channel=6
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=$wpaPW
rsn_pairwise=CCMP
EOL
}

#===== Samba einrichten
sambaSpeicher1Config() {
  log="$(stamp) LOG ### smb4.conf wird beschrieben"
  echo "$log"
  logger -t bsd_sh "$log"

  cat >>"$sambaconf" <<EOL
[global]
   workgroup = WORKGROUP
   server string = FreeBSD Samba Server
   netbios name = Speicher1
   security = user
   map to guest = Bad User
   log file = /var/log/samba4/log.%m
   max log size = 50
   dns proxy = no
   # Optional: Bind an spezifische IP, falls gewünscht
   # interfaces = 192.168.1.100
   # bind interfaces only = yes

[public]
   path = /srv/samba/public
   public = yes
   writable = yes
   guest ok = yes
   guest only = yes
   create mask = 0775
   directory mask = 0775
   # Optional: Besitzer und Gruppe für bessere Kontrolle
   force user = nobody
   force group = nogroup

[private]
   path = /srv/samba/private
   valid users = @users
   guest ok = no
   writable = yes
   create mask = 0700
   directory mask = 0700
   # Optional: Besitzer und Gruppe für bessere Kontrolle
   force user = youruser
   force group = users
EOL}

sambaSpeicher2Config() {
  log="$(stamp) LOG ### smb4.conf wird beschrieben"
  echo "$log"
  logger -t bsd_sh "$log"

  cat >>"$sambaconf" <<EOL
[global]
   workgroup = WORKGROUP
   server string = FreeBSD Samba Server
   netbios name = Speicher2
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
}

#===== Samba Verzeichnisse und Rechte anlegen
sambaUser() {
  log="$(stamp) LOG ### public Verzeiniss anlegen"
  echo "$log"
  logger -t bsd_sh "$log"
  mkdir -p /srv/samba/public || {
    ero="$(stamp) ERO ### public Verzeiniss konnte nicht anlegen werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
  log="$(stamp) LOG ### private Verzeiniss anlegen"
  echo "$log"
  logger -t bsd_sh "$log"
  mkdir -p /srv/samba/private || {
    ero="$(stamp) ERO ### private Verzeiniss konnte nicht anlegen werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
  log="$(stamp) LOG ### Rechte nobody vergeben"
  echo "$log"
  logger -t bsd_sh "$log"
  chown -R nobody:nogroup /srv/samba/public || {
    ero="$(stamp) ERO ### rechte nobody konnten nicht vergeben werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
  log="$(stamp) LOG ### 0775 für public"
  echo "$log"
  logger -t bsd_sh "$log"
  chmod -R 0775 /srv/samba/public || {
    ero="$(stamp) ERO ### 0775 konten nicht vergeben werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### Gruppe user wurde angelegt"
  echo "$log"
  logger -t bsd_sh "$log"
  pw groupadd users || {
    ero="$(stamp) ERO ### Gruppe user konnte nicht angelegt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  for user in "${users[@]}"; do
    log="$(stamp) LOG ### Benutzer $user wird für Samba angelegt"
    echo "$log" | tee -a /var/log/bsd_install.log | logger -t bsd_sh
    pw useradd "$user" -m || {
      ero="$(stamp) ERO ### Benutzer $user konnte nicht erstellt werden"
      logger -t bsd_sh "$ero"
      exit 1
    }
    pdbedit -a "$user" || {
      ero="$(stamp) ERO ### Samba-Benutzer $user konnte nicht angelegt werden"
      logger -t bsd_sh "$ero"
      exit 1
    }
  done

  log="$(stamp) LOG ### user werden in die Gruppe users hinzugefuegt"
  echo "$log"
  logger -t bsd_sh "$log"
  for user in "${users[@]}"; do
    pw groupmod users -m "$user" || {
      ero="$(stamp) ERO ### Benutzer $user konnte nicht zur Gruppe hinzugefuegt werden"
      logger -t bsd_sh "$ero"
      exit 1
    }
  done
}

#===== SSH Konfiguration ändern
sshConfig() {
  log="$(stamp) LOG ### sshd_config wird angepasst"
  echo "$log"
  logger -t bsd_sh "$log"
  sed -i '' -e '/^#\?X11Forwarding/s/.*/X11Forwarding yes/' "$sshconf"
  sed -i '' -e '/^#\?X11UseLocalhost/s/.*/X11UseLocalhost no/' "$sshconf"
  grep -q '^X11Forwarding' "$sshconf" || echo "X11Forwarding yes" | tee -a "$sshconf"
  grep -q '^X11UseLocalhost' "$sshconf" || echo "X11UseLocalhost no" | tee -a "$sshconf"
}

startFirewall() {
  log="$(stamp) LOG ### Firewall starten"
  echo "$log"
  logger -t bsd_sh "$log"
  service pf start || {
    ero="$(stamp) ERO ### Firewall konnte nicht neu gestartet werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  pfctl -f /etc/pf.conf || {
    ero="$(stamp) ERO ### Firewall konnte nicht neu gestartet werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### Firewall aktivieren"
  echo "$log"
  logger -t bsd_sh "$log"
  sysrc pf_enable="YES" || {
    ero="$(stamp) ERO ### Firewall konnte nicht aktiviert werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
}

startDhcp() {
  log="$(stamp) LOG ### DHCP starten"
  echo "$log"
  logger -t bsd_sh "$log"
  service isc-dhcpd start || {
    ero="$(stamp) ERO ### DHCP konnte nicht neu gestartet werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### DHCP aktivieren"
  echo "$log"
  logger -t bsd_sh "$log"
  sysrc isc_dhcpd_enable="YES" || {
    ero="$(stamp) ERO ### DHCP konnte nicht aktiviert werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
}

startSsh() {
  log="$(stamp) LOG ### ssh starten"
  echo "$log"
  logger -t bsd_sh "$log"
  service sshd start || {
    ero="$(stamp) ero ### ssh konnte nicht neu gestartet werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### ssh aktivieren"
  echo "$log"
  logger -t bsd_sh "$log"
  sysrc sshd_enable="YES" || {
    ero="$(stamp) ero ### ssh konnte nicht aktiviert werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
}

startSamba() {
  log="$(stamp) LOG ### Samba starten"
  echo "$log"
  logger -t bsd_sh "$log"
  service samba_server start || {
    ero="$(stamp) ERO ### Samba konnte nicht gestartet werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### Samba aktivieren"
  echo "$log"
  logger -t bsd_sh "$log"
  sysrc samba_server_enable="YES" || {
    ero="$(stamp) ERO ### Samba konnte nicht aktiviert werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
}

startWlan() {
  log="$(stamp) LOG ### hostapd aktivieren"
  echo "$log"
  logger -t bsd_sh "$log"
  sysrc hostapd_enable="YES" || {
    ero="$(stamp) ERO ### hostapd konnte nicht aktiviert werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
}

startAntivir() {
  log="$(stamp) LOG ### Antivirus aktivieren"
  echo "$log"
  logger -t bsd_sh "$log"
  sysrc clamav_clamd_enable="YES" || {
    ero="$(stamp) ERO ### Antivirus konnte nicht aktiviert werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
}

#===== Konfig ueberpruefen
checkConfigRouter() {
  ifconfig || {
    ero="$(stamp) ERO ### ifconfig konnte nicht ausgefuehrt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  pfctl -s info || {
    ero="$(stamp) ERO ### Firewall info konnte nicht ausgelesen werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  pfctl -s rules || {
    ero="$(stamp) ERO ### Firewall rules konnte nicht ausgelesen werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
}

main() {
  # Zeitstempel
  stamp

  # Logging einrichten
  loggin

  # erstes Update
  updates

  # Installation von pkg Programmen
  installprog

  # Installation von npm Programmen
  installnpm

  # zweites Update
  updates

  # Ordnerstruktur erstellen
  makeDir

  # Git Repos clonen
  gitClone

  # Konfigurationsdateien kopieren
  gitCopy

  # Setup Router
  ipRouterConfig
  firewallConfigRouter
  dhcpConfig
  wlanConfig
  sambaSpeicher1Config
  sambaUser
  sshConfig
  startFirewall
  startDhcp
  startSsh
  startSamba
  startWlan
  startAntivir

  # Check Setup Router
  checkConfigRouter

  #  # Setup Speicher2
  #  ipSpeicherConfig
  #  sambaSpeicher2Config
  #  sambaUser
  #  sshConfig
  #  startSsh
  #  startSamba

  # drittes Update
  updates
}

main
