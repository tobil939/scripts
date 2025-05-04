#!/bin/bash

echo -e "Benutzername: ?"
user_name=$(whoami)
LOG_FILE="/home/$user_name/install.log"
ERROR_LOG_FILE="/home/$user_name/errorinstall.log"
datef="$(date '+%Y-%m-%d %H:%M:%S')"
echo -e "\n $datef Benutzername: $user_name \n" >> "$LOG_FILE" 2>> "$ERROR_LOG_FILE"


echo -e "\n \n \n ------bluetooth------"
sudo systemctl start bluetooth.service >> "$LOG_FILE" 2>> "$ERROR_LOG_FILE"
sudo systemctl enable bluetooth.service >> "$LOG_FILE" 2>> "$ERROR_LOG_FILE"

echo -e "\n \n \n ------fertig------"
#reboot
