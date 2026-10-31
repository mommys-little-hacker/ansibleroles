# TASK-004: Исправить ошибки ansible-lint в роли docker

**Статус:** Готово
**Создана:** 2026-10-29 (PM: opencode)
**Взята в работу:** 2026-10-30 (dev: GLM-5.3-Flash)
**Завершена:** 2026-10-31 (QA)

## Описание
Устранить замечания `ansible-lint` в роли `docker`: права на файлы/каталоги, сравнение с литералом, схема meta, FQCN и `truthy`/`syntax-check` в molecule-сценариях.

## ТЗ/Требования
- `risky-file-permissions` (`roles/docker/tasks/configure.yml`):
  - «Create docker storage directory» (`/storage`) — добавить явные `owner`, `group`, `mode` (для каталога docker-хранилища разумно `root:root`, `mode: "0711"` или `"0755"` — уточнить у владельца репозитория, если неочевидно).
  - «Create docker configuration directory» (`/etc/docker`) — `owner: root`, `group: root`, `mode: "0755"`.
  - «Copy Docker daemon config» (`/etc/docker/daemon.json`) — `owner: root`, `group: root`, `mode: "0644"`.
- `literal-compare` (`roles/docker/tasks/install.yml:22`): заменить `when: docker_pip.force == False` на `when: not docker_pip.force`.
- `schema[meta]` (`roles/docker/meta/main.yml:6`): `min_ansible_version: 2.8` указать строкой: `min_ansible_version: "2.8"`.
- `fqcn[action-core]` (`roles/docker/molecule/bionic/prepare.yml:7`): `raw` → `ansible.builtin.raw`.
- `yaml[truthy]` (`roles/docker/molecule/default/molecule.yml:8,25`): заменить `yes/no` на `true/false`. Для `bionic`/`xenial` исправления не требуются — сценарии удаляются целиком (см. пункт про `syntax-check`).
- `syntax-check[specific]` (`roles/docker/molecule/bionic/playbook.yml:5`): роль `ansible_docker` не найдена. **Решение владельца (2026-10-29): устаревшие molecule-сценарии удалить** — удалить каталоги `roles/docker/molecule/bionic/` и `roles/docker/molecule/xenial/` (Ubuntu 18.04/16.04 EOL, целевая платформа — Debian 13). Сценарий `default` сохранить и актуализировать (`yaml[truthy]` в `molecule/default/molecule.yml`). Заодно это снимет замечания `truthy` и `fqcn` в `bionic/prepare.yml` — их отдельно исправлять не нужно.
- Логику роли не менять; идемпотентность сохранить.
- **Molecule-тесты не запускать** (`molecule test` запрещён — сценарии пока не готовы, см. `AGENT_CONTEXT.md`); правки файлов molecule-сценариев выполняются только ради прохождения `ansible-lint`.

## Тест-кейсы
1. `ansible-lint roles/docker/` завершается без ошибок и предупреждений.
2. Идемпотентность по коду задач: права на `/storage`, `/etc/docker`, `daemon.json` заданы явно (`owner`/`group`/`mode`) через модули `ansible.builtin.file`/`ansible.builtin.copy`/`template` — при повторном применении задачи не дают `changed` (статический анализ логики).
3. При `docker_pip.force: false` ставится `python3-docker` из apt, при `true` — pip-пакет (поведение не изменилось; проверка по коду `roles/docker/tasks/install.yml`).

## Комментарии
- 2026-10-29 (PM): Задача создана по результатам прогона `ansible-lint`.
- 2026-10-29 (PM): Владелец принял решение — устаревшие molecule-сценарии `bionic` и `xenial` удалить.
- 2026-10-29 (PM): Тест-кейс про `molecule test` удалён: molecule-сценарии в репозитории пока не готовы, запускать molecule запрещено (см. `AGENT_CONTEXT.md`). Требование удалить `bionic`/`xenial` и актуализировать `molecule/default/molecule.yml` остаётся — эти правки нужны для прохождения `ansible-lint`.
- 2026-10-29 (PM): Тест-кейс 2 переписан на статическую проверку: репозиторий — чистая коллекция ролей без плейбуков, запускать плейбуки/роли (включая `--check --diff`) запрещено (см. `AGENT_CONTEXT.md`). Идемпотентность проверяется анализом кода задач.
- 2026-10-30 (dev: GLM-5.3-Flash): Все правки из ТЗ выполнены: права (`owner`/`group`/`mode`) добавлены для `/storage` (`0755`), `/etc/docker` (`0755`), `daemon.json` (`0644`); `literal-compare` заменён на `when: not docker_pip.force`; `min_ansible_version` указан строкой `"2.8"`; molecule-сценарии `bionic` и `xenial` удалены; в `molecule/default/molecule.yml` `yes/no` заменены на `true/false`.
- 2026-10-30 (dev: GLM-5.3-Flash): Линтер дополнительно обнаружил `var-naming[no-role-prefix]` — словарь `docker` без префикса. По согласованию с владельцем переименован в `docker_apt` (обновлены `defaults/main.yml`, `tasks/install.yml`, таблица переменных в `README.md`). Интерфейс роли изменился — потребителям роли потребуется обновить переменные.
- 2026-10-30 (dev: GLM-5.3-Flash): `ansible-lint roles/docker/` и `yamllint roles/docker/` проходят без ошибок и предупреждений (профиль production). `molecule test` не запускался (запрещён). Тест-кейсы 1–3 выполнены (2 и 3 — статическим анализом кода).
- 2026-10-31 (QA: GLM-5.3-Flash): Тестирование пройдено. Все тест-кейсы выполнены: `ansible-lint`/`yamllint` по проекту — 0 failures, 0 warnings (профиль production); права `/storage` и `/etc/docker` — `0755`, `daemon.json` — `0644`, root:root; `when: not docker_pip.force` / `when: docker_pip.force` корректно разветвляют apt/pip; `min_ansible_version: "2.8"` в кавычках; molecule-сценарии `bionic`/`xenial` удалены; `true/false` в molecule.yml; переименование `docker_apt` чистое (включая таблицу в README). Статус → Готово. Не забыть: breaking change переменной `docker` → `docker_apt` — отразить в changelog при следующем релизе.
