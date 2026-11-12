"""Настройки бота из окружения (.env.example — полный список)."""

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Токен продуктового бота от @BotFather. Те же имена переменных, что у бэкенда.
    telegram_bot_token: SecretStr | None = None
    # Сервисный ключ: бот ходит в API с X-Service-Key и X-Telegram-Id пользователя.
    bot_service_key: SecretStr | None = None
    # Хост API без префикса /api/v1. Локально — мок Prism или бэкенд.
    api_base_url: str = "http://localhost:4011"
    api_timeout_seconds: float = 15.0
    # Адрес Mini App (HTTPS). Без него кнопки Mini App не показываются.
    mini_app_url: str | None = None
    # Как часто забирать очередь уведомлений бэкенда, секунд.
    notifications_poll_seconds: float = 3.0
    # Карточки HTML-виджетами (Bot API 10.4). false — прежние текстовые сообщения.
    widgets_enabled: bool = True

    def mini_app_link(self, path: str | None) -> str | None:
        """Адрес экрана Mini App по маршруту клиента из контракта (`/appeals/21`)."""
        if not self.mini_app_url:
            return None
        base = self.mini_app_url.rstrip("/")
        return base + path if path else base

    def missing(self) -> list[str]:
        """Обязательные переменные, без которых бот не запускается."""
        missing = []
        if not self.telegram_bot_token or not self.telegram_bot_token.get_secret_value():
            missing.append("TELEGRAM_BOT_TOKEN")
        if not self.bot_service_key or not self.bot_service_key.get_secret_value():
            missing.append("BOT_SERVICE_KEY")
        return missing
