#!/bin/bash

# Pfade zu den Bilderordnern
ORDNER1="$HOME/Pictures/lingerie"
ORDNER2="$HOME/Pictures/nice"
ORDNER3="$HOME/Pictures/anal"
ORDNER4="$HOME/Pictures/cum"
ORDNERM="$HOME/Pictures/musik"
delaytime1="20"
delaytime2="4"

# Prüfen, ob die Ordner existieren
for ordner in "$ORDNER1" "$ORDNER2" "$ORDNER3" "$ORDNER4" "$ORDNERM" ; do
  if [ ! -d "$ordner" ]; then
    echo "Fehler: Ordner $ordner existiert nicht!"
    exit 1
  fi
done

# Prüfen, ob feh installiert ist
if ! command -v feh &> /dev/null; then
  echo "Fehler: feh ist nicht installiert. Bitte installiere es mit 'sudo pacman -S feh'."
  exit 1
fi

# VLC auf Worksace 5 staten 
hyprctl dispatch workspace 5
vlc --no-video --random  "$ORDNERM" &
PID1=$!
sleep $delaytime2

# Diashow 1 auf Workspace 4
hyprctl dispatch workspace 4
feh --slideshow-delay $delaytime1 --randomize --scale-down "$ORDNER1" &
PID2=$!
sleep $delaytime2

# Diashow 2 auf Workspace 4
hyprctl dispatch workspace 4
feh --slideshow-delay $delaytime1  --randomize --scale-down "$ORDNER2" &
PID3=$!
sleep $delaytime2

# Diashow 3 auf Workspace 8
hyprctl dispatch workspace 8
feh --slideshow-delay $delaytime1 --randomize --scale-down "$ORDNER3" &
PID4=$!
sleep $delaytime2

# Diashow 4 auf Workspace 4
hyprctl dispatch workspace 8
feh --slideshow-delay $delaytime1 --randomize --scale-down "$ORDNER4" &
PID5=$!
sleep $delaytime2

# Warten auf alle Diashows
wait $PID1 $PID2 $PID3 $PID4 $PID5
echo "Alle Diashows beendet."
