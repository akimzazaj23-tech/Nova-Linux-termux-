# Nova Linux

Linux-система для Android на базе Ubuntu, с собственным названием и брендингом.
Работает без root: через Termux + proot-distro.

## Установка

1. Установи **Termux** с [F-Droid](https://f-droid.org/packages/com.termux/) или GitHub
   (версия из Google Play устарела и не работает).
2. В Termux выполни:

```bash
pkg install -y curl
curl -fsSL https://raw.githubusercontent.com/akimzazaj23-tech/Nova-Linux-termux-/main/install.sh | bash
```

## Запуск

```bash
nova
```

Внутри: `cat /etc/os-release` покажет Nova Linux. Пакеты ставятся как в Ubuntu: `apt install ...`.

## Переименование

Открой `install.sh` и поменяй блок «НАСТРОЙКИ БРЕНДА» (`OS_NAME`, `OS_ID`, `OS_VERSION`, `OS_URL`, `ALIAS`).

> Обновление пакета `base-files` может вернуть оригинальный `/etc/os-release`.
> Просто запусти `install.sh` ещё раз — он идемпотентный и заново применит брендинг.

## Удаление

```bash
proot-distro remove nova
rm $PREFIX/bin/nova
```

## Юридически

- Не используй слова «Ubuntu»/«Canonical» в названии и логотипе своей системы — это торговые марки.
  Фраза «на базе Ubuntu» допустима. Правила: https://ubuntu.com/legal/intellectual-property-policy
- Скрипты в этом репозитории — MIT. Пакеты внутри системы остаются под своими лицензиями (GPL и др.).

## Планы

- [ ] Нативное Android-приложение (APK) со встроенным терминалом
- [ ] Графический рабочий стол (XFCE + VNC)
- [ ] Свой набор предустановленных пакетов
