#!/bin/sh
# Сторож почты шины. Ждёт новое непрочитанное сообщение и завершается, как только оно пришло.
# Запускать фоном из Claude Code (Bash с run_in_background: true): когда фоновая команда завершается,
# сессия просыпается, даже если её ход уже закончен. Почту сторож не помечает прочитанной —
# прочитай её через bus_inbox (или sh bus/inbox.sh) и запусти сторожа снова.
#   sh bus/watch-mail.sh [интервал опроса в секундах, по умолчанию 15]
cd "$(git rev-parse --show-toplevel)" || exit 2
TOK=$(grep -o 'bus_[A-Za-z0-9_-]*' .mcp.json 2>/dev/null | head -1)
if [ -z "$TOK" ]; then
  echo "Нет .mcp.json с токеном шины: сначала запусти bus/setup-bus.sh"
  exit 2
fi
mkdir -p .bus
LAST=$(cat .bus/watch-last-id 2>/dev/null || echo 0)
INTERVAL=${1:-15}

while :; do
  R=$(curl -s -m 20 -H "Authorization: Bearer $TOK" "https://systm.kz/bus/api/peek")
  NEW=""
  for id in $(printf '%s' "$R" | grep -o '"id": [0-9]*' | grep -o '[0-9]*$'); do
    [ "$id" -gt "$LAST" ] && NEW="$NEW #$id"
  done
  if [ -n "$NEW" ]; then
    MAX=$(printf '%s' "$NEW" | tr -d '#' | tr ' ' '\n' | sort -n | tail -1)
    echo "$MAX" > .bus/watch-last-id
    echo "Новая почта на шине:$NEW."
    echo "Прочитай её через bus_inbox (или sh bus/inbox.sh), обработай и снова запусти sh bus/watch-mail.sh фоном."
    exit 0
  fi
  sleep "$INTERVAL"
done
