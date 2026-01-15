#!/usr/bin/env bash

# bash script for installation and setup for my arch linux system
# rev. 5.0
# total rework, more yay an more functions

# Variables
deathtime="180s"
warntime="170s"

username=$(logname)
user="/home/$username"

progyay=(
  "wayland"
  "hyprland"
  "network-manager-applet"
  "gnome-calendar"
  "git"
  "github-cli"
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
  "texmaker"
  "texlab"
  "texlive-binextra"
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
  "evolution"
  "lua-language-server"
  "bash-language-server"
  "gtk3"
  "gtk4"
  "lazygit"
  "glade"
  "nasm"
  "ghc"
  #"haskell-language-server"
  "tree-sitter-cli"
  "go"
  "gopls"
  "ruff"
  "pyright"
  "octave"
  "delve"
  "python"
  "python3"
  "python-debugpy"
  "python-pip"
  #"haskell-hlint"
  "go-tools"
  "zig"
  "zls"
  "copyq"
  "ddcutil"
)

progyaynosudo=(
  "xorg"
  "texlive"
  "neofetch"
  "arc-gtk-theme"
  "python-gdbgui"
  "codelldb"
  "gtk2"
  "gtk-engine-murrine"
  "nitrogen"
  "google-chrome"
  "asm-lsp"
  "ormolu-bin"
  "local-lua-debugger-vscode-git"
)

proglang=(
  "lua"
  "clang"
  "cpp"
  "bash"
  "go"
  #"haskell"
  "nasm"
  "latex"
)

homedirs=(
  "Git"
  "git1"
  "Scripts"
  "Doku"
  "Prog"
  "Testing"
)

git_repo=(
  "scripts"
  "Clang"
  "neovim"
  "config"
  "RP2040"
  "Bash"
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
#logfilename=$(basename "$logfile")

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
      echo "$timestamp Script completed successfully" | tee -a "$logfile"
      ;;
    1)
      echo "$timestamp ERROR: Logfile cannot be created" | tee -a "$logfile"
      ;;
    2)
      echo "$timestamp ERROR: Script must be executed as root (sudo)" | tee -a "$logfile"
      ;;
    3)
      echo "$timestamp ERROR: Arch Keyring Update failed" | tee -a "$logfile"
      ;;
    4)
      echo "$timestamp ERROR: Pacman Update or Package install failed" | tee -a "$logfile"
      ;;
    5)
      echo "$timestamp ERROR: Yay Update or Package install failed" | tee -a "$logfile"
      ;;
    6)
      echo "$timestamp ERROR: NPM Update or Package install failed" | tee -a "$logfile"
      ;;
    7)
      echo "$timestamp ERROR: AUR package installation via Yay failed" | tee -a "$logfile"
      ;;
    8)
      echo "$timestamp ERROR: NPM global packages installation failed" | tee -a "$logfile"
      ;;
    9)
      echo "$timestamp ERROR: Directories for program folders could not be created" | tee -a "$logfile"
      ;;
    10)
      echo "$timestamp ERROR: Home directories could not be created" | tee -a "$logfile"
      ;;
    11)
      echo "$timestamp ERROR: Git directories could not be created" | tee -a "$logfile"
      ;;
    12)
      echo "$timestamp ERROR: Config directories could not be created" | tee -a "$logfile"
      ;;
    13)
      echo "$timestamp ERROR: Git repositories could not be cloned" | tee -a "$logfile"
      ;;
    14 | 15 | 16 | 17 | 18 | 19)
      echo "$timestamp ERROR: Config files could not be copied" | tee -a "$logfile"
      ;;
    20)
      echo "$timestamp ERROR: Fuzzyfind Bash function could not be set up" | tee -a "$logfile"
      ;;
    21)
      echo "$timestamp ERROR: HiDrive SSH key could not be created or copied" | tee -a "$logfile"
      ;;
    22)
      echo "$timestamp ERROR: Dark mode could not be activated" | tee -a "$logfile"
      ;;
    23)
      echo "$timestamp ERROR: Bluetooth could not be started or enabled" | tee -a "$logfile"
      ;;
    24)
      echo "$timestamp ERROR: something wrong with the cleanup" | tee -a "$logfile"
      ;;
    124)
      echo "$timestamp ERROR: Watchdog timeout reached, script aborted" | tee -a "$logfile"
      ;;
    *)
      echo "$timestamp Unknown ERROR (Exit-Code: $error)" | tee -a "$logfile"
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

#upnpm() {
#  rootcheck
#  get_timestamp
#  echo "$timestamp npm update" | tee -a "$logfile"
#  npm update -g || exit 6
#}

#installpacman() {
#  rootcheck
#  if [[ -f /var/lib/pacman/db.lck ]]; then
#    echo "$timestamp pacman db is locked, trying to fix it" | tee -a "$logfile"
#    rm -rf /var/lib/pacman/db.lck
#  fi
#  for prog in "${progpac[@]}"; do
#    get_timestamp
#    echo "$timestamp $prog will be installed" | tee -a "$logfile"
#    watchdog pacman -S "$prog" --needed --noconfirm || exit 4
#  done
#
#  for prog in "${progpacnowatchdog[@]}"; do
#    get_timestamp
#    echo "$timestamp $prog will be installed without watchdog" | tee -a "$logfile"
#    pacman -S "$prog" --needed --noconfirm || exit 4
#  done
#}

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
}

installyaysudo() {
  get_timestamp
  echo "$timestamp yay pac will be installed" | tee -a "$logfile"

  for prog in "${progyay[@]}"; do
    get_timestamp
    echo "$timestamp $prog will be installed" | tee -a "$logfile"
    yay -S "$prog" --needed --noconfirm || exit 7
  done
}

