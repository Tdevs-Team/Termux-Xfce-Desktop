#!/data/data/com.termux/files/usr/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
APT_OPTS="-y -o Dpkg::Options::=--force-confnew"

### COLORS ###
CYAN="\033[1;36m"
BLUE="\033[1;94m"
RED="\033[1;91m"
RESET="\033[0m"

clear

################ BANNER ################
echo -e "${CYAN}"
cat << "EOF"
████████╗██████╗ ███████╗██╗   ██╗███████╗
╚══██╔══╝██╔══██╗██╔════╝██║   ██║██╔════╝
   ██║   ██║  ██║█████╗  ██║   ██║███████╗
   ██║   ██║  ██║██╔══╝  ╚██╗ ██╔╝╚════██║
   ██║   ██████╔╝███████╗ ╚████╔╝ ███████║
   ╚═╝   ╚═════╝ ╚══════╝  ╚═══╝  ╚══════╝
EOF
echo -e "${BLUE}Dev : @TechTern${RESET}\n"

################ MENU ################
echo -e "${CYAN}1) Install Desktop"
echo -e "2) Uninstall Everything${RESET}"
read -r -p "> " ACTION </dev/tty

################ UNINSTALL ################
if [ "$ACTION" = "2" ]; then
  pkg uninstall $APT_OPTS \
    xfce4 xfce4-goodies termux-x11 pulseaudio dbus mesa \
    firefox chromium code-server python xorg-xhost || true

  rm -rf ~/.config/tx11 ~/.config/code-server ~/.config/pulse
  rm -f $PREFIX/bin/tx11-desktop

  pkill -f termux-x11 2>/dev/null || true
  pkill xfce4-session 2>/dev/null || true
  pulseaudio -k 2>/dev/null || true

  clear
  echo -e "${BLUE}✔ Everything removed successfully${RESET}"
  exit 0
fi

################ STORAGE ################
[ ! -d "$HOME/storage" ] && termux-setup-storage
sleep 2
clear

################ UPDATE ################
pkg update $APT_OPTS
pkg upgrade $APT_OPTS
clear

################ REPOS ################
pkg install $APT_OPTS x11-repo tur-repo
clear

################ CORE ################
pkg install $APT_OPTS \
  termux-x11 xfce4 xfce4-goodies \
  dbus pulseaudio mesa xorg-xhost
clear

################ BROWSER ################
echo -e "${CYAN}Browser:${RESET}"
echo -e "${BLUE}1) Firefox"
echo -e "2) Chromium"
echo -e "3) Both${RESET}"
read -r -p "> " BROWSER </dev/tty

case "$BROWSER" in
  1) pkg install $APT_OPTS firefox ;;
  2) pkg install $APT_OPTS chromium ;;
  3) pkg install $APT_OPTS firefox chromium ;;
esac
clear

################ PYTHON ################
echo -e "${CYAN}Install Python? (y/n)${RESET}"
read -r -p "> " PYTHON </dev/tty
[[ "$PYTHON" =~ ^[Yy]$ ]] && pkg install $APT_OPTS python
clear

################ CODE SERVER ################
echo -e "${CYAN}Install VS Code (code-server)? (y/n)${RESET}"
read -r -p "> " VSCODE </dev/tty

if [[ "$VSCODE" =~ ^[Yy]$ ]]; then
  pkg install $APT_OPTS code-server

  echo -e "${CYAN}Set code-server password:${RESET}"
  read -s -p "Password: " CS_PASS </dev/tty
  echo
  read -s -p "Confirm: " CS_CONFIRM </dev/tty
  echo

  if [ "$CS_PASS" = "$CS_CONFIRM" ] && [ -n "$CS_PASS" ]; then
    mkdir -p ~/.config/code-server
    cat > ~/.config/code-server/config.yaml << EOF
bind-addr: 127.0.0.1:8080
auth: password
password: ${CS_PASS}
cert: false
EOF
  fi
fi
clear

################ AUDIO FIX ################
mkdir -p ~/.config/pulse
cat > ~/.config/pulse/default.pa << 'EOF'
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
EOF

################ XFCE ################
mkdir -p ~/.config/tx11

cat > ~/.config/tx11/startxfce.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

export DISPLAY=:0
export XDG_RUNTIME_DIR=$TMPDIR
export PULSE_SERVER=127.0.0.1

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

pulseaudio -k >/dev/null 2>&1 || true
sleep 1

pulseaudio \
  --start \
  --exit-idle-time=-1 \
  --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
  --daemonize=yes

exec dbus-launch --exit-with-session xfce4-session
EOF

chmod +x ~/.config/tx11/startxfce.sh

################ X11 START ################
cat > $PREFIX/bin/tx11-desktop << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

pkill -f termux-x11 2>/dev/null || true
pkill xfce4-session 2>/dev/null || true

am start --user 0 -n com.termux.x11/.MainActivity >/dev/null 2>&1

for i in {1..12}; do
  termux-x11 :0 >/dev/null 2>&1 && break
  sleep 1
done

~/.config/tx11/startxfce.sh
EOF

chmod +x $PREFIX/bin/tx11-desktop

################ DONE ################
clear
echo -e "${BLUE}✔ Installation complete${RESET}"
echo -e "${CYAN}Start desktop using:${RESET}"
echo -e "${BLUE}tx11-desktop${RESET}"

tx11-desktop
