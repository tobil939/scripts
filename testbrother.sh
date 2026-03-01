#!/usr/bin/env bash
set -e

# Pakete installieren
sudo pkg update
sudo pkg install -y cups cups-filters ghostscript10 avahi-app nss_mdns sane-backends sane-airscan ipp-usb simple-scan epiphany libusb linux_base-c7 rpm4 bash

# Dienste aktivieren/starten
sudo sysrc cupsd_enable=YES
sudo sysrc avahi_daemon_enable=YES
sudo sysrc ippusb_enable=YES
sudo service cupsd start
sudo service avahi-daemon start
sudo service ippusb start

# Brother Printer Treiber (LPR + CUPS) herunterladen und installieren
cd /tmp
fetch https://download.brother.com/welcome/dlf105958/mfcl2860dwlpr-4.1.0-1.i386.rpm
fetch https://download.brother.com/welcome/dlf105959/mfcl2860dwcupswrapper-4.1.0-1.i386.rpm
rpm2cpio mfcl2860dwlpr-4.1.0-1.i386.rpm | sudo cpio -idmv
rpm2cpio mfcl2860dwcupswrapper-4.1.0-1.i386.rpm | sudo cpio -idmv
sudo sed -i.bak 's/chown lp/chown root/' /opt/brother/Printers/MFCL2860DW/inf/setupPrintcap
sudo sed -i.bak 's/chgrp lp/chgrp daemon/' /opt/brother/Printers/MFCL2860DW/inf/setupPrintcap
sudo /opt/brother/Printers/MFCL2860DW/inf/setupPrintcap MFCL2860DW -i USB

# Brother Scanner Treiber (brscan4)
fetch https://download.brother.com/welcome/dlf006893/brscan4-0.4.11-1.i386.rpm
rpm2cpio brscan4-0.4.11-1.i386.rpm | sudo cpio -idmv
sudo brsaneconfig4 -a name=MFC model=MFC-L2860DW nodename=usb://Brother/MFC-L2860DW

# USB checken
usbconfig list | grep Brother || { echo "Kein Brother-Gerät gefunden"; exit 1; }

# IPP finden
ippname=$(lpinfo -v | grep Brother | awk '{print $2}')
echo "IPP: $ippname"

# Scanner checken
scanimage -L || { echo "Kein Scanner gefunden"; exit 2; }

# Cleanup
sudo pkg upgrade -y
sudo pkg autoremove -y

# Tools öffnen
epiphany http://localhost:631 &
simple-scan &

echo "Fertig. Drucker in CUPS konfigurieren falls nötig."
