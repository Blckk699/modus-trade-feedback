#!/bin/sh
# Хуки Claude Code для шины. Токен читается из .mcp.json в корне репозитория и не попадает в текст команды хука:
# если хук упадёт, Claude Code покажет агенту только «sh .../bus/hook.sh <режим>», без токена.
#   sh bus/hook.sh post <PostToolUse|UserPromptSubmit>   уведомление о новой почте
#   sh bus/hook.sh usage                                  счётчик агентов (данные хука из stdin)
#   sh bus/hook.sh stop                                   запрет завершать ход с непрочитанной почтой (данные из stdin)
# Любая ошибка — тихий выход с кодом 0: хук не должен мешать работе агента.
ROOT=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd) || exit 0
TOK=$(grep -o 'bus_[A-Za-z0-9_-]*' "$ROOT/.mcp.json" 2>/dev/null | head -1)
[ -n "$TOK" ] || exit 0
BUS="https://systm.kz/bus"

case "$1" in
  post)
    curl -sf -m 5 -H "Authorization: Bearer $TOK" "$BUS/api/hook/post?event=${2:-PostToolUse}" 2>/dev/null ;;
  usage)
    curl -s -m 5 -X POST -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' \
      --data-binary @- "$BUS/api/hook/usage" >/dev/null 2>&1 ;;
  stop)
    curl -sf -m 10 -X POST -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' \
      --data-binary @- "$BUS/api/hook/stop" 2>/dev/null ;;
esac
exit 0
