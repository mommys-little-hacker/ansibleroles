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
├── ansible.cfg               # Конфиг по умолчанию (roles_path и т.д.)
├── requirements.yml          # Внешние зависимости из Galaxy (community-коллекции)
├── .ansibleroles/            # Виртуальное окружение с Ansible (не в git)
├── .yamllint                 # Правила yamllint
├── .config/
│   └── ansible-lint.yml      # Правила ansible-lint
├── scripts/
│   └── lint.sh               # Локальный прогон линтеров (yamllint + ansible-lint)
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

> **Важно:** репозиторий закрытый. Любое подключение ролей требует доступа
> к приватному репозиторию ansibleroles на git-сервере проекта:

- для людей — SSH-ключ, добавленный в аккаунт на git-сервере, и права на чтение репозитория;
- для CI/CD и серверов — **deploy key** (read-only SSH-ключ) или read-only токен доступа (названия и настройка зависят от вашей git-платформы).

Репозиторий не привязан к конкретной git-платформе. В примерах ниже
используется плейсхолдер `git@<git-сервер>:<группа>/ansibleroles.git` —
подставьте фактический SSH-URL (узнать: `git remote get-url origin`).

`ansible-galaxy` не умеет устанавливать отдельную роль из подкаталога
git-репозитория, поэтому роли подключаются **всего репозитория целиком** одним
из способов ниже. Все варианты требуют настроенного SSH-доступа:

```bash
ssh -T git@<git-сервер>   # успешная аутентификация подтверждается сообщением сервера
```

### Вариант 1 — git submodule (рекомендуется)

Позволяет зафиксировать конкретную версию репозитория ролей и обновлять её
осознанно.

```bash
cd <ваш-репозиторий-с-плейбуками>

# Подключить (по умолчанию — ветка main)
git submodule add git@<git-сервер>:<группа>/ansibleroles.git vendor/ansibleroles

# Зафиксировать конкретную версию (тег)
cd vendor/ansibleroles
git checkout v1.2.0
cd -
git add vendor/ansibleroles
git commit -m "Add ansibleroles v1.2.0"
```

Обновление до новой версии:

```bash
git submodule update --remote vendor/ansibleroles
cd vendor/ansibleroles && git checkout vX.Y.Z && cd -
git add vendor/ansibleroles && git commit -m "Bump ansibleroles to vX.Y.Z"
```

Клонирование вашего репозитория вместе с ролями:

```bash
git clone --recurse-submodules git@<git-сервер>:<группа>/<репозиторий-плейбуков>.git
# или, если уже склонировано:
git submodule update --init --recursive
```

### Вариант 2 — обычный clone

Подходит для быстрых экспериментов и рабочих станций, где не нужен
контроль версий на стороне потребителя:

```bash
mkdir -p vendor
git clone git@<git-сервер>:<группа>/ansibleroles.git vendor/ansibleroles
```

### Подключение ролей к плейбукам

В `ansible.cfg` вашего репозитория добавьте каталог с ролями в `roles_path`
(первым указывается локальный `roles/`, потом роли этого репозитория):

```ini
[defaults]
roles_path = roles:vendor/ansibleroles/roles
```

После этого роли доступны в плейбуках просто по имени каталога:

```yaml
---
- name: Настройка сервера
  hosts: all
  become: true
  roles:
    - common            # роль из vendor/ansibleroles/roles/common
```

Пример переопределения переменных роли:

```yaml
---
- name: Настройка сервера
  hosts: all
  become: true
  roles:
    - role: common
      vars:
        common_packages:
          - curl
          - vim
```

Запуск:

```bash
ansible-playbook -i inventory/production playbooks/site.yml
```

### CI в вашем репозитории

Проект не привязан к конкретной CI-системе; любая из них должна уметь
забирать приватный репозиторий ролей:

1. Создайте в репозитории ansibleroles deploy key (read-only) или заведите
   read-only токен — в зависимости от возможностей вашей git-платформы.
2. Передайте ключ/токен в CI через его механизм секретов.
3. Перед запуском плейбуков в пайплайне инициализируйте субмодули:

```bash
git submodule update --init --recursive
```

Итого CI нужен только SSH-доступ с правом **чтения** к репозиторию
ansibleroles; права записи не требуются.

### Версионирование

- Ветка `main` — основная, всегда работоспособная.
- Стабильные версии фиксируются тегами вида `vX.Y.Z` (семантическое версионирование):
  - `X` — несовместимые изменения (переименование переменных, смена поведения по умолчанию);
  - `Y` — новая функциональность, обратно совместимая;
  - `Z` — исправления багов.
- В production подключайте роли по тегам, а не по `main`.

### Список ролей

| Роль | Назначение | Ключевые переменные |
|------|------------|---------------------|
| `common` | Базовая настройка серверов (пакеты, часовой пояс) | `common_packages`, `common_timezone` |

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
7. После мержа при необходимости выпустите тег `vX.Y.Z`:

```bash
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
