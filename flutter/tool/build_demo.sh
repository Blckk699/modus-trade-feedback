#!/usr/bin/env bash
# Сборки для демо на реальном сервере (без публикации).
#   flutter/tool/build_demo.sh [адрес сервера]   по умолчанию https://modus.systm.kz
# Android: подписанный release APK — build/app/outputs/flutter-apk/app-release.apk.
#   Ключ подписи — android/key.properties (в .gitignore, хранится вне репозитория).
#   Без него APK подписывается отладочным ключом.
# iOS: сборка для симулятора (release для симулятора Flutter не поддерживает) —
#   build/ios/iphonesimulator/Runner.app; запуск: xcrun simctl install booted <app> && xcrun simctl launch booted kz.modustrade.modusFeedback
set -euo pipefail

URL="${1:-https://modus.systm.kz}"
cd "$(dirname "$0")/.."

if [ ! -f android/key.properties ]; then
  echo "Внимание: нет android/key.properties — release APK будет подписан отладочным ключом." >&2
fi

flutter build apk --release --dart-define=API_BASE_URL="$URL"
flutter build ios --simulator --debug --dart-define=API_BASE_URL="$URL"
echo "Готово: сервер $URL"
