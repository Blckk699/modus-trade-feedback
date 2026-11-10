# Подключает Claude Code в этой копии репозитория к шине агентов (комната modus). Для Windows.
# Запуск из любой папки внутри репозитория:
#   powershell -ExecutionPolicy Bypass -File bus\setup-bus.ps1 <путь к файлу токена>
# Токен не печатается. Он попадает только в два локальных файла, которые игнорирует git:
#   .mcp.json                     — MCP-сервер шины `bus`
#   .claude\settings.local.json   — хуки: уведомления о почте, запрет завершать ход с непрочитанной почтой, счётчик агентов
# Хуки Claude Code на Windows выполняются в Git Bash, поэтому команды в них написаны для bash.
param([Parameter(Mandatory = $true)][string]$TokenFile)
$ErrorActionPreference = "Stop"
$Bus = "https://systm.kz/bus"

if (-not (Test-Path $TokenFile)) { Write-Host "Файл токена не найден: $TokenFile"; exit 1 }
$Tok = (Get-Content -Raw $TokenFile).Trim()
if (-not $Tok.StartsWith("bus_")) { Write-Host "В файле не токен шины: он должен начинаться с bus_"; exit 1 }

$Root = (git rev-parse --show-toplevel).Trim()
Set-Location $Root

try {
  Invoke-RestMethod -Method Post -Uri "$Bus/api/status" -Headers @{ Authorization = "Bearer $Tok" } `
    -ContentType "application/json" -Body '{"state":"idle"}' -TimeoutSec 15 | Out-Null
} catch {
  Write-Host "Шина не приняла токен. Проверьте файл токена и интернет."
  exit 1
}

New-Item -ItemType Directory -Force -Path ".claude" | Out-Null
if (Test-Path ".claude\settings.local.json") {
  Copy-Item ".claude\settings.local.json" ".claude\settings.local.json.bak" -Force
  Write-Host "Старые .claude\settings.local.json сохранены в .claude\settings.local.json.bak"
}

$Auth = "-H 'Authorization: Bearer $Tok'"
$Json = "-H 'Content-Type: application/json' --data-binary @-"
function Cmd([string]$c) { @{ type = "command"; command = $c } }
$Usage = "curl -s -m 5 -X POST $Auth $Json '$Bus/api/hook/usage' >/dev/null || true"

$Mcp = @{ mcpServers = @{ bus = @{ type = "http"; url = "$Bus/mcp"; headers = @{ Authorization = "Bearer $Tok" } } } }
$Settings = [ordered]@{
  enabledMcpjsonServers = @("bus")
  hooks = [ordered]@{
    SessionStart     = @(@{ hooks = @(Cmd $Usage) })
    SessionEnd       = @(@{ hooks = @(Cmd $Usage) })
    SubagentStop     = @(@{ hooks = @(Cmd $Usage) })
    PreToolUse       = @(@{ matcher = "Agent|Task"; hooks = @(Cmd $Usage) })
    UserPromptSubmit = @(@{ hooks = @(Cmd "curl -s -m 5 $Auth '$Bus/api/hook/post?event=UserPromptSubmit' || true") })
    PostToolUse      = @(@{ matcher = "*"; hooks = @(Cmd "curl -s -m 5 $Auth '$Bus/api/hook/post?event=PostToolUse' || true") })
    Stop             = @(@{ hooks = @(Cmd "curl -s -m 10 -X POST $Auth $Json '$Bus/api/hook/stop' || true") })
  }
}

$Utf8 = New-Object System.Text.UTF8Encoding($false)   # без BOM, иначе Claude Code не прочитает JSON
[IO.File]::WriteAllText((Join-Path $Root ".mcp.json"), ($Mcp | ConvertTo-Json -Depth 10), $Utf8)
[IO.File]::WriteAllText((Join-Path $Root ".claude\settings.local.json"), ($Settings | ConvertTo-Json -Depth 10), $Utf8)

Write-Host "Готово: шина подключена. Перезапустите Claude Code в этой папке и проверьте командой /mcp, что сервер bus подключён."
