#!/usr/bin/env bash
# Генерирует клиент API из contract/openapi.yaml в flutter/packages/modus_api.
# Нужны Node.js 18+ и Java 11+ (openapi-generator). Запуск из любой папки:
#   flutter/tool/generate_api.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/flutter/packages/modus_api"
GEN_VERSION="7.27.0"

rm -rf "$OUT"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"  # openapi-generator-cli пишет openapitools.json в текущую папку
npx -y @openapitools/openapi-generator-cli@2.25.2 version-manager set "$GEN_VERSION" >/dev/null
npx -y @openapitools/openapi-generator-cli@2.25.2 generate \
  -i "$ROOT/contract/openapi.yaml" \
  -g dart \
  -o "$OUT" \
  --additional-properties=pubName=modus_api,pubVersion=1.0.0 \
  --global-property=apiTests=false,modelTests=false,apiDocs=false,modelDocs=false \
  >/dev/null

# Генератор 7.x пишет значение по умолчанию у встроенного enum как вызов приватного
# конструктора (`const Foo_Enum._('form')`), что не компилируется. Меняем на константу enum.
find "$OUT/lib" -name '*.dart' -print0 | xargs -0 perl -pi -e "s/const (\w+_Enum)\._\('(\w+)'\)/\1.\2/g"

rm -rf "$OUT/test" "$OUT/doc" "$OUT/git_push.sh" "$OUT/.travis.yml" "$OUT/.openapi-generator" "$OUT/.openapi-generator-ignore"
echo "Клиент API обновлён: $OUT"
