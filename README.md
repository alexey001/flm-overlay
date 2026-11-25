# flm-overlay

Личный Gentoo overlay для серверной инфраструктуры: платформа 1С, HashiCorp-стек,
PHP-стек, инструменты контейнерной сборки. Ebuild'ы заточены под конкретную
инфраструктуру (`~amd64`) и не претендуют на стабильность для всех сценариев.

## Подключение

```sh
eselect repository add flm-overlay git https://github.com/alexey001/flm-overlay.git
emaint sync -r flm-overlay
```

Примечание: внутри репозитория `profiles/repo_name` = `local` (историческое имя);
portage идентифицирует репозиторий по нему, поэтому в `emerge --info` репозиторий
может отображаться как `local`.

## Содержимое

| Пакет | Что это |
|---|---|
| `app-office/1c-enterprise` | Платформа 1С:Предприятие 8.3. RESTRICT="fetch" — дистрибутив кладётся в `/var/cache/distfiles` вручную |
| `app-backup/pgbackrest` | Backup-утилита PostgreSQL |
| `app-crypt/lego` | ACME-клиент (Let's Encrypt) |
| `dev-db/postgresql` | PostgreSQL 18 с патчем совместимости 1С (`USE=1c`) и LTO |
| `dev-db/timescaledb` | TimescaleDB (пин ниже 2.29 — совместимость с 1С) |
| `dev-php/php-spx` | SPX-профилировщик для PHP 8.3–8.5 |
| `dev-util/kubler` | Kubler — сборка минимальных контейнерных образов |
| `net-libs/nodejs` | Node.js 24 LTS |
| `net-misc/aspia-relay`, `net-misc/aspia-router` | Серверные компоненты Aspia (remote desktop) |
| `sys-cluster/nomad`, `nomad-driver-podman`, `consul`, `vault` | HashiCorp-стек |
| `sys-fs/seaweedfs` | Распределённое файловое хранилище |
| `www-servers/freeunit` | FreeUnit (форк nginx-unit) |
| `www-servers/nginx-unit` | nginx-unit |
| `acct-user/*`, `acct-group/*` | Фиксированные uid/gid сервисных учёток (1С, Aspia) |

## Локальные профили

- `local:pgr-min` — минимальный glibc-профиль (без pam);
- `local:pgr-min-musl` — то же на musl.

Служебные `package.mask` (пины версий) и `use.local.desc` (описание локальных
USE-флагов) — в `profiles/`.

## License

Ebuild'ы — GPL-2 (`LICENSE`); лицензии самих пакетов — по их ebuild'ам
(например, `licenses/BUSL-1.1` для TimescaleDB).
