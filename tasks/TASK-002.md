# TASK-002: Исправить ошибки ansible-lint в роли nginx и мета-данных коллекции

**Статус:** Готово
**Создана:** 2026-10-29 (PM: opencode)
**Взята в работу:** 2026-10-29 (developer)
**Завершена:** -

## Описание
Устранить замечания `ansible-lint` в роли `nginx` (no-changed-when, risky-file-permissions, yaml truthy) и в мета-данных коллекции (`galaxy.yml`: отсутствие changelog и meta/runtime.yml, недопустимое значение license).

## ТЗ/Требования

### Роль nginx
- `no-changed-when` (`roles/nginx/handlers/main.yml:6`, «Reload nginx»): задача на `shell` (`nginx -t && nginx -s reload`) без `changed_when`. Handler по определению выполняется при изменениях — добавить `changed_when: true` (или зарегистрировать результат и указать явное условие), не меняя логики: сначала проверка конфига `nginx -t`, затем reload.
- `no-changed-when` (`roles/nginx/tasks/install.yml:7`, «Dearmor key»): `shell` без `changed_when`. Варианты решения (согласовать): добавить `changed_when: true`, либо перевести на идемпотентную схему — скачивать/дермарморить во временный файл и копировать через `ansible.builtin.copy` с `notify` на обновление ключа; предпочтителен идемпотентный вариант.
- `risky-file-permissions` (`roles/nginx/tasks/install.yml:2`, «Add nginx repo key»): `get_url` без `mode` — добавить `mode: "0644"` (файл во временном каталоге, но правило требует явных прав).
- `yaml[truthy]` (`roles/nginx/tasks/main.yml:10`): `enabled: yes` → `enabled: true`.

### Мета коллекции (galaxy.yml)
- `galaxy[no-changelog]`: создать changelog-файл. Рекомендуется `CHANGELOG.md` в корне с секциями по существующим тегам релизов (vX.Y.Z, см. `galaxy.yml` version и историю git-тегов); формат — на усмотрение владельца (changelog dry-run из antsibull-changelog либо простой markdown).
- `galaxy[no-runtime]`: создать `meta/runtime.yml`. Минимальное содержимое — `requires_ansible: ">=2.12.0"` (согласовать минимальную версию с фактически используемой; учесть `min_ansible_version` в `roles/*/meta/main.yml`). Дополнительные секции (action_groups, plugin routing) не нужны — коллекция содержит только роли.
- `schema[galaxy]`: `license: EULA` не входит в список SPDX. **Решение владельца (2026-10-29): лицензия не имеет смысла — коллекция закрытая, для частного использования.** Убрать поле `license` (и список `license:` в `galaxy.yml`) полностью; убедиться, что схема и `ansible-lint` перестают выдавать `schema[galaxy]`. Если схема/линтер потребуют обязательного значения — вернуться к владельцу за решением, самостоятельно плейсхолдер не выбирать.
- Структуру репозитория и механизм установки коллекции не менять (см. AGENTS.md).

## Тест-кейсы
1. `ansible-lint` по всему проекту не возвращает замечаний по роли `nginx` и по `galaxy.yml` (правила galaxy, schema[galaxy]).
2. Handler «Reload nginx» по коду корректен: `changed_when: true` присутствует, внутри handler'а сначала выполняется проверка конфига (`nginx -t`), затем reload; notify ссылается на существующий handler.
3. Идемпотентность по коду задач: «Dearmor key» либо переведена на идемпотентную схему (временный файл + `ansible.builtin.copy` с `notify`), либо имеет корректное `changed_when`; ключ репозитория и репозиторий не «переобновляются» при повторном применении роли (статический анализ логики).
4. `ansible-galaxy collection build` проходит без предупреждений о changelog/runtime (можно проверить локально в каталоге сборки).
5. Содержимое `meta/runtime.yml` валидно: `ansible-galaxy collection build`/`install` не выдаёт ошибок схемы.

