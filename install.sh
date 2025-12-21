#!/bin/bash

# bash-script for initialisation of bluetooth devices
# rev. 2.0
# includes basic error handling and improved messages

# Variabesl
deathtime="180s"
warntime="170s"

username=$(logname)
user="/home/$username"

# Installlist Pacman
progpac=(
  "wayland"
  "hyprland"
  "xorg"
  "network-manager-applet"
  "gnome-calendar"
  "git"
  "github-cli"
  "python3"
  "nodejs"
  "node-gyp"
  "stylua"
  "shfmt"
  "clang"
  "lldb"
  "fzf"
  "lua"
  "gcc"
  "cmake"
  "make"
  "base-devel"
  "ripgrep"
  "luacheck"
  "cppcheck"
  "qutebrowser"
  "arm-none-eabi-gdb"
  "perl-yaml-tiny"
  "perl-file-homedir"
  "shellcheck"
  "base-devel"
)

progpacnowatchdog=(
  "texlive"
  "texmaker"
  "texlab"
  "texlive-binextra"
)

progyay=(
  "polkit"
  "waybar"
  "swaync"
  "wofi"
  "hypridle"
  "hyprlock"
  "hyprshot"
  "pavucontrol"
  "qt5-wayland"
  "qt6-wayland"
  "kitty"
  "firefox"
  "gedit"
  "ttf-meslo-nerd"
  "picom"
  "feh"
  "nautilus"
  "lxappearance"
  "evince"
  "neovim"
  "gdb"
  "npm"
  "libreoffice-still"
  "bluez"
  "bluez-utils"
  "blueman"
  "gdbgui"
  "evolution"
  "lua-language-server"
  "bash-language-server"
)

progyaynosudo=(
  "neofetch"
  "arc-gtk-theme"
  "gtk2"
  "gtk3"
  "gtk4"
  "gtk-engine-murrine"
  "nitrogen"
  "google-chrome"
)

proglang=(
  "lua"
  "clang"
  "cpp"
  "bash"
)

homedirs=(
  "git"
  "git1"
  "Scripts"
)

git_repo=(
  "scripts"
  "Clang"
  "neovim"
  "config"
  "RP2040"
)

confdirs=(
  "$user/.config/nvim/lua/config"
  "$user/.config/nvim/lua/plugins"
  "$user/.config/hypr"
  "$user/.config/waybar"
  "$user/.config/kitty"
  "$user/.config/qutebrowser"
)

