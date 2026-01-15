#!/usr/bin/env bash
# viel Spaß beim coden!

### creating a script to help me setup my brohter mfc l2860dwe printer
### no network shering jet
### v1.0
### basics

BrotherProgs=(
  "cups"
  "usbutils"
  "cups-filters"
  "epiphany"
  "ghostscript"
  "avahi"
  "nss-mdns"
  "brscan4"
  "sane"
  "sane-airscan"
  "ipp-usb"
  "brother-mfc-l2860dwe"
  "simple-scan"
)

installing() {
  echo "installing the needed prog"
  for prog in "${BrotherProgs[@]}"; do
    echo "installing $prog"
    yay -Sy "$prog" --noconfirm
  done
}

starting() {
  sudo systemctl enable --now avahi-daemon
  sudo systemctl enable --now ipp-usb
  sudo systemctl enable --now cups
}

initing() {
  sudo brsaneconfig4 -a name=MFC model=MFC-L2860DW nodename=usb://Brother/MFC-L2860DW
  lsusb | grep Brother
  [[ "$?" -ne 0 ]] && echo "nothing found" && exit 1
  ippname=$(lpinfo -v | grep Brother | awk '{print $2}')
  echo "ipp saved in ippname"
  echo "$ippname"
  scanimage -L
  [[ "$?" -ne 0 ]] && echo "nothing found" && exit 2
}

cleanup() {
  echo "making an yay update"
  yay -Syu --noconfirm

  echo "cleaning up yay"
  yay -Ycc --noconfirm
}

installing
starting
initing
cleanup
echo "########## $ippname"
(epiphany http://localhost:631) &
(simple-scan) &
