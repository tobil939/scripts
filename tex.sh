#!/bin/bash

# Bash-Script for initialisation of Bluetooth Devices
# Rev. 2.0
# Includes Errorhandling, sort of, better Messages

# Variabels
tex_file=$1

pdf_file="${tex_file%.tex}.pdf"
aux_file="${tex_file%.tex}.aux"
dvi_file="${tex_file%.tex}.dvi"
log_file="${tex_file%.tex}.log"
out_file="${tex_file%.tex}.out"
toc_file="${tex_file%.tex}.toc"
nav_file="${tex_file%.tex}.nav"
snm_file="${tex_file%.tex}.snm"

# Logging
# Place where the Logfile will be saved
logfile="latex.log"

# Timestamp
get_timestamp() {
  timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
}

logging() {
  get_timestamp
  if [[ -f "$logfile" ]]; then
    echo "Logfile exists"
  else
    echo "Logfile will be created"
    touch "$logfile" || exit 1
  fi

  get_timestamp
  [[ -f "$logfile" ]] || exit 1
  echo "$timestamp first entry" | tee -a "$logfile" || exit 1
}

# Errorhandling
# Better Errormessages
handling() {
  get_timestamp
  local error
  error="$?"
  case $error in
  0) (
    echo "$timestamp everything went as planned, no errors" | tee -a "$logfile"
    echo "$timestamp Logfile will be moved into /tmp" | tee -a "$logfile"
    mv -v "$logfile" "/tmp/latex.log"
  ) ;;
  1) echo "$timestamp something went wrong with the logfile" | tee -a "$logfile" ;;
  2) echo "$timestamp must be run as root or with sudo!" | tee -a "$logfile" ;;
  3) echo "$timestamp No tex file was added, or exists" | tee -a "$logfile" ;;
  4) echo "$timestamp pdf/ or out/ cannot be cleard" | tee -a "$logfile" ;;
  5) echo "$timestamp pdf/ or out/ cannot be create" | tee -a "$logfile" ;;
  6) echo "$timestamp error while running lualatex" | tee -a "$logfile" ;;
  7) echo "$timestamp error while running pdflatex" | tee -a "$logfile" ;;
  8) echo "$timestamp cannot move the contend of out/ and/or pdf/" | tee -a "$logfile" ;;
  9) echo "$timestamp cannot move the logfile to temp" | tee -a "$logfile" ;;
  *) echo "$timestamp unknown error" | tee -a "$logfile" ;;
  esac
}

# Root
# Checking if it was stared with sudo
rootcheck() {
  get_timestamp
  if [[ $UID -ne 0 ]]; then
    exit 4
  fi
}

# Arguments
# Checking if there was an Arguments (.tex file) added
argumentscheck() {
  get_timestamp
  if [ -z "$tex_file" ]; then
    echo "$timestamp Usage: ./tex.sh <datei.tex>" | tee -a "$logfile"
    exit 3
  fi
}

# Cleanup
# cleaning up the directorys
cleanup() {
  local filename
  get_timestamp
  if [[ -d "out/" ]]; then
    echo "$timestamp out/ will be cleard" | tee -a "$logfile"
    rm -rf out/* || exit 4
  else
    echo "$timestamp out/ will be created" | tee -a "$logfile"
    mkdir -p out || exit 5
  fi

  get_timestamp
  if [[ -d "pdf/" ]]; then
    echo "$timestamp pdf/ will be cleard" | tee -a "$logfile"
    rm -rf pdf/* || exit 4
  else
    echo "$timestamp pdf/ will be created" | tee -a "$logfile"
    mkdir -p pdf || exit 5
  fi

  get_timestamp
  echo "$timestamp cleanup is done" | tee -a "$logfile"

  get_timestamp
  if [[ -f "$logfile" ]]; then
    echo "$timestamp moving log to tmp" | tee -a "$logfile"
    filename=$(basename "$logfile")
    mv "$logfile" "/tmp/$filename" || exit 9
  fi
}

prerun() {
  get_timestamp
  if [[ -d "pdf/" ]]; then
    echo "$timestamp pdf/ exists" | tee -a "$logfile"
  else
    echo "$timestamp pdf/ will be created" | tee -a "$logfile"
    mkdir -p pdf || exit 5
  fi

  get_timestamp
  if [[ -d "out/" ]]; then
    echo "$timestamp out/ exists" | tee -a "$logfile"
  else
    echo "$timestamp out/ will be created" | tee -a "$logfile"
    mkdir -p out || exit 5
  fi

  get_timestamp
  if [ ! -f "$tex_file" ]; then
    echo "$timestamp Error: Datei $tex_file existiert nicht." | tee -a "$logfile"
    exit 2
  fi
}

postrun() {
  get_timestamp
  if [ -f "$pdf_file" ]; then
    if [ -d "pdf" ]; then
      mv "$pdf_file" pdf/
      echo "$timestamp PDF wurde erfolgreich nach 'pdf' verschoben: pdf/$pdf_file" | tee -a "$logfile"
    else
      echo "$timestamp Error: Der Ordner 'pdf' existiert nicht." | tee -a "$logfile"
      exit 8
    fi
  else
    echo "$timestamp Error: PDF-Datei $pdf_file wurde nicht erstellt." | tee -a "$logfile"
    exit 8
  fi

  get_timestamp
  for file in "$aux_file" "$dvi_file" "$log_file" "$out_file" "$toc_file" "$nav_file" "$snm_file"; do
    if [ -f "$file" ]; then
      mv "$file" out/
      echo "$timestamp Datei $file wurde nach 'out' verschoben." | tee -a "$logfile"
    else
      echo "$timestamp Warnung: Datei $file wurde nicht gefunden." | tee -a "$logfile"
    fi
  done
}

# Main
get_timestamp
logging
argumentscheck
cleanup
prerun
lualatex "$tex_file" || exit 6
echo "$timestamp lualatex runned successfull" | tee -a "$logfile"
pdflatex "$tex_file" || exit 7
echo "$timestamp lualatex runned successfull" | tee -a "$logfile"
postrun

trap handling EXIT