installyaynosudo() {
  get_timestamp
  echo "$timestamp yay without root  will be installed" | tee -a "$logfile"

  for prog in "${progyaynosudo[@]}"; do
    get_timestamp
    echo "$timestamp $prog will be installed" | tee -a "$logfile"
    sudo -u "$username" yay -S "$prog" --needed --noconfirm || exit 7
  done
}

#installnpm() {
#  Will be installed with yay
#  get_timestamp
#  echo "$timestamp npm pac will be installed" | tee -a "$logfile"
#  echo "$timestamp tree-sitter will be installed" | tee -a "$logfile"
#  #npm install -g tree-sitter --silent --verbose || exit 8
#
#  get_timestamp
#  echo "$timestamp tree-sitter-cli will be installed" | tee -a "$logfile"
#  npm install -g tree-sitter-cli --silent --verbose || exit 8
#
#  get_timestamp
#  echo "$timestamp prettier will be installed" | tee -a "$logfile"
#  npm install -g prettier --silent --verbose || exit 8
#}

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
  echo "$timestamp init.lua will be copied" | tee -a "$logfile"
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

confbashrc() {
  get_timestamp
  cat >>"$user/.bashrc" <<'HERE'
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '
#export GREP_COLORS='mt=1;35'
#export LS_COLORS="di=1;35:fi=0:ln=36"

alias grep='grep --color=auto'
alias ls='ls --color=auto'
alias sl='ls -lh --color=auto'

fuzzy() {
  local file
  file=$(find . -type f | fzf --preview 'cat {}' --height 80% --border)
  [[ -n "$file" ]] && nvim "$file"
}

greppy() {
  local file=$(find . -type f | fzf --preview "grep -i --color=always {q} {} | head -n 20" --bind "change:reload:find . -type f")
  [[ -n "$file" ]] && nvim "$file" +/{q}
}

trs() {
  for file in "$@"; do
    filename=$(basename "$file")
    mv "$file" /tmp/"$filename"
  done
}

bashing() {

  local data
  local path
  local file
  local oldpath

  oldpath=$(pwd)

  data="$1"
  [[ -z "$data" ]] && exit 91

  handling() {
    local error="$1"
    case $error in
      0) echo "completed successfully" ;;
      88) echo "can't change into directory" ;;
      89) echo "can't create file" ;;
      90) echo "can't make it executable" ;;
      91) echo "no filename" ;;
      *) echo "unknown error" ;;
    esac
  }

  trap 'handling $?' EXIT

  file=$(basename "$data")
  path=$(dirname "$data")

  if [[ -d "$path" ]]; then
    cd "$path" || exit 88
    [[ -f "$file" ]] && trs "$file"
    touch "$file" || exit 89
    chmod +x "$file" || exit 90
    ls -lh
  else
    mkdir -p "$path"
    cd "$path" || exit 88
    touch "$file" || exit 89
    chmod +x "$file" || exit 90
    ls -lh
  fi

  cat <<EOF >"$file"
#!/usr/bin/env bash 
# Script: $file
# Author: $(whoami)
# Date: $(date +"%Y-%m-%d_%H:%M:%S") 
# License: MIT
# Description: ....

EOF

  cat <<'EOF' >>"$file"
# Logfile 
logfile="$HOME/logging/logfile.log"
logpath="$HOME/logging/"

# Zeitstempel holen
get_timestamp() {
  timestamp=$(date +"%Y-%m-%d_%H:%M:%S")
}

# Logging initialisieren
logging() {
  get_timestamp
  echo "$timestamp Log path: $logpath" | tee -a "$logfile"
  echo "$timestamp Log file: $logfile" | tee -a "$logfile"

  # Logfile pruefen/erstellen
  if [[ -f "$logfile" ]]; then
    get_timestamp
    echo "$timestamp Logfile exists" | tee -a "$logfile"
  else
    get_timestamp
    echo "$timestamp Creating logfile" | tee -a "$logfile"
    mkdir -p "$logpath" || { echo "$timestamp Failed to create logpath" | tee -a "$logfile"; exit 1; }
    touch "$logfile" || { echo "$timestamp Failed to create logfile" | tee -a "$logfile"; exit 2; }
    echo "$timestamp Logfile created" | tee -a "$logfile"
  fi
}

# Fehlerbehandlung
handling() {
  local error="$1"
  get_timestamp
  case $error in
    0) echo "$timestamp Script completed successfully" | tee -a "$logfile";;
    1) echo "$timestamp Directory error" | tee -a "$logfile"; exit 1;;
    2) echo "$timestamp Logfile error" | tee -a "$logfile"; exit 2;;
    4) echo "$timestamp nvim not installed" | tee -a "$logfile"; exit 4;;
    *) echo "$timestamp Unknown error: $error" | tee -a "$logfile"; exit "$error";;
  esac
}

trap 'handling $?' EXIT

EOF

  cd "$oldpath" || exit 88
}
export PATH="/home/tobil/.pixi/bin:$PATH"
HERE
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

cleanup() {
  get_timestamp
  echo "$timestamp cleaning up yay" | tee -a "$logfile"
  yay -Ycc || exit 24
  yay -Yc || exit 24
}

#haskellstack() {
#  get_timestamp
#  echo "$timestamp install stack" | tee -a "$logfile"
#  yay -Sy stack
#  stack haskell-debug-adapter
#}

# Main
echo "getting started"

trap 'handling $?' EXIT
logging
rootcheck
installyay
installyaysudo
installyaynosudo
#installnpm
#haskellstack
makedir
clonegit
copieconf
confbashrc
get_dbus_address
confdarkmode
confblue
upyay
#upnpm
uppacman
cleanup
