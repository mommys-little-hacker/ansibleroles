# TASK-000: Исправить ошибки ansible-lint в роли basic

**Статус:** Тестирование
**Создана:** 2026-10-29 (PM: opencode)
**Взята в работу:** 2026-10-29 (developer)
**Завершена:** -

## Описание
Устранить замечания `ansible-lint` в роли `basic`: префиксы переменных и замечание `no-handler`. Проверено grep'ом: переименовываемые переменные используются только внутри роли, ломающего влияния на другие роли нет.

## ТЗ/Требования
- `var-naming[no-role-prefix]`: переменную `environment_name` в `roles/basic/defaults/main.yml` переименовать в `basic_environment_name` (обновить её использование в `basic_git_ssh_src`, строка 5).
- `var-naming[no-role-prefix]`: register `certlist` в `roles/basic/tasks/main.yml` (строка 15) переименовать в `basic_certlist` (обновить `when: certlist.changed`, строка 21).
- `no-handler`: задача «Update CA certificates» (`roles/basic/tasks/main.yml`, строки 18–21) помечена линтером как кандидат в handlers. Переводить её в handler **нельзя** — есть осознанное решение (см. комментарий в коде): CA-сертификаты должны обновляться сразу, иначе последующие обновления apt-кеша могут сломаться. Вместо этого подавить правило локально, например добавить в строку задачи `# noqa no-handler` (рядом с существующим `# noqa command-instead-of-shell no-changed-when`) — проверить, что линтер перестаёт ругаться; при необходимости оформить `# noqa` в валидном формате.
- Не изменять логику роли: идемпотентность, теги, блок git-key — без изменений.

## Тест-кейсы
1. `ansible-lint roles/basic/` завершается без ошибок и предупреждений по правилам `var-naming[no-role-prefix]` и `no-handler`.
2. Повторный запуск плейбука с ролью `basic` идемпотентен: при `--check --diff` на уже настроенном хосте нет неожиданных изменений.
3. При изменении `/etc/ca-certificates.conf` задача «Update CA certificates» выполняется (проверить по `basic_certlist.changed`).
4. При `basic_git_ssh_enabled: true` ключ копируется в `/root/.ssh/git/id_ecdsa`, путь строится от `basic_environment_name`.

## Комментарии
- 2026-10-29 (PM): Задача создана по результатам прогона `ansible-lint` (57 ошибок по проекту). Задача scope'ится только на роль `basic`. Связанные задачи: TASK-002 (common), TASK-004 (docker), TASK-006 (certbot), TASK-008 (nginx + мета коллекции).
- 2026-10-29 (developer): Реализовано. `environment_name` → `basic_environment_name` (defaults + использование в `basic_git_ssh_src`), `certlist` → `basic_certlist` (register + `when`), к задаче «Update CA certificates» добавлен `no-handler` в строку `# noqa`. Логика роли не менялась. Проверки: `ansible-lint roles/basic/` — Passed (0 failures, 0 warnings, профиль `production`); `yamllint roles/basic/` — чисто; `ansible-lint` по всему проекту — 49 failures, все по другим ролям (docker, nginx, certbot), по `basic` замечаний нет.
