#!/usr/bin/env bash
set -e

USERNAME=$(whoami)

# Pakete
sudo pkg update
sudo pkg install -y cups cups-filters ghostscript10 avahi-app nss_mdns sane-backends sane-airscan ipp-usb simple-scan epiphany libusb linux_base-c7 rpm4 bash

# Dienste
sudo sysrc cupsd_enable=YES avahi_daemon_enable=YES ippusb_enable=YES
sudo service cupsd start avahi-daemon start ippusb start

# Drucker-Treiber
cd /tmp
fetch https://download.brother.com/welcome/dlf105958/mfcl2860dwlpr-4.1.0-1.i386.rpm
fetch https://download.brother.com/welcome/dlf105959/mfcl2860dwcupswrapper-4.1.0-1.i386.rpm
rpm2cpio mfcl2860dwlpr-*.rpm | sudo cpio -idmv
rpm2cpio mfcl2860dwcupswrapper-*.rpm | sudo cpio -idmv
sudo sed -i.bak 's/chown lp/chown root/' /opt/brother/Printers/MFCL2860DW/inf/setupPrintcap
sudo sed -i.bak 's/chgrp lp/chgrp daemon/' /opt/brother/Printers/MFCL2860DW/inf/setupPrintcap
sudo /opt/brother/Printers/MFCL2860DW/inf/setupPrintcap MFCL2860DW -i USB

# Scanner-Treiber (brscan5)
fetch https://download.brother.com/welcome/dlf106346/brscan5-1.3.2-0.i386.rpm
rpm2cpio brscan5-*.rpm | sudo cpio -idmv
sudo brsaneconfig5 -a name=MFC model=MFC-L2860DW nodename=usb://Brother/MFC-L2860DW

# SANE Backends aktivieren
sudo sysrc -f /usr/local/etc/sane.d/dll.conf brscan5
echo "brscan5" | sudo tee -a /usr/local/etc/sane.d/dll.conf
echo "airscan" | sudo tee -a /usr/local/etc/sane.d/dll.conf

# devd.conf für Permissions (korrigiert)
cat << EOF | sudo tee /usr/local/etc/devd/brother.conf
notify 100 {
    match "system" "USB";
    match "subsystem" "DEVICE";
    match "type" "ATTACH";
    match "vendor" "0x04f9";
    match "product" "0x054b";
    action "chown -L cups:saned /dev/\$cdev && chmod -L 660 /dev/\$cdev";
};
EOF
sudo service devd restart

# Gruppen
sudo pw groupmod cups -m "$USERNAME"
sudo pw groupmod saned -m "$USERNAME"

# Cleanup
sudo pkg upgrade -y
sudo pkg autoremove -y

# Test
echo "Drucker: lpstat -v"
echo "Scanner: scanimage -L"
epiphany http://localhost:631 &
simple-scan &
