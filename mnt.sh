#!/bin/bash

# sdb1 Externe Festplatten finden
if lsblk | grep -q "sdb1"; then
	notify-send "Festplatte usb1 gefunden"
	sudo mkdir -p /mnt/usb1
	notify-send "Ordner wurden erstellt"
	sudo mount -t ntfs-3g /dev/sdb1 /mnt/usb1
	notify-send "Festplatte wurde eingehängt"
	if ! grep -Fxq "file:///mnt/usb1 usb1" ~/.config/gtk-3.0/bookmarks; then
		echo "file:///mnt/usb1 usb1" >>~/.config/gtk-3.0/bookmarks
		notify-send "Bookmark wurde eingetragen"
	else
		notify-send "Bookmark bereits vorhanden"
	fi
else
	notify-send "Festplatte nicht gefunden"
fi

# sdb2 Externe Festplatten finden
if lsblk | grep -q "sdb2"; then
	notify-send "Festplatte usb2 gefunden"
	sudo mkdir -p /mnt/usb2
	notify-send "Ordner wurden erstellt"
	sudo mount -t ntfs-3g /dev/sdb2 /mnt/usb2
	notify-send "Festplatte wurde eingehängt"
	if ! grep -Fxq "file:///mnt/usb2 usb2" ~/.config/gtk-3.0/bookmarks; then
		echo "file:///mnt/usb2 usb2" >>~/.config/gtk-3.0/bookmarks
		notify-send "Bookmark wurde eingetragen"
	else
		notify-send "Bookmark bereits vorhanden"
	fi
else
	notify-send "Festplatte nicht gefunden"
fi
