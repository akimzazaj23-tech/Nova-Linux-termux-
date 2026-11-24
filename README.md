# Nova Linux

Linux-система для Android на базе Ubuntu, с собственным названием и брендингом.
Работает без root: через Termux + proot-distro. Есть консольный и графический (Termux:X11) режимы.

## Установка (консоль)

1. Установи **Termux** с [F-Droid](https://f-droid.org/packages/com.termux/) или GitHub
   (версия из Google Play устарела и не работает).
2. В Termux выполни:

```bash
pkg install -y curl
curl -fsSL https://raw.githubusercontent.com/akimzazaj23-tech/Nova-Linux-termux-/main/install.sh | bash
```

Запуск:

```bash
nova
```

Внутри: `cat /etc/os-release` покажет Nova Linux. Пакеты ставятся как в Ubuntu: `apt install ...`.

## Графический режим (Termux:X11)

1. Установи приложение **Termux:X11** (APK) со страницы
   [releases](https://github.com/termux/termux-x11/releases) — лучше nightly-версию,
   она должна совпадать с пакетом `termux-x11-nightly`, который ставит скрипт.
2. Сначала должна быть установлена консольная система (см. выше), потом в Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/akimzazaj23-tech/Nova-Linux-termux-/main/install-desktop.sh | bash
```

3. Запуск рабочего стола:

```bash
nova-desktop
```

Откроется Termux:X11 с рабочим столом XFCE. Выйти: меню XFCE → Log Out.

Что ставится: XFCE, терминал, текстовый редактор, пользователь `nova` (с sudo без пароля —
это песочница на телефоне, но при желании поменяй в `install-desktop.sh`).
Нужно примерно 2–3 ГБ свободного места, установка занимает 10–30 минут.

### Установка приложений

Из Termux (приглашение `~ $`) или из консоли Nova:

```bash
nova-install firefox vlc gimp      # установить
nova-install --list                # каталог популярных приложений
nova-install --search слово        # найти пакет
nova-install --remove vlc          # удалить
nova-install --update              # обновить систему
```

Можно указать и любое имя пакета apt: `nova-install htop`. Установленные программы появятся в меню
Applications рабочего стола. Firefox ставится из официального репозитория Mozilla
(в Ubuntu он идёт как snap, а snap в proot не работает).

Вручную: в консоли Nova (`nova`, ты root) работает обычный `apt install ...`. В терминале рабочего стола
(пользователь `nova`) используй `sudo apt install ...` или, если `sudo` не срабатывает, `nova-root apt install ...` из Termux.

### Экран выглядит маленьким или с чёрными полосами

Поверни телефон горизонтально. Или в приложении Termux:X11 открой настройки
(Preferences → Display) и выбери режим разрешения `native` — рабочий стол займёт весь экран.

**Если рабочий стол закрывается сам (Android 12+):** система убивает фоновые процессы.
Включи в «Параметрах разработчика» отключение ограничений дочерних процессов
(на Android 14+ — «Disable child process restrictions») или отключи Phantom Process Killer через adb.

**Браузер:** Firefox из Ubuntu — snap, в proot не работает. Используй `nova-install firefox` (официальный deb от Mozilla).

## Переименование

Открой `install.sh` и поменяй блок «НАСТРОЙКИ БРЕНДА» (`OS_NAME`, `OS_ID`, `OS_VERSION`, `OS_URL`, `ALIAS`).
Если меняешь `ALIAS`, поменяй его и в `install-desktop.sh`.

> Обновление пакета `base-files` может вернуть оригинальный `/etc/os-release`.
> Просто запусти `install.sh` ещё раз — он идемпотентный и заново применит брендинг.

## Удаление

```bash
proot-distro remove nova
rm $PREFIX/bin/nova $PREFIX/bin/nova-desktop $PREFIX/bin/nova-root $PREFIX/bin/nova-install
```

## Юридически

- Не используй слова «Ubuntu»/«Canonical» в названии и логотипе своей системы — это торговые марки.
  Фраза «на базе Ubuntu» допустима. Правила: https://ubuntu.com/legal/intellectual-property-policy
- Скрипты в этом репозитории — MIT. Пакеты внутри системы остаются под своими лицензиями (GPL и др.).

## Планы

- [x] Графический рабочий стол (XFCE + Termux:X11)
- [ ] Свои обои и тема Nova
- [ ] Нативное Android-приложение (APK) со встроенным терминалом
- [ ] Свой набор предустановленных пакетов
