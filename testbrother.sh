#!/usr/bin/env bash
set -e

# Pakete
sudo pkg update
sudo pkg install -y cups cups-filters ghostscript10 avahi-app nss_mdns sane-backends sane-airscan ipp-usb simple-scan epiphany rpm4 bash linux_base-rl9

# Linux-Emulation
sudo sysrc linux_enable=YES
sudo kldload linux linux64
sudo service linux start

# Dienste
sudo sysrc cupsd_enable=YES avahi_daemon_enable=YES ipp-usb_enable=YES
sudo service cupsd start
sudo service avahi-daemon start
sudo service ipp-usb start

# Drucker-Treiber
cd /tmp
fetch https://download.brother.com/welcome/dlf106067/mfcl2860dwepdrv-4.1.0-1.i386.rpm
rpm2cpio mfcl2860dwepdrv-4.1.0-1.i386.rpm | sudo cpio -idmv
sudo sed -i.bak 's/chown lp/chown root/' /opt/brother/Printers/MFCL2860DWE/inf/setupPrintcap
sudo sed -i.bak 's/chgrp lp/chgrp daemon/' /opt/brother/Printers/MFCL2860DWE/inf/setupPrintcap
sudo /opt/brother/Printers/MFCL2860DWE/inf/setupPrintcap MFCL2860DWE -i USB

# Scanner-Treiber
fetch https://download.brother.com/welcome/dlf104036/brscan5-1.5.1-0.x86_64.rpm
rpm2cpio brscan5-1.5.1-0.x86_64.rpm | sudo cpio -idmv
sudo ln -s /opt/brother/scanner/brscan5/libSane-brscan5.so.1.0.0 /usr/local/lib/sane/libsane-brscan5.so.1
sudo ldconfig

# Scanner konfigurieren
sudo mkdir -p /etc/opt/brother/scanner/brscan5
sudo touch /etc/opt/brother/scanner/brscan5/brsaneinetdevice.cfg
sudo chmod 666 /etc/opt/brother/scanner/brscan5/brsaneinetdevice.cfg
sudo /opt/brother/scanner/brscan5/brsaneconfig5 -a name=MFC-L2860DWE model=MFC-L2860DWE nodename=usb://Brother/MFC-L2860DWE

# SANE Backends
echo "brscan5" | sudo tee -a /usr/local/etc/sane.d/dll.conf
echo "airscan" | sudo tee -a /usr/local/etc/sane.d/dll.conf

# devd.conf
cat << EOF | sudo tee /usr/local/etc/devd/brother.conf
notify 100 {
    match "system" "USB";
    match "subsystem" "INTERFACE";
    match "type" "ATTACH";
    match "vendor" "0x04f9";
    match "product" "0x054b";
    action "chown -L cups:saned /dev/\$cdev && chmod -L 660 /dev/\$cdev";
};
EOF
sudo service devd restart

# Gruppen
USERNAME=$(whoami)
sudo pw groupmod cups -m "$USERNAME"
sudo pw groupmod saned -m "$USERNAME"

# Cleanup
sudo pkg upgrade -y
sudo pkg autoremove -y

# Tools
epiphany http://localhost:631 &
simple-scan &

echo "Fertig. Teste: lp -d MFCL2860DWE /usr/share/cups/testprint.ps; scanimage -L"
