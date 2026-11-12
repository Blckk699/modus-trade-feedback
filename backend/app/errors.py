"""Доменные ошибки и единый формат ответа об ошибке.

Любая ошибка API отдаётся так (см. contract/openapi.yaml):

    {"error": {"code": "<snake_case>", "message": "<текст по-русски>", "details": {...} | null}}

Бизнес-код поднимает наследника `AppError`; обработчики ниже превращают его в ответ.
"""

from __future__ import annotations

import logging
from typing import Any

from fastapi import FastAPI, Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

log = logging.getLogger(__name__)


class AppError(Exception):
    status_code: int = 400
    code: str = "bad_request"
    message: str = "Некорректный запрос"

    def __init__(
        self,
        message: str | None = None,
        *,
        code: str | None = None,
        details: dict[str, Any] | None = None,
        status_code: int | None = None,
    ) -> None:
        self.message = message or self.message
        self.code = code or self.code
        self.details = details
        if status_code is not None:
            self.status_code = status_code
        super().__init__(self.message)


class ValidationFailed(AppError):
    status_code = 422
    code = "validation_error"
    message = "Проверьте заполнение полей"


class Unauthorized(AppError):
    status_code = 401
    code = "unauthorized"
    message = "Требуется вход в систему"


class UserNotRegistered(AppError):
    status_code = 403
    code = "user_not_registered"
    message = "Вас нет в списке сотрудников. Обратитесь к администратору."


class UserDisabled(AppError):
    status_code = 403
    code = "user_disabled"
    message = "Доступ отключён. Обратитесь к администратору."


class InvalidTelegramAuth(AppError):
    status_code = 401
    code = "invalid_telegram_auth"
    message = "Не удалось подтвердить вход через Telegram."


class InvalidLoginCode(AppError):
    status_code = 401
    code = "invalid_login_code"
    message = "Код неверный или истёк. Запросите новый код в боте."


class DevLoginDisabled(AppError):
    status_code = 403
    code = "dev_login_disabled"
    message = "Dev-вход выключен."


class FileTooLarge(AppError):
    status_code = 413
    code = "file_too_large"
    message = "Файл слишком большой."


class TooManyRequests(AppError):
    status_code = 429
    code = "too_many_requests"
    message = "Слишком много неудачных попыток. Подождите и попробуйте снова."


class Forbidden(AppError):
    status_code = 403
    code = "forbidden"
    message = "Недостаточно прав для этого действия"


class NotFound(AppError):
    status_code = 404
    code = "not_found"
    message = "Не найдено"


class Conflict(AppError):
    status_code = 409
    code = "conflict"
    message = "Действие конфликтует с текущим состоянием"


class InvalidTransition(Conflict):
    code = "invalid_transition"
    message = "Такой переход статуса недопустим"


class VotingClosed(Conflict):
    code = "voting_closed"
    message = "Обсуждение завершено."


class AlreadyRegistered(Conflict):
    code = "already_registered"
    message = "Вы уже есть в системе. Войдите."


class InvalidCredentials(AppError):
    status_code = 401
    code = "invalid_credentials"
    message = "Неверная почта или пароль."


class AccessRequestPending(AppError):
    status_code = 403
    code = "access_request_pending"
    message = "Заявка на рассмотрении. Войти можно после одобрения."


class AccessRequestRejected(AppError):
    status_code = 403
    code = "access_request_rejected"
    message = "Заявка на доступ отклонена."


class PasswordChangeRequired(AppError):
    status_code = 403
    code = "password_change_required"
    message = "Это временный пароль. Задайте новый."


class EmailTaken(Conflict):
    code = "email_taken"
    message = "Эта почта уже зарегистрирована. Войдите или попросите администратора сбросить пароль."


class TelegramTaken(Conflict):
    code = "telegram_taken"
    message = "Этот Telegram уже привязан к другому сотруднику."


class LastLoginMethod(Conflict):
    code = "last_login_method"
    message = "Сначала задайте почту и пароль — иначе вы не сможете войти."


class InviteInvalid(AppError):
    status_code = 410
    code = "invite_invalid"
    message = "Приглашение недействительно. Подайте заявку на доступ."


class ExternalServiceError(AppError):
    """Внешний сервис (Claude, ElevenLabs, Telegram, Битрикс24) не ответил или ответил ошибкой."""

    status_code = 503
    code = "external_service_unavailable"
    message = "Внешний сервис временно недоступен"


_HTTP_CODES: dict[int, tuple[str, str]] = {
    400: ("bad_request", "Некорректный запрос"),
    401: ("unauthorized", "Требуется вход в систему"),
    403: ("forbidden", "Недостаточно прав для этого действия"),
    404: ("not_found", "Не найдено"),
    405: ("method_not_allowed", "Метод не поддерживается"),
    409: ("conflict", "Действие конфликтует с текущим состоянием"),
    413: ("payload_too_large", "Слишком большой запрос"),
    415: ("unsupported_media_type", "Неподдерживаемый тип данных"),
    422: ("validation_error", "Проверьте заполнение полей"),
    429: ("too_many_requests", "Слишком много запросов"),
}


def error_body(code: str, message: str, details: dict[str, Any] | None = None) -> dict[str, Any]:
    return {"error": {"code": code, "message": message, "details": details}}


def _response(status: int, code: str, message: str, details: Any = None, headers=None) -> JSONResponse:
    return JSONResponse(
        status_code=status,
        content=jsonable_encoder(error_body(code, message, details)),
        headers=headers,
    )


async def _app_error(_: Request, exc: AppError) -> JSONResponse:
    return _response(exc.status_code, exc.code, exc.message, exc.details)


async def _validation_error(_: Request, exc: RequestValidationError) -> JSONResponse:
    # Формат контракта: {"fields": [{"field": "reason", "message": "..."}]}. `field` — путь без "body".
    fields = []
    for err in exc.errors():
        loc = [str(part) for part in err.get("loc", [])]
        if loc and loc[0] == "body":
            loc = loc[1:]
        fields.append({"field": ".".join(loc) or None, "message": err.get("msg", ""), "type": err.get("type", "")})
    return _response(422, ValidationFailed.code, ValidationFailed.message, {"fields": fields})


async def _http_error(_: Request, exc: StarletteHTTPException) -> JSONResponse:
    code, message = _HTTP_CODES.get(exc.status_code, ("http_error", "Ошибка запроса"))
    detail = exc.detail if isinstance(exc.detail, str) else None
    # Текст Starlette по умолчанию английский ("Not Found") — его не показываем.
    details = {"detail": detail} if detail and exc.status_code not in _HTTP_CODES else None
    return _response(exc.status_code, code, message, details, headers=getattr(exc, "headers", None))


async def _unhandled(_: Request, exc: Exception) -> JSONResponse:
    log.exception("Необработанная ошибка", exc_info=exc)
    return _response(500, "internal_error", "Внутренняя ошибка сервера")


def install_error_handlers(app: FastAPI) -> None:
    app.add_exception_handler(AppError, _app_error)
    app.add_exception_handler(RequestValidationError, _validation_error)
    app.add_exception_handler(StarletteHTTPException, _http_error)
    app.add_exception_handler(Exception, _unhandled)
