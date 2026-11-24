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

log "Обновляю Termux и ставлю proot-distro..."
pkg update -y </dev/null
pkg upgrade -y </dev/null
pkg install -y proot-distro curl </dev/null

if proot-distro login "$ALIAS" -- true </dev/null >/dev/null 2>&1; then
  log "Система '$ALIAS' уже установлена — пропускаю загрузку, обновляю брендинг."
else
  log "Скачиваю и устанавливаю базу ($BASE_DISTRO)..."
  # proot-distro 5.x: --name, более старые версии: --override-alias
  proot-distro install "$BASE_DISTRO" --name "$ALIAS" </dev/null \
    || proot-distro install "$BASE_DISTRO" --override-alias "$ALIAS" </dev/null
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

cat > /usr/local/bin/nova-install <<'EONI'
#!/bin/bash
# nova-install — установка приложений в Nova Linux
export DEBIAN_FRONTEND=noninteractive

usage() {
  cat <<'EOT'
nova-install — установка приложений в Nova Linux

  nova-install firefox vlc gimp     установить приложения
  nova-install --list               каталог популярных приложений
  nova-install --search слово       поиск пакета в репозитории
  nova-install --remove vlc         удалить приложение
  nova-install --update             обновить список пакетов и систему

Можно указывать и любое имя пакета apt (например: nova-install htop).
Установленные программы появятся в меню Applications рабочего стола.
EOT
}

list_apps() {
  cat <<'EOT'
Браузер:        firefox
Видео и аудио:  vlc, mpv, audacity
Графика:        gimp, inkscape
Офис:           libreoffice, pdf (просмотр PDF), geany (редактор кода)
Фото:           images (просмотр картинок)
Разработка:     python, node, dev (gcc, make), git
Мессенджер:     telegram
Утилиты:        htop, fastfetch

Любого другого пакета нет в списке? Просто укажи его имя: nova-install <пакет>
EOT
}

pkgs_for() {
  case "$1" in
    firefox)         echo "@firefox" ;;
    vlc)             echo "vlc" ;;
    mpv)             echo "mpv" ;;
    audacity)        echo "audacity" ;;
    gimp)            echo "gimp" ;;
    inkscape)        echo "inkscape" ;;
    libreoffice)     echo "libreoffice" ;;
    pdf|evince)      echo "evince" ;;
    geany)           echo "geany" ;;
    images|ristretto) echo "ristretto" ;;
    python)          echo "python3 python3-pip python3-venv" ;;
    node|nodejs)     echo "nodejs npm" ;;
    dev|gcc|build)   echo "build-essential" ;;
    git)             echo "git" ;;
    telegram)        echo "telegram-desktop" ;;
    htop)            echo "htop" ;;
    fastfetch)       echo "fastfetch" ;;
    *)               echo "$1" ;;
  esac
}

need_root() {
  if [ "$(id -u)" != "0" ]; then
    echo "Нужны права root. Пробую sudo (не выйдет — запусти из Termux: nova-install ...)" >&2
    exec sudo "$0" "$@"
  fi
}

# Firefox в Ubuntu — это snap, в proot он не работает. Ставим официальный deb от Mozilla.
setup_firefox() {
  install -d -m 0755 /etc/apt/keyrings || return 1
  wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg \
    -O /etc/apt/keyrings/packages.mozilla.org.asc || return 1
  echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
    > /etc/apt/sources.list.d/mozilla.list
  printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' \
    > /etc/apt/preferences.d/mozilla
}

resolve_pkgs() {
  # заполняет глобальные WANT_FF и PKGS
  WANT_FF=0
  PKGS=()
  local a p x
  for a in "$@"; do
    case "$a" in
      -*) echo "Неизвестная опция: $a (см. nova-install --help)" >&2; return 1 ;;
    esac
    p="$(pkgs_for "$a")"
    if [ "$p" = "@firefox" ]; then
      WANT_FF=1
      PKGS+=("firefox")
    else
      for x in $p; do PKGS+=("$x"); done
    fi
  done
}

install_apps() {
  need_root "$@"
  resolve_pkgs "$@" || return 1
  dpkg --configure -a >/dev/null 2>&1 || true
  apt-get update || echo "Не удалось обновить список пакетов — продолжаю."
  if [ "$WANT_FF" = 1 ]; then
    apt-get install -y wget ca-certificates || true
    setup_firefox || { echo "Не удалось добавить репозиторий Mozilla." >&2; return 1; }
    apt-get update
  fi
  if apt-get install -y "${PKGS[@]}"; then
    echo
    echo "Готово! Приложение появится в меню Applications на рабочем столе."
  else
    echo >&2
    echo "Не получилось. Проверь имя пакета: nova-install --search <слово>" >&2
    return 1
  fi
}

remove_apps() {
  need_root --remove "$@"
  resolve_pkgs "$@" || return 1
  apt-get remove -y "${PKGS[@]}"
}

search_pkgs() {
  if [ $# -eq 0 ]; then echo "Укажи, что искать: nova-install --search <слово>" >&2; return 1; fi
  local out
  out="$(apt-cache search "$*" | head -30)"
  if [ -z "$out" ]; then
    echo "Ничего не найдено. Если список пакетов пуст, выполни: nova-install --update"
  else
    echo "$out"
  fi
}

case "${1:-}" in
  ""|-h|--help|help)      usage ;;
  -l|--list|list)         list_apps ;;
  -s|--search|search)     shift; search_pkgs "$@" ;;
  -r|--remove|remove)     shift; remove_apps "$@" ;;
  -u|--update|update)     need_root --update; apt-get update && apt-get -y upgrade ;;
  *)                      install_apps "$@" ;;
esac
EONI
chmod +x /usr/local/bin/nova-install

for f in /root/.bashrc /etc/skel/.bashrc; do
  [ -f "$f" ] || continue
  grep -q "nova-prompt" "$f" || cat >> "$f" <<'EOP'

# nova-prompt
PS1='\[\e[1;35m\](nova)\[\e[0m\] \u@\h:\w\$ '
EOP
done

export DEBIAN_FRONTEND=noninteractive
dpkg --configure -a || true
apt-get install -f -y || true
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

log "Создаю команду 'nova-install' (установка приложений)..."
cat > "$PREFIX/bin/nova-install" <<EOF
#!$PREFIX/bin/bash
exec proot-distro login $ALIAS --shared-tmp -- /usr/local/bin/nova-install "\$@"
EOF
chmod +x "$PREFIX/bin/nova-install"

log "Готово! Войти в систему: $OS_ID   |   Выйти обратно в Termux: exit"
log "Установка приложений: nova-install firefox vlc gimp   (список: nova-install --list)"
log "Для графического рабочего стола (Termux:X11) запусти: bash install-desktop.sh"
