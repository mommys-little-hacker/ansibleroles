# TASK-001: Исправить ошибки ansible-lint в роли common

**Статус:** Новая
**Создана:** 2026-10-29 (PM: opencode)
**Взята в работу:** -
**Завершена:** -

## Описание
Устранить замечания `var-naming[no-role-prefix]` в роли `common`: пять переменных в `roles/common/defaults/main.yml` не имеют префикса роли.

## ТЗ/Требования
- Переименовать переменные в `roles/common/defaults/main.yml`:
  - `timezone` → `common_timezone`
  - `users_create` → `common_users_create`
  - `users_delete` → `common_users_delete`
  - `cron_env` → `common_cron_env`
  - `extra_pkgs` → `common_extra_pkgs`
- Перед переименованием выполнить grep по репозиторию (включая inventory, molecule, плейбуки) — обновить все места использования каждой переменной. Если переменная используется во внешних inventory/плейбуках вне репозитория — отразить это в комментариях задачи как breaking change для пользователей роли.
- Не изменять логику роли.
- Прогнать `./scripts/lint.sh` — по роли `common` замечаний быть не должно.

## Тест-кейсы
1. `ansible-lint roles/common/` завершается без замечаний `var-naming[no-role-prefix]`.
2. Grep по репозиторию не находит старых имён переменных (`timezone:`, `users_create`, `users_delete`, `cron_env`, `extra_pkgs`) вне новых `common_*` имён.
3. Повторный прогон плейбука с ролью `common` идемпотентен: таймзона, пользователи, cron и пакеты не меняются при повторном запуске (`--check --diff`).
4. `./scripts/lint.sh` не возвращает новых замечаний по сравнению с базовой линией.

## Комментарии
- 2026-10-29 (PM): Задача создана по результатам прогона `ansible-lint`. Нумерация задач: TASK-000, TASK-001, ... (сквозная, по указанию заказчика).
