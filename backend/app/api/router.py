"""Корневой роутер API. Все маршруты — под префиксом /api/v1.

Новый модуль: создайте свой `APIRouter` и подключите его здесь одной строкой.
"""

from fastapi import APIRouter

from app.admin import router as admin
from app.api import health
from app.appeals import actions_router as appeal_actions
from app.appeals import bitrix as appeal_bitrix
from app.appeals import duplicates
from app.appeals import router as appeals
from app.auth import router as auth
from app.directory import router as directory
from app.drafts import router as drafts
from app.notifications import router as notifications

API_PREFIX = "/api/v1"

api_router = APIRouter(prefix=API_PREFIX)
api_router.include_router(health.router)
api_router.include_router(auth.router)
api_router.include_router(appeals.router)
api_router.include_router(appeal_actions.router)
api_router.include_router(duplicates.router)
api_router.include_router(appeal_bitrix.router)
api_router.include_router(directory.router)
api_router.include_router(notifications.router)
api_router.include_router(admin.router)
api_router.include_router(drafts.router)
