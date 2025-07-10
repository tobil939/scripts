#!/bin/bash

# Sicherheitschecks
if ! command -v sudo >/dev/null; then
  echo "sudo ist nicht installiert. Skript wird abgebrochen."
  exit 1
fi

# Benutzername und Log-Dateien
user_name=$(whoami)
log_file="/home/$user_name/Log/install.txt"
error_log_file="/home/$user_name/Log/errorinstall.txt"
datef="$(date '+%Y-%m-%d %H:%M:%S')"
mkdir -p "/home/$user_name/Log/"
touch "$log_file" "$error_log_file"
if [ ! -w "$log_file" ] || [ ! -w "$error_log_file" ]; then
  echo "Keine Schreibrechte für Log-Dateien. Skript wird abgebrochen."
  exit 1
fi
echo -e "\n $datef Benutzername: $user_name \n" >>"$log_file" 2>>"$error_log_file"

# Fehlerprüfungsfunktion
check_error() {
  if [ $? -ne 0 ]; then
    echo "Fehler bei $1. Skript wird abgebrochen." | tee -a "$log_file"
    notify-send "Fehler bei $1"
    exit 1
  fi
}

# Erstes Update
echo -e "Erstes Update"
notify-send "pacman Update"
sudo pacman -Syu --noconfirm archlinux-keyring >>"$log_file" 2>>"$error_log_file"
check_error "System-Update"

# Paketlisten
progpac=(
  "wayland"
  "hyprland"
  "xorg"
  "network-manager-applet"
  "texlive"
  "texmaker"
  "gnome-calendar"
  "python3"
  "python-numba"
  "python-dask"
  "python-pandas"
  "python-numpy"
  "python-openpyxl"
  "python-black"
  "python-flake8"
  "stylua"
  "shfmt"
  "clang"
  "lldb"
  "fzf"
  "go"
  "nasm"
  "lua"
  "gopls"
  "gcc"
  "cmake"
  "make"
  "base-devel"
  "ripgrep"
  "luacheck"
  "cppcheck"
  "shellcheck"
  "ncurses"
  "libffi"
  "gmp"
  "qutebrowser"
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
  "neofetch"
  "kitty"
  "firefox"
  "gedit"
  "ttf-meslo-nerd"
  "picom"
  "feh"
  "git"
  "github-cli"
  "nautilus"
  "dolphin"
  "timeshift"
  "gtk2"
  "gtk3"
  "gtk4"
  "arc-gtk-theme"
  "gtk-engine-murrine"
  "lxappearance"
  "evince"
  "nitrogen"
  "neovim"
  "gdb"
  "npm"
  "libreoffice-still"
  "bluez"
  "bluez-utils"
  "blueman"
  #"python-gdbgui"
  "gdbgui"
  "evolution"
  "lua-language-server"
  "lua-local-lua-debugger"
  "delve"
  "python-lsp-server"
  "zig"
  "zls"
  "asm-lsp"
  "bashdb"
  "bash-language-server"
  "python-debugpy"
  "go-asmfmt"
  "golangci-lint"
)

proglang=(
  "lua"
  "clang"
  "go"
  "py"
  "zig"
  "nasm"
  "bash"
)

