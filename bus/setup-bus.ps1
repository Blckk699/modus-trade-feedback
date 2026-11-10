# Подключает Claude Code в этой копии репозитория к шине агентов (комната modus). Для Windows.
# Запуск из любой папки внутри репозитория:
#   powershell -ExecutionPolicy Bypass -File bus\setup-bus.ps1 <путь к файлу токена>
# Токен не печатается. Он попадает только в два локальных файла, которые игнорирует git:
#   .mcp.json                     — MCP-сервер шины `bus`
#   .claude\settings.local.json   — хуки через bus/hook.sh (токен в командах хуков не пишется)
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

# Хуки вызывают bus/hook.sh: он сам читает токен из .mcp.json, поэтому в командах хуков токена нет.
$H = 'sh "${CLAUDE_PROJECT_DIR:-.}/bus/hook.sh"'
function Cmd([string]$c) { @{ type = "command"; command = $c } }

$Mcp = @{ mcpServers = @{ bus = @{ type = "http"; url = "$Bus/mcp"; headers = @{ Authorization = "Bearer $Tok" } } } }
$Settings = [ordered]@{
  enabledMcpjsonServers = @("bus")
  hooks = [ordered]@{
    SessionStart     = @(@{ hooks = @(Cmd "$H usage") })
    SessionEnd       = @(@{ hooks = @(Cmd "$H usage") })
    SubagentStop     = @(@{ hooks = @(Cmd "$H usage") })
    PreToolUse       = @(@{ matcher = "Agent|Task"; hooks = @(Cmd "$H usage") })
    UserPromptSubmit = @(@{ hooks = @(Cmd "$H post UserPromptSubmit") })
    PostToolUse      = @(@{ matcher = "*"; hooks = @(Cmd "$H post PostToolUse") })
    Stop             = @(@{ hooks = @(Cmd "$H stop") })
  }
}

$Utf8 = New-Object System.Text.UTF8Encoding($false)   # без BOM, иначе Claude Code не прочитает JSON
[IO.File]::WriteAllText((Join-Path $Root ".mcp.json"), ($Mcp | ConvertTo-Json -Depth 10), $Utf8)
[IO.File]::WriteAllText((Join-Path $Root ".claude\settings.local.json"), ($Settings | ConvertTo-Json -Depth 10), $Utf8)

Write-Host "Готово: шина подключена. Перезапустите Claude Code в этой папке и проверьте командой /mcp, что сервер bus подключён."
