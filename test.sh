#!/bin/bash

# Sicherheitschecks
if ! command -v sudo >/dev/null; then
  echo "sudo ist nicht installiert. Skript wird abgebrochen."
  exit 1
fi

# Benutzername und Log-Dateien
user_name=$(whoami)
log_file="/home/$user_name/Log/kopieren.txt"
error_log_file="/home/$user_name/Log/errorkopieren.txt"
datef="$(date '+%Y-%m-%d %H:%M:%S')"

user_name=$(whoami)
cp -r /home/$user_name/git1/scripts/* $HOME/Scripts/

