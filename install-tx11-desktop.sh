#!/data/data/com.termux/files/usr/bin/bash

set -e

### COLORS ###
CYAN="\033[1;36m"
BLUE="\033[1;94m"
RED="\033[1;91m"
RESET="\033[0m"

clear

### LOADER ###
loader () {
  echo -ne "${BLUE}"
  for i in {1..25}; do
    echo -ne "#"
    sleep 0.07
  done
  echo -e "${RESET}"
}

### BANNER ###
echo -e "${CYAN}"
cat << "EOF"
████████╗██████╗ ███████╗██╗   ██╗███████╗
╚══██╔══╝██╔══██╗██╔════╝██║   ██║██╔════╝
   ██║   ██║  ██║█████╗  ██║   ██║███████╗
   ██║   ██║  ██║██╔══╝  ╚██╗ ██╔╝╚════██║
   ██║   ██████╔╝███████╗ ╚████╔╝ ███████║
   ╚═╝   ╚═════╝ ╚══════╝  ╚═══╝  ╚══════╝
EOF
echo -e "${BLUE}           Dev : @TechTern${RESET}\n"

### MENU ###
echo -e "${CYAN}Select an option:${RESET}"
echo -e "${BLUE}1) Install Desktop Environment"
echo -e "2) Uninstall Everything${RESET}"
read -r -p "> " ACTION
echo ""

#################################
# UNINSTALL
#################################
if [ "$ACTION" = "2" ]; then
  echo -e "${RED}Uninstalling desktop environment...${RESET}"
  loader

  pkg uninstall -y \
    xfce4 \
    xfce4-goodies \
    termux-x11 \
    pulseaudio \
    dbus \
    mesa \
    firefox \
    chromium \
    code-server \
    xorg-xhost \
    >/dev/null 2>&1 || true

  rm -rf ~/.config/tx11
  rm -f $PREFIX/bin/tx11-desktop

  pkill -f termux-x11 2>/dev/null || true
  pkill xfce4-session 2>/dev/null || true

  echo -e "\n${BLUE}✔ Desktop environment removed successfully${RESET}"
  echo -e "${CYAN}Restart Termux for a clean state.${RESET}\n"
  exit 0
fi

#################################
# INSTALL
#################################

echo -e "${CYAN}[*] Please wait, this may take a few minutes...${RESET}\n"

### USER NAME ###
read -r -p "Enter your name (desktop greeting): " USERNAME
[ -z "$USERNAME" ] && USERNAME="User"

### STORAGE ###
echo -e "\n${CYAN}Checking storage permission...${RESET}"
if [ ! -d "$HOME/storage" ]; then
  echo -e "${BLUE}Requesting storage permission...${RESET}"
  loader
  termux-setup-storage >/dev/null 2>&1
  sleep 3
else
  echo -e "${BLUE}Storage permission already granted ✔${RESET}"
fi

### UPDATE ###
echo -e "\n${CYAN}Updating system packages...${RESET}"
loader
pkg update -y >/dev/null 2>&1
pkg upgrade -y >/dev/null 2>&1

### X11 REPO ###
echo -e "\n${CYAN}Enabling X11 repository...${RESET}"
loader
pkg install -y x11-repo >/dev/null 2>&1

### CORE PACKAGES ###
echo -e "\n${CYAN}Installing desktop & audio components...${RESET}"
loader
pkg install -y \
  termux-x11 \
  xfce4 \
  xfce4-goodies \
  dbus \
  pulseaudio \
  mesa \
  xorg-xhost \
  >/dev/null 2>&1

### BROWSER ###
echo -e "\n${CYAN}Choose browser:${RESET}"
echo -e "${BLUE}1) Firefox"
echo -e "2) Chromium"
echo -e "3) Both${RESET}"
read -r -p "> " BROWSER

loader
case "$BROWSER" in
  1) pkg install -y firefox >/dev/null 2>&1 ;;
  2) pkg install -y chromium >/dev/null 2>&1 ;;
  3) pkg install -y firefox chromium >/dev/null 2>&1 ;;
esac

### VSCODE ###
echo -e "\n${CYAN}Install VS Code (code-server)? (y/n)${RESET}"
read -r -p "> " VSCODE
if [[ "$VSCODE" =~ ^[Yy]$ ]]; then
  echo -e "${CYAN}Installing VS Code...${RESET}"
  loader
  pkg install -y code-server >/dev/null 2>&1
fi

### CONFIG ###
echo -e "\n${CYAN}Configuring desktop session...${RESET}"
loader

mkdir -p ~/.config/tx11

cat > ~/.config/tx11/startxfce.sh << EOF
#!/data/data/com.termux/files/usr/bin/bash

export DISPLAY=:0
export XDG_RUNTIME_DIR=\$TMPDIR
export PULSE_SERVER=127.0.0.1

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

pulseaudio --start --exit-idle-time=-1 >/dev/null 2>&1

notify-send "Welcome $USERNAME 👋" "XFCE Desktop is ready"

exec dbus-launch --exit-with-session xfce4-session
EOF

chmod +x ~/.config/tx11/startxfce.sh

### COMMAND ###
cat > $PREFIX/bin/tx11-desktop << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

pkill -f termux-x11 2>/dev/null || true
pkill xfce4-session 2>/dev/null || true

am start --user 0 -n com.termux.x11/.MainActivity >/dev/null 2>&1
sleep 2

termux-x11 :0 >/dev/null 2>&1 &
sleep 1

~/.config/tx11/startxfce.sh
EOF

chmod +x $PREFIX/bin/tx11-desktop

### DONE ###
echo -e "\n${BLUE}✔ Installation complete!${RESET}"
echo -e "${CYAN}Start desktop anytime using:${RESET}"
echo -e "${BLUE}tx11-desktop${RESET}\n"

sleep 2
tx11-desktop