nvim_plugin_files=(
  "aerial.lua"
  "alpha.lua"
  "cmp.lua"
  "dap.lua"
  "formatter.lua"
  "help.lua"
  "lint.lua"
  "lsp.lua"
  "lualine.lua"
  "luasnip.lua"
  "mason.lua"
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

qute_files=(
  "config.py"
)

kitty_files=(
  "kitty.conf"
)

# logging
# place where the logfile will be saved
logfile="/var/log/install_setup.log"
logfilename=$(basename "$logfile")

# timestamp
get_timestamp() {
  timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
}

logging() {
  if [[ -f "$logfile" ]]; then
    echo "logfile exists"
  else
    echo "logfile will be created"
    touch "$logfile" || exit 1
  fi

  get_timestamp
  [[ -f "$logfile" ]] || exit 1
  echo "$timestamp first entry" | tee -a "$logfile" || exit 1
}

# errorhandling
# better errormessages
handling() {
  local error="$1"
  get_timestamp
  case $error in
  0)
    echo "$timestamp Alles lief erfolgreich, keine Fehler." | tee -a "$logfile"
    echo "$timestamp Logfile wird nach /tmp verschoben." | tee -a "$logfile"
    mv -v "$logfile" "/tmp/$logfilename"
    ;;
  1)
    echo "$timestamp Fehler: Logfile konnte nicht erstellt oder beschrieben werden." | tee -a "$logfile"
    ;;
  2)
    echo "$timestamp Fehler: Skript muss als root oder mit sudo ausgeführt werden." | tee -a "$logfile"
    ;;
  3)
    echo "$timestamp Fehler: Arch Keyring Update fehlgeschlagen." | tee -a "$logfile"
    ;;
  4)
    echo "$timestamp Fehler: Pacman Update oder Paketinstallation fehlgeschlagen." | tee -a "$logfile"
    ;;
  5)
    echo "$timestamp Fehler: Yay Update oder Installation fehlgeschlagen." | tee -a "$logfile"
    ;;
  6)
    echo "$timestamp Fehler: NPM Update oder Installation globaler Pakete fehlgeschlagen." | tee -a "$logfile"
    ;;
  7)
    echo "$timestamp Fehler: AUR Paketinstallation über Yay fehlgeschlagen." | tee -a "$logfile"
    ;;
  8)
    echo "$timestamp Fehler: NPM globale Packages Installation fehlgeschlagen." | tee -a "$logfile"
    ;;
  9)
    echo "$timestamp Fehler: Verzeichnisse für Programm-Ordner konnten nicht erstellt werden." | tee -a "$logfile"
    ;;
  10)
    echo "$timestamp Fehler: Home-Verzeichnisse konnten nicht erstellt werden." | tee -a "$logfile"
    ;;
  11)
    echo "$timestamp Fehler: Git-Verzeichnisse konnten nicht erstellt werden." | tee -a "$logfile"
    ;;
  12)
    echo "$timestamp Fehler: Config-Verzeichnisse konnten nicht erstellt werden." | tee -a "$logfile"
    ;;
  13)
    echo "$timestamp Fehler: Git Repositories konnten nicht geklont werden." | tee -a "$logfile"
    ;;
  14 | 15 | 16 | 17 | 18 | 19)
    echo "$timestamp Fehler: Config-Dateien konnten nicht kopiert werden." | tee -a "$logfile"
    ;;
  20)
    echo "$timestamp Fehler: Fuzzyfind Bash-Funktion konnte nicht eingerichtet werden." | tee -a "$logfile"
    ;;
  21)
    echo "$timestamp Fehler: HiDrive SSH-Key konnte nicht erstellt oder kopiert werden." | tee -a "$logfile"
    ;;
  22)
    echo "$timestamp Fehler: Darkmode konnte nicht aktiviert werden." | tee -a "$logfile"
    ;;
  23)
    echo "$timestamp Fehler: Bluetooth konnte nicht gestartet oder aktiviert werden." | tee -a "$logfile"
    ;;
  124)
    echo "$timestamp Fehler: Watchdog Timeout erreicht, Skript abgebrochen." | tee -a "$logfile"
    ;;
  *)
    echo "$timestamp Unbekannter Fehler (Exit-Code: $error)" | tee -a "$logfile"
    ;;
  esac
}

# root
# checking if it was started with sudo
rootcheck() {
  get_timestamp
  if ! command -v sudo >/dev/null; then
    echo "$timestamp sudo is not installed" | tee -a "$logfile"
    exit 2
  fi

  get_timestamp
  if [[ $UID -ne 0 ]]; then
    exit 2
  fi
}

uppacman() {
  rootcheck
  get_timestamp
  if [[ -f /var/lib/pacman/db.lck ]]; then
    echo "$timestamp pacman db is locked, trying to fix it" | tee -a "$logfile"
    rm -rf /var/lib/pacman/db.lck
  fi
  echo "$timestamp pacman keyring update" | tee -a "$logfile"
  watchdog pacman -Syu archlinux-keyring --noconfirm || exit 3

  get_timestamp
  echo "$timestamp pacman update" | tee -a "$logfile"
  watchdog pacman -Syu --noconfirm || exit 4
}

upyay() {
  rootcheck
  get_timestamp
  echo "$timestamp yay update" | tee -a "$logfile"
  sudo -u "$username" yay -Syu --noconfirm || exit 5
}

upnpm() {
  rootcheck
  get_timestamp
  echo "$timestamp npm update" | tee -a "$logfile"
  npm update -g || exit 6
}

installpacman() {
  rootcheck
  if [[ -f /var/lib/pacman/db.lck ]]; then
    echo "$timestamp pacman db is locked, trying to fix it" | tee -a "$logfile"
    rm -rf /var/lib/pacman/db.lck
  fi
  for prog in "${progpac[@]}"; do
    get_timestamp
    echo "$timestamp $prog will be installed" | tee -a "$logfile"
    watchdog pacman -S "$prog" --needed --noconfirm || exit 4
  done

  for prog in "${progpacnowatchdog[@]}"; do
    get_timestamp
    echo "$timestamp $prog will be installed without watchdog" | tee -a "$logfile"
    pacman -S "$prog" --needed --noconfirm || exit 4
  done
}

