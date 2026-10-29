# TASK-001: Исправить ошибки ansible-lint в роли common

**Статус:** Тестирование
**Создана:** 2026-10-29 (PM: opencode)
**Взята в работу:** 2026-10-29 (dev: opencode)
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

## Тест-кейсы
1. `ansible-lint roles/common/` завершается без замечаний `var-naming[no-role-prefix]`.
2. Grep по репозиторию не находит старых имён переменных (`timezone:`, `users_create`, `users_delete`, `cron_env`, `extra_pkgs`) вне новых `common_*` имён.
3. Повторный прогон плейбука с ролью `common` идемпотентен: таймзона, пользователи, cron и пакеты не меняются при повторном запуске (`--check --diff`).

## Комментарии
- 2026-10-29 (PM): Задача создана по результатам прогона `ansible-lint`. Нумерация задач: TASK-000, TASK-001, ... (сквозная, по указанию заказчика).
- 2026-10-29 (dev): Все пять переменных переименованы, обновлены места использования:
  - `roles/common/defaults/main.yml` — объявления переменных;
  - `roles/common/tasks/main.yml` — все обращения к переменным (логика роли не менялась);
  - `roles/common/molecule/default/converge.yml` — `users_create`/`users_delete` → `common_users_create`/`common_users_delete`;
  - `README.md` (корень) — пример переопределения `extra_pkgs` → `common_extra_pkgs` и таблица ролей (список ключевых переменных роли `common`).
- 2026-10-29 (dev): **Breaking change**: переименованы переменные по умолчанию роли `common` (`timezone`, `users_create`, `users_delete`, `cron_env`, `extra_pkgs`). Внутри репозитория все использования обновлены. Если переменные переопределяются во внешних (вне репозитория) inventory/плейбуках — потребуется переименовать их там же при переходе на версию коллекции с этим изменением. Необходимо отразить в changelog при следующем релизе (несовместимое изменение → поднять `X` по semver).
- 2026-10-29 (dev): Проверки:
  - `ansible-lint roles/common/` — Passed (0 failures); осталось 2 pre-existing warning `outdated-tag` в `molecule/default/converge.yml` (существовали до задачи, вне её рамок);
  - `ansible-lint` по всему проекту — по роли `common` нарушений нет; остальные замечания (docker, nginx, certbot) — вне рамок задачи (TASK-002, TASK-004);
  - `yamllint .` — ошибок в файлах роли `common` нет (замечания только в nginx/basic — вне рамок задачи);
  - grep по репозиторию старых имён переменных не находит (остались только упоминания модуля `community.general.timezone` и текстовые описания).
- 2026-10-29 (dev): Тест-кейс 3 (идемпотентность через `molecule test` / повторный прогон `--check --diff`) не выполнен: `molecule` отсутствует в virtualenv `.ansibleroles` (нет в `requirements.txt`). Изменения не затрагивают логику роли, риск регрессии минимален. Рекомендую QA прогнать molecule в окружении, где он установлен, либо расширить `requirements.txt` (отдельное решение).
