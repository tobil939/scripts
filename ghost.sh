#!/usr/bin/env bash
# Script: ghost.sh
# Author: tobil
# Date: 2026-03-10_19:37:53
# License: MIT
# Description: Installations Skript das auf einem GhostBSD System meine Programme installiert und Hyprland einrichtet

username=$(logname)
user="/home/$username"

# Logfile
logfile="$user/logging/logfile.log"
logpath="$user/logging/"

progs=(
  "hyprland"
  "seatd"
  "xdg-desktop-portal"
  "xdg-desktop-portal-hyprland"
  "polkit"
  "grim"
  "slurp"
  "wl-clipboard"
  "wlr-randr"
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
  "mako"
  "libnotify"
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
  "haskell-language-server"
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
  "haskell-hlint"
  "go-tools"
  "zig"
  "zls"
  "copyq"
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
  "haskell"
  "nasm"
  "latex"
  "mojo"
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

rc_conf() {
  log "changing rc.conf"
  grep -q seatd_enable /etc/rc.conf || echo 'seatd_enable="YES"' >> /etc/rc.conf
  grep -q dbus_enable /etc/rc.conf || echo 'dbus_enable="YES"' >> /etc/rc.conf
}

usersetup() {
  log "changing user rights and adding to group"
  pw groupmod video -m "$username"
}

wrapper() {
  cat >/usr/local/bin/start-hyprland <<'EOF'
#!/bin/sh
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export WAYLAND_DISPLAY=wayland-1
export XKB_DEFAULT_RULES=evdev

export GDK_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export SDL_VIDEODRIVER=wayland
export MOZ_ENABLE_WAYLAND=1
export CLUTTER_BACKEND=wayland

exec ck-launch-session dbus-launch --exit-with-session Hyprland
EOF

  chmod +x /usr/local/bin/start-hyprland

  # Greeter-Session
  mkdir -p /usr/local/share/wayland-sessions
  cat >/usr/local/share/wayland-sessions/hyprland.desktop <<'EOF'
[Desktop Entry]
Name=Hyprland
Comment=Hyprland Wayland Compositor
Exec=/usr/local/bin/start-hyprland
Type=Application
EOF
}

restartservice() {
  service seatd restart
  service lightdm restart
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
    mkdir -p "$logpath" || {
      echo "$timestamp Failed to create logpath" | tee -a "$logfile"
      exit 1
    }
    touch "$logfile" || {
      echo "$timestamp Failed to create logfile" | tee -a "$logfile"
      exit 2
    }
    echo "$timestamp Logfile created" | tee -a "$logfile"
  fi
}

mojo() {
  get_timestamp
  log "insatlling mojo"
  curl -fsSL https://pixi.sh/install.sh | bash

  get_timestamp
  log "reloading bash"
  source "$user/.bashrc"

  pixi init "first_mojo_project" -c https://conda.modular.com/max-nightly/ -c conda-forge

  get_timestamp
  log "changing into first_mojo_project"
  cd first_mojo_project || exit 1

  pixi add mojo

  get_timestamp
  log "showing the version of mojo"
  pixi run mojo --version | tee -a "$logfile"

  cd .. || exit 1

  get_timestamp
  log "deleting first_mojo_project"
  rm -rf first_mojo_project/
}

#LOG Eintrag
log() {
  local message
  message="$1"
  get_timestamp
  echo "### ### ### $timestamp $message" | tee -a "$logfile"
}

# Fehlerbehandlung
handling() {
  local error="$1"
  get_timestamp
  case $error in
    0) echo "$timestamp Script completed successfully" | tee -a "$logfile" ;;
    1)
      echo "$timestamp Directory error" | tee -a "$logfile"
      exit 1
      ;;
    2)
      echo "$timestamp Logfile error" | tee -a "$logfile"
      exit 2
      ;;
    4)
      echo "$timestamp nvim not installed" | tee -a "$logfile"
      exit 4
      ;;
    *)
      echo "$timestamp Unknown error: $error" | tee -a "$logfile"
      exit "$error"
      ;;
  esac
}

# Installation der Programme
installprog() {
  local count="0"
  local max="0"
  max="${#progs[@]}"
  log "Installation der Programme"
  log "$max werden installiert"
  for prog in "${progs[@]}"; do
    log "$prog installation"
    pkg install -y "$prog"
    log "$count von $max installiert"
    ((count++))
  done
}

# Update und Upgrade
updateos() {
  log "updating OS"
  pkg update
  log "upgrading OS"
  pkg upgrade -y
}

# Cleanup
cleanup() {
  log "cleanup machen"
  pkg clean -y
}

trap 'handling $?' EXIT

logging
log "START"
updateos
installprog
updateos
makedir
clonegit
copieconf
confbashrc
mojo
usersetup
rc_conf
wrapper
restartservice
updateos
cleanup
