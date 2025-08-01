#!/usr/local/bin/bash

#===== Programme die mit pkg installiert werden
prog1=(
  "neovim"
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
  "user1"
  "user2"
  "user3"
  "user4"
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

user_name="$(pwd)"

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
loggin(){
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
rooting(){
  log="$(stamp) LOG ### als Root anmelden"
  echo "$log" 
  logger -t bsd_sh "$log"
  su 
}

#===== erstes Update
updates(){
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
setupBash(){ 
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
  echo "neofetch" >> ~/.bashrc || {
    ero="$(stamp) ERO ### Neofetch konnte nicht hinzugefuegt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }

  log="$(stamp) LOG ### Kitty als Terminal hinzugefuegt"
  echo "$log" 
  logger -t bsd_sh "$log"
  echo "export TERMINAL=kitty" >> ~/.bashrc || {
    ero="$(stamp) ERO ### Kitty als Termnial konnte nicht hinzugefuegt werden"
    echo "$ero"
    logger -t bsd_sh "$ero"
    exit 1
  }
}

#===== Programme werden mit pkg installiert
installprog(){
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
installnpm(){
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
makeDir(){
  mkdir -p "/home/$user_name/Git/config/" "/home/$user_name/Git/scripts" >>"$log_file" 2>>"$error_log_file"
  mkdir -p "/home/$user_name/Scripts" "/home/$user_name/git1/config" "/home/$user_name/git1/scripts" "/home/$user_name/git1/neovim" >>"$log_file" 2>>"$error_log_file"
  mkdir -p "$HOME/.config/nvim/lua/config" "$HOME/.config/nvim/lua/plugins" "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/kitty" "$HOME/.config/qutebrowser" 
}

#===== Git-Repositories klonen
gitClone(){
  echo -e "\n ------Dateien klonen------"
  notify-send "Dateien werden geklont"
  for repo in "${git_repo[@]}"; do
    echo "$repo" >>"$log_file" 2>>"$error_log_file"
    git clone "https://github.com/tobil939/$repo.git" "/home/$user_name/git1/$repo" >>"$log_file" 2>>"$error_log_file"
    echo "https://github.com/tobil939/$repo.git" >>"$log_file" 2>>"$error_log_file"
    echo "/home/$user_name/git1/$repo" >>"$log_file" 2>>"$error_log_file"
    check_error "Klonen von $repo" >>"$log_file" 2>>"$error_log_file"
  done
}

#===== Dateien aus tobil939/config kopieren
confCopy(){
  echo -e "\n ------Daten kopieren (config)------"
  notify-send "Konfigurationsdateien werden kopiert"
  cd /home/$user_name/git1/config
  check_error "Wechseln in config-Verzeichnis"

  #===== Neovim-Dateien
  for file in "${nvim_plugin_files[@]}"; do
    if [ ! -f "/home/$user_name/git1/config/$file" ]; then
      echo "Fehler: $file existiert nicht in /home/$user_name/git1/config/" >>"$log_file" 2>>"$error_log_file"
      check_error "Quelldatei $file fehlt"
    fi
    if [ -f "$HOME/.config/nvim/lua/plugins/$file" ]; then
      mv "$HOME/.config/nvim/lua/plugins/$file" "$HOME/.config/nvim/lua/plugins/$file.bak" >>"$log_file" 2>>"$error_log_file"
      echo "Backup von $file erstellt" >>"$log_file"
    else
      mkdir -p "$HOME/.config/nvim/lua/plugins/"
      echo "nvim plugins Ordner wurde ertellt"
    fi
    cp "/home/$user_name/git1/config/$file" "$HOME/.config/nvim/lua/plugins/$file" >>"$log_file" 2>>"$error_log_file"
    check_error "Kopieren von $file"
  done
  for file in "${nvim_config_files[@]}"; do
    if [ ! -f "/home/$user_name/git1/config/$file" ]; then
      echo "Fehler: $file existiert nicht in /home/$user_name/git1/config/" >>"$log_file" 2>>"$error_log_file"
      check_error "Quelldatei $file fehlt"
    else
      mkdir -p "$HOME/.config/nvim/lua/config/"
      echo "nvim config Ordner wurde erstllt"
    fi
    if [ -f "$HOME/.config/nvim/lua/config/$file" ]; then
      mv "$HOME/.config/nvim/lua/config/$file" "$HOME/.config/nvim/lua/config/$file.bak" >>"$log_file" 2>>"$error_log_file"
      echo "Backup von $file erstellt" >>"$log_file"
    fi
    cp "/home/$user_name/git1/config/$file" "$HOME/.config/nvim/lua/config/$file" >>"$log_file" 2>>"$error_log_file"
    check_error "Kopieren von $file"
  done
  if [ ! -f "/home/$user_name/git1/config/init.lua" ]; then
    echo "Fehler: init.lua existiert nicht in /home/$user_name/git1/config/" >>"$log_file" 2>>"$error_log_file"
    check_error "Quelldatei init.lua fehlt"
  fi
  if [ -f "$HOME/.config/nvim/init.lua" ]; then
    mv "$HOME/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua.bak" >>"$log_file" 2>>"$error_log_file"
    echo "Backup von init.lua erstellt" >>"$log_file"
  fi
  cp "/home/$user_name/git1/config/init.lua" "$HOME/.config/nvim/init.lua" >>"$log_file" 2>>"$error_log_file"
  check_error "Kopieren von init.lua"

  # Hyprland-Dateien
  for file in "${hypr_files[@]}"; do
    if [ ! -f "/home/$user_name/git1/config/$file" ]; then
      echo "Fehler: $file existiert nicht in /home/$user_name/git1/config/" >>"$log_file" 2>>"$error_log_file"
      check_error "Quelldatei $file fehlt"
    fi
    if [ -f "$HOME/.config/hypr/$file" ]; then
      mv "$HOME/.config/hypr/$file" "$HOME/.config/hypr/$file.bak" >>"$log_file" 2>>"$error_log_file"
      echo "Backup von $file erstellt" >>"$log_file"
    else
      mkdir -p "$HOME/.config/hypr/"
      echo "hypr Ordner wurde erstellt"
    fi
    cp "/home/$user_name/git1/config/$file" "$HOME/.config/hypr/$file" >>"$log_file" 2>>"$error_log_file"
    check_error "Kopieren von $file"
  done
}

#===== Netzwerkschnittstellen konfigurieren
ipConfigRouter(){
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
}

#===== Firewall konfigurieren
firewallConfigRouter(){
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
pass in on $lan_if proto tcp from any to any port {139, 445} keep state 
EOL
}

#===== DHCP konfigurieren
dhcpConfig(){
  log="$(stamp) LOG ### dhcp.conf wird beschhrieben"
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
}

#===== WLan Accespoint konfigurieren
wlanConfig(){
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
}

#===== Samba einrichten
sambaConfig(){
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
}


#===== Samba Verzeichnisse und Rechte anlegen
sambaUser(){
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
  for user in "${users{[@]}"; do 
    pw groupmod users -m "$user" || { 
      ero="$(stamp) ERO ### Benutzer $user konnte nicht zur Gruppe hinzugefuegt werden"
      logger -t bsd_sh "$ero"
      exit 1
    }
  done
}

#===== SSH Konfiguration ändern
sshConfig(){
  log="$(stamp) LOG ### sshd_config wird angepasst"
  echo "$log"
  logger -t bsd_sh "$log"
  sed -i '' -e '/^#\?X11Forwarding/s/.*/X11Forwarding yes/' "$sshconf"
  sed -i '' -e '/^#\?X11UseLocalhost/s/.*/X11UseLocalhost no/' "$sshconf"
  grep -q '^X11Forwarding' "$sshconf" || echo "X11Forwarding yes" | tee -a "$sshconf"
  grep -q '^X11UseLocalhost' "$sshconf" || echo "X11UseLocalhost no" | tee -a "$sshconf"
}

startFirewall(){
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

startDhcp(){
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

startSsh(){
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

startSamba(){
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

startWlan(){
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

startAntivir(){
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
checkConfigRouter(){
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

main(){
  # Zeitstempel 
  stamp

  # Logging einrichten
  loggin 

  # Als su anmelden 
  rooting

  # erstes Update
  updates

  # Bash einrichten 
  setupBash

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
  confCopy 

  # Setup Router 
  ipConfigRouter
  firewallConfigRouter
  dhcpConfig 
  wlanConfig 
  sambaConfig 
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

  # drittes Update 
  updates 
}

