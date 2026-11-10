#!/bin/sh
# Читает непрочитанную почту шины через REST и помечает её прочитанной — запасной путь, если MCP-инструменты
# `bus` в сессии ещё не загрузились. Выводит отправителя, тип, тему и текст каждого сообщения.
#   sh bus/inbox.sh          прочитать и пометить прочитанным
#   sh bus/inbox.sh peek     только посмотреть, не помечая
cd "$(git rev-parse --show-toplevel)" || exit 2
TOK=$(grep -o 'bus_[A-Za-z0-9_-]*' .mcp.json 2>/dev/null | head -1)
if [ -z "$TOK" ]; then
  echo "Нет .mcp.json с токеном шины: сначала запусти bus/setup-bus.sh"
  exit 2
fi
EP=inbox
[ "$1" = "peek" ] && EP=peek
curl -s -m 20 -H "Authorization: Bearer $TOK" "https://systm.kz/bus/api/$EP" | python3 -c '
import json, sys
msgs = json.load(sys.stdin)
if not msgs:
    print("Непрочитанных сообщений нет.")
for m in msgs:
    print("#%s %s [%s] %s -> %s: %s" % (m["id"], m["time"], m["type"], m["from"], m["to"], m["subject"]))
    if m.get("reply_to"):
        print("  в ответ на #%s" % m["reply_to"])
    print("  " + m["body"].replace("\n", "\n  "))
    if m.get("refs"):
        print("  ссылки: " + ", ".join(m["refs"]))
'
