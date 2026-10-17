#!/usr/bin/env bash
# Локальный прогон линтеров: yamllint + ansible-lint.
# VCS-независимая проверка, используется перед коммитом и в чек-листах.
set -euo pipefail

cd "$(dirname "$0")/.."

VENV=".ansibleroles"
if [ ! -x "$VENV/bin/yamllint" ] || [ ! -x "$VENV/bin/ansible-lint" ]; then
    echo "Ошибка: окружение $VENV не найдено или неполное." >&2
    echo "Создайте его по инструкции в README (раздел «Требования»):" >&2
    echo "  python3 -m venv $VENV && source $VENV/bin/activate && pip install ansible ansible-lint yamllint" >&2
    exit 1
fi

"$VENV/bin/yamllint" .
"$VENV/bin/ansible-lint"
