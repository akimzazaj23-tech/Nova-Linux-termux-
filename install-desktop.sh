#!/data/data/com.termux/files/usr/bin/bash
# Nova Linux — графический рабочий стол (XFCE) для Termux:X11
# Запускать ПОСЛЕ install.sh
set -euo pipefail

OS_NAME="Nova Linux"
ALIAS="nova"        # должен совпадать с ALIAS в install.sh
DESKTOP_USER="nova" # обычный пользователь для рабочего стола

log() { printf '\033[1;36m[%s]\033[0m %s\n' "$OS_NAME" "$*"; }

BASE_URL="https://raw.githubusercontent.com/akimzazaj23-tech/Nova-Linux-termux-/main"

if [ -z "${PREFIX:-}" ] || [ ! -d "$PREFIX" ] || [ "$(id -u)" = "0" ]; then
  echo "Этот скрипт нужно запускать в Termux, а не внутри Linux." >&2
  echo "Если у тебя приглашение 'root@localhost', набери: exit" >&2
  echo "Запускай команду, когда увидишь приглашение '~ \$'." >&2
  exit 1
fi

# завершаем зависшие процессы proot от прошлых запусков (они держат блокировки dpkg)
command -v pkill >/dev/null 2>&1 || pkg install -y procps </dev/null
stale_proot() {
  pgrep -x proot >/dev/null 2>&1 \
    || pgrep -f '[l]ibexec/proot/loader' >/dev/null 2>&1 \
    || pgrep -f '[b]in/proot-distro' >/dev/null 2>&1
}
if stale_proot; then
  log "Нашёл зависшие процессы proot — завершаю их (открытые окна Nova закроются)..."
  pkill -9 -x proot 2>/dev/null || true
  pkill -9 -f '[l]ibexec/proot/loader' 2>/dev/null || true
  pkill -9 -f '[b]in/proot-distro' 2>/dev/null || true
  sleep 1
fi

# если базовая система не установлена — ставим её автоматически
if ! proot-distro login "$ALIAS" -- true </dev/null >/dev/null 2>&1; then
  log "Базовая система не найдена — сначала устанавливаю её..."
  pkg install -y curl </dev/null
  curl -fsSL "$BASE_URL/install.sh" | bash
fi

log "Ставлю X11-репозиторий, Termux:X11 и PulseAudio..."
pkg install -y x11-repo </dev/null
pkg update -y </dev/null
pkg install -y termux-x11-nightly pulseaudio </dev/null

read -r -d '' SETUP <<'EOS' || true
set -e
export DEBIAN_FRONTEND=noninteractive

# чиним прерванную установку пакетов, если она осталась с прошлого раза
dpkg --configure -a || true
apt-get install -f -y || true

apt-get update
# обязательные пакеты
apt-get install -y xfce4 xfce4-terminal dbus-x11 sudo
# необязательные: если какого-то нет в этой версии Ubuntu — не страшно
for pkg in mousepad fonts-dejavu-core x11-xserver-utils; do
  apt-get install -y "$pkg" || echo "пропускаю $pkg"
done

if ! id "$DESKTOP_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash -G sudo "$DESKTOP_USER"
fi
echo "$DESKTOP_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$DESKTOP_USER"
chmod 440 "/etc/sudoers.d/$DESKTOP_USER"
EOS

log "Ставлю XFCE внутри системы (это долго, ~1 ГБ)..."
proot-distro login "$ALIAS" -- env DESKTOP_USER="$DESKTOP_USER" bash -c "$SETUP" </dev/null

log "Создаю команду запуска 'nova-desktop'..."
cat > "$PREFIX/bin/nova-desktop" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Запуск рабочего стола Nova Linux в Termux:X11
ALIAS="nova"
DESKTOP_USER="nova"

cleanup() {
  pkill -f termux.x11 2>/dev/null || true
  pulseaudio --kill 2>/dev/null || true
  termux-wake-unlock 2>/dev/null || true
}
trap cleanup EXIT

cleanup
termux-wake-lock 2>/dev/null || true

# звук
pulseaudio --start --exit-idle-time=-1 \
  --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1"

# X-сервер и приложение Termux:X11
export XDG_RUNTIME_DIR="${TMPDIR:-$PREFIX/tmp}"
termux-x11 :0 >/dev/null 2>&1 &
sleep 3
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || \
  echo "Открой приложение Termux:X11 вручную."

# рабочий стол
proot-distro login "$ALIAS" --user "$DESKTOP_USER" --shared-tmp -- env \
  DISPLAY=:0 PULSE_SERVER=127.0.0.1 LIBGL_ALWAYS_SOFTWARE=1 \
  MOZ_DISABLE_CONTENT_SANDBOX=1 MOZ_DISABLE_GMP_SANDBOX=1 MOZ_DISABLE_RDD_SANDBOX=1 MOZ_DISABLE_SOCKET_PROCESS_SANDBOX=1 \
  XDG_RUNTIME_DIR="/tmp/runtime-$DESKTOP_USER" \
  bash -c 'mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR" && exec dbus-launch --exit-with-session startxfce4'
EOF
chmod +x "$PREFIX/bin/nova-desktop"

log "Создаю команду 'nova-root' (запуск команд в Nova от root)..."
cat > "$PREFIX/bin/nova-root" <<'EOR'
#!/data/data/com.termux/files/usr/bin/bash
# Примеры:  nova-root apt install -y firefox-esr   |   nova-root  (консоль root)
if [ $# -eq 0 ]; then
  exec proot-distro login nova --shared-tmp
fi
exec proot-distro login nova --shared-tmp -- "$@"
EOR
chmod +x "$PREFIX/bin/nova-root"

log "Готово!"
echo
echo "1) Установи приложение Termux:X11 (APK): https://github.com/termux/termux-x11/releases"
echo "2) Запусти в Termux команду:  nova-desktop"
echo "3) Устанавливать программы от root:  nova-root apt install <пакет>"