## Комментарии
- 2026-10-31 (QA: GLM-5.3-Flash): Тестирование пройдено. Все тест-кейсы выполнены: `ansible-lint`/`yamllint` по проекту — 0 failures, 0 warnings (профиль production); handler «Reload nginx» — `nginx -t && nginx -s reload` + `changed_when: true`; схема «Dearmor key» идемпотентна (get_url → dearmor `changed_when: false` → copy в `/etc/apt/keyrings`); `galaxy.yml` без `license`, `meta/runtime.yml` валиден, `CHANGELOG.md` присутствует; `ansible-galaxy collection build` — успешно (`qwertys-roles-1.0.0.tar.gz`); устаревший `# noqa 301 305` в `roles/nginx/tasks/configure.yml` заменён на `command: nginx -qt` + `changed_when: false`. Статус → Готово.
- 2026-10-29 (PM): Задача создана по результатам прогона `ansible-lint`.
- 2026-10-29 (PM): Решения владельца: (1) поле `license` в galaxy.yml — удалить (коллекция закрытая, лицензия не имеет смысла); (2) минимальную версию Ansible для `meta/runtime.yml` взять из фактически поддерживаемых ролей (`min_ansible_version` в `roles/*/meta/main.yml`), согласовать с владельцем, если значения расходятся; (3) формат changelog — простой markdown-файл CHANGELOG.md на усмотрение исполнителя.
- 2026-10-29 (PM): Тест-кейсы 2–3 переписаны на статические проверки: репозиторий — чистая коллекция ролей без плейбуков, запускать плейбуки/роли (включая `--check --diff`) запрещено (см. `AGENT_CONTEXT.md`). Поведение handler'а и идемпотентность проверяются анализом кода, а не прогоном.
- 2026-10-29 (developer): Задача взята в работу, изменения внесены:
  - nginx: handler «Reload nginx» — `changed_when: true`; «Dearmor key» переведена на идемпотентную схему (дермарморинг во временный файл с `changed_when: false` + гарантия каталога `/etc/apt/keyrings` + `ansible.builtin.copy` 0644 без notify — по решению владельца, apt читает keyring с диска при каждой операции); `get_url` получил `mode: "0644"`; `enabled: yes` → `enabled: true`.
  - galaxy.yml: поле `license` удалено (решение владельца).
  - Создан `meta/runtime.yml` с `requires_ansible: ">=2.15.0"`.
  - Создан `CHANGELOG.md` (простой markdown, секции по тегам 0.1.0–0.1.2).
  - `.config/ansible-lint.yml`: в `skip_list` добавлен `galaxy[no-license]` (с явного согласия владельца — после удаления license ansible-lint требует лицензию, для закрытой коллекции она подавлена).
- 2026-10-29 (developer): Решения владельца в ходе работы: (1) `requires_ansible` поднят до `>=2.15.0` вместо изначальной идеи `>=2.12.0` — ansible-lint (meta-runtime[unsupported-version]) принимает только >=2.15.0…>=2.19.0; (2) подавление `galaxy[no-license]` вместо указания SPDX-лицензии.
- 2026-10-29 (developer): Проверки: `ansible-lint` по `roles/nginx` + `galaxy.yml` + `meta` — 0 провалов (профиль production, 5/5); `ansible-galaxy collection build`/`install` — без ошибок схемы и предупреждений о changelog/runtime; `yamllint` по изменённым файлам — чисто. Прогон по всему проекту оставшиеся нарушения не даёт по рамкам задачи: они в `certbot` (TASK-003), `docker` (TASK-004, включая molecule-сценарии) и molecule (устаревшие noqa-теги, `roles/nginx/tasks/configure.yml:61` — вне рамок TASK-002, вынесено на усмотрение PM).
- 2026-10-31 (developer): Доработка по результатам тестирования — устранены 2 оставшихся warning `warning[outdated-tag]` (устаревшие noqa-теги `301`/`305`):
  - `roles/nginx/tasks/configure.yml` («Validate configuration», `nginx -qt`): вместо обновления noqa-тегов причины устранены по существу — `ansible.builtin.shell` → `ansible.builtin.command` (шелловых конструкций в команде нет) + `changed_when: false` (задача только валидирует конфиг, состояние не меняет); noqa-комментарий удалён.
  - `roles/common/molecule/default/converge.yml:27` («Edit hostname», `hostnamectl set-hostname`): аналогично — `shell` → `command` + `changed_when: true`; noqa-комментарий удалён. Шаг оставлен (не удалялся) — он задаёт ожидаемое имя хоста инстансу перед прогоном роли `common` в molecule-сценарии.
  - Важно: molecule-файл правился только статически, molecule-тесты не запускались (ограничение `AGENT_CONTEXT.md`); поведение сценария не менялось (замена `shell`→`command` для команды без шелл-конструкций эквивалентна).
- 2026-10-31 (developer): Проверки: `ansible-lint` по всему проекту — 0 провалов, 0 warnings (профиль production, 5/5); `yamllint` по изменённым файлам — чисто.
