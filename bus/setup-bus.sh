#!/bin/sh
# Подключает Claude Code в этой копии репозитория к шине агентов (комната modus).
# Запуск из любой папки внутри репозитория:  sh bus/setup-bus.sh <путь к файлу токена>
# Токен не печатается. Он попадает только в два локальных файла, которые игнорирует git:
#   .mcp.json                     — MCP-сервер шины `bus`
#   .claude/settings.local.json   — хуки: уведомления о почте, запрет завершать ход с непрочитанной почтой, счётчик агентов
set -e

BUS="https://systm.kz/bus"

if [ -z "$1" ] || [ ! -f "$1" ]; then
  echo "Использование: sh bus/setup-bus.sh <путь к файлу токена>"
  exit 1
fi
TOK=$(tr -d ' \r\n' < "$1")
case "$TOK" in
  bus_*) ;;
  *) echo "В файле не токен шины: он должен начинаться с bus_"; exit 1 ;;
esac

cd "$(git rev-parse --show-toplevel)"

code=$(curl -s -m 15 -o /dev/null -w '%{http_code}' -X POST "$BUS/api/status" \
  -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' -d '{"state":"idle"}')
if [ "$code" != "200" ]; then
  echo "Шина не приняла токен (HTTP $code). Проверьте файл токена и интернет."
  exit 1
fi

mkdir -p .claude
if [ -f .claude/settings.local.json ]; then
  cp .claude/settings.local.json .claude/settings.local.json.bak
  echo "Старые .claude/settings.local.json сохранены в .claude/settings.local.json.bak"
fi

AUTH="-H 'Authorization: Bearer $TOK'"
JSON="-H 'Content-Type: application/json' --data-binary @-"

umask 077
cat > .mcp.json <<EOF
{
  "mcpServers": {
    "bus": {
      "type": "http",
      "url": "$BUS/mcp",
      "headers": { "Authorization": "Bearer $TOK" }
    }
  }
}
EOF

cat > .claude/settings.local.json <<EOF
{
  "enabledMcpjsonServers": ["bus"],
  "hooks": {
    "SessionStart": [{ "hooks": [{ "type": "command", "command": "curl -s -m 5 -X POST $AUTH $JSON '$BUS/api/hook/usage' >/dev/null || true" }] }],
    "SessionEnd": [{ "hooks": [{ "type": "command", "command": "curl -s -m 5 -X POST $AUTH $JSON '$BUS/api/hook/usage' >/dev/null || true" }] }],
    "SubagentStop": [{ "hooks": [{ "type": "command", "command": "curl -s -m 5 -X POST $AUTH $JSON '$BUS/api/hook/usage' >/dev/null || true" }] }],
    "PreToolUse": [{ "matcher": "Agent|Task", "hooks": [{ "type": "command", "command": "curl -s -m 5 -X POST $AUTH $JSON '$BUS/api/hook/usage' >/dev/null || true" }] }],
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "curl -s -m 5 $AUTH '$BUS/api/hook/post?event=UserPromptSubmit' || true" }] }],
    "PostToolUse": [{ "matcher": "*", "hooks": [{ "type": "command", "command": "curl -s -m 5 $AUTH '$BUS/api/hook/post?event=PostToolUse' || true" }] }],
    "Stop": [{ "hooks": [{ "type": "command", "command": "curl -s -m 10 -X POST $AUTH $JSON '$BUS/api/hook/stop' || true" }] }]
  }
}
EOF

echo "Готово: шина подключена. Перезапустите Claude Code в этой папке и проверьте командой /mcp, что сервер bus подключён."
