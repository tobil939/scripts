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

# Log-Verzeichnis erstellen
mkdir -p "/home/$user_name/Log/" 2>>"$error_log_file" || {
  echo "Fehler: Konnte Log-Verzeichnis nicht erstellen" >&2
  exit 1
}

# Schreibrechte prüfen
if [ ! -w "/home/$user_name/Log/" ]; then
  echo "Keine Schreibrechte für Log-Verzeichnis. Skript wird abgebrochen." >&2
  exit 1
fi

# Log-Eintrag mit Zeitstempel und Benutzername
echo -e "\n$datef Benutzername: $user_name\n" >>"$log_file" 2>>"$error_log_file"

# Fehlerprüfungsfunktion
check_error() {
  if [ $? -ne 0 ]; then
    echo "Fehler bei $1. Skript wird abgebrochen." | tee -a "$log_file"
    command -v notify-send >/dev/null && notify-send "Fehler bei $1" 2>>"$error_log_file"
    exit 1
  fi
}

# Array mit den Dateien und Verzeichnissen
source_dirs=(
  "$HOME/.config/nvim/lua/plugins"
  "$HOME/.config/nvim/lua/config"
  "$HOME/.config/hypr"
  "$HOME/.config/waybar"
  "$HOME/.config/kitty"
  "$HOME/.config/qutebrowser"
)

nvim_plugin_files=(
  "aerial.lua"
  "alpha.lua"
  "formatter.lua"
  "lsp.lua"
  "lualine.lua"
  "luasnip.lua"
  "nvim-dap.lua"
  "nvim-tree.lua"
  "telescope.lua"
  "toggleterm.lua"
  "treesitter.lua"
  "theme.lua"
)

nvim_config_files=(
  "autocmds.lua"
  "keymaps.lua"
  "options.lua"
)

hypr_files=(
  "hypridle.conf"
  "hyprland.conf"
  "hyprlock.conf"
)

waybar_files=(
  "config.jsonc"
)

kitty_files=(
  "kitty.conf"
)

qutebrowser_files=(
  "config.py"
)

# Zielverzeichnis
dest_base="$HOME/Git/config"

# Prüfen, ob Quellverzeichnisse existieren
for dir in "${source_dirs[@]}"; do
  if [[ ! -d "$dir" ]]; then
    echo "Warnung: Quellverzeichnis $dir existiert nicht, überspringe..." | tee -a "$log_file"
    continue
  fi
done

# Zielverzeichnis erstellen
mkdir -p "$dest_base" 2>>"$error_log_file"
check_error "Erstellung des Zielverzeichnisses"

# Funktion zum Kopieren von Dateien
copy_files() {
  local src_dir="$1"
  local dest_dir="$2"
  shift 2
  local files=("$@")

  # Prüfe, ob das Quellverzeichnis existiert
  if [[ ! -d "$src_dir" ]]; then
    echo "Warnung: Quellverzeichnis $src_dir existiert nicht, überspringe..." | tee -a "$log_file"
    return
  fi

  # Erstelle Zielverzeichnis
  mkdir -p "$dest_dir" 2>>"$error_log_file"
  check_error "Erstellung von $dest_dir"

  # Kopiere Dateien
  for file in "${files[@]}"; do
    source_file="$src_dir/$file"
    dest_file="$dest_dir/$file"
    if [[ -f "$source_file" ]]; then
      cp "$source_file" "$dest_file" 2>>"$error_log_file"
      check_error "Kopieren von $file"
      echo "Kopiert: $source_file -> $dest_file" | tee -a "$log_file"
    else
      echo "Warnung: $file existiert nicht in $src_dir" | tee -a "$log_file"
    fi
  done
}

# Kopieren der Dateien
copy_files "${source_dirs[0]}" "$dest_base/.config/nvim/lua/plugins" "${nvim_plugin_files[@]}"
copy_files "${source_dirs[1]}" "$dest_base/.config/nvim/lua/config" "${nvim_config_files[@]}"
copy_files "${source_dirs[2]}" "$dest_base/.config/hypr" "${hypr_files[@]}"
copy_files "${source_dirs[3]}" "$dest_base/.config/waybar" "${waybar_files[@]}"
copy_files "${source_dirs[4]}" "$dest_base/.config/kitty" "${kitty_files[@]}"
copy_files "${source_dirs[5]}" "$dest_base/.config/qutebrowser" "${qutebrowser_files[@]}"

# Kopieren der Skripte
echo "Kopieren der Skripte" | tee -a "$log_file"
mkdir -p "$HOME/Scripts" "$HOME/Git/scripts" 2>>"$error_log_file"
check_error "Erstellung der Skript-Verzeichnisse"
cp -r /usr/local/bin/* "$HOME/Scripts/" 2>>"$error_log_file"
check_error "Kopieren von /usr/local/bin nach ~/Scripts"
cp -r "$HOME/Scripts"/* "$HOME/Git/scripts/" 2>>"$error_log_file"
check_error "Kopieren von ~/Scripts nach ~/Git/scripts"

CONFIG_DIR=$dest_base
SCRIPTS_DIR="$HOME/Git/scripts"
CONFIG_REPO="git@github.com:tobil939/config.git"
SCRIPTS_REPO="git@github.com:tobil939/scripts.git"

# Function to push a directory to its GitHub repository
push_to_github() {
    local dir="$1"
    local repo="$2"
    local repo_name=$(basename "$repo" .git)

    # Check if directory exists
    if [[ ! -d "$dir" ]]; then
        echo "Error: Directory $dir does not exist."
        exit 1
    fi

    # Navigate to the directory
    cd "$dir" || { echo "Error: Could not change to $dir"; exit 1; }

    # Check if it's a git repository
    if [[ ! -d ".git" ]]; then
        echo "Error: $dir is not a git repository. Initializing it..."
        git init
        git remote add origin "$repo"
    fi

    # Add all changes
    git add .

    # Commit changes with a timestamp
    git commit -m "Update $repo_name - $(date '+%Y-%m-%d %H:%M:%S')" || {
        echo "Nothing to commit in $dir"
    }

    # Push to GitHub
    git push origin main || {
        echo "Error: Failed to push to $repo"
        exit 1
    }

    echo "Successfully pushed $dir to $repo"
}

# Push both repositories
push_to_github "$CONFIG_DIR" "$CONFIG_REPO"
push_to_github "$SCRIPTS_DIR" "$SCRIPTS_REPO"

echo "All repositories have been pushed to GitHub."
echo "Kopiervorgang abgeschlossen." | tee -a "$log_file"
command -v notify-send >/dev/null && notify-send "Kopiervorgang abgeschlossen."
