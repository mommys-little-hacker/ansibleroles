# ansibleroles

Закрытый (приватный) репозиторий с коллекцией Ansible-ролей для инфраструктуры
`qwertys.ru`. Доступ к репозиторию и к ролям есть только у участников проекта.

- **Для пользователей ролей** — раздел [«Подключение ролей»](#подключение-ролей-для-пользователей).
- **Для разработчиков** — раздел [«Разработчикам»](#разработчикам).
- **Для ИИ-агентов** — см. [AGENTS.md](AGENTS.md).

---

## Структура репозитория

```
ansibleroles/
├── README.md                 # Этот файл
├── AGENTS.md                 # Инструкции для ИИ-агентов
├── galaxy.yml                # Метаданные Ansible-коллекции (qwertys.roles)
├── ansible.cfg               # Конфиг по умолчанию (roles_path и т.д.)
├── requirements.yml          # Внешние зависимости из Galaxy (community-коллекции)
├── .ansibleroles/            # Виртуальное окружение с Ansible (не в git)
├── .yamllint                 # Правила yamllint
├── .config/
│   └── ansible-lint.yml      # Правила ansible-lint
├── roles/                    # Роли проекта (имя каталога = имя роли)
│   ├── README.md
│   └── common/               # Пример роли
│       ├── README.md
│       ├── defaults/         # Переменные по умолчанию (перезаписываются извне)
│       │   └── main.yml
│       ├── files/            # Статические файлы для copy
│       ├── handlers/         # Обработчики (restart и т.п.)
│       │   └── main.yml
│       ├── meta/             # Метаданные роли, зависимости
│       │   └── main.yml
│       ├── tasks/            # Основная логика
│       │   └── main.yml
│       ├── templates/        # Jinja2-шаблоны
│       ├── vars/             # Внутренние переменные (не перезаписываются извне)
│       └── molecule/         # Тесты Molecule (опционально, добавляется по мере надобности)
├── playbooks/
│   └── example.yml           # Пример плейбука
└── docs/
    └── new-role-checklist.md # Чек-лист создания новой роли
```

## Требования

- Python >= 3.10 (инструменты Ansible живут в виртуальном окружении `.ansibleroles/`)
- `ansible-lint`, `yamllint` — обязательны для любого MR
- `molecule` + драйвер (например, `molecule-plugins[podman]`) — опционально, для тестов ролей

Инструменты ставятся в виртуальное окружение `.ansibleroles/` (в корне
репозитория, не коммитится — см. `.gitignore`):

```bash
python3 -m venv .ansibleroles
source .ansibleroles/bin/activate
pip install --upgrade pip
pip install ansible ansible-lint yamllint
```

Активация нужна в каждой новой shell-сессии (`source .ansibleroles/bin/activate`);
после неё доступны `ansible-playbook`, `ansible-lint`, `yamllint`, `molecule`.
Без активации используйте полные пути: `.ansibleroles/bin/ansible-lint`.

---

## Подключение ролей (для пользователей)

Репозиторий оформлен как **Ansible-коллекция** `qwertys.roles` и подключается
к проектам через `ansible-galaxy collection install` прямо из приватного
git-репозитория — без копирования файлов или git-submodule.

> **Важно:** репозиторий закрытый. Установка требует доступа к приватному
> репозиторию ansibleroles на git-сервере проекта:

- для людей — SSH-ключ, добавленный в аккаунт на git-сервере, и права на чтение репозитория;
- для CI/CD и серверов — **deploy key** (read-only SSH-ключ) или read-only токен доступа (названия и настройка зависят от вашей git-платформы).

Репозиторий не привязан к конкретной git-платформе. В примерах ниже
используется плейсхолдер `git@<git-сервер>:<группа>/ansibleroles.git` —
подставьте фактический SSH-URL (узнать: `git remote get-url origin`).

### Установка коллекции

```bash
ssh -T git@<git-сервер>   # проверка аутентификации

# Установка последней версии из ветки main
ansible-galaxy collection install git@<git-сервер>:<группа>/ansibleroles.git

# Установка конкретной версии (тег) — рекомендуется для production
ansible-galaxy collection install 'git+ssh://git@<git-сервер>/<группа>/ansibleroles.git,v1.0.0'

# Обновление до новой версии
ansible-galaxy collection install --upgrade git@<git-сервер>:<группа>/ansibleroles.git
```

По умолчанию коллекция ставится в `~/.ansible/collections/` (путь можно
переопределить через `--collections-path` или `collections_path` в
`ansible.cfg`). Все роли репозитория ставятся одной командой; роли
`community.general` и `ansible.posix`, используемые ролями, ставятся
автоматически (объявлены в `galaxy.yml`).

### Подключение к плейбукам

После установки роли доступны в плейбуках по полному имени
`qwertys.roles.<роль>`:

```yaml
---
- name: Настройка сервера
  hosts: all
  become: true
  roles:
    - qwertys.roles.basic      # выполняется первой, зависимости подтянутся сами
    - qwertys.roles.common
    - qwertys.roles.nginx
```

Пример переопределения переменных роли:

```yaml
---
- name: Настройка сервера
  hosts: all
  become: true
  roles:
    - role: qwertys.roles.common
      vars:
        common_extra_pkgs:
          - curl
          - vim
```

Внутри коллекции роли уже объявляют зависимость от роли `basic` в
`meta/main.yml`, поэтому отдельно перечислять её необязательно — она
выполнится автоматически перед зависящей от неё ролью.

Запуск:

```bash
ansible-playbook -i inventory/production playbooks/site.yml
```

### Установка из requirements.yml

Чтобы зафиксировать версии коллекций проекта в одном файле, добавьте
коллекцию в `requirements.yml` вашего репозитория:

```yaml
---
collections:
  # Роли qwertys.ru (приватный git-репозиторий)
  - name: git@<git-сервер>:<группа>/ansibleroles.git
    type: git
    version: v1.0.0
  # Роль common использует эти коллекции (ставятся и из galaxy.yml автоматически)
  - name: community.general
  - name: ansible.posix
```

```bash
ansible-galaxy collection install -r requirements.yml
```

### CI в вашем репозитории

Проект не привязан к конкретной CI-системе; любая из них должна уметь
забирать приватный репозиторий ролей:

1. Создайте в репозитории ansibleroles deploy key (read-only) или заведите
   read-only токен — в зависимости от возможностей вашей git-платформы.
2. Передайте ключ/токен в CI через его механизм секретов.
3. Перед запуском плейбуков в пайплайне установите коллекцию:

```bash
ansible-galaxy collection install 'git+ssh://git@<git-сервер>/<группа>/ansibleroles.git,vX.Y.Z'
```

Итого CI нужен только SSH-доступ с правом **чтения** к репозиторию
ansibleroles; права записи не требуются.

### Версионирование

- Ветка `main` — основная, всегда работоспособная.
- Стабильные версии фиксируются тегами вида `vX.Y.Z` (семантическое версионирование):
  - `X` — несовместимые изменения (переименование переменных, смена поведения по умолчанию);
  - `Y` — новая функциональность, обратно совместимая;
  - `Z` — исправления багов.
- При выпуске тега синхронно поднимается `version` в `galaxy.yml`.
- В production подключайте роли по тегам, а не по `main`.

### Список ролей

Все роли ставятся в составе коллекции `qwertys.roles` и зависят от роли
`basic` (базовые пакеты и настройки).

| Роль | Назначение | Ключевые переменные |
|------|------------|---------------------|
| `basic` | Базовые пакеты и настройки, общие для всех остальных ролей | `basic_packages`, `basic_git_ssh_enabled`, `basic_git_ssh_src` |
| `common` | Базовая настройка серверов (часовой пояс, пользователи, cron, sysctl) | `common_pkgs`, `common_extra_pkgs`, `common_timezone`, `common_users_create`, `common_users_delete`, `common_cron_env` |
| `docker` | Установка и настройка Docker CE | `docker_apt.repo_line`, `docker_apt.repo_key`, `docker_apt.package`, `docker_apt.version`, `docker_pip` |
| `nginx` | Установка nginx с репозитория nginx.org | `nginx_repo_enable`, `nginx_packages`, `nginx_packages_extra`, `nginx_install` |
| `certbot` | Установка certbot и выпуск TLS-сертификатов Let's Encrypt | `certbot_version`, `certbot_email`, `certbot_webroot`, `certbot_route53`, `certbot_cloudflare` |

*При добавлении роли обязательно дополните таблицу.*

---

## Разработчикам

### Создание новой роли

1. Скопируйте скелет из существующей роли (или выполните `ansible-galaxy role init roles/<имя>`).
2. Имя роли: строчные буквы, цифры, подчёркивания (`nginx_site`, `backup_client`).
3. Соблюдайте правила из [AGENTS.md](AGENTS.md) и [docs/new-role-checklist.md](docs/new-role-checklist.md):
   - переменные роли в `defaults/` имеют префикс `<имя_роли>_`;
   - модули — с FQCN (`ansible.builtin.package`, а не `package`);
   - роль идемпотентна, не содержит секретов и внешних вызовов без переменных.
4. Проверьте локально (в активированном окружении `.ansibleroles`; см. [«Требования»](#требования)):

```bash
source .ansibleroles/bin/activate
./scripts/lint.sh        # или раздельно: yamllint . && ansible-lint
```

5. Опционально добавьте Molecule-сценарий: `molecule init scenario` внутри роли.
6. Откройте merge/pull request в `main`. Линтеры (`./scripts/lint.sh`) и CI, если настроен на git-платформе, должны пройти.
7. После мержа при необходимости выпустите тег `vX.Y.Z`, синхронно подняв
   `version` в корневом `galaxy.yml`:

```bash
# version: 1.1.0 в galaxy.yml
git tag -a v1.1.0 -m "New role: backup_client"
git push origin v1.1.0
```

### Стиль кода

- YAML: отступ 2 пробела, документ начинается с `---`, строки до 120 символов (см. `.yamllint`).
- Комментарии в коде — на русском или английском, единообразно внутри одной роли.
- Секреты — только через `ansible-vault` (vault-password хранится **вне** репозитория, например `~/.config/qwertys/vault_pass`); в `ansible.cfg` можно раскомментировать `vault_password_file`.
- Внешние коллекции (не `ansible.builtin`) добавляются в `requirements.yml`.

### Помощь

Вопросы по ролям и доступам — в рабочем чате проекта / issues приватного репозитория.
