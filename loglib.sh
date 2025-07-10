#!/bin/bash

# Schutz vor Mehrfach-Einbindung
[[ -n "${_LOGLIB_LOADED}" ]] && return
_LOGLIB_LOADED=1

# Globale Variablen für Log-Dateien
declare -g LOG_FILE=""
declare -g ERROR_LOG_FILE=""

# Funktion: Log-Umgebung initialisieren
# Usage: init_logging
init_logging() {
    local user_name
    local log_dir
    local datef

    # Benutzername ermitteln
    user_name=$(whoami) || {
        echo "Fehler: Benutzername konnte nicht ermittelt werden." >&2
        return 1
    }

    # Log-Verzeichnis und Dateipfade
    log_dir="/home/$user_name/Log"
    LOG_FILE="$log_dir/install.txt"
    ERROR_LOG_FILE="$log_dir/errorinstall.txt"
    datef="$(date '+%Y-%m-%d %H:%M:%S')"

    # Log-Verzeichnis erstellen
    mkdir -p "$log_dir" || {
        echo "Fehler: Konnte Verzeichnis $log_dir nicht erstellen." >&2
        return 1
    }

    # Log-Dateien erstellen
    touch "$LOG_FILE" "$ERROR_LOG_FILE" || {
        echo "Fehler: Konnte Log-Dateien nicht erstellen." >&2
        return 1
    }

    # Schreibrechte prüfen
    if [[ ! -w "$LOG_FILE" ]] || [[ ! -w "$ERROR_LOG_FILE" ]]; then
        echo "Fehler: Keine Schreibrechte für Log-Dateien." >&2
        return 1
    fi

    # Initialen Log-Eintrag schreiben
    echo -e "\n$datef Benutzername: $user_name\n" >>"$LOG_FILE" 2>>"$ERROR_LOG_FILE" || {
        echo "Fehler: Konnte initialen Log-Eintrag nicht schreiben." >&2
        return 1
    }

    return 0
}

# Funktion: Ausgabe in Log-Datei und Fehler in Error-Log
# Usage: log_output "Nachricht" [Kommandos...]
log_output() {
    if [[ -z "$LOG_FILE" ]] || [[ -z "$ERROR_LOG_FILE" ]]; then
        echo "Fehler: Log-Dateien nicht initialisiert. Bitte init_logging aufrufen." >&2
        return 1
    fi

    # Wenn eine Nachricht übergeben wurde, direkt loggen
    if [[ $# -eq 1 ]]; then
        echo "$1" >>"$LOG_FILE" 2>>"$ERROR_LOG_FILE"
    # Wenn ein Kommando übergeben wurde, dessen Ausgabe umleiten
    else
        "${@:2}" >>"$LOG_FILE" 2>>"$ERROR_LOG_FILE"
    fi
}

# Funktion: Ausgabe in Log-Datei und auf Konsole (mit tee)
# Usage: log_tee "Nachricht" [Kommandos...]
log_tee() {
    if [[ -z "$LOG_FILE" ]]; then
        echo "Fehler: Log-Datei nicht initialisiert. Bitte init_logging aufrufen." >&2
        return 1
    fi

    # Wenn eine Nachricht übergeben wurde, direkt loggen
    if [[ $# -eq 1 ]]; then
        echo "$1" | tee -a "$LOG_FILE"
    # Wenn ein Kommando übergeben wurde, dessen Ausgabe umleiten
    else
        "${@:2}" | tee -a "$LOG_FILE"
    fi
}
