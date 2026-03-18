#!/bin/sh
# HP Z440 FreeBSD Router + NAS Setup
# als root ausführen

LOGFILE="/var/log/setup_router_nas.log"
log() { echo "$(date '+%F %T') | $1" | tee -a $LOGFILE; }

log "=== START SETUP ==="

# -------------------------
# Pakete
# -------------------------
log "Installiere Pakete..."
pkg update
pkg install -y samba419 isc-dhcp44-server rkhunter cups sane-airscan avahi-app

# -------------------------
# ZFS Pools
# -------------------------
log "Erstelle ZFS Pools..."

# speicher1 (ACHTUNG: Partition anpassen!)
zpool create -f -o ashift=12 speicher1 /dev/nda0p4 2>/dev/null || true
zfs set mountpoint=/speicher1 speicher1

# speicher2 RAID1
zpool create -f -o ashift=12 speicher2 mirror /dev/ada0 /dev/ada1 2>/dev/null || true
zfs set mountpoint=/speicher2 speicher2

# -------------------------
# User + Rechte
# -------------------------
log "User + Rechte..."

pw groupadd users 2>/dev/null || true
pw useradd tobil -m -g users -s /bin/sh 2>/dev/null || true
echo "12345" | pw usermod tobil -h 0

chown -R root:users /speicher1 /speicher2
chmod -R 775 /speicher1 /speicher2

# -------------------------
# Samba
# -------------------------
log "Samba einrichten..."

echo -e "12345\n12345" | smbpasswd -s -a tobil

cat > /usr/local/etc/smb4.conf <<EOF
[global]
   workgroup = WORKGROUP
   security = user
   map to guest = Bad User

[speicher1]
   path = /speicher1
   browsable = yes
   writable = yes
   valid users = @users
   create mask = 0775
   directory mask = 0775

[speicher2]
   path = /speicher2
   browsable = yes
   writable = yes
   valid users = @users
   create mask = 0775
   directory mask = 0775
EOF

sysrc samba_server_enable="YES"

# -------------------------
# Netzwerk
# -------------------------
log "Netzwerk konfigurieren..."

sysrc ifconfig_re0="DHCP"

sysrc cloned_interfaces="bridge0"
sysrc ifconfig_em0="up"
sysrc ifconfig_igb0="up"
sysrc ifconfig_igb1="up"
sysrc ifconfig_bridge0="addm em0 addm igb0 addm igb1 inet 10.10.10.1 netmask 255.255.255.0 up"

sysrc gateway_enable="YES"

# -------------------------
# DHCP Server
# -------------------------
log "DHCP konfigurieren..."

sysrc dhcpd_enable="YES"
sysrc dhcpd_ifaces="bridge0"

cat > /usr/local/etc/dhcpd.conf <<EOF
subnet 10.10.10.0 netmask 255.255.255.0 {
  range 10.10.10.3 10.10.10.20;
  option routers 10.10.10.1;
  option domain-name-servers 8.8.8.8;
}

host brother_printer {
  hardware ethernet XX:XX:XX:XX:XX:XX;
  fixed-address 10.10.10.2;
}
EOF

# -------------------------
# Firewall (pf + NAT)
# -------------------------
log "Firewall konfigurieren..."

cat > /etc/pf.conf <<EOF
ext_if="re0"
int_if="bridge0"

set skip on lo

nat on \$ext_if from \$int_if:network to any -> (\$ext_if)

block all
pass out all keep state
pass in on \$int_if all keep state
EOF

sysrc pf_enable="YES"

# -------------------------
# SSH
# -------------------------
log "SSH aktivieren..."
sysrc sshd_enable="YES"

# -------------------------
# rkhunter
# -------------------------
log "rkhunter einrichten..."
rkhunter --update
rkhunter --propupd

# -------------------------
# Dienste starten
# -------------------------
log "Starte Dienste..."
service netif restart
service routing restart
service pf start
service dhcpd start
service samba_server start
service sshd start

log "=== SETUP FERTIG ==="
echo "👉 Reboot empfohlen: shutdown -r now"
