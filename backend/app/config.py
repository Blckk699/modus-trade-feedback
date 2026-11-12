"""Настройки приложения из переменных окружения (и файла `.env`, если он есть)."""

from __future__ import annotations

import re
from datetime import time, timedelta, timezone
from functools import cached_property

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_OFFSET_RE = re.compile(r"^(?:UTC)?([+-])(\d{1,2}):?(\d{2})?$")


def parse_utc_offset(value: str) -> timezone:
    """`+05:00`, `+5`, `UTC+05:00` -> фиксированный часовой пояс."""
    match = _OFFSET_RE.match(value.strip())
    if not match:
        raise ValueError(f"TIMEZONE должен быть смещением вида +05:00, получено {value!r}")
    sign, hours, minutes = match.groups()
    delta = timedelta(hours=int(hours), minutes=int(minutes or 0))
    if delta > timedelta(hours=14):
        raise ValueError(f"Смещение часового пояса вне диапазона: {value!r}")
    return timezone(-delta if sign == "-" else delta, name=f"UTC{sign}{int(hours):02d}:{int(minutes or 0):02d}")


def to_async_url(url: str) -> str:
    """Приводит адрес базы к драйверу asyncpg: `postgresql://` -> `postgresql+asyncpg://`."""
    for prefix in ("postgresql+asyncpg://", "postgresql+psycopg://", "postgresql://", "postgres://"):
        if url.startswith(prefix):
            return "postgresql+asyncpg://" + url[len(prefix):]
    return url


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_url: str = "postgresql+asyncpg://modus:modus@localhost:5432/modus"

    # Вход для разработки с выбором пользователя (B-03). На сервере для демо выключен.
    dev_login_enabled: bool = False
    # Сервисный ключ бота: заголовок X-Service-Key.
    bot_service_key: str = ""

    anthropic_api_key: str = ""
    claude_model: str = "claude-sonnet-5-5"

    elevenlabs_api_key: str = ""
    elevenlabs_stt_model: str = "scribe_v1"
    elevenlabs_language: str = "rus"

    telegram_bot_token: str = ""

    bitrix24_webhook_url: str = ""
    # Кому назначать задачу в портале (ID пользователя Битрикс24); у вебхука это обязательное поле.
    bitrix24_responsible_id: int = 1

    # Часовой пояс системы — фиксированное смещение, по спеке UTC+5.
    timezone: str = "+05:00"
    # Время ежедневной сводки по часовому поясу системы.
    digest_time: time = time(9, 0)
    # Как часто проверять сроки и эскалацию (B-07).
    escalation_interval_minutes: int = 10

    # Вложения: каталог файлов (в docker — volume) и предельный размер файла.
    attachments_dir: str = "data/attachments"
    attachment_max_bytes: int = 20 * 1024 * 1024

    # Вход (B-03): срок жизни сессии, одноразового кода из бота и данных Telegram (initData, Login Widget).
    session_ttl_days: int = 30
    login_code_ttl_seconds: int = 300
    # initData Mini App живёт, пока открыто приложение; данные виджета — только что подписаны.
    telegram_auth_max_age_seconds: int = 86400
    telegram_widget_max_age_seconds: int = 600
    # Защита кода из бота от перебора: неудачные попытки с одного IP за окно -> 429;
    # столько неудач по всем IP за время жизни кода -> все активные коды сжигаются.
    login_code_max_failures_per_ip: int = 5
    login_code_failure_window_seconds: int = 900
    login_code_burn_after_failures: int = 30
    # Заявки на доступ и приглашения (B-18): не больше N подач с одного Telegram-аккаунта за окно.
    access_request_max_per_window: int = 5
    access_request_window_seconds: int = 3600
    # Перебор токенов приглашений: неудачные попытки с одного IP (у бота — с одного Telegram ID) за окно -> 429.
    invite_max_failures: int = 10
    # Вход по паролю: 5 неудач подряд по почте — блок на 5 минут; общий порог адреса выше (офис за NAT).
    password_max_failures: int = 5
    password_lock_seconds: int = 300
    password_max_failures_per_ip: int = 50
    password_ip_window_seconds: int = 900
    # За NAT офиса все сотрудники на одном адресе: порог адреса выше порога одного человека.
    invite_max_failures_per_ip: int = 100
    invite_failure_window_seconds: int = 900
    # Ссылки приглашений: диплинк бота и страница веба.
    telegram_bot_username: str = "modus_feedback_bot"
    public_web_url: str = "http://localhost:5173"
    # Кому верить в X-Forwarded-For (Caddy). Через запятую, можно подсети.
    trusted_proxies: str = "127.0.0.1,::1"

    # Фоновый воркер внутри процесса API. В тестах выключен: задачи гоняются вручную.
    jobs_worker_enabled: bool = True
    jobs_poll_seconds: float = 5.0

    @field_validator("timezone")
    @classmethod
    def _check_timezone(cls, value: str) -> str:
        parse_utc_offset(value)
        return value

    @cached_property
    def tz(self) -> timezone:
        return parse_utc_offset(self.timezone)

    @property
    def async_database_url(self) -> str:
        return to_async_url(self.database_url)


def get_settings() -> Settings:
    return Settings()