installyay() {
  get_timestamp
  echo "$timestamp yay will be installed" | tee -a "$logfile"
  echo "$timestamp pacman --needed git and base-devel are installed" | tee -a "$logfile"
  sudo pacman -S --needed --noconfirm git base-devel
  echo "$timestamp changing into $user" | tee -a "$logfile"
  cd "$user" || exit 7
  echo "$timestamp if yay does not exists, git clone" | tee -a "$logfile"
  if [[ ! -d "yay" ]]; then
    sudo -u "$username" git clone https://aur.archlinux.org/yay.git
  fi
  get_timestamp
  echo "$timestamp changing into yay" | tee -a "$logfile"
  cd yay || exit 7
  sudo -u "$username" makepkg -si --noconfirm --needed || exit 7
  get_timestamp
  echo "$timestamp changing back to $user" | tee -a "$logfile"
  cd "$user" || exit 7

  get_timestamp
  echo "$timestamp yay pac will be installed" | tee -a "$logfile"

  for prog in "${progyay[@]}"; do
    get_timestamp
    echo "$timestamp $prog will be installed" | tee -a "$logfile"
    yay -S "$prog" --needed --noconfirm || exit 7
  done

  get_timestamp
  echo "$timestamp yay without root  will be installed" | tee -a "$logfile"

  for prog in "${progyaynosudo[@]}"; do
    get_timestamp
    echo "$timestamp $prog will be installed" | tee -a "$logfile"
    sudo -u "$username" yay -S "$prog" --needed --noconfirm || exit 7
  done
}

installnpm() {
  get_timestamp
  echo "$timestamp npm pac will be installed" | tee -a "$logfile"
  echo "$timestamp tree-sitter will be installed" | tee -a "$logfile"
  #npm install -g tree-sitter --silent --verbose || exit 8

  get_timestamp
  echo "$timestamp tree-sitter-cli will be installed" | tee -a "$logfile"
  npm install -g tree-sitter-cli --silent --verbose || exit 8

  get_timestamp
  echo "$timestamp prettier will be installed" | tee -a "$logfile"
  npm install -g prettier --silent --verbose || exit 8
}

watchdog() {
  local cmd=("$@")

  (sleep ${warntime%s} && get_timestamp && echo "$timestamp Warning, 10s left before the script will be stopped" | tee -a "$logfile") &
  local warn_pid=$!

  if ! timeout "$deathtime" "${cmd[@]}"; then
    get_timestamp
    echo "$timestamp Watchdog was reached, script will be stopped" | tee -a "$logfile"
    exit 124
  fi

  kill "$warn_pid" 2>/dev/null
}
makedir() {
  get_timestamp
  echo "$timestamp creating directories for prog" | tee -a "$logfile"
  for prog in "${proglang[@]}"; do
    get_timestamp
    echo "$timestamp creating directories $prog" | tee -a "$logfile"
    sudo -u "$username" mkdir -p "$user/Prog/$prog" "$user/Doku/$prog" "$user/Git/$prog" || exit 9
  done

  get_timestamp
  echo "$timestamp creating directories in HOME" | tee -a "$logfile"
  for dirs in "${homedirs[@]}"; do
    get_timestamp
    echo "$timestamp creating directories $dirs" | tee -a "$logfile"
    sudo -u "$username" mkdir -p "$user/$dirs" || exit 10
  done

  get_timestamp
  echo "$timestamp creating directories for git repos" | tee -a "$logfile"
  for dirs in "${git_repo[@]}"; do
    get_timestamp
    echo "$timestamp creating directories $dirs" | tee -a "$logfile"
    sudo -u "$username" mkdir -p "$user/git1/$dirs" || exit 11
  done

  get_timestamp
  echo "$timestamp creating directories for .config files" | tee -a "$logfile"
  for dirs in "${confdirs[@]}"; do
    get_timestamp
    echo "$timestamp creating directories $dirs" | tee -a "$logfile"
    sudo -u "$username" mkdir -p "$dirs" || exit 12
  done
}

clonegit() {
  get_timestamp
  echo "$timestamp git repos will be cloned" | tee -a "$logfile"
  echo "$user"
  for repo in "${git_repo[@]}"; do
    repo_url="https://github.com/tobil939/$repo.git"
    target_dir="$user/git1/$repo"

    if [[ -d "$target_dir/.git" ]]; then
      echo "$timestamp $repo already cloned" | tee -a "$logfile"
    else
      sudo -u "$username" git clone --depth=1 "$repo_url" "$target_dir" || exit 13
    fi
  done
}