git_repo=(
  "config"
  "scripts"
  "RP2040"
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

# Installation von pacman-Paketen
echo -e "\n ------------------------------------"
echo -e "Installiere Programme mit pacman"
notify-send "pacman-Pakete werden installiert"
sudo pacman -S --needed --noconfirm "${progpac[@]}" >>"$log_file" 2>>"$error_log_file"
check_error "Installation von pacman-Paketen"

# Installation von yay
echo -e "\n ------yay------"
notify-send "yay wird installiert"
sudo pacman -S --needed --noconfirm git base-devel >>"$log_file" 2>>"$error_log_file"
check_error "Installation von git und base-devel"
cd /home/$user_name
if [ ! -d "yay" ]; then
  git clone https://aur.archlinux.org/yay.git >>"$log_file" 2>>"$error_log_file"
  check_error "Klonen von yay"
fi
cd yay
makepkg -si --noconfirm >>"$log_file" 2>>"$error_log_file"
check_error "Installation von yay"
cd /home/$user_name

# Installation von yay-Paketen
echo -e "\n ------------------------------------"
echo -e "Installiere Programme mit yay"
notify-send "yay-Pakete werden installiert"
for pkg in "${progyay[@]}"; do
  echo -e "Installiere $pkg"
  yay -S --noconfirm "$pkg" >>"$log_file" 2>>"$error_log_file"
  if [ $? -ne 0 ]; then
    echo "Warnung: Installation von $pkg fehlgeschlagen. Fahre mit nächstem Paket fort." >>"$log_file"
  fi
done

# npm-Pakete
echo -e "\n ------npm------"
notify-send "npm-Pakete werden installiert"
sudo npm install -g tree-sitter --silent >>"$log_file" 2>>"$error_log_file"
sudo npm install -g tree-sitter-cli --silent >>"$log_file" 2>>"$error_log_file"
sudo npm install -g matlab-language-server --silent >>"$log_file" 2>>"$error_log_file"
sudo npm install -g prettier --silent >>"$log_file" 2>>"$error_log_file"
check_error "Installation von npm-Paketen"

#Go-Tools
echo -e "\n ------Go------"
notify-send "Go-Tools werden installiert"
go install golang.org/x/tools/gopls@latest >>"$log_file" 2>>"$error_log_file"
go install github.com/segmentio/golines@latest >>"$log_file" 2>>"$error_log_file"
check_error "Installation von Go-Tools"

# Ordnererstellung
echo -e "\n ------------------------------------"
echo -e "Ordner werden erstellt"
notify-send "Ordner werden erstellt"
cd /home/$user_name
for prog in "${proglang[@]}"; do
  echo -e "Erstelle Ordner für $prog"
  mkdir -p "/home/$user_name/Prog/$prog" "/home/$user_name/Doku/$prog" "/home/$user_name/Git/$prog" "/home/$user_name/Doku/latex/prog/$prog" >>"$log_file" 2>>"$error_log_file"
done
mkdir -p "/home/$user_name/Git/config/" "/home/$user_name/Git/scripts" >>"$log_file" 2>>"$error_log_file"
mkdir -p "/home/$user_name/Log" "/home/$user_name/Scripts" "/home/$user_name/git1/config" "/home/$user_name/git1/scripts" "/home/$user_name/git1/RP2040" >>"$log_file" 2>>"$error_log_file"
mkdir -p "$HOME/.config/nvim/lua/config" "$HOME/.config/nvim/lua/plugins" "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/kitty" "$HOME/.config/qutebrowser" >>"$log_file" 2>>"$error_log_file"
check_error "Ordnererstellung"

# Git-Repositories klonen
echo -e "\n ------Dateien klonen------"
notify-send "Dateien werden geklont"
for repo in "${git_repo[@]}"; do
	echo "$repo">>"$log_file" 2>>"$error_log_file"
    git clone "https://github.com/tobil939/$repo.git" "/home/$user_name/git1/$repo" >>"$log_file" 2>>"$error_log_file"
    echo "https://github.com/tobil939/$repo.git">>"$log_file" 2>>"$error_log_file"
    echo "/home/$user_name/git1/$repo">>"$log_file" 2>>"$error_log_file"
    check_error "Klonen von $repo">>"$log_file" 2>>"$error_log_file"
done

# Dateien aus tobil939/config kopieren
echo -e "\n ------Daten kopieren (config)------"
notify-send "Konfigurationsdateien werden kopiert"
cd /home/$user_name/git1/config
check_error "Wechseln in config-Verzeichnis"

# Neovim-Dateien
for file in "${nvim_plugin_files[@]}"; do
  if [ ! -f "/home/$user_name/git1/config/$file" ]; then
    echo "Fehler: $file existiert nicht in /home/$user_name/git1/config/" >>"$log_file" 2>>"$error_log_file"
    check_error "Quelldatei $file fehlt"
  fi
  if [ -f "$HOME/.config/nvim/lua/plugins/$file" ]; then
    sudo mv "$HOME/.config/nvim/lua/plugins/$file" "$HOME/.config/nvim/lua/plugins/$file.bak" >>"$log_file" 2>>"$error_log_file"
    echo "Backup von $file erstellt" >>"$log_file"
else
	mkdir -p "$HOME/.config/nvim/lua/plugins/"
	echo "nvim plugins Ordner wurde ertellt"
  fi
  sudo cp "/home/$user_name/git1/config/$file" "$HOME/.config/nvim/lua/plugins/$file" >>"$log_file" 2>>"$error_log_file"
  check_error "Kopieren von $file"
done
for file in "${nvim_config_files[@]}"; do
  if [ ! -f "/home/$user_name/git1/config/$file" ]; then
    echo "Fehler: $file existiert nicht in /home/$user_name/git1/config/" >>"$log_file" 2>>"$error_log_file"
    check_error "Quelldatei $file fehlt"
else
	mkdir -p "$HOME/.config/nvim/lua/config/"
	echo "nvim config Ordner wurde erstllt"
  fi
  if [ -f "$HOME/.config/nvim/lua/config/$file" ]; then
    sudo mv "$HOME/.config/nvim/lua/config/$file" "$HOME/.config/nvim/lua/config/$file.bak" >>"$log_file" 2>>"$error_log_file"
    echo "Backup von $file erstellt" >>"$log_file"
  fi
  sudo cp "/home/$user_name/git1/config/$file" "$HOME/.config/nvim/lua/config/$file" >>"$log_file" 2>>"$error_log_file"
  check_error "Kopieren von $file"
done
if [ ! -f "/home/$user_name/git1/config/init.lua" ]; then
  echo "Fehler: init.lua existiert nicht in /home/$user_name/git1/config/" >>"$log_file" 2>>"$error_log_file"
  check_error "Quelldatei init.lua fehlt"
fi
if [ -f "$HOME/.config/nvim/init.lua" ]; then
  sudo mv "$HOME/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua.bak" >>"$log_file" 2>>"$error_log_file"
  echo "Backup von init.lua erstellt" >>"$log_file"
fi
sudo cp "/home/$user_name/git1/config/init.lua" "$HOME/.config/nvim/init.lua" >>"$log_file" 2>>"$error_log_file"
check_error "Kopieren von init.lua"

# Hyprland-Dateien
for file in "${hypr_files[@]}"; do
  if [ ! -f "/home/$user_name/git1/config/$file" ]; then
    echo "Fehler: $file existiert nicht in /home/$user_name/git1/config/" >>"$log_file" 2>>"$error_log_file"
    check_error "Quelldatei $file fehlt"
  fi
  if [ -f "$HOME/.config/hypr/$file" ]; then
    sudo mv "$HOME/.config/hypr/$file" "$HOME/.config/hypr/$file.bak" >>"$log_file" 2>>"$error_log_file"
    echo "Backup von $file erstellt" >>"$log_file"
else
	mkdir -p "$HOME/.config/hypr/"
	echo "hypr Ordner wurde erstellt"
  fi
  sudo cp "/home/$user_name/git1/config/$file" "$HOME/.config/hypr/$file" >>"$log_file" 2>>"$error_log_file"
  check_error "Kopieren von $file"
done

# Waybar-Dateien
for file in "${waybar_files[@]}"; do
  if [ ! -f "/home/$user_name/git1/config/$file" ]; then
    echo "Fehler: $file existiert nicht in /home/$user_name/git1/config/" >>"$log_file" 2>>"$error_log_file"
    check_error "Quelldatei $file fehlt"
  fi
  if [ -f "$HOME/.config/waybar/$file" ]; then
    sudo mv "$HOME/.config/waybar/$file" "$HOME/.config/waybar/$file.bak" >>"$log_file" 2>>"$error_log_file"
    echo "Backup von $file erstellt" >>"$log_file"
else
	mkdir -p "$HOME/.config/waybar"
	echo "waybar Ordner wurde erstllt"
  fi
  sudo cp "/home/$user_name/git1/config/$file" "$HOME/.config/waybar/$file" >>"$log_file" 2>>"$error_log_file"
  check_error "Kopieren von $file"
done

# Qutebrowser
if [ ! -f "/home/$user_name/git1/config/config.py" ]; then
  echo "Fehler: config.py existiert nicht in /home/$user_name/git1/config/" >>"$log_file" 2>>"$error_log_file"
  check_error "Quelldatei config.py fehlt"
fi
if [ -f "$HOME/.config/qutebrowser/config.py" ]; then
  sudo mv "$HOME/.config/qutebrowser/config.py" "$HOME/.config/qutebrowser/config.py.bak" >>"$log_file" 2>>"$error_log_file"
  echo "Backup von config.py erstellt" >>"$log_file"
else
	mkdir -p "$HOME/.config/qutebrowser/"
	echo "qutebrowser Ordner wurde erstllt"
fi
sudo cp "/home/$user_name/git1/config/config.py" "$HOME/.config/qutebrowser/config.py" >>"$log_file" 2>>"$error_log_file"
check_error "Kopieren von config.py"

# Kitty-Konfiguration
echo -e "\n ------Kitty-Konfiguration------"
notify-send "Kitty wird konfiguriert"
if [ ! -f "/home/$user_name/git1/config/kitty.conf" ]; then
  echo "Fehler: kitty.conf existiert nicht in /home/$user_name/git1/config/" >>"$log_file" 2>>"$error_log_file"
  check_error "Quelldatei kitty.conf fehlt"
fi
if [ -f "$HOME/.config/kitty/kitty.conf" ]; then
  sudo mv "$HOME/.config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf.bak" >>"$log_file" 2>>"$error_log_file"
  echo "Backup von kitty.conf erstellt" >>"$log_file"
else
	mkdir -p "$HOME/.config/kitty/"
	echo "kitty Ordner wurde erstellt"
fi
sudo cp "/home/$user_name/git1/config/kitty.conf" "$HOME/.config/kitty/kitty.conf" >>"$log_file" 2>>"$error_log_file"
check_error "Kopieren von kitty.conf"

# Dateien aus tobil939/scripts kopieren
echo -e "\n ------Daten kopieren (scripts)------"
notify-send "Skripte werden kopiert"
cp -r /home/$user_name/git1/scripts/* $HOME/Scripts/
cd /home/$user_name/git1/scripts
check_error "Wechseln in scripts-Verzeichnis"
script_files=("bluetooth.sh" "bunga.sh" "flash.sh" "mnt.sh" "pico.sh" "tex.sh" "update.sh")
for file in "${script_files[@]}"; do
  if [ ! -f "/home/$user_name/git1/scripts/$file" ]; then
    echo "Fehler: $file existiert nicht in /home/$user_name/git1/scripts/" >>"$log_file" 2>>"$error_log_file"
    check_error "Quelldatei $file fehlt"
  fi
  if [ -f "/usr/local/bin/$file" ]; then
    sudo mv "/usr/local/bin/$file" "/usr/local/bin/$file.bak" >>"$log_file" 2>>"$error_log_file"
    echo "Backup von $file erstellt" >>"$log_file"
  fi
  sudo cp "/home/$user_name/git1/scripts/$file" "/usr/local/bin/$file" >>"$log_file" 2>>"$error_log_file"
  sudo chmod +x "/usr/local/bin/$file" >>"$log_file" 2>>"$error_log_file"
  check_error "Kopieren und Ausführbar-Machen von $file"
done

# Dark Mode
echo -e "\n ------Dark Mode------"
notify-send "Dark Mode wird aktiviert"
if command -v gsettings >/dev/null; then
  gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark" >>"$log_file" 2>>"$error_log_file"
  gsettings set org.gnome.desktop.interface icon-theme "Adwaita" >>"$log_file" 2>>"$error_log_file"
  gsettings set org.gnome.shell.extensions.user-theme name "Adwaita" >>"$log_file" 2>>"$error_log_file"
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark >>"$log_file" 2>>"$error_log_file"
  check_error "Aktivierung von Dark Mode"
else
  echo "GNOME nicht gefunden, Dark Mode wird übersprungen" >>"$log_file"
fi

# Bluetooth
echo -e "\n ------Bluetooth------"
notify-send "Bluetooth wird aktiviert"
sudo systemctl start bluetooth.service >>"$log_file" 2>>"$error_log_file"
sudo systemctl enable bluetooth.service >>"$log_file" 2>>"$error_log_file"
check_error "Aktivierung von Bluetooth"

if [ ! -w ~/.bashrc ]; then
  echo "Fehler: ~/.bashrc ist nicht beschreibbar" >>"$error_log_file"
  exit 1
fi

# Neofetch in .bashrc
echo -e "\n ------Neofetch einbinden------"
if ! grep -Fxq "neofetch" ~/.bashrc; then
  echo "neofetch" >> ~/.bashrc 2>>"$error_log_file"
  echo "neofetch hinzugefügt" >>"$log_file"
else
  echo "neofetch bereits vorhanden" >>"$log_file"
fi

# Git-Konfiguration
echo -e "\n ------Git config------"
read -p "Benutzername für git: " user_git
echo -e "\n Benutzername für git: $user_git \n" >>"$log_file"
read -p "Emailadresse für git: " user_email
echo -e "\n Emailadresse für git: $user_email \n" >>"$log_file"
git config --global user.name "$user_git" >>"$log_file" 2>>"$error_log_file"
git config --global user.email "$user_email" >>"$log_file" 2>>"$error_log_file"
git config --global core.editor nvim >>"$log_file" 2>>"$error_log_file"
check_error "Git-Konfiguration"

# Abschluss
echo -e "\n ------Fertig------"
notify-send "Installation abgeschlossen"
#reboot
