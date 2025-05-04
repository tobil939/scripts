#!/bin/bash

# Benutzernamen herausfinden
echo -e "Benutzername: ?"
user_name=$(whoami)
mkdir -p "/home/$user_name/log/error"                                              # LOG Ordner erstellen
LOG_FILE="/home/$user_name/log/install.log"                                        # LOG allgemein
ERROR_LOG_FILE="/home/$user_name/log/error/errorinstall.log"                       # LOG Error
datef="$(date '+%Y-%m-%d %H:%M:%S')"                                              # Datum formatieren

# Erste LOG Einträge
echo -e "\n$datef Benutzername: $user_name\n" | tee -a "$LOG_FILE" 2> >(tee -a "$ERROR_LOG_FILE" >/dev/null)

# Suchen nach Updates und installieren
echo -e "\n\n\n------Update------" | tee -a "$LOG_FILE"
sudo pacman -Syu --noconfirm 2> >(tee -a "$ERROR_LOG_FILE" >/dev/null) | tee -a "$LOG_FILE"
yay -Syu --noconfirm 2> >(tee -a "$ERROR_LOG_FILE" >/dev/null) | tee -a "$LOG_FILE"
sudo npm update -g 2> >(tee -a "$ERROR_LOG_FILE" >/dev/null) | tee -a "$LOG_FILE"
