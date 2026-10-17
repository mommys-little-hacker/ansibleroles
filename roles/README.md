# Роли

Каталог с ролями проекта. Имя каталога = имя роли.

Канонический скелет роли:

```
roles/<имя>/
├── README.md      # Назначение, переменные, пример использования
├── defaults/      # main.yml — переменные по умолчанию (префикс <имя>_)
├── files/         # Статические файлы
├── handlers/      # main.yml — обработчики
├── meta/          # main.yml — метаданные, зависимости
├── tasks/         # main.yml — основная логика
├── templates/     # Jinja2-шаблоны
└── vars/          # main.yml — внутренние переменные
```

Правила — см. [AGENTS.md](../AGENTS.md), процесс добавления роли —
[README.md](../README.md) и [docs/new-role-checklist.md](../docs/new-role-checklist.md).
