# Changelog

Все заметные изменения коллекции `qwertys.roles` описываются в этом файле.
Формат основан на [Keep a Changelog](https://keepachangelog.com/), версии
соответствуют git-тегам `vX.Y.Z` (см. `galaxy.yml`).

## [Unreleased]

### Changed

- **Breaking changes** — потребители коллекции должны обновить переменные
  при переходе на эту версию:
  - Роль `common` (TASK-001): переименованы переменные без префикса роли —
    `timezone` → `common_timezone`, `users_create` → `common_users_create`,
    `users_delete` → `common_users_delete`, `cron_env` → `common_cron_env`,
    `extra_pkgs` → `common_extra_pkgs`.
  - Роль `docker` (TASK-004): словарь `docker` переименован в `docker_apt`
    (`repo_key`, `repo_line`, `package`, `version` внутри него — без
    изменений).
  - Роль `basic` (TASK-000): переменная `environment_name` переименована в
    `basic_environment_name`; register `certlist` в задачах — в
    `basic_certlist` (внутреннее имя, на потребителей не влияет).

Прочее:

- Роль `basic` (TASK-000): подавление правила `no-handler` для задачи
  «Update CA certificates» (`# noqa`); поведение роли не изменилось —
  сертификаты CA обновляются сразу после изменения `/etc/ca-certificates.conf`.
- Роль `nginx` (TASK-002): handler «Reload nginx» получил `changed_when: true`;
  установка ключа репозитория переведена на идемпотентную схему (dearmoring во
  временный файл с `changed_when: false` + копирование в
  `/etc/apt/keyrings`); задача валидации конфигурации переведена с `shell`
  на `command` (`nginx -qt`, `changed_when: false`).
- Роль `certbot` (TASK-003): pre/post hook в standalone-режиме вместо
  `ignore_errors: true` использует `failed_when: false` + `changed_when: false`
  (сбои hook'ов по-прежнему не прерывают выпуск сертификата); форматирование
  Jinja-выражений и перенос строк в cron-командах renew — итоговые команды не
  изменились.
- Роль `docker` (TASK-004): добавлены права доступа (`owner`/`group`/`mode`)
  для каталога `/storage`, `/etc/docker` и `daemon.json`; установка
  `python3-docker` разветвлена по `docker_pip.force` (apt по умолчанию, pip
  при `force: true`).

### Removed

- Роль `docker` (TASK-004): удалены molecule-сценарии для Ubuntu 16.04
  (`xenial`) и Debian 8 (`bionic`) — платформы не поддерживаются
  (поддерживаемые платформы см. `meta/main.yml` ролей).

### Added

- Мета коллекции (TASK-002): `meta/runtime.yml` (`requires_ansible: ">=2.15.0"`)
  и `CHANGELOG.md`; из `galaxy.yml` удалено поле `license` (закрытая коллекция,
  подавлено правило `galaxy[no-license]`).

## [0.1.2] - 2026-10-23

### Changed

- Роль `docker`: скрытие учётных данных в выводе задач (`no_log`).

## [0.1.1] - 2026-10-22

### Changed

- Роль `docker`: обновление конфигурации.

## [0.1.0] - 2026-10-22

### Added

- Первичный релиз коллекции: базовая структура, роли `basic`, `common`,
  `nginx`, `certbot`, `docker`.
