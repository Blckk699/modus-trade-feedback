"""Общие для бота и e2e/backend_server.py значения. Без импорта бэкенда: у него тоже пакет `app`."""

SERVICE_KEY = "e2e-service-key"
# Токен бота только для e2e: им бэкенд проверяет подпись Telegram Login, а тест ею подписывает.
BOT_TOKEN = "123456:e2e-telegram-login"
FIRST_TELEGRAM_ID = 100_000_001  # Telegram ID демо-пользователя = FIRST_TELEGRAM_ID + номер в app/seed/data.py