copieconf() {
  local fromdir
  local todir
  fromdir="$user/git1/neovim"
  todir="$user/.config/nvim"
  get_timestamp
  echo "$timestamp init.lua wll be copied" | tee -a "$logfile"
  cp "$fromdir/init.lua" "$todir/init.lua"
  if [[ ! -f "$todir/init.lua" ]]; then
    echo "$timestamp init.lua was not copied"
  fi

  get_timestamp
  echo "$timestamp config files will be copied" | tee -a "$logfile"
  [[ -d "${confdirs[0]}" ]] || exit 14
  for files in "${nvim_config_files[@]}"; do
    get_timestamp
    echo "$timestamp $files will be copied" | tee -a "$logfile"
    cp "$user/git1/neovim/$files" "${confdirs[0]}/$files" || exit 14
  done

  [[ -d "${confdirs[1]}" ]] || exit 15
  for files in "${nvim_plugin_files[@]}"; do
    get_timestamp
    echo "$timestamp $files will be copied" | tee -a "$logfile"
    cp "$user/git1/neovim/$files" "${confdirs[1]}/$files" || exit 15
  done

  [[ -d "${confdirs[2]}" ]] || exit 16
  for files in "${hypr_files[@]}"; do
    get_timestamp
    echo "$timestamp $files will be copied" | tee -a "$logfile"
    cp "$user/git1/config/$files" "${confdirs[2]}/$files" || exit 16
  done

  [[ -d "${confdirs[3]}" ]] || exit 17
  for files in "${waybar_files[@]}"; do
    get_timestamp
    echo "$timestamp $files will be copied" | tee -a "$logfile"
    cp "$user/git1/config/$files" "${confdirs[3]}/$files" || exit 17
  done

  [[ -d "${confdirs[4]}" ]] || exit 18
  for files in "${kitty_files[@]}"; do
    get_timestamp
    echo "$timestamp $files will be copied" | tee -a "$logfile"
    cp "$user/git1/config/$files" "${confdirs[4]}/$files" || exit 18
  done

  [[ -d "${confdirs[5]}" ]] || exit 19
  for files in "${qute_files[@]}"; do
    get_timestamp
    echo "$timestamp $files will be copied" | tee -a "$logfile"
    cp "$user/git1/config/$files" "${confdirs[5]}/$files" || exit 19
  done
}

conffuzzy() {
  get_timestamp
  echo "$timestamp config fuzzyfind" | tee -a "$logfile"
  if ! grep -q fuzzy ~/.bashrc; then
    cat >>"$user/.bashrc" <<'EOF'
export GREP_COLORS='mt=1;35'
export LS_COLORS="di=1;35:fi=0:ln=36"

alias grep='grep --color=auto'
alias ls='ls --color=auto'
alias sl='ls -lh --color=auto'

fuzzy() {
  local file
  file=$(find . -type f | fzf --preview 'cat {}' --height 80% --border)
  [[ -n "$file" ]] && nvim "$file"
}
EOF
  fi
}

get_dbus_address() {
  get_timestamp

  pid=$(pgrep -u "$username" gnome-session | head -n 1)
  if [[ -z "$pid" ]]; then
    echo "$timestamp Fehler: Keine gnome-session für $username gefunden." | tee -a "$logfile"
    return 1
  fi

  DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/"$pid"/environ | sed -e 's/DBUS_SESSION_BUS_ADDRESS=//')
  if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
    echo "$timestamp Fehler: Konnte DBUS_SESSION_BUS_ADDRESS nicht auslesen." | tee -a "$logfile"
    return 1
  fi

  export DBUS_SESSION_BUS_ADDRESS
}

confdarkmode() {
  get_timestamp
  echo "$timestamp Setting up dark mode..." | tee -a "$logfile"

  if command -v gsettings >/dev/null; then
    get_dbus_address

    themes=(
      'org.gnome.desktop.interface gtk-theme "Arc-Dark"'
      'org.gnome.desktop.interface icon-theme "Adwaita"'
      'org.gnome.shell.extensions.user-theme "Adwaita"'
      'org.gnome.desktop.interface color-scheme "prefer-dark"'
    )

    for setting in "${themes[@]}"; do
      sudo -u "$username" DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" gsettings set "$setting"
    done

    echo "$timestamp Dark Mode aktiviert" | tee -a "$logfile"
  else
    echo "$timestamp GNOME nicht gefunden, Dark Mode wird übersprungen" | tee -a "$logfile"
  fi
}

confblue() {
  rootcheck
  get_timestamp
  echo "$timestamp setting up bluetooth" | tee -a "$logfile"
  systemctl start bluetooth.service || exit 23
  systemctl enable bluetooth.service || exit 23
}

# Main
trap 'handling $?' EXIT
get_timestamp
logging
rootcheck
uppacman
installpacman
uppacman
installyay
upyay
installnpm
upnpm
makedir
clonegit
copieconf
conffuzzy
confdarkmode
confblue
