# Модус Трейд — мобильное приложение (Flutter)

Android и iOS. Вход по одноразовому коду из бота, на моке и локально — dev-вход.

## Запуск на моке

```bash
# из корня репозитория: мок-сервер по контракту
npx -y @stoplight/prism-cli@5.15.11 mock -h 0.0.0.0 -p 4010 contract/openapi.yaml
# в другом терминале
cd flutter && flutter run
```

По умолчанию приложение ходит в мок: `http://localhost:4010` с симулятора iOS, `http://10.0.2.2:4010`
с эмулятора Android. Другой сервер — экран «Сервер» на входе или при сборке:

```bash
flutter run --dart-define=API_BASE_URL=https://<адрес сервера>
```

Адрес — хост без `/api/v1`. При смене сервера сессия закрывается.

## Клиент API

`packages/modus_api` сгенерирован из `contract/openapi.yaml` генератором `openapi-generator` (`dart`).
Руками не правится. После изменения контракта:

```bash
flutter/tool/generate_api.sh   # нужны Node.js 18+ и Java 11+
```

## Структура

- `lib/api` — `ApiService` (адрес, токен, доступ к `*Api`) и `AppError` (ошибки контракта).
- `lib/session` — сессия: вход по коду и dev-вход, восстановление при запуске, выход; токен в Keychain/Keystore.
- `lib/navigation/sections.dart` — разделы по `Me.permissions` и стартовый раздел роли.
- `lib/ui` — экраны.

## Проверка

```bash
cd flutter && flutter analyze && flutter test
```
