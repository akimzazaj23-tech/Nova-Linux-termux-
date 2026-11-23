#!/data/data/com.termux/files/usr/bin/bash
# Nova Linux — установщик для Termux (Android)
# Ставит Ubuntu rootfs через proot-distro и переименовывает его в свою систему.
set -euo pipefail

# ======== НАСТРОЙКИ БРЕНДА (меняй под себя) ========
OS_NAME="Nova Linux"
OS_ID="nova"
OS_VERSION="1.0"
OS_URL="https://github.com/akimzazaj23-tech/Nova-Linux-termux-"
BASE_DISTRO="ubuntu"
ALIAS="nova"          # команда входа: proot-distro login nova
# ===================================================

log() { printf '\033[1;36m[%s]\033[0m %s\n' "$OS_NAME" "$*"; }

if [ -z "${PREFIX:-}" ] || [ ! -d "$PREFIX" ] || [ "$(id -u)" = "0" ]; then
  echo "Этот скрипт нужно запускать в Termux, а не внутри Linux." >&2
  echo "Если у тебя приглашение 'root@localhost', набери: exit" >&2
  echo "Запускай команду, когда увидишь приглашение '~ \$'." >&2
  exit 1
fi

log "Обновляю Termux и ставлю proot-distro..."
pkg update -y </dev/null
pkg upgrade -y </dev/null
pkg install -y proot-distro curl </dev/null

ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/$ALIAS"
if [ -d "$ROOTFS" ]; then
  log "Система '$ALIAS' уже установлена — пропускаю загрузку, обновляю брендинг."
else
  log "Скачиваю и устанавливаю базу ($BASE_DISTRO)..."
  proot-distro install "$BASE_DISTRO" --override-alias "$ALIAS" </dev/null
fi

read -r -d '' REBRAND <<'EOS' || true
set -e
# читаем оригинальные данные до подмены
. /usr/lib/os-release
CODENAME="${VERSION_CODENAME:-}"
BASE_VER="${VERSION_ID:-}"

rm -f /etc/os-release
cat > /etc/os-release <<EOF
PRETTY_NAME="${OS_NAME} ${OS_VERSION} (на базе Ubuntu ${BASE_VER})"
NAME="${OS_NAME}"
VERSION_ID="${OS_VERSION}"
VERSION="${OS_VERSION}"
VERSION_CODENAME=${CODENAME}
ID=${OS_ID}
ID_LIKE="ubuntu debian"
UBUNTU_CODENAME=${CODENAME}
HOME_URL="${OS_URL}"
EOF

echo "${OS_NAME} ${OS_VERSION} \\n \\l" > /etc/issue
echo "${OS_ID}" > /etc/hostname

cat > /etc/motd <<EOF

  ${OS_NAME} ${OS_VERSION}
  Linux в твоём кармане. Добро пожаловать!
  ${OS_URL}

EOF

cat > /etc/profile.d/00-welcome.sh <<'EOT'
if [ -t 1 ] && [ -f /etc/motd ]; then cat /etc/motd; fi
EOT

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y sudo nano curl wget git htop locales
EOS

log "Применяю брендинг и ставлю базовые пакеты..."
proot-distro login "$ALIAS" -- env \
  OS_NAME="$OS_NAME" OS_ID="$OS_ID" OS_VERSION="$OS_VERSION" OS_URL="$OS_URL" \
  bash -c "$REBRAND" </dev/null

log "Создаю команду запуска '$OS_ID'..."
cat > "$PREFIX/bin/$OS_ID" <<EOF
#!$PREFIX/bin/bash
exec proot-distro login $ALIAS --shared-tmp "\$@"
EOF
chmod +x "$PREFIX/bin/$OS_ID"

log "Готово! Запуск: введи команду  $OS_ID"
log "Для графического рабочего стола (Termux:X11) запусти: bash install-desktop.sh"
