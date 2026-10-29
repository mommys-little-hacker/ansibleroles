---
name: Ansible Setup
description: Подготовка окружения для работы с Ansible - создание virtualenv, установка pip-зависимостей (requirements.txt), установка коллекций и ролей из galaxy (requirements.yml), проверка наличия бинарей локальных MCP-серверов из opencode.json
---

# Подготовка окружения Ansible

Используй этот скилл для первичной подготовки окружения и синхронизации
зависимостей: при первом развертывании репозитория, после изменения
`requirements.txt` / `requirements.yml`, а также при ошибках вида
"модуль не найден", "коллекция не найдена" или отсутствии virtualenv.

Скилл не запускает плейбуки и vault-операции - только готовит окружение.
Запуск плейбуков - см. скилл `ansible-run`, vault - см. скилл `ansible-vault`.

## Предусловия

- Рабочая директория - корень репозитория.
- Имена файлов зависимостей стандартные: `requirements.txt` (pip) и
  `requirements.yml` (ansible-galaxy) в корне репозитория.
- Конфигурация ansible (`ansible.cfg`) в корне репозитория определяет пути
  установки galaxy-зависимостей (например, `collections_path`), отдельно
  указывать `-p` не нужно.
- Файл конфигурации opencode `opencode.json` в корне репозитория используется
  для проверки бинарей локальных MCP-серверов.

## Порядок действий

### 1. Создать virtualenv (если отсутствует)

Виртуальное окружение - папка `.ansibleroles` в корне репозитория (имя папки
может отличаться в других проектах - используй принятое в проекте):

```sh
test -x .ansibleroles/bin/python && echo "venv ok" || python3 -m venv .ansibleroles
```

Если `python3` недоступен - остановиться и сообщить пользователю.

### 2. Синхронизировать pip-зависимости

Изменения определяются сравнением контрольных сумм файлов с маркером
`.ansibleroles/.deps.sha256`. Так отслеживаются и незакоммиченные правки, и
правки, пришедшие с коммитами.

Проверка:

```sh
sha256sum --check .ansibleroles/.deps.sha256 --status && echo "deps up to date" || echo "deps changed"
```

Если маркера нет или проверка не прошла:

```sh
source .ansibleroles/bin/activate
pip install -r requirements.txt
```

Если `requirements.txt` отсутствует - пропустить шаг.

### 3. Установить зависимости из galaxy

В том же сеансе (virtualenv активирован):

```sh
ansible-galaxy install -r requirements.yml
```

Замечания:
- Если `requirements.yml` отсутствует или пуст (содержит только `[]`) - шаг
  пропустить.
- `ansible-galaxy` ставит зависимости в пути из `ansible.cfg`
  (например, `collections_path = collections`), системная установка не нужна.

### 4. Обновить маркер зависимостей

Только после успешного выполнения шагов 2 и 3:

```sh
source .ansibleroles/bin/activate
sha256sum requirements.txt requirements.yml > .ansibleroles/.deps.sha256
```

- При ошибке установки любого из шагов маркер не обновлять, чтобы попытка
  повторилась при следующем запуске.
- Если какой-то из файлов отсутствует и пропущен - исключить его из маркера
  (например, указать только существующие файлы).
- Выяснять, какой именно файл изменился, не обязательно: допустимо выполнять
  оба шага установки.

### 5. Проверить бинари локальных MCP-серверов

Для каждого сервера с `type: local` из `opencode.json` проверить наличие
исполняемого файла из первого элемента `command`. Файл может содержать
комментарии и завершающие запятые (JSONC), поэтому парсить с fallback:

```sh
python3 - <<'EOF'
import json, shutil

def strip_jsonc(text):
    # Удаляет комментарии и завершающие запятые, не трогая содержимое строк.
    out = []
    i, n = 0, len(text)
    in_string = False
    while i < n:
        c = text[i]
        if in_string:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if c == '"':
                in_string = False
            i += 1
            continue
        if c == '"':
            in_string = True
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2
            continue
        out.append(c)
        i += 1
    # Убрать запятые непосредственно перед } или ]
    return json.loads(
        __import__("re").sub(r",\s*([}\]])", r"\1", "".join(out))
    )

text = open("opencode.json").read()
cfg = strip_jsonc(text)

for name, srv in cfg.get("mcp", {}).get("servers", {}).items():
    if srv.get("type") != "local":
        continue
    cmd = srv.get("command") or []
    binary = cmd[0] if cmd else None
    status = "ok" if binary and shutil.which(binary) else "MISSING"
    print(f"{name}: {binary}: {status}")
EOF
```

- Remote-серверы пропускаются: им локальные бинари не нужны.
- Об отсутствующих бинарях сообщить пользователю. Самостоятельно ничего не
  устанавливать: способ установки зависит от окружения (например, для `npx`
  нужен установленный Node.js).
- Независимо от результата проверки окружение ansible считается готовым,
  если шаги 1-4 завершились успешно.

## Ограничения

- Не править `requirements.txt`, `requirements.yml`, `ansible.cfg` и
  `opencode.json` в рамках подготовки окружения: если для работы нужен новый
  пакет, роль или MCP-сервер - сообщить пользователю.
- Не запускать плейбуки и vault-операции в этом скилле - для этого есть
  отдельные скиллы (`ansible-run`, `ansible-vault`).
- Не удалять и не пересоздавать существующий virtualenv без явного запроса
  пользователя.
