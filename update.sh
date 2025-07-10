#!/bin/bash

# Bibliothek einbinden
source /usr/local/lib/loglib.sh

# Log Initialisieren
init_logging || {
  echo "Initialiserung fehlgeschlagen. Skript wird abgebrochen:"
  exit 1
}
log_output "" date 
log_tee "" date 
log_output "" echo -e "Update Skript"
log_tee "" echo -e "Update Skript"

# Suchen nach Updates und installieren
log_tee "" echo -e "\n\n\n------Update------" 
log_tee "" echo -e "\n\n\n------Update Archlinux Keyring------"
log_output "" sudo pacman -Syu archlinux-keyring --noconfirm
log_tee "" echo -e "\n\n\n------Update Pacman------"
log_output "" sudo pacman -Syu --noconfirm  
log_tee "" echo -e "\n\n\n------Update yay------"
log_output "" yay -Syu --noconfirm 
log_tee "" echo -e "\n\n\n------Update npm------"
log_output "" sudo npm update -g  
